### download latest policy file
    curl -o iam_policy_latest.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
### create iam policy
    aws iam create-policy \
      --policy-name AWSLoadBalancerControllerIAMPolicy \
      --policy-document file://iam_policy_latest.json

### Policy ARN
    Policy ARN:  arn:aws:iam::130488647343:policy/AWSLoadBalancerControllerIAMPolicy

### Verify if any existing service account
    kubectl get sa -n kube-system
    kubectl get sa aws-load-balancer-controller -n kube-system

### create iamserviceaccount
    eksctl create iamserviceaccount \
        --cluster=eksdemonew \
        --namespace=kube-system \
        --name=aws-load-balancer-controller \
        --attach-policy-arn=arn:aws:iam::130488647343:policy/AWSLoadBalancerControllerIAMPolicy \
        --override-existing-serviceaccounts \
        --approve

### Verify if any IAM Service Accounts present in EKS Cluster
    eksctl get iamserviceaccount --cluster=eksdemonew

### Verify if any existing service account
    kubectl get sa -n kube-system
    kubectl get sa aws-load-balancer-controller -n kube-system
    kubectl describe sa aws-load-balancer-controller -n kube-system

### region code and account number
    https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
    us-east-1=602401143452.dkr.ecr.us-east-1.amazonaws.com
    
## install aws loadbalancer controller
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=eksdemonew \
        --set serviceAccount.create=false \
        --set serviceAccount.name=aws-load-balancer-controller \
        --set region=us-east-1 \
        --set vpcId=vpc-0363f386a43e395g7 \
        --set image.repository=602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller