#!/bin/bash
AWS_REGION="us-west-2"
API_NAME="ETL_API"
API_STAGE="prod"
ETL_STATUS_RESOURCE="status"
API_FUNCTION_NAME="etl_status_api"

echo "Creating API Gateway REST API: $API_NAME"
REST_API_ID=$(aws apigateway create-rest-api --name "$API_NAME" --region $AWS_REGION --query 'id' --output text)
echo "Created REST API with ID: $REST_API_ID"


PARENT_ID=$(aws apigateway get-resources --rest-api-id $REST_API_ID --region $AWS_REGION --query 'items[0].id' --output text)


ETL_RESOURCE_ID=$(aws apigateway create-resource --rest-api-id $REST_API_ID --region $AWS_REGION --parent-id $PARENT_ID --path-part "etl" --query 'id' --output text)
echo "Created /etl resource with ID: $ETL_RESOURCE_ID"


STATUS_RESOURCE_ID=$(aws apigateway create-resource --rest-api-id $REST_API_ID --region $AWS_REGION --parent-id $ETL_RESOURCE_ID --path-part "$ETL_STATUS_RESOURCE" --query 'id' --output text)
echo "Created /etl/$ETL_STATUS_RESOURCE resource with ID: $STATUS_RESOURCE_ID"


aws apigateway put-method --rest-api-id $REST_API_ID --region $AWS_REGION --resource-id $STATUS_RESOURCE_ID --http-method GET --authorization-type "NONE"


LAMBDA_ARN="arn:aws:lambda:$AWS_REGION:$(aws sts get-caller-identity --query Account --output text):function:$API_FUNCTION_NAME"
aws apigateway put-integration --rest-api-id $REST_API_ID --region $AWS_REGION --resource-id $STATUS_RESOURCE_ID --http-method GET \
    --type AWS_PROXY --integration-http-method POST \
    --uri "arn:aws:apigateway:$AWS_REGION:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations"


aws lambda add-permission --function-name $API_FUNCTION_NAME --region $AWS_REGION \
    --statement-id apigateway-etl-status-permission \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$AWS_REGION:$(aws sts get-caller-identity --query Account --output text):$REST_API_ID/*/GET/etl/$ETL_STATUS_RESOURCE"


aws apigateway create-deployment --rest-api-id $REST_API_ID --region $AWS_REGION --stage-name $API_STAGE

API_URL="https://$REST_API_ID.execute-api.$AWS_REGION.amazonaws.com/$API_STAGE/etl/$ETL_STATUS_RESOURCE"
echo "API deployed. Invoke URL: $API_URL"
