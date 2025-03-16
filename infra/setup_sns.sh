#!/bin/bash
AWS_REGION="us-west-2"
SNS_TOPIC_NAME="etl-alerts"

echo "Creating SNS topic: $SNS_TOPIC_NAME"
TOPIC_ARN=$(aws sns create-topic --name $SNS_TOPIC_NAME --region $AWS_REGION --query 'TopicArn' --output text)
echo "Created SNS topic with ARN: $TOPIC_ARN"


EMAIL="youremail@example.com"
aws sns subscribe --topic-arn $TOPIC_ARN --protocol email --notification-endpoint $EMAIL --region $AWS_REGION
echo "Subscription request sent to $EMAIL. Check your email to confirm the subscription."

echo "Update config/settings.json with the SNS topic ARN: $TOPIC_ARN"
