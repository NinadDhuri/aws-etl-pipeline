from fastapi import FastAPI
import pymysql
import json
from datetime import datetime

app = FastAPI()


with open('config/settings.json') as f:
    config = json.load(f)

@app.get("/etl/status")
def etl_status():
    """Health check endpoint for the ETL pipeline."""
    status = {"status": "OK", "last_run": None, "records_in_db": None}
    try:
      
        conn = pymysql.connect(host=config['rds']['endpoint'],
                               user=config['rds']['username'],
                               password=config['rds']['password'],
                               database=config['rds']['db_name'],
                               port=config['rds'].get('port', 3306))
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM transactions;")
        result = cursor.fetchone()
        if result:
            count = result[0]
        else:
            count = 0
        status['records_in_db'] = count
        cursor.close()
        conn.close()
        status['last_run'] = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')
    except Exception as e:
        status = {"status": "ERROR", "message": str(e)}
    return status


try:
    from mangum import Mangum
    handler = Mangum(app)
except ImportError:
   
    handler = None
