# Get the resource group name of the AKS cluster 
    az aks show --resource-group aks-rg1 --name aks-demo --query nodeResourceGroup -o tsv

# REPLACE - Create Public IP: Replace Resource Group value
    az network public-ip create --resource-group MC_aks-rg1_aks-demo_australiacentral \
                                --name myAKSPublicIPForIngress \
                                --sku Standard \
                                --allocation-method static \
                                --query publicIp.ipAddress \
                                -o tsv
    20.248.120.175

install ingress controller

# Create a namespace for your ingress resources
    kubectl create namespace ingress-controller

# Add the official stable repository
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update

#  Customizing the Chart Before Installing. 
    helm show values ingress-nginx/ingress-nginx


# Replace Static IP captured in Step-02 (without beta for NodeSelectors)
    helm install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-controller \
        --set controller.replicaCount=2 \
        --set controller.nodeSelector."kubernetes\.io/os"=linux \
        --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
        --set controller.service.externalTrafficPolicy=Local \
        --set controller.service.loadBalancerIP="20.248.120.175"     

# List Pods
    kubectl get pods -n ingress-basic
    kubectl get all -n ingress-basic

provide iam permission for modify dns from kubernets
# To get Azure Tenant ID
az account show --query "tenantId"
"a6383c01-86e8-47bf-a624-a462401c5f4b"
# To get Azure Subscription ID
az account show --query "id"
"3e88818b-115e-4822-8976-03b2dcc0472e"
manageidentity - client id
Create azure.json file - userAssignedIdentityID
{
  "tenantId": "a6383c01-86e8-47bf-a624-a462401c5f4b",
  "subscriptionId": "3e88818b-115e-4822-8976-03b2dcc0472e",
  "resourceGroup": "dns-zones", 
  "useManagedIdentityExtension": true,
  "userAssignedIdentityID": "e7d34fff-0238-4a5e-803e-d06b0c251c09"  
}

external-dns.yml

apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
rules:
  - apiGroups: [""]
    resources: ["services","endpoints","pods", "nodes"]
    verbs: ["get","watch","list"]
  - apiGroups: ["extensions","networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get","watch","list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
  - kind: ServiceAccount
    name: external-dns
    namespace: default
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: external-dns
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
        - name: external-dns 
          image: registry.k8s.io/external-dns/external-dns:v0.15.0
          args:
            - --source=service
            - --source=ingress
            #- --domain-filter=example.com # (optional) limit to only example.com domains; change to match the zone created above.
            - --provider=azure
            #- --azure-resource-group=MyDnsResourceGroup # (optional) use the DNS zones from the tutorial's resource group
            - --txt-prefix=externaldns-
          volumeMounts:
            - name: azure-config-file
              mountPath: /etc/kubernetes
              readOnly: true
      volumes:
        - name: azure-config-file
          secret:
            secretName: azure-config-file


Install Cert-Manager 

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml

# Label the ingress-basic namespace to disable resource validation
kubectl label namespace ingress-controller cert-manager.io/disable-validation=true

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io

# Update your local Helm chart repository cache
helm repo update

# Install the cert-manager Helm chart
helm install \
  cert-manager jetstack/cert-manager \
  --namespace ingress-controller \
  --version v1.16.2 \
  --set installCRDs=true





issuer - lets encrypt

apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    # You must replace this email address with your own.
    # Let's Encrypt will use this to contact you about expiring
    # certificates, and issues related to your account.
    email: dkalyanreddy@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: letsencrypt
    # Add a single challenge solver, HTTP01 using nginx
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx            

