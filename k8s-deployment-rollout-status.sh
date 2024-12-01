#!/bin/bash

sleep 60s

if ! kubectl -n employee rollout status deploy employee-frontend --timeout=30s | grep -q "successfully rolled out"; then
    echo "Deployment employee-frontend Rollout has Failed"
    kubectl -n employee rollout undo deploy employee-frontend
    exit 1
else
    echo "Deployment employee-frontend Rollout is Success"
fi
