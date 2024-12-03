#!/bin/bash
dockerImageName=$(awk 'NR==1 {print $2}' Dockerfile)
echo $dockerImageName

trivy image -f json -o trivy.json --exit-code 0 --severity HIGH --light $dockerImageName
trivy image -f json -o trivy.json --exit-code 1 --severity CRITICAL --light $dockerImageName

    exit_code=$?
    echo "Exit Code : $exit_code"

    if [[ "${exit_code}" == 1 ]]; then
        echo "Image scanning failed. Vulnerabilities found"
        exit 1
    else
        echo "Image scanning passed. No CRITICAL vulnerabilities found"
    fi;