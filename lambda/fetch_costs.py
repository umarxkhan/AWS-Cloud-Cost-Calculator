import boto3
import json
import os
from datetime import datetime, timedelta

# -----------------------------
# Environment variables from Lambda
# -----------------------------
DDB_TABLE = os.environ['DDB_TABLE']          # DynamoDB table name
S3_BUCKET = os.environ['S3_BUCKET_NAME']     # Updated to match Terraform variable

# -----------------------------
# Initialize AWS clients
# -----------------------------
ce = boto3.client('ce', region_name='eu-central-1')           # Cost Explorer client
ddb = boto3.resource('dynamodb', region_name='eu-central-1') # DynamoDB resource
s3 = boto3.client('s3', region_name='eu-central-1')          # S3 client

table = ddb.Table(DDB_TABLE)

# -----------------------------
# Helper function to categorize AWS services
# -----------------------------
def categorize_service(service_name):
    service_name = service_name.lower()
    if any(x in service_name for x in ['ec2', 'lambda', 'ecs', 'eks', 'lightsail']):
        return 'Compute'
    elif any(x in service_name for x in ['s3', 'ebs', 'efs', 'glacier']):
        return 'Storage'
    elif any(x in service_name for x in ['rds', 'dynamodb', 'redshift']):
        return 'Database'
    elif any(x in service_name for x in ['vpc', 'cloudfront', 'route 53', 'elb', 'alb']):
        return 'Networking'
    else:
        return 'Other'

# -----------------------------
# Lambda handler
# -----------------------------
def lambda_handler(event, context):
    # --- 1. Calculate yesterday's date ---
    today = datetime.utcnow().date()
    yesterday = today - timedelta(days=1)
    start_str = yesterday.strftime('%Y-%m-%d')
    end_str = today.strftime('%Y-%m-%d')

    # --- 2. Fetch cost data from Cost Explorer ---
    response = ce.get_cost_and_usage(
        TimePeriod={'Start': start_str, 'End': end_str},
        Granularity='DAILY',
        Metrics=['UnblendedCost'],
        GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}]
    )

    # --- 3. Aggregate costs by category ---
    categories = {}
    for group in response['ResultsByTime'][0]['Groups']:
        service_name = group['Keys'][0]
        amount = float(group['Metrics']['UnblendedCost']['Amount'])
        category = categorize_service(service_name)
        categories[category] = categories.get(category, 0.0) + amount

        # --- 4. Store individual service costs in DynamoDB ---
        table.put_item(
            Item={
                'record_date': start_str,
                'service_category': category,
                'service_name': service_name,
                'cost': str(amount)
            }
        )

    total_spend = sum(categories.values())

    # --- 5. Fetch last 14 days trend from DynamoDB ---
    trend = []
    for i in range(14, 0, -1):
        day = today - timedelta(days=i)
        day_str = day.strftime('%Y-%m-%d')

        # Query all items for this day
        response = table.query(
            KeyConditionExpression=boto3.dynamodb.conditions.Key('record_date').eq(day_str)
        )

        day_total = sum(float(item['cost']) for item in response.get('Items', []))
        trend.append({'date': day_str, 'amount': day_total})

    # --- 6. Build dashboard JSON ---
    dashboard_data = {
        'total_spend': total_spend,
        'categories': categories,
        'trend': trend
    }

    # --- 7. Upload JSON to S3 ---
    s3.put_object(
        Bucket=S3_BUCKET,
        Key='data/cost_data.json',
        Body=json.dumps(dashboard_data),
        ContentType='application/json'
    )

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Cost data updated', 'date': start_str})
    }
