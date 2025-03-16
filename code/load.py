import pymysql

def load_data(data, rds_config):
    """Load the transformed data into the MySQL RDS database."""
    
    connection = pymysql.connect(host=rds_config['endpoint'],
                                 user=rds_config['username'],
                                 password=rds_config['password'],
                                 database=rds_config['db_name'],
                                 port=rds_config.get('port', 3306))
    try:
        with connection.cursor() as cursor:
           
            insert_query = ("INSERT INTO transactions (date, domain, location, value, transaction_count) "
                            "VALUES (%s, %s, %s, %s, %s)")
            for item in data:
                cursor.execute(insert_query, (
                    item.get('Date'),
                    item.get('Domain'),
                    item.get('Location'),
                    item.get('Value'),
                    item.get('Transaction_count')
                ))
        connection.commit()
    except Exception as e:
        
        connection.rollback()
        print(f"Error during load: {e}")
        raise
    finally:
        connection.close()
