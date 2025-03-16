#!/bin/bash
# Configuration variables (modify these as needed)
DB_INSTANCE_ID="my-etl-db"
DB_NAME="etl_db"
DB_USER="admin"
DB_PASS="YourPassword123"
DB_INSTANCE_CLASS="db.t2.micro"
DB_ENGINE="mysql"
DB_ENGINE_VERSION="8.0"
AWS_REGION="us-west-2"

echo "Creating RDS database instance: $DB_INSTANCE_ID..."
aws rds create-db-instance \
    --db-instance-identifier $DB_INSTANCE_ID \
    --engine $DB_ENGINE \
    --engine-version $DB_ENGINE_VERSION \
    --master-username $DB_USER \
    --master-user-password $DB_PASS \
    --db-name $DB_NAME \
    --db-instance-class $DB_INSTANCE_CLASS \
    --allocated-storage 20 \
    --no-multi-az \
    --publicly-accessible \
    --storage-type gp2 \
    --region $AWS_REGION

echo "Waiting for RDS instance to become available (this may take several minutes)..."
aws rds wait db-instance-available --db-instance-identifier $DB_INSTANCE_ID --region $AWS_REGION


RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_ID --region $AWS_REGION --query 'DBInstances[0].Endpoint.Address' --output text)
echo "RDS instance is available. Endpoint: $RDS_ENDPOINT"

echo "Update your config/settings.json with the RDS endpoint before running the pipeline."
