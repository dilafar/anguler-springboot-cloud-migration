#!/bin/bash
dockerImageName=$(awk 'NR==1 {print $2}' Dockerfile)
echo $dockerImageName

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $WORKSPACE:/root/.cache/ --user $(id -u jenkins):$(id -g jenkins) aquasec/trivy:0.57.1 -q image --exit-code 0 --severity HIGH --light $dockerImageName
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $WORKSPACE:/root/.cache/ --user $(id -u jenkins):$(id -g jenkins) aquasec/trivy:0.57.1 -q image --exit-code 1 --severity CRITICAL --light $dockerImageName

    exit_code=$?
    echo "Exit Code : $exit_code"

    if [[ "${exit_code}" == 1 ]]; then
        echo "Image scanning failed. Vulnerabilities found"
        rm -rf /var/lib/jenkins/workspace/my-pipeline/trivy
        exit 1
    else
        echo "Image scanning passed. No CRITICAL vulnerabilities found"
        rm -rf /var/lib/jenkins/workspace/my-pipeline/trivy 
    fi;