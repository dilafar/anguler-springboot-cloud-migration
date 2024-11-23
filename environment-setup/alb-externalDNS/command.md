### create externaldns policy
    aws iam create-policy \
      --policy-name AllowExternalDNSUpdates \
      --policy-document file://external_dns.json

### Policy ARN
    arn:aws:iam::170799657422:policy/AllowExternalDNSUpdates

### create iamserviceaccount
    eksctl create iamserviceaccount \
    --name external-dns \
    --namespace default \
    --cluster eksdemonew \
    --attach-policy-arn arn:aws:iam::170799657422:policy/AllowExternalDNSUpdates \
    --approve \
    --override-existing-serviceaccounts

### verify Service Account
    kubectl get sa external-dns
    kubectl describe sa external-dns
    eksctl get iamserviceaccount --cluster eksdemonew

### verify externalDNS logs
    kubectl logs -f $(kubectl get po | egrep -o 'external-dns[A-Za-z0-9-]+')

    
    