import requests
import sys

file_name = sys.argv[1]
scan_type = ''

if file_name == 'njsscan.sarif':
    scan_type = 'SARIF'
elif file_name == 'semgrep.json':
    scan_type = 'Semgrep JSON Report'
elif file_name == 'retire.json':
    scan_type = 'Retire.js Scan'
elif file_name == 'dependency-check-report.json':
   scan_type = 'Dependency Check Scan'

headers = {
            'Authorization': 'Token fea987f6c02f4bc9db7ba7d3afc28589e720cf6b'
          }

url = 'https://demo.defectdojo.org/api/v2/import-scan/'

data = {
    'active': True,
    'verified': True,
    'scan_type': scan_type,
    'minimum_severity': 'Low',
    'engagement': 15
}

files = {
    'file': open(file_name, 'rb')
}

response = requests.post(url, headers=headers, data=data, files=files)

if response.status_code == 201:
    print("scan results imported successfully")
else:
    print(f"Failed to import scan results : {response.content}")