dockerImageName=$(awk 'NR==1 {print $2}' Dockerfile)
echo $dockerImageName

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.57.1 -q image -f json --exit-code 0 --severity HIGH --light $dockerImageName > trivy.json
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.57.1 -q image -f json --exit-code 1 --severity CRITICAL --light $dockerImageName > trivy.json

    exit_code=$?
    echo "Exit Code : $exit_code"

    if [[ "${exit_code}" == 1 ]]; then
        echo "Image scanning failed. Vulnerabilities found"
        exit 1
    else
        echo "Image scanning passed. No CRITICAL vulnerabilities found"