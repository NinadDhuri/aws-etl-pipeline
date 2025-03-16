AWS ETL Pipeline

Introduction
The AWS ETL Pipeline repository contains a serverless ETL (Extract, Transform, Load) solution for processing banking transaction data. The pipeline’s purpose is to automatically extract raw data from a source (CSV file), transform it into a clean, structured format, and load it into a MySQL database on AWS. By leveraging AWS managed services, this pipeline can handle data ingestion with minimal infrastructure management. The end result is a relational database populated with processed transaction records, enabling easy retrieval of insights (e.g. total transactions by location, highest transaction values) using SQL queries. This README provides an overview of the pipeline’s functionality and instructions on setting it up and using it.

ETL Flow
The ETL process is designed to move data from the source CSV through transformation into the target database in a series of well-defined steps:
    Extraction – A new CSV dataset is uploaded (for example, to an S3 bucket). This upload triggers the ETL process. An AWS Lambda function retrieves the raw CSV file contents.
    
    Transformation – The Lambda ETL code reads each record from the CSV and cleans or converts the data. For instance, dates are parsed into a standard format, numerical values are converted from strings (removing symbols like $ or ,), and text fields (like location names) are standardized (e.g. consistent capitalization). Any invalid or corrupt records are skipped or logged for review.
    
    Loading – After transformation, the Lambda connects to an AWS MySQL RDS instance and inserts the cleaned data into the target table. Batch inserts or upsert logic can be used to efficiently load multiple records. Once loading is complete, the Lambda function closes the database connection.
    
    Post-Load – The Lambda logs the outcome (number of records processed, any errors) to Amazon CloudWatch. If the ETL fails at any step, an alert is sent via Amazon SNS to notify the team. On success, the new data is now available in the MySQL database for query and analysis.
 
 The process begins when a CSV file is added to the source (e.g., an S3 bucket or upload location). This triggers an AWS Lambda function that performs the extraction of data from the CSV. Next, the Lambda function applies transformations such as data cleaning (for example, converting date formats and removing currency symbols) and prepares the data for insertion. Finally, the transformed data is loaded into the MySQL RDS database. Throughout the process, logs are recorded to CloudWatch, and any errors will prompt an SNS alert. This end-to-end flow ensures raw data is systematically converted into a query-ready form in the database.

Tech Stack
This ETL pipeline uses a combination of AWS services and technologies, chosen for their serverless capabilities and ease of integration:
    Amazon S3 – Used as the data source for the raw CSV file. S3 provides durable, scalable storage and the ability to trigger events when new files are uploaded, making it an ideal choice to initiate the ETL process.
    
    AWS Lambda – Serves as the compute engine for the ETL. The pipeline’s core logic (file reading, transforming, and database writing) runs in a Lambda function. Lambda was chosen because it’s serverless (no servers to manage), can be triggered by events (like S3 uploads or scheduled tasks), and scales automatically to handle the workload.
    
    Amazon API Gateway – Provides a RESTful API endpoint to interact with the pipeline (specifically for checking status via /etl/status). API Gateway was chosen to securely expose the FastAPI service running in Lambda to external clients, allowing monitoring or control of the ETL via HTTP requests.
    
    FastAPI (Python) – A modern, fast web framework used to implement the API (in the Lambda). FastAPI was selected for its ease of building a lightweight REST API; in this project it powers the /etl/status endpoint, allowing us to quickly develop an HTTP interface for status checks.
    
    Amazon RDS (MySQL) – Acts as the persistent datastore for the transformed data. A MySQL database was chosen to store the cleaned transactions because it offers relational querying with SQL, which is well-suited for analytical queries (sums, counts, etc.). Amazon RDS manages backups, updates, and scaling for the database, reducing maintenance overhead.
    
    Amazon SNS (Simple Notification Service) – Used for alert notifications. SNS was incorporated to send out alerts (e.g., email or SMS) if the ETL pipeline fails or encounters an error. This service was chosen for its simple pub/sub model and the ability to fan-out messages to multiple subscribers, ensuring the development/devOps team is notified of issues immediately.
    
    Amazon CloudWatch – Utilized for logging and monitoring. All Lambda execution logs (including success messages, processed record counts, and error stack traces) are automatically captured in CloudWatch Logs. CloudWatch was chosen because it integrates seamlessly with Lambda and allows setting up Alarms (which can trigger SNS) based on logs or metrics (for example, a CloudWatch Alarm can detect if a Lambda error occurs and notify via SNS).

