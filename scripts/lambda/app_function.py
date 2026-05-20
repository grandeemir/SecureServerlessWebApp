import json
import os
import boto3
import uuid
from botocore.exceptions import ClientError
from datetime import datetime

# Initialize AWS resources
dynamodb = boto3.resource('dynamodb')
s3_client = boto3.client('s3')

# Get configuration from environment variables
TABLE_NAME = os.environ.get('TABLE_NAME')
BUCKET_NAME = os.environ.get('BUCKET_NAME')
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    """
    AWS Lambda handler for the AetherVault application.
    Handles file metadata and S3 presigned URLs.
    """
    http_method = event.get('requestContext', {}).get('http', {}).get('method')
    path = event.get('rawPath')
    
    # Extract username from Cognito JWT claims
    claims = event.get('requestContext', {}).get('authorizer', {}).get('jwt', {}).get('claims', {})
    username = claims.get('username') or claims.get('cognito:username', 'anonymous')

    print(f"Request: {http_method} {path} from user {username}")

    try:
        # GET /files - List user's files
        if http_method == 'GET' and path == '/files':
            return list_files(username)
        
        # POST /files/upload-url - Get presigned URL for upload
        elif http_method == 'POST' and path == '/files/upload-url':
            return get_upload_url(username, event)
            
        # POST /files - Record file metadata
        elif http_method == 'POST' and path == '/files':
            return record_metadata(username, event)
            
        # GET /files/{id}/download-url - Get presigned URL for download
        elif http_method == 'GET' and path.startswith('/files/') and path.endswith('/download-url'):
            file_id = path.split('/')[2]
            return get_download_url(username, file_id)
            
        # DELETE /files/{id} - Delete file
        elif http_method == 'DELETE' and path.startswith('/files/'):
            file_id = path.split('/')[2]
            return delete_file(username, file_id)
        
        else:
            return _build_response(404, {'error': f'Route not found: {http_method} {path}'})
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return _build_response(500, {'error': 'Internal server error'})

def list_files(username):
    """Retrieve all file metadata for a specific user."""
    # Note: In a real production app, use a GSI on 'owner' for efficient querying.
    # For this prototype, we'll filter a scan (not recommended for large tables).
    response = table.scan(
        FilterExpression=boto3.dynamodb.conditions.Attr('owner').eq(username)
    )
    return _build_response(200, response.get('Items', []))

def get_upload_url(username, event):
    """Generate a presigned URL for uploading a file to S3."""
    body = _parse_body(event)
    file_name = body.get('fileName')
    file_type = body.get('fileType', 'application/octet-stream')
    
    if not file_name:
        return _build_response(400, {'error': 'Missing fileName'})
        
    # Create a unique S3 key for the file
    file_id = str(uuid.uuid4())
    s3_key = f"uploads/{username}/{file_id}/{file_name}"
    
    try:
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': BUCKET_NAME,
                'Key': s3_key,
                'ContentType': file_type
            },
            ExpiresIn=3600
        )
        return _build_response(200, {
            'uploadUrl': presigned_url,
            'fileId': file_id,
            's3Key': s3_key
        })
    except ClientError as e:
        return _build_response(500, {'error': str(e)})

def record_metadata(username, event):
    """Record file metadata in DynamoDB after successful upload."""
    body = _parse_body(event)
    file_name = body.get('fileName')
    file_size = body.get('size')
    # In a real app, the client would pass the s3Key/fileId returned from upload-url
    # For this simplified version, we'll re-generate or expect the client to track it.
    
    if not file_name:
        return _build_response(400, {'error': 'Missing metadata'})
        
    file_id = str(uuid.uuid4())
    item = {
        'id': file_id,
        'owner': username,
        'name': file_name,
        'size': file_size,
        'uploadedAt': datetime.now().isoformat(),
        'status': 'active'
    }
    
    table.put_item(Item=item)
    return _build_response(201, item)

def get_download_url(username, file_id):
    """Generate a presigned URL for downloading a file."""
    # 1. Verify ownership from DynamoDB
    response = table.get_item(Key={'id': file_id})
    item = response.get('Item')
    
    if not item or item['owner'] != username:
        return _build_response(403, {'error': 'Access denied or file not found'})
    
    # 2. Generate URL (In a real app, s3Key would be stored in metadata)
    # For now, we reconstruct the expected key structure
    s3_key = f"uploads/{username}/{file_id}/{item['name']}"
    
    try:
        url = s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': BUCKET_NAME, 'Key': s3_key},
            ExpiresIn=3600
        )
        return _build_response(200, {'downloadUrl': url})
    except ClientError as e:
        return _build_response(500, {'error': str(e)})

def delete_file(username, file_id):
    """Delete file metadata and (optionally) the S3 object."""
    response = table.get_item(Key={'id': file_id})
    item = response.get('Item')
    
    if not item or item['owner'] != username:
        return _build_response(403, {'error': 'Access denied'})
        
    table.delete_item(Key={'id': file_id})
    # Optional: Delete from S3 here as well
    return _build_response(204, None)

# --- Helper Functions ---

def _build_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body) if body is not None else ''
    }

def _parse_body(event):
    try:
        body = event.get('body', '{}')
        if event.get('isBase64Encoded'):
             import base64
             body = base64.b64decode(body).decode('utf-8')
        return json.loads(body)
    except:
        return {}
