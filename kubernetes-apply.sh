#!/bin/bash

kubectl config view
cat kustomization/base/frontend-deployment.yml
cat kustomization/base/frontend-service.yml
cat kustomization/base/backend-deployment.yml
cat kustomization/base/backend-service.yml

deploy_component() {
    local COMPONENT_NAME=$1
    local NAMESPACE=$2
    local NEW_IMAGE=$3

    if kubectl get deploy -n $NAMESPACE | grep -q "$COMPONENT_NAME"; then
        CURRENT_IMAGE=$(kubectl get deploy $COMPONENT_NAME -n $NAMESPACE -o=jsonpath='{.spec.template.spec.containers[0].image}')
        echo "Current image for $COMPONENT_NAME: $CURRENT_IMAGE"

        kubectl set image deploy $COMPONENT_NAME $COMPONENT_NAME=$NEW_IMAGE -n $NAMESPACE
        kubectl rollout restart deploy $COMPONENT_NAME -n $NAMESPACE
        kubectl get all -n $NAMESPACE
        kubectl rollout status deploy $COMPONENT_NAME -n $NAMESPACE --timeout 60s

        POD_STATUS=$(kubectl get pods -n $NAMESPACE -l app=$COMPONENT_NAME -o jsonpath='{.items[0].status.phase}')

        if [ "$POD_STATUS" != "Running" ]; then
            echo "Error: Container image for $COMPONENT_NAME is crashing."
            if kubectl rollout history deploy $COMPONENT_NAME -n $NAMESPACE | grep -q "REVISION"; then
                echo "Rolling back $COMPONENT_NAME to previous version..."
                kubectl rollout undo deploy $COMPONENT_NAME -n $NAMESPACE
            else
                echo "Error: No previous version to roll back to for $COMPONENT_NAME."
                exit 1
            fi
        fi
        echo "$COMPONENT_NAME deployment successful"
    else
        kubectl apply -k kustomization/overlays/dev
        kubectl get all -n $NAMESPACE
        kubectl rollout status deploy $COMPONENT_NAME -n $NAMESPACE --timeout 60s

        POD_STATUS=$(kubectl get pods -n $NAMESPACE -l app=$COMPONENT_NAME -o jsonpath='{.items[0].status.phase}')

        if [ "$POD_STATUS" != "Running" ]; then
            echo "Error: Container image for $COMPONENT_NAME is crashing."
            if kubectl rollout history deploy $COMPONENT_NAME -n $NAMESPACE | grep -q "REVISION"; then
                echo "Rolling back $COMPONENT_NAME to previous version..."
                kubectl rollout undo deploy $COMPONENT_NAME -n $NAMESPACE
            else
                echo "Error: No previous version to roll back to for $COMPONENT_NAME."
                exit 1
            fi
        fi
        echo "$COMPONENT_NAME deployment successful"
    fi
}

# frontend check
echo "frontend deployment check...!!!\n"
NEW_FRONTEND_IMAGE="$DOCKER_REPO:frontend-v$IMAGE_VERSION"
deploy_component "employee-frontend" "employee" "$NEW_FRONTEND_IMAGE"

# backend check
echo "backend deployment check...!!!\n"
NEW_BACKEND_IMAGE="$DOCKER_REPO:backend-v$IMAGE_VERSION"
deploy_component "employee-backend" "employee" "$NEW_BACKEND_IMAGE"
