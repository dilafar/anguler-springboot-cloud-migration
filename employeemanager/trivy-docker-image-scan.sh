#!/bin/bash

dockerImageName=$(awk 'NR==1 {print $2}' Dockerfile)
echo $dockerImageName

#docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.57.1 -q image  --exit-code 0 --severity HIGH --light $dockerImageName 
#docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.57.1 -q image  --exit-code 1 --severity CRITICAL --light $dockerImageName 

trivy image -f json -o trivy.json --severity HIGH,CRITICAL --exit-code 1 $dockerImageName

exit_code=$?

                                        
if [[ $exit_code -eq 1 ]]; then
    echo "Image scanning failed on $dockerImageName. HIGH or CRITICAL vulnerabilities found."
    exit 1
else
    echo "Image scanning passed. No HIGH or CRITICAL vulnerabilities found."
fi