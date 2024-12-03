dockerImageName=$(awk 'NR==1 {print $2}' Dockerfile)
echo $dockerImageName

#docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.57.1 -q image -f json --exit-code 0 --severity HIGH --light $dockerImageName > trivy.json
#docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.57.1 -q image -f json --exit-code 1 --severity CRITICAL --light $dockerImageName > trivy.json


trivy image -f json -o trivy.json --severity HIGH --exit-code 0 $dockerImageName
exit_code=$?
echo "Trivy HIGH Severity Exit Code: $exit_code"

     
trivy image -f json -o trivy_critical.json --severity CRITICAL --exit-code 1 $dockerImageName
critical_exit_code=$?
echo "Trivy CRITICAL Severity Exit Code: $critical_exit_code"

if [[ "${critical_exit_code}" -eq 1 ]]; then
        echo "Image scanning failed. CRITICAL vulnerabilities found."
        exit 1
else
        echo "Image scanning passed. No CRITICAL vulnerabilities found."
fi