SQL Schema & Sample Queries
Database Schema
The MySQL database schema for this pipeline is defined in the create_tables.sql script. The main table stores the processed transaction records. Below is the schema definition for the primary table in the database:
sql
Copy
-- Create table for transactions data
CREATE TABLE transactions (
    transaction_id    INT PRIMARY KEY,
    transaction_date  DATETIME,
    account_id        VARCHAR(20),
    location          VARCHAR(50),
    amount            DECIMAL(10,2)
);
transactions: Holds each transaction record after ETL processing.
transaction_id – Unique identifier for the transaction (primary key).
transaction_date – Date and time of the transaction (stored as DATETIME after transformation).
account_id – Account number or identifier associated with the transaction.
location – Location where the transaction took place (e.g., city or branch name).
amount – Transaction amount in numeric form (currency symbols/commas removed, stored as a decimal for precision).
Example Queries
Once data is loaded into the transactions table, you can run SQL queries to retrieve insights. Here are a couple of example queries and their purpose:
sql
Copy
-- Query 1: Total number of transactions and total amount by location
SELECT location, 
       COUNT(*) AS total_transactions, 
       SUM(amount) AS total_amount
FROM transactions
GROUP BY location;
This query returns the total count of transactions and the sum of transaction amounts for each location. It helps identify which locations have the highest number of transactions and the largest transaction volumes.
sql
Copy
-- Query 2: Top 5 transactions by highest value
SELECT transaction_id, account_id, location, amount
FROM transactions
ORDER BY amount DESC
LIMIT 5;
This query fetches the five largest transactions in terms of monetary value, showing which transactions were highest and where they occurred (including the account and location details for context). You can adjust these queries or write new ones to analyze the data further (for example, filtering by date ranges, specific account IDs, or transaction types if those were included in the dataset).




Sample Dataset
The pipeline processes a CSV dataset containing raw transaction records. Below is a small sample from the uploaded CSV file (showing a few rows of raw data) and the corresponding transformed data after the ETL: Sample Raw Data (CSV)
pgsql
Copy
transaction_id,date,account_id,location,amount
1001,1/15/2025,ACC123,New York,"$1,200.50"
1002,1/16/2025,ACC456,Los Angeles,$50.00
1003,1/16/2025,ACC789,new york,$300.75
In the raw data: the date is in MM/DD/YYYY format, the amount values include a currency symbol (and a comma as a thousands separator in the first record), and the location names are not consistent in case (e.g., "New York" vs "new york"). This is how the data might look coming directly from the source. Sample Transformed Data (Loaded into DB)
yaml
Copy
transaction_id | transaction_date | account_id | location    | amount  
1001           | 2025-01-15       | ACC123     | New York    | 1200.50  
1002           | 2025-01-16       | ACC456     | Los Angeles | 50.00  
1003           | 2025-01-16       | ACC789     | New York    | 300.75  
After transformation: dates are standardized to YYYY-MM-DD format (or full datetime as needed), currency symbols and commas are removed from the amount (stored as numeric 1200.50, 50.00, 300.75), and location names are consistently capitalized (e.g., "new york" was corrected to "New York"). This transformed data is what gets loaded into the MySQL database. It is now ready for accurate querying and analysis.

