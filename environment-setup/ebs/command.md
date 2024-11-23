## Install AWS-EBS-CSI-Driver in EKS

### create policy
    name: Amazon_EBS_CSI_Driver
    policy: policy.json
    description: policy for  EC2 Instances to access EBS
    
    aws iam create-policy \
      --policy-name Amazon_EBS_CSI_Driver \
      --policy-document file://policy.json

### find iam role of worker node (role can be found under any ec2 worker node)
    kubectl -n kube-system describe configmap aws-auth
### from output check rolearn
    rolearn: arn:aws:iam::180789647333:role/eksctl-eksdemo1-nodegroup-eksdemo-NodeInstanceRole-IJN07ZKXAWNN
#### assign Amazon_EBS_CSI_Driver policy for eksctl-eksdemo1-nodegroup-eksdemo-NodeInstanceRole-IJN07ZKXAWNN role

### Deploy EBS CSI Driver(latest) | kubectl >= 1.14
    kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"

### Verify ebs-csi pods
    kubectl get pods -n kube-system