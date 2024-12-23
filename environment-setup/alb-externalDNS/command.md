### create externaldns policy
    aws iam create-policy \
      --policy-name AllowExternalDNSUpdates \
      --policy-document file://external_dns.json

### Policy ARN
    arn:aws:iam::503561445256:policy/AllowExternalDNSUpdates

### create iamserviceaccount
    eksctl create iamserviceaccount \
    --name external-dns \
    --namespace default \
    --cluster eksdemo \
    --attach-policy-arn arn:aws:iam::503561445256:policy/AllowExternalDNSUpdates \
    --approve \
    --override-existing-serviceaccounts

### verify Service Account
    kubectl get sa external-dns
    kubectl describe sa external-dns
    eksctl get iamserviceaccount --cluster eksdemo

arn:aws:iam::503561445256:role/eksctl-eksdemo-addon-iamserviceaccount-defaul-Role1-27DkWPj0rk67

### verify externalDNS logs
    kubectl logs -f $(kubectl get po | egrep -o 'external-dns[A-Za-z0-9-]+')

    
    