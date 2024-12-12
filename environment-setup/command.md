# Create Cluster
eksctl create cluster --name=eksdemo1 \
                      --region=us-east-1 \
                      --zones=us-east-1a,us-east-1b \
                      --without-nodegroup 

# Get List of clusters
eksctl get cluster   

# Replace with region & cluster name
eksctl utils associate-iam-oidc-provider \
    --region us-east-1 \
    --cluster eksdemo1 \
    --approve

eksctl create nodegroup --cluster=eksdemo1 \
                        --region=us-east-1 \
                        --name=eksdemo1-ng-private1 \
                        --node-type=t3.medium \
                        --nodes-min=2 \
                        --nodes-max=4 \
                        --node-volume-size=20 \
                        --ssh-access \
                        --ssh-public-key=kube-demo \
                        --managed \
                        --asg-access \
                        --external-dns-access \
                        --full-ecr-access \
                        --appmesh-access \
                        --alb-ingress-access \
                        --node-private-networking   

# Verfy EKS Cluster
eksctl get cluster

# Verify EKS Node Groups
eksctl get nodegroup --cluster=eksdemo

# Verify if any IAM Service Accounts present in EKS Cluster
eksctl get iamserviceaccount --cluster=eksdemo
Observation:
1. No k8s Service accounts as of now. 

# Configure kubeconfig for kubectl
eksctl get cluster # TO GET CLUSTER NAME
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
aws eks --region us-east-1 update-kubeconfig --name eksdemo

# Verify EKS Nodes in EKS Cluster using kubectl
kubectl get nodes
