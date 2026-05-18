import json
import os
import boto3
import uuid
from botocore.exceptions import ClientError

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')

# Get table name from environment variable
TABLE_NAME = os.environ.get('TABLE_NAME', 'TodosTable')
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    """
    AWS Lambda handler for the Todo application.
    Expected to be integrated with API Gateway using HTTP API or REST API.
    """
    
    # Extract HTTP method and path
    http_method = event.get('httpMethod') or event.get('requestContext', {}).get('http', {}).get('method')
    path = event.get('path') or event.get('rawPath')
    
    if not http_method or not path:
        return _build_response(400, {'error': 'Invalid request format. Missing HTTP method or path.'})

    print(f"Received request: {http_method} {path}")

    try:
        if http_method == 'GET' and (path == '/todos' or path == '/todos/'):
            return get_all_todos()
        
        elif http_method == 'GET' and path.startswith('/todos/'):
            todo_id = _get_path_parameter(event, 'id', path)
            if todo_id:
                return get_todo(todo_id)
            return _build_response(400, {'error': 'Missing todo ID'})
        
        elif http_method == 'POST' and (path == '/todos' or path == '/todos/'):
            return create_todo(event)
        
        elif http_method == 'PUT' and path.startswith('/todos/'):
            todo_id = _get_path_parameter(event, 'id', path)
            if todo_id:
                return update_todo(todo_id, event)
            return _build_response(400, {'error': 'Missing todo ID'})
        
        elif http_method == 'DELETE' and path.startswith('/todos/'):
            todo_id = _get_path_parameter(event, 'id', path)
            if todo_id:
                return delete_todo(todo_id)
            return _build_response(400, {'error': 'Missing todo ID'})
        
        else:
            return _build_response(404, {'error': f'Unsupported route: {http_method} {path}'})
            
    except ClientError as e:
        print(f"DynamoDB Error: {e}")
        return _build_response(500, {'error': 'Database operation failed'})
    except Exception as e:
        print(f"Internal Error: {e}")
        return _build_response(500, {'error': 'Internal server error'})

def get_all_todos():
    """Retrieve all todos from DynamoDB."""
    response = table.scan()
    return _build_response(200, response.get('Items', []))

def get_todo(todo_id):
    """Retrieve a specific todo by ID."""
    response = table.get_item(Key={'id': todo_id})
    item = response.get('Item')
    if item:
        return _build_response(200, item)
    return _build_response(404, {'error': 'Todo not found'})

def create_todo(event):
    """Create a new todo."""
    body = _parse_body(event)
    if not body or 'task' not in body:
        return _build_response(400, {'error': 'Missing "task" in request body'})
        
    todo_id = str(uuid.uuid4())
    item = {
        'id': todo_id,
        'task': body['task'],
        'completed': body.get('completed', False)
    }
    
    table.put_item(Item=item)
    return _build_response(201, item)

def update_todo(todo_id, event):
    """Update an existing todo."""
    body = _parse_body(event)
    if not body:
        return _build_response(400, {'error': 'Empty request body'})
        
    update_expression = "SET "
    expression_attribute_values = {}
    expression_attribute_names = {}
    
    if 'task' in body:
        update_expression += "#t = :task, "
        expression_attribute_names['#t'] = 'task'
        expression_attribute_values[':task'] = body['task']
        
    if 'completed' in body:
        update_expression += "completed = :completed, "
        expression_attribute_values[':completed'] = body['completed']
        
    # Remove trailing comma and space
    if update_expression.endswith(', '):
        update_expression = update_expression[:-2]
        
    if not expression_attribute_values:
        return _build_response(400, {'error': 'No fields to update'})
        
    try:
        # Construct kwargs dynamically to avoid boto3 errors if ExpressionAttributeNames is empty
        kwargs = {
            'Key': {'id': todo_id},
            'UpdateExpression': update_expression,
            'ExpressionAttributeValues': expression_attribute_values,
            'ReturnValues': "ALL_NEW"
        }
        if expression_attribute_names:
            kwargs['ExpressionAttributeNames'] = expression_attribute_names
            
        response = table.update_item(**kwargs)
            
        return _build_response(200, response.get('Attributes', {}))
    except ClientError as e:
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            return _build_response(404, {'error': 'Todo not found'})
        raise

def delete_todo(todo_id):
    """Delete a todo."""
    table.delete_item(Key={'id': todo_id})
    return _build_response(204, '')

# --- Helper Functions ---

def _build_response(status_code, body):
    """Build the API Gateway HTTP response object."""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*' # Adjust in production
        },
        'body': json.dumps(body) if body else ''
    }

def _parse_body(event):
    """Safely parse the JSON body from the event."""
    try:
        body = event.get('body', '{}')
        if event.get('isBase64Encoded'):
             import base64
             body = base64.b64decode(body).decode('utf-8')
        return json.loads(body)
    except json.JSONDecodeError:
        return None

def _get_path_parameter(event, param_name, path):
    """Extract path parameter from API Gateway REST or HTTP API event."""
    # Try REST API pathParameters
    path_params = event.get('pathParameters')
    if path_params and param_name in path_params:
        return path_params[param_name]
        
    # Try HTTP API path extraction manually if pathParameters is empty
    parts = path.strip('/').split('/')
    if len(parts) > 1 and parts[0] == 'todos':
        return parts[1]
        
    return None
