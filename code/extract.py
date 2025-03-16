import csv
import requests

def extract_data(source):
    """Extract data from a given source (CSV file or API)."""
    data = []
    try:
        if source.startswith("http"):
          
            response = requests.get(source)
            response.raise_for_status()
            content = response.text
           
            reader = csv.DictReader(content.splitlines())
            for row in reader:
                data.append(row)
        else:
           
            with open(source, 'r') as csvfile:
                reader = csv.DictReader(csvfile)
                for row in reader:
                    data.append(row)
    except Exception as e:
        
        print(f"Error during extraction: {e}")
        raise
    return data