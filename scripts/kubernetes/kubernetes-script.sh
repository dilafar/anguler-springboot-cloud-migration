#!/bin/bash

kubectl apply -f ../../kustomization/platform/rbac/jenkins-setup.yml

JENKINS_TOKEN=$(kubectl get secret jenkins-token -n employee -o jsonpath='{.data.token}' | base64 --decode)

JENKINS_USER="jenkins"
CLUSTER_NAME=$(kubectl config view -o jsonpath='{.clusters[0].name}')
CLUSTER_SERVER=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')

kubectl config set-credentials ${JENKINS_USER} --token="${JENKINS_TOKEN}"

kubectl config set-context ${JENKINS_USER}@${CLUSTER_NAME} \
  --cluster=${CLUSTER_NAME} \
  --user=${JENKINS_USER} \
  --namespace=employee

kubectl config use-context ${JENKINS_USER}@${CLUSTER_NAME}

kubectl config current-context

kubectl config view

echo "Test kubeconfig.................."

kubectl auth can-i get pods --as=system:serviceaccount:employee:jenkins
kubectl auth can-i get service --as=system:serviceaccount:employee:jenkins
kubectl auth can-i create service --as=system:serviceaccount:employee:jenkins

kubectl get pods -n employee