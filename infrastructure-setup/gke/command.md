# Configure kubectl
gcloud container clusters get-credentials standered-gke --region us-central1 --project single-portal-443110-r7

# Verify Kubernetes Worker Nodes
kubectl get nodes

# Verify System Pod in kube-system Namespace
kubectl -n kube-system get pods

# Verify kubeconfig file
cat $HOME/.kube/config
kubectl config view

# ExternalDNS 

gcloud iam service-accounts create external-dns-gsa 

gcloud projects add-iam-policy-binding warm-axle-445714-v1 --member "serviceAccount:external-dns-gsa@warm-axle-445714-v1.iam.gserviceaccount.com" --role "roles/dns.admin" 

kubectl create ns external-dns-ns

kubectl create sa external-dns-ksa  -n external-dns-ns

gcloud iam service-accounts add-iam-policy-binding external-dns-gsa@warm-axle-445714-v1.iam.gserviceaccount.com --role roles/iam.workloadIdentityUser --member "serviceAccount:warm-axle-445714-v1.svc.id.goog[external-dns-ns/external-dns-ksa]"

kubectl annotate serviceaccount external-dns-ksa -n external-dns-ns iam.gke.io/gcp-service-account=external-dns-gsa@warm-axle-445714-v1.iam.gserviceaccount.com

kubectl -n external-dns-ns describe sa external-dns-ksa 


kubectl -n external-dns-ns get all

### List pods (external-dns pod should be in running state)
kubectl -n external-dns-ns get pods

### Verify Deployment by checking logs
kubectl -n external-dns-ns logs -f $(kubectl -n external-dns-ns get po | egrep -o 'external-dns[A-Za-z0-9-]+')
[or]
kubectl -n external-dns-ns get pods
kubectl -n external-dns-ns logs -f <External-DNS-Pod-Name>
kubectl get frontendconfig

### List Managed Certificates
kubectl get managedcertificate

### Describe Managed Certificates
kubectl describe managedcertificate managed-cert-for-ingress

# External secret

gcloud iam service-accounts create external-secret-gsa --project=single-portal-443110-r7

gcloud projects add-iam-policy-binding single-portal-443110-r7 --member "serviceAccount:external-secret-gsa@single-portal-443110-r7.iam.gserviceaccount.com" --role "roles/secretmanager.secretAccessor" 

kubectl create ns external-secret-ns

kubectl create sa external-secret-ksa  -n external-secret-ns

gcloud iam service-accounts add-iam-policy-binding external-secret-gsa@single-portal-443110-r7.iam.gserviceaccount.com --role roles/iam.workloadIdentityUser --member "serviceAccount:single-portal-443110-r7.svc.id.goog[external-secret-ns/external-secret-ksa]" --project=single-portal-443110-r7

gcloud iam service-accounts keys create my-key --iam-account=external-secret-gsa@single-portal-443110-r7.iam.gserviceaccount.com

kubectl create secret generic gcpsm-secret --from-file=secret-access-credentials=my-key -n external-secret-ns

kubectl annotate serviceaccount external-secret-ksa -n external-secret-ns iam.gke.io/gcp-service-account=external-secret-gsa@single-portal-443110-r7.iam.gserviceaccount.com

helm repo add external-secrets https://charts.external-secrets.io

helm repo update 

helm upgrade -install external-secrets external-secrets/external-secrets --set 'serviceAccount.annotations.iam\.gke\.io\/gcp-service-account'="external-secret-gsa@single-portal-443110-r7.iam.gserviceaccount.com" --namespace external-secret-ns --create-namespace --debug  --wait

kubectl get all -n external-secret-ns

