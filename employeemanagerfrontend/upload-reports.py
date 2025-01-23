import requests
import sys

file_name = sys.argv[1]
scan_type = ''

if file_name == 'njsscan.sarif':
    scan_type = 'SARIF'
#elif file_name == 'semgrep.json':
#    scan_type = 'Semgrep JSON Report'
elif file_name == 'retire.json':
    scan_type = 'Retire.js Scan'
#elif file_name == 'dependency-check-report.json':
#    scan_type = 'Dependency Check Scan'

headers = {
            'Authorization': 'Token 936454dee286e811f75fc711655b5624a4e89e72'
          }

url = 'https://demo.defectdojo.org/api/v2/import-scan/'

data = {
    'active': True,
    'verified': True,
    'scan_type': scan_type,
    'minimum_severity': 'Low',
    'engagement': 17
}

files = {
    'file': open(file_name, 'rb')
}

response = requests.post(url, headers=headers, data=data, files=files)

if response.status_code == 201:
    print("scan results imported successfully")
else:
    print(f"Failed to import scan results : {response.content}")