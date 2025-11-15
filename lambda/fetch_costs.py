import boto3
import json
import os
from datetime import datetime, timedelta
from boto3.dynamodb.conditions import Key

# -----------------------------
# Environment variables (can be from Lambda or set manually)
# -----------------------------
DDB_TABLE = os.environ.get('DDB_TABLE', 'aws-cost-tracker')          # DynamoDB table name
S3_BUCKET = os.environ.get('S3_BUCKET_NAME', '')                    # S3 bucket name (optional for local)
OUTPUT_FILE = os.environ.get('OUTPUT_FILE', 'data/cost_data.json')  # Output file path

# -----------------------------
# Initialize AWS clients
# -----------------------------
ce = boto3.client('ce', region_name='eu-central-1')           # Cost Explorer client
ddb = boto3.resource('dynamodb', region_name='eu-central-1')  # DynamoDB resource
s3 = boto3.client('s3', region_name='eu-central-1')           # S3 client

table = ddb.Table(DDB_TABLE)

# -----------------------------
# Helper function to categorize AWS services
# -----------------------------
def categorize_service(service_name):
    service_name = service_name.lower()
    if any(x in service_name for x in ['ec2', 'lambda', 'ecs', 'eks', 'lightsail', 'fargate', 'batch']):
        return 'Compute'
    elif any(x in service_name for x in ['s3', 'ebs', 'efs', 'glacier', 'storage']):
        return 'Storage'
    elif any(x in service_name for x in ['rds', 'dynamodb', 'redshift', 'elasticache', 'documentdb']):
        return 'Database'
    elif any(x in service_name for x in ['vpc', 'cloudfront', 'route 53', 'elb', 'alb', 'nlb', 'direct connect', 'transit gateway']):
        return 'Networking'
    else:
        return 'Other'

# -----------------------------
# Initialize all categories with zero
# -----------------------------
def init_categories():
    return {
        'Compute': 0.0,
        'Storage': 0.0,
        'Database': 0.0,
        'Networking': 0.0,
        'Other': 0.0
    }

# -----------------------------
# Get categories for a specific date range from DynamoDB
# -----------------------------
def get_categories_for_period(start_date, end_date):
    categories = init_categories()
    
    current_date = start_date
    while current_date <= end_date:
        day_str = current_date.strftime('%Y-%m-%d')
        
        try:
            response = table.query(
                KeyConditionExpression=Key('record_date').eq(day_str)
            )
            
            for item in response.get('Items', []):
                category = item.get('service_category', 'Other')
                cost = float(item.get('cost', 0))
                if category in categories:
                    categories[category] += cost
        except Exception as e:
            print(f"Warning: Could not query DynamoDB for {day_str}: {e}")
        
        current_date += timedelta(days=1)
    
    return categories

# -----------------------------
# Main function (works as Lambda handler or standalone)
# -----------------------------
def lambda_handler(event=None, context=None):
    # --- 1. Calculate date ranges ---
    today = datetime.utcnow().date()
    yesterday = today - timedelta(days=1)
    start_str = yesterday.strftime('%Y-%m-%d')
    end_str = today.strftime('%Y-%m-%d')
    
    # Previous period (for comparison)
    prev_start = yesterday - timedelta(days=1)
    prev_end = yesterday
    prev_start_str = prev_start.strftime('%Y-%m-%d')
    prev_end_str = prev_end.strftime('%Y-%m-%d')

    # --- 2. Fetch cost data from Cost Explorer ---
    try:
        response = ce.get_cost_and_usage(
            TimePeriod={'Start': start_str, 'End': end_str},
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}]
        )
    except Exception as e:
        print(f"Error fetching from Cost Explorer: {e}")
        raise

    # --- 3. Aggregate costs by category ---
    categories = init_categories()
    
    for group in response['ResultsByTime'][0]['Groups']:
        service_name = group['Keys'][0]
        amount = float(group['Metrics']['UnblendedCost']['Amount'])
        category = categorize_service(service_name)
        categories[category] += amount

        # --- 4. Store individual service costs in DynamoDB ---
        try:
            table.put_item(
                Item={
                    'record_date': start_str,
                    'service_category': category,
                    'service_name': service_name,
                    'cost': str(amount)
                }
            )
        except Exception as e:
            print(f"Warning: Could not write to DynamoDB for {service_name}: {e}")

    total_spend = sum(categories.values())

    # --- 5. Get previous period categories for comparison ---
    categories_previous = get_categories_for_period(prev_start, prev_end)

    # --- 6. Fetch last 30 days trend from DynamoDB (to support different time ranges) ---
    trend = []
    for i in range(30, 0, -1):
        day = today - timedelta(days=i)
        day_str = day.strftime('%Y-%m-%d')

        try:
            # Query all items for this day
            response = table.query(
                KeyConditionExpression=Key('record_date').eq(day_str)
            )

            day_total = sum(float(item.get('cost', 0)) for item in response.get('Items', []))
            trend.append({'date': day_str, 'amount': round(day_total, 2)})
        except Exception as e:
            print(f"Warning: Could not query trend data for {day_str}: {e}")
            # Add zero if query fails
            trend.append({'date': day_str, 'amount': 0.0})

    # --- 7. Build dashboard JSON (matching index.html expectations) ---
    dashboard_data = {
        'total_spend': round(total_spend, 2),
        'categories': {k: round(v, 2) for k, v in categories.items()},
        'categories_previous': {k: round(v, 2) for k, v in categories_previous.items()},
        'trend': trend
    }

    # --- 8. Save JSON locally or upload to S3 ---
    json_output = json.dumps(dashboard_data, indent=2)
    
    # Save to local file
    output_path = OUTPUT_FILE
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        f.write(json_output)
    print(f"Cost data saved to {output_path}")
    
    # Upload to S3 if bucket is specified
    if S3_BUCKET:
        try:
            s3.put_object(
                Bucket=S3_BUCKET,
                Key='data/cost_data.json',
                Body=json_output,
                ContentType='application/json'
            )
            print(f"Cost data uploaded to s3://{S3_BUCKET}/data/cost_data.json")
        except Exception as e:
            print(f"Warning: Could not upload to S3: {e}")

    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Cost data updated',
            'date': start_str,
            'total_spend': total_spend
        })
    }

# -----------------------------
# Allow running as standalone script
# -----------------------------
if __name__ == '__main__':
    # Can set environment variables here for local testing
    # os.environ['DDB_TABLE'] = 'your-table-name'
    # os.environ['S3_BUCKET_NAME'] = 'your-bucket-name'
    
    result = lambda_handler()
    print(json.dumps(result, indent=2))

