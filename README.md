# SecureServerlessWebApp

Terraform project that provisions a secure AWS serverless web app with:

- CloudFront (TLS-only) in front of a private S3 static site (OAC + blocked public access)
- API Gateway HTTP API integrated with AWS Lambda
- Cognito User Pool + JWT authorizer for protected API routes
- DynamoDB with KMS encryption and point-in-time recovery
- KMS-backed encryption and CloudWatch logs retention for Lambda and API

## Prerequisites

- Terraform >= 1.5
- AWS credentials with permissions to create the resources above

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

After apply, use outputs:

- `cloudfront_url`
- `api_endpoint`
- `cognito_user_pool_id`
- `cognito_app_client_id`

## Cleanup

```bash
terraform destroy
```
