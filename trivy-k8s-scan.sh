#!/bin/bash

echo $1 

trivy image --exit-code 0 --severity HIGH --light $1 
trivy image --exit-code 1 --severity CRITICAL --light $1 

    exit_code=$?
    echo "Exit Code : $exit_code"

    if [[ "${exit_code}" == 1 ]]; then
        echo "Image scanning failed. Vulnerabilities found"
        exit 1
    else
        echo "Image scanning passed. No CRITICAL vulnerabilities found"
    fi;