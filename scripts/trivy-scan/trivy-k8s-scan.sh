#!/bin/bash

echo $1 
echo $2
 
trivy image -f json -o reports/$2 --severity HIGH,CRITICAL --exit-code 1 $1

exit_code=$?

                                        
if [[ $exit_code -eq 1 ]]; then
    echo "Image scanning failed. HIGH or CRITICAL vulnerabilities found."
    exit 1
else
    echo "Image scanning passed. No HIGH or CRITICAL vulnerabilities found."
fi