#!/bin/bash

kubectl config view
cat kustomization/frontend-deployment.yml
cat kustomization/frontend-service.yml

if kubectl get deploy -n employee | grep -q 'employee-frontend'; then
    
    CURRENT_IMAGE=$(kubectl get deploy employee-frontend -n employee -o=jsonpath='{.spec.template.spec.containers[0].image}')
    echo "Current image: $CURRENT_IMAGE"
    
    NEW_IMAGE="fadhiljr/nginxapp:employee-frontend-v$IMAGE_VERSION"
    
    kubectl set image deploy employee-frontend employee-frontend=$NEW_IMAGE -n employee

    kubectl rollout restart deploy employee-frontend -n employee 

    kubectl get all -n employee

    kubectl rollout status deploy employee-frontend -n employee --timeout 60s

    POD_STATUS=$(kubectl get pods -n employee -l app=employee-frontend -o jsonpath='{.items[0].status.phase}')

    if [ "$POD_STATUS" != "Running" ]; then
        echo "Error: Container image is crashing."

        if kubectl rollout history deploy employee-frontend -n employee | grep -q "REVISION"; then
            echo "Rolling back to previous version..."
            kubectl rollout undo deploy employee-frontend -n employee
        else
            echo "Error: No previous version to roll back to."
            exit 1
        fi
    fi
    echo "deployment successfull"
else

    kubectl apply -k kustomization/
    kubectl get all -n employee

    kubectl rollout status deploy employee-frontend -n employee --timeout 60s


    POD_STATUS=$(kubectl get pods -n employee -l app=employee-frontend -o jsonpath='{.items[0].status.phase}')


    if [ "$POD_STATUS" != "Running" ]; then
        echo "Error: Container image is crashing."


        if kubectl rollout history deploy employee-frontend -n employee | grep -q "REVISION"; then
            echo "Rolling back to previous version..."
            kubectl rollout undo deploy employee-frontend -n employee
        else
            echo "Error: No previous version to roll back to."
            exit 1
        fi
    fi
    echo "deployment successfull"
fi
