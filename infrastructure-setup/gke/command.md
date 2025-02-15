# Configure kubectl
 ```sh
   gcloud container clusters get-credentials standered-gke --region us-central1 --project single-portal-443110-r7
 ```
# Verify Kubernetes Worker Nodes
 ```sh
   kubectl get nodes
 ```
# Verify System Pod in kube-system Namespace
 ```sh
   kubectl -n kube-system get pods
 ```
# ExternalDNS and External Secrets Configuration on GKE

## ExternalDNS Setup
ExternalDNS is used to automatically manage DNS records in Google Cloud DNS for Kubernetes services.

### Steps to Configure ExternalDNS

1. **Create a Google Service Account (GSA) for ExternalDNS:**
   ```sh
   gcloud iam service-accounts create external-dns-gsa
   ```

2. **Grant DNS Admin Role to the Service Account:**
   ```sh
   gcloud projects add-iam-policy-binding warm-axle-445714-v1 --member "serviceAccount:external-dns-gsa@warm-axle-445714-v1.iam.gserviceaccount.com" --role "roles/dns.admin"
   ```

3. **Create a Kubernetes Namespace for ExternalDNS:**
   ```sh
   kubectl create ns external-dns-ns
   ```

4. **Create a Kubernetes Service Account (KSA) for ExternalDNS:**
   ```sh
   kubectl create sa external-dns-ksa -n external-dns-ns
   ```

5. **Bind GSA with KSA using Workload Identity:**
   ```sh
   gcloud iam service-accounts add-iam-policy-binding external-dns-gsa@warm-axle-445714-v1.iam.gserviceaccount.com --role roles/iam.workloadIdentityUser --member "serviceAccount:warm-axle-445714-v1.svc.id.goog[external-dns-ns/external-dns-ksa]"
   ```

6. **Annotate the Kubernetes Service Account:**
   ```sh
   kubectl annotate serviceaccount external-dns-ksa -n external-dns-ns iam.gke.io/gcp-service-account=external-dns-gsa@warm-axle-445714-v1.iam.gserviceaccount.com
   ```
7. **deploy External DNS using the provided configuration file:**
   ```sh
   kubectl apply -f kustomization/platform/external-dns/externalDNS.yml
   ```
8. **Verify the Service Account Setup:**
   ```sh
   kubectl -n external-dns-ns describe sa external-dns-ksa
   ```

9. **Check All Resources in the Namespace:**
   ```sh
   kubectl -n external-dns-ns get all
   ```

10. **List and Verify the ExternalDNS Pod:**
   ```sh
   kubectl -n external-dns-ns get pods
   ```

11. **Check ExternalDNS Logs to Verify Deployment:**
    ```sh
    kubectl -n external-dns-ns logs -f $(kubectl -n external-dns-ns get po | egrep -o 'external-dns[A-Za-z0-9-]+')
    ```

## Managed Certificates

12. **List Managed Certificates:**
    ```sh
    kubectl get managedcertificate
    ```

13. **Describe a Managed Certificate:**
    ```sh
    kubectl describe managedcertificate managed-cert-for-ingress
    ```

---

## External Secrets Setup
External Secrets fetches secrets from Google Secret Manager and injects them into Kubernetes clusters.

### Steps to Configure External Secrets

1. **Create a Google Service Account (GSA) for External Secrets:**
   ```sh
   gcloud iam service-accounts create external-secret-gsa --project=single-portal-443110-r7
   ```

2. **Grant Secret Manager Access to the Service Account:**
   ```sh
   gcloud projects add-iam-policy-binding single-portal-443110-r7 --member "serviceAccount:external-secret-gsa@single-portal-443110-r7.iam.gserviceaccount.com" --role "roles/secretmanager.secretAccessor"
   ```

3. **Create a Kubernetes Namespace for External Secrets:**
   ```sh
   kubectl create ns external-secret-ns
   ```

4. **Create a Kubernetes Service Account (KSA):**
   ```sh
   kubectl create sa external-secret-ksa -n external-secret-ns
   ```

5. **Bind GSA with KSA using Workload Identity:**
   ```sh
   gcloud iam service-accounts add-iam-policy-binding external-secret-gsa@single-portal-443110-r7.iam.gserviceaccount.com --role roles/iam.workloadIdentityUser --member "serviceAccount:single-portal-443110-r7.svc.id.goog[external-secret-ns/external-secret-ksa]" --project=single-portal-443110-r7
   ```

6. **Create a Key for the Service Account and Store It in Kubernetes:**
   ```sh
   gcloud iam service-accounts keys create my-key --iam-account=external-secret-gsa@single-portal-443110-r7.iam.gserviceaccount.com
   kubectl create secret generic gcpsm-secret --from-file=secret-access-credentials=my-key -n external-secret-ns
   ```

7. **Annotate the Kubernetes Service Account:**
   ```sh
   kubectl annotate serviceaccount external-secret-ksa -n external-secret-ns iam.gke.io/gcp-service-account=external-secret-gsa@single-portal-443110-r7.iam.gserviceaccount.com
   ```

8. **Install External Secrets Operator using Helm:**
   ```sh
   helm repo add external-secrets https://charts.external-secrets.io
   helm repo update
   helm upgrade -install external-secrets external-secrets/external-secrets --set 'serviceAccount.annotations.iam.gke.io/gcp-service-account'="external-secret-gsa@single-portal-443110-r7.iam.gserviceaccount.com" --namespace external-secret-ns --create-namespace --debug --wait
   ```

9. **Verify the Deployment:**
   ```sh
   kubectl get all -n external-secret-ns
   ```

### External Secrets Custom Resource Definitions (CRDs)

10. **ClusterSecretStore Configuration:**
    ```yaml
    apiVersion: external-secrets.io/v1beta1
    kind: ClusterSecretStore
    metadata:
      name: gcp-secret-store
    spec:
      provider:
        gcpsm:
          auth:
            secretRef:
              secretAccessKeySecretRef:
                name: gcpsm-secret
                key: secret-access-credentials
                namespace: external-secret-ns
          projectID: single-portal-443110-r7
    ```

11. **ExternalSecret Configuration for MySQL Password:**
    ```yaml
    apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    metadata:
      name: mysql-db-password-secret
      namespace: employee
    spec:
      refreshInterval: 10s
      secretStoreRef:
        name: gcp-secret-store
        kind: ClusterSecretStore
      target:
        name: mysql-db-password
        creationPolicy: Owner

      data:
        - remoteRef:
             key: password
          secretKey: password
    ```


