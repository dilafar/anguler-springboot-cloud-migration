#!/bin/bash

# Apply Jenkins setup
kubectl apply -f jenkins-setup.yml

# Get the Jenkins token
JENKINS_TOKEN=$(kubectl get secret jenkins-token -n employee -o jsonpath='{.data.token}' | base64 --decode)

# Set Jenkins user and cluster details
JENKINS_USER="jenkins"
CLUSTER_NAME=$(kubectl config view -o jsonpath='{.clusters[0].name}')
CLUSTER_SERVER=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')

# Check if the context already exists and delete it if so
EXISTING_CONTEXT=$(kubectl config get-contexts -o name | grep "${JENKINS_USER}@${CLUSTER_NAME}")
if [ -n "$EXISTING_CONTEXT" ]; then
  echo "Context ${JENKINS_USER}@${CLUSTER_NAME} already exists. Deleting it."
  kubectl config delete-context ${JENKINS_USER}@${CLUSTER_NAME}
  kubectl config delete-user ${JENKINS_USER}
fi

# Set the new credentials
kubectl config set-credentials ${JENKINS_USER} --token="${JENKINS_TOKEN}"

# Set the new context
kubectl config set-context ${JENKINS_USER}@${CLUSTER_NAME} \
  --cluster=${CLUSTER_NAME} \
  --user=${JENKINS_USER} \
  --namespace=employee

# Use the new context
kubectl config use-context ${JENKINS_USER}@${CLUSTER_NAME}

# Display the current context and view the kubeconfig
kubectl config current-context
kubectl config view

# Test kubeconfig permissions
echo "Test kubeconfig.................."
kubectl auth can-i get pods --as=system:serviceaccount:employee:jenkins
kubectl auth can-i get service --as=system:serviceaccount:employee:jenkins
kubectl auth can-i create service --as=system:serviceaccount:employee:jenkins

# Get the list of pods in the 'employee' namespace
kubectl get pods -n employee