Architecture 
The flow begins with an S3 bucket (left) where the CSV data is stored; an upload event here triggers the ETL Lambda function. The Lambda (ETL) is responsible for reading the file from S3, performing transformations, and then writing the cleaned data to Amazon RDS (MySQL) (right). To enable monitoring, an API Gateway is configured (top) which invokes a separate Lambda running a FastAPI application. This FastAPI Lambda provides the /etl/status endpoint that allows users to check the pipeline status. CloudWatch Logs (bottom) receive all logs from the Lambda functions for monitoring and debugging. In case of any errors during the ETL execution, the Lambda publishes a message to an SNS topic (shown with a notification icon), which in turn sends out email/SMS alerts to subscribers. The architecture is entirely serverless, leveraging managed AWS services to ensure scalability, reliability, and minimal operational maintenance.



Setup & Deployment Instructions
Follow these steps to set up and deploy the ETL pipeline on AWS. The repository includes AWS CLI scripts to automate many of these steps. Ensure you have AWS CLI installed and configured with appropriate credentials before proceeding.
Clone the Repository: Download or clone the aws-etl-pipeline repository to your local machine. Review the code to familiarize yourself with the Lambda functions and configuration files.
Prepare AWS Resources:
S3 Bucket: Create an S3 bucket (if not already created) to hold the CSV data. You can use the AWS CLI or Console. For example, via CLI:
bash
Copy
aws s3 mb s3://<your-bucket-name>
Upload the dataset CSV file to this bucket (e.g., aws s3 cp data/bankdataset.csv s3://<your-bucket-name>/ or use the provided script if available).
RDS MySQL Instance: Launch an Amazon RDS MySQL instance. This can be done through the AWS Console or CLI. Specify a DB instance identifier, master username, and password. For testing or small-scale use, a db.t2.micro instance (with Free Tier if eligible) is sufficient. Note: Save the RDS endpoint, username, and password for the next steps. Also ensure the Lambda will be able to connect to this DB (you might make the DB publicly accessible for simplicity, or configure the Lambda’s VPC access if using private subnets).
Database Setup: Once the MySQL instance is available, connect to it (using MySQL client or AWS Query Editor) and run the create_tables.sql script from the repository. This will create the required schema (e.g., the transactions table) in your database.
Configure Environment Variables: Update the configuration for the ETL Lambda function with the necessary environment variables so it knows how to access the database and other resources. Specifically, set:
DB_HOST – the endpoint of your RDS instance (e.g., mydb.cleabcde123.us-west-2.rds.amazonaws.com).
DB_NAME – the database name (schema name) where the table resides.
DB_USER – the database master username or a dedicated user for the ETL to connect.
DB_PASS – the database password.
S3_BUCKET – the name of the S3 bucket where the CSV is stored (if the code expects it as an env var).
SNS_TOPIC_ARN – the ARN of the SNS topic for alerts (if the Lambda publishes to SNS on failure).
These can be set in the AWS CLI deployment script or after deployment by using aws lambda update-function-configuration for the ETL function. If a configuration file (like a .env or config JSON) is used in the code, update that before packaging.
Deploy the ETL Lambda Function: Use the provided AWS CLI script or commands to package and deploy the ETL Lambda. This typically involves zipping the Lambda code and using aws lambda create-function (or updating if it already exists) with the appropriate IAM role. For example:
bash
Copy
aws lambda create-function --function-name EtlLambda \
    --runtime python3.9 --handler lambda_function.handler \
    --zip-file fileb://etl_code.zip --role <execution-role-ARN> \
    --environment Variables="{DB_HOST=<...>,DB_NAME=<...>,...}"
(The actual script in the repo may handle these details; follow its usage instructions.)
Set up Trigger for the ETL Lambda: If using S3 event trigger, configure the S3 bucket to notify the Lambda on new object creation. This can be done via the AWS CLI or Console by adding a bucket notification for the .csv object key. The provided setup script might automate this (e.g., using aws s3api put-bucket-notification-configuration to link to the Lambda). If using a scheduled trigger instead, create a CloudWatch Events rule (EventBridge rule) to invoke the Lambda on a schedule (cron/rate expression).
Deploy the FastAPI Lambda and API Gateway: Package the FastAPI application (which provides the /etl/status endpoint) similarly and deploy it as a Lambda function. Then create an API Gateway to expose this Lambda via an HTTP endpoint. The repository might include an AWS CLI script to set up API Gateway routes and link them to the Lambda using an AWS Proxy integration. If so, run that script. Otherwise, manually create a REST API in API Gateway, define a resource /etl/status with GET method, and integrate it with the FastAPI Lambda (using Lambda Proxy integration). Deploy the API to a stage (e.g., “prod”) to get a invoke URL. Note the base URL for the deployed API (you’ll use it to call the status endpoint).
SNS Topic and Subscription: Ensure an SNS Topic is created (via CLI or AWS Console) for pipeline alerts. If not already created by a script, do:
bash
Copy
aws sns create-topic --name etl-pipeline-alerts
Take the Topic ARN and set it as an environment variable (SNS_TOPIC_ARN) in the ETL Lambda configuration (as done in step 3). Subscribe your email or phone number to the topic to receive notifications:
bash
Copy
aws sns subscribe --topic-arn <SNS_TOPIC_ARN> --protocol email --notification-endpoint <youremail@example.com>
Confirm the subscription from your email before testing the pipeline.
Test the Pipeline: With everything deployed, perform a test run. For example, upload a test CSV file to the S3 bucket (if S3 trigger is enabled). This should invoke the ETL Lambda. Monitor the Lambda’s execution (via CloudWatch logs or the Lambda console) to see that it processed the file and loaded data into RDS. If the Lambda encounters an error, it should send an SNS alert — check your email for any SNS notification.
Alternatively, if no S3 trigger, you can manually invoke the Lambda via the AWS Console or CLI (aws lambda invoke) with a test event pointing to the S3 file key.
Verify Data Load: After the Lambda completes, connect to the MySQL database and verify that the data has been inserted into the transactions table. Run a simple SELECT query (or one of the sample queries above) to ensure records are present.
Check API Endpoint: Finally, test the /etl/status API endpoint. (See the next section for usage details.) This confirms that the API Gateway and status Lambda are working and able to communicate.
Following these steps, you will have the ETL pipeline running in your AWS environment. The provided scripts in the repository are meant to simplify resource creation and deployment, so use them as needed for your setup. Always clean up or delete resources (S3 bucket, RDS instance, Lambdas, etc.) when they are no longer needed to avoid incurring ongoing costs.


API Usage (ETL Status)
If the pipeline is deployed with the FastAPI-based status endpoint, you can interact with it to retrieve the ETL pipeline’s status or metadata. The API is exposed via API Gateway at the path /etl/status. Here’s how to use it:
Method: GET
Endpoint: /etl/status (on your deployed API Gateway base URL)
(For example, if your API Gateway URL is https://abc123.execute-api.us-west-2.amazonaws.com/prod, the full URL would be https://abc123.execute-api.us-west-2.amazonaws.com/prod/etl/status.)
When you send a GET request to this endpoint, the Lambda running FastAPI will respond with a JSON object containing the status information. There is no authentication by default (unless you added API keys or authorizers), so any client with the URL can call it. Example usage:
bash
Copy
# Using curl to get ETL status (replace <API_URL> with your API Gateway base URL)
curl -X GET <API_URL>/etl/status 
Example Response:
json
Copy
{
  "status": "Success",
  "last_run": "2025-03-15T22:00:00Z",
  "records_processed": 12345
}
In this example, the JSON indicates the last ETL run was successful, provides a timestamp for the last run, and shows how many records were processed in that run. The actual response format depends on how the FastAPI endpoint is implemented. It might include fields such as:
"status" – could be a message or code (e.g., "Success", "Failed", "Running") indicating the state of the ETL process.
"last_run" – a timestamp or human-readable date of the last pipeline execution.
"records_processed" – number of records processed or loaded in the last run.
"error_message" – (optional) if the last run failed, an error summary might be provided.
Use tools like curl, Postman, or a web browser to hit the endpoint. If the pipeline was just triggered or is running, the status might show as running/in-progress (if implemented). Typically, however, since the ETL Lambda runs quickly and then exits, this status endpoint is mainly to report on the last completed run or overall system health. Note: The actual URL of the API Gateway is not provided here for security reasons. Replace <API_URL> with your deployment’s URL. If you used the provided scripts, the deployment process might output the URL for convenience.




Monitoring & Troubleshooting
Monitoring the ETL pipeline is crucial for maintaining reliability. This pipeline uses AWS CloudWatch and SNS for monitoring and alerting:
CloudWatch Logging: All actions performed by the Lambda functions (both the ETL Lambda and the API Lambda) are logged to AWS CloudWatch. You can view these logs in the CloudWatch Logs console. There will be a log group for each Lambda (e.g., /aws/lambda/EtlLambda and /aws/lambda/StatusApiLambda). Within the log streams, you can find detailed logs such as the number of records read from the file, how many were successfully inserted into the DB, and any error stack traces if exceptions occurred.
Usage: In AWS Console, navigate to CloudWatch > Logs > Log Groups, find the relevant Lambda log group, and inspect the latest log stream for recent runs. This is the first place to check when troubleshooting issues (e.g., if data didn’t appear in the database, the logs might show a database connection error or data format issue).
CloudWatch Metrics: AWS Lambda automatically records certain metrics like invocation count, duration, errors, and throttles. In CloudWatch Metrics, you can find these under the Lambda namespace. If desired, you can set up CloudWatch Alarms on these metrics. For example, you might create an alarm that triggers if the Lambda function errors more than once in a given timeframe.
SNS Alerts: The pipeline is configured to send alerts via Amazon SNS for failures. This could be implemented in two ways:
Application-Level Alerts: The Lambda function’s code catches runtime exceptions during the ETL process (e.g., a database insert failure or file parsing error) and explicitly publishes a message to the SNS topic (using the AWS SDK). The message can contain details like the error message or which step failed. If the SNS topic has an email subscription, you would receive an email with this information promptly after the failure occurs.
CloudWatch Alarm to SNS: Alternatively, a CloudWatch Alarm can be set to monitor the Lambda’s error metric and send an SNS notification when an error is detected. This is a configuration that can be set up if not using the application-level approach.
In this pipeline, the typical approach is the first: the ETL Lambda will invoke SNS on catching an error. To ensure you receive these alerts, double-check that your SNS subscription is confirmed and that the Lambda has permission to publish to the SNS topic (the IAM role for Lambda should include SNS publish rights to the topic).
Troubleshooting Tips:
If no data appears in the database, check the Lambda logs for connectivity issues (e.g., cannot connect to RDS – might be a VPC configuration or security group issue) or data errors.
If the Lambda function timed out (visible in CloudWatch logs or Lambda console), consider increasing the timeout setting or assess if the dataset is too large for a single run (see the Future Enhancements section for scaling solutions).
If you did not receive an SNS email on failure, verify in the SNS console whether the message was published (there are metrics for number of messages published) and that your subscription is in Confirmed status. Also verify the Lambda environment variable for SNS_TOPIC_ARN is correct.
Use the /etl/status API to cross-check the pipeline’s state. If it reports a failure status or hasn’t updated after a run, that indicates the ETL might have stopped before completion.
By using CloudWatch and SNS together, you get both detailed internal logs and immediate external notifications. This helps in quickly detecting and diagnosing any problems in the pipeline.
