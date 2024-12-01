#!/bin/bash

echo "Starting rollout check for deployment 'employee-frontend'..."
sleep 60s

echo "Running kubectl rollout status..."
kubectl -n employee rollout status deploy employee-frontend --timeout=30s 2>&1 | tee rollout.log

if ! grep -q "successfully rolled out" rollout.log; then
    echo "Deployment employee-frontend Rollout has Failed"
    echo "Rolling back to the previous deployment..."
    kubectl -n employee rollout undo deploy employee-frontend
    exit 1
else
    echo "Deployment employee-frontend Rollout is Success"
fi

