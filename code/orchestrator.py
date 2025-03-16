import json
import logging
import boto3
from extract import extract_data
from transform import transform_data
from load import load_data


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def lambda_handler(event=None, context=None):
    """AWS Lambda handler to orchestrate the ETL process."""
   
    try:
        with open('config/settings.json') as f:
            config = json.load(f)
    except Exception as e:
        logger.error(f"Failed to load configuration: {e}")
        raise
    
    try:
        logger.info("Starting ETL process...")
        
        source = config.get('etl_source')
        data = extract_data(source)
        logger.info(f"Extracted {len(data)} records.")
        
        data = transform_data(data)
        logger.info(f"Transformed data. Records ready for load: {len(data)}.")
        
        load_data(data, config.get('rds'))
        logger.info("Data loaded into RDS successfully.")
        logger.info("ETL process completed successfully.")
    except Exception as e:
        logger.error(f"ETL process failed: {e}")
        
        try:
            sns_client = boto3.client('sns', region_name=config.get('aws_region'))
            sns_client.publish(
                TopicArn=config.get('sns_topic_arn'),
                Subject='ETL Pipeline Failure',
                Message=f"ETL pipeline failed with error: {e}"
            )
            logger.info("Failure alert sent to SNS.")
        except Exception as sns_error:
            logger.error(f"Failed to send SNS alert: {sns_error}")
       
        raise
