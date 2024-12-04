#!/bin/bash

# Wait for initial stabilization
sleep 60s

# Namespace and Deployment variables
NAMESPACE="employee"
DEPLOYMENT="employee-frontend"

# Check the rollout status with a longer timeout
echo "Checking rollout status for deployment: $DEPLOYMENT in namespace: $NAMESPACE"

if ! kubectl -n $NAMESPACE rollout status deploy $DEPLOYMENT --timeout=60s | grep -q "successfully rolled out"; then
    echo "Deployment $DEPLOYMENT rollout has FAILED"

    # Attempt to rollback if history exists
    if kubectl -n $NAMESPACE rollout history deploy $DEPLOYMENT | grep -q "REVISION"; then
        echo "Rolling back deployment $DEPLOYMENT..."
        kubectl -n $NAMESPACE rollout undo deploy $DEPLOYMENT
    else
        echo "No rollback history found for deployment $DEPLOYMENT. Manual intervention required."
    fi

    # Exit with failure
    exit 1
else
    echo "Deployment $DEPLOYMENT rollout is SUCCESSFUL"
fi
