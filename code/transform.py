from datetime import datetime

def transform_data(data):
    """Clean and transform the extracted data."""
    transformed = []
    for item in data:
        try:
            
            if 'Date' in item:
                try:
                    parsed_date = datetime.strptime(item['Date'], '%m/%d/%Y')
                    item['Date'] = parsed_date.strftime('%Y-%m-%d')
                except Exception:
                    
                    item['Date'] = item.get('Date')
            
            if 'Domain' in item and item['Domain'].upper() == 'RESTRAUNT':
                item['Domain'] = 'RESTAURANT'
            
            if 'Value' in item:
                item['Value'] = int(float(item['Value']))
            if 'Transaction_count' in item:
                item['Transaction_count'] = int(float(item['Transaction_count']))
        except Exception as e:
           
            print(f"Transformation error for item {item}: {e}")
            continue
        transformed.append(item)
    return transformed