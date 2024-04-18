import json
import boto3

def lambda_handler(event, context):
    # Initialize DynamoDB client
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')

    # Query the DynamoDB table
    try:
        response = table.scan()
    except Exception as e:
        print(f"Error querying DynamoDB table: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Error querying DynamoDB table'})
        }

    # Extract user data from the response
    user_data = []
    for item in response['Items']:
        user_data.append({
            'rowid': item['rowid'],
            'username': item['username'],
            'userstatus': item['userstatus']
        })

    # Return the user data as a JSON response
    return {
        'statusCode': 200,
        'body': json.dumps(user_data),
        'headers': {
            'Content-Type': 'application/json'
        }
    }