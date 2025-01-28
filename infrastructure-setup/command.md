gcloud iam service-accounts create external-dns-gsa 

gcloud projects add-iam-policy-binding warm-axle-445714-v1 --member "serviceAccount:external-dns-gsa@warm-axle-445714-v1.iam.gserviceaccount.com" --role "roles/dns.admin" 

kubectl create ns external-dns-ns

kubectl create sa external-dns-ksa  -n external-dns-ns

gcloud iam service-accounts add-iam-policy-binding external-dns-gsa@warm-axle-445714-v1.iam.gserviceaccount.com --role roles/iam.workloadIdentityUser --member "serviceAccount:warm-axle-445714-v1.svc.id.goog[external-dns-ns/external-dns-ksa]"

kubectl annotate serviceaccount external-dns-ksa -n external-dns-ns iam.gke.io/gcp-service-account=external-dns-gsa@warm-axle-445714-v1.iam.gserviceaccount.com

kubectl -n external-dns-ns describe sa external-dns-ksa 


kubectl -n external-dns-ns get all

# List pods (external-dns pod should be in running state)
kubectl -n external-dns-ns get pods

# Verify Deployment by checking logs
kubectl -n external-dns-ns logs -f $(kubectl -n external-dns-ns get po | egrep -o 'external-dns[A-Za-z0-9-]+')
[or]
kubectl -n external-dns-ns get pods
kubectl -n external-dns-ns logs -f <External-DNS-Pod-Name>
kubectl get frontendconfig

# List Managed Certificates
kubectl get managedcertificate

# Describe Managed Certificates
kubectl describe managedcertificate managed-cert-for-ingress