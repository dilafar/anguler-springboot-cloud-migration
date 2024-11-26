## Verify eksctl version
    eksctl version

## Verify EKS Cluster version
    kubectl version --short

## create eks cluster
    eksctl create cluster --name=eksdemonew \
                      --region=us-east-1 \
                      --zones=us-east-1a,us-east-1b \
                      --without-nodegroup 

## create and associate iam oidc provider
    eksctl utils associate-iam-oidc-provider \
                        --region us-east-1 \
                        --cluster eksdemonew \
                        --approve

## create public node group
    eksctl create nodegroup --cluster=eksdemonew \
                       --region=us-east-1 \
                       --name=eksdemonew-ng-public1 \
                       --node-type=t3.medium \
                       --nodes=2 \
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
                       --alb-ingress-access 

## create private nodegroup

### get nodegroup and delete
    eksctl get nodegroup --cluster=eksdemonew
    eksctl delete nodegroup eksdemonew-ng-public1 --cluster eksdemonew

### create private nodegroup
    eksctl create nodegroup --cluster=eksdemonew \
                        --region=us-east-1 \
                        --name=eksdemonew-ng-public1 \
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

### Verfy EKS Cluster
    eksctl get cluster      

### get nodegroup 
    eksctl get nodegroup --cluster=eksdemonew

### Verify if any IAM Service Accounts present in EKS Cluster
    eksctl get iamserviceaccount --cluster=eksdemonew

### Configure kubeconfig for kubectl
    aws eks --region us-east-1 update-kubeconfig --name eksdemonew

### verify nodes
    kubectl get nodes -o wide