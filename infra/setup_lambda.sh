#!/bin/bash
AWS_REGION="us-west-2"
LAMBDA_ROLE_ARN="arn:aws:iam::123456789012:role/etl_lambda_role"   # Replace with your IAM role ARN
FUNCTION_NAME="etl_pipeline_function"
API_FUNCTION_NAME="etl_status_api"

echo "Packaging Lambda function code..."
zip -r9 function.zip code config sql > /dev/null

echo "Creating Lambda function for ETL pipeline: $FUNCTION_NAME"
aws lambda create-function \
    --function-name $FUNCTION_NAME \
    --runtime python3.9 \
    --handler orchestrator.lambda_handler \
    --zip-file fileb://function.zip \
    --role $LAMBDA_ROLE_ARN \
    --timeout 900 \
    --memory-size 256 \
    --environment Variables={AWS_REGION=$AWS_REGION} \
    --region $AWS_REGION

echo "Creating Lambda function for ETL status API: $API_FUNCTION_NAME"
aws lambda create-function \
    --function-name $API_FUNCTION_NAME \
    --runtime python3.9 \
    --handler api.handler \
    --zip-file fileb://function.zip \
    --role $LAMBDA_ROLE_ARN \
    --timeout 30 \
    --memory-size 128 \
    --environment Variables={AWS_REGION=$AWS_REGION} \
    --region $AWS_REGION

echo "Lambda functions created successfully."
