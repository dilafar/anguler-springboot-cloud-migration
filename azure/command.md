# Get the resource group name of the AKS cluster 
    az aks show --resource-group aks-rg1 --name aks-demo --query nodeResourceGroup -o tsv

# Setting Up External DNS on AKS with Managed Service Identity (MSI)

This guide outlines the steps to configure External DNS on Azure Kubernetes Service (AKS) using Managed Service Identity (MSI). This allows ExternalDNS to securely manage DNS records in Azure DNS Zones.

## Steps to Configure External DNS on AKS

### 1. Gather Required Information
Before setting up External DNS, collect the necessary details:
- **Azure Tenant ID**: Retrieve using `az account show --query "tenantId"`
- **Azure Subscription ID**: Retrieve using `az account show --query "id"`

### 2. Create `azure.json` Configuration File
The `azure.json` file contains authentication details for External DNS to interact with Azure DNS. It includes:
- **Tenant ID**
- **Subscription ID**
- **Resource Group containing DNS zones**
- **User Assigned Managed Identity ID**

```json
{
  "tenantId": "<your-tenant-id>",
  "subscriptionId": "<your-subscription-id>",
  "resourceGroup": "dns-zones", 
  "useManagedIdentityExtension": true,
  "userAssignedIdentityID": "<your-msi-id>"  
}
```

### 3. Review and Apply External DNS Manifests
The `external-dns.yml` file contains Kubernetes resources required for deploying ExternalDNS:
- **ServiceAccount**: Defines access permissions.
- **ClusterRole & ClusterRoleBinding**: Grants necessary RBAC permissions.
- **Deployment**: Deploys External DNS with the correct provider settings for Azure.

### 4. Create Managed Service Identity (MSI) for External DNS
1. Navigate to **Azure Portal** > **Managed Identities** > **Add**
2. Provide the following details:
   - **Resource Name**: `aksdemo1-externaldns-access-to-dnszones`
   - **Subscription**: `Pay-as-you-go`
   - **Resource Group**: `aks-rg1`
   - **Location**: `Central US`
3. Click **Create**

### 5. Assign Azure Role to MSI
1. Navigate to **MSI: aksdemo1-externaldns-access-to-dnszones**
2. Click **Azure Role Assignments** > **Add role assignment**
3. Provide the following details:
   - **Scope**: `Resource group`
   - **Subscription**: `Pay-as-you-go`
   - **Resource Group**: `dns-zones`
   - **Role**: `Contributor`
4. Make a note of **Client ID** from the **Overview** tab and update `azure.json` under `userAssignedIdentityID`.

### 6. Associate MSI with AKS Cluster Virtual Machine Scale Sets (VMSS)
1. Navigate to **Azure Portal** > **Virtual Machine Scale Sets (VMSS)**
2. Open the relevant **AKS VMSS** (e.g., `aks-agentpool-27193923-vmss`)
3. Go to **Settings** > **Identity** > **User assigned** > **Add** > `aksdemo1-externaldns-access-to-dnszones`

### 7. Create Kubernetes Secret and Deploy ExternalDNS
1. Navigate to `kube-manifests/01-ExternalDNS`
2. Create a Kubernetes secret for the `azure.json` file:
   ```sh
   kubectl create secret generic azure-config-file --from-file=azure.json
   ```
3. Verify the created secret:
   ```sh
   kubectl get secrets
   ```
4. Deploy ExternalDNS:
   ```sh
   kubectl apply -f external-dns.yml
   ```
5. Check ExternalDNS logs to verify successful execution:
   ```sh
   kubectl logs -f $(kubectl get po | egrep -o 'external-dns[A-Za-z0-9-]+')
   ```


## Setting Up NGINX Ingress Controller on AKS

This section outlines the steps to install and configure the NGINX Ingress Controller on Azure Kubernetes Service (AKS).

### 1. Retrieve Node Resource Group
To get the node resource group for your AKS cluster, run:
```sh
az aks show --resource-group aks-rg1 --name aksdemo1 --query nodeResourceGroup -o tsv
```
Expected Output:
```
MC_aks-rg_aks-demo_eastus
```

### 2. Create a Public IP Address for Ingress Controller
Create a static public IP address for the ingress controller:
```sh
az network public-ip create --resource-group MC_aks-rg_aks-demo_eastus --name AKSPublicIPForIngress --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv
```
Expected Output:
```
172.191.40.85
```

### 3. Install NGINX Ingress Controller
1. Create a namespace for the ingress controller:
   ```sh
   kubectl create namespace ingress-controller
   ```
2. Add the official stable repository and update Helm charts:
   ```sh
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm repo update
   ```
3. Install the ingress controller using Helm:
   ```sh
   helm install ingress-nginx ingress-nginx/ingress-nginx \
     --namespace ingress-controller \
     --set controller.replicaCount=2 \
     --set controller.nodeSelector."kubernetes\.io/os"=linux \
     --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
     --set controller.service.externalTrafficPolicy=Local \
     --set controller.service.loadBalancerIP="172.191.40.85"
   ```
# Setting Up Azure Key Vault with External Secrets on AKS

This guide outlines the steps to configure Azure Key Vault integration with External Secrets on Azure Kubernetes Service (AKS). This setup allows you to securely fetch secrets from Azure Key Vault into your Kubernetes workloads using Azure Workload Identity.

## Steps to Configure Azure Key Vault with External Secrets on AKS

### 1. Gather Required Information
Before setting up External Secrets, collect the necessary details:
- **Azure Tenant ID**: Retrieve using `az account show --query "tenantId"`
- **Azure Subscription ID**: Retrieve using `az account show --query "id"`

### 2. Install External Secrets Chart
Add the External Secrets Helm chart repository and install it in your AKS cluster to manage secrets.

```sh
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets --namespace external-secrets --create-namespace --set installCRDs=true
```

### 3. Create Azure Key Vault
Create an Azure Key Vault to securely store your secrets.

```sh
az keyvault create --resource-group aks-rg --name keyvault-aks-db
```

### 4. Set a Secret in Azure Key Vault
Add a secret, for example, a database password, to your Key Vault.

```sh
az keyvault secret set --vault-name keyvault-aks-db --name "dbpassword" --value "<password>"
```

### 5. Create a Managed Identity
Create a managed identity that will be used by AKS to access the Azure Key Vault.

```sh
az identity create --name access-keyvault --resource-group aks-rg
```

### 6. Assign Key Vault Access Permissions
Assign the necessary permissions for the managed identity to access secrets in Azure Key Vault.

```sh
export USER_ASSIGNED_IDENTITY_CLIENT_ID="$(az identity show --name access-keyvault --resource-group aks-rg --query 'clientId' -otsv)"
export USER_ASSIGNED_IDENTITY_OBJECT_ID="$(az identity show --name access-keyvault --resource-group aks-rg --query 'principalId' -otsv)"
az keyvault set-policy --name keyvault-aks-db --secret-permissions get --object-id "${USER_ASSIGNED_IDENTITY_OBJECT_ID}"
```

Additionally, assign the `Key Vault Secrets Officer` role to the managed identity.

```sh
az role assignment create --assignee "${USER_ASSIGNED_IDENTITY_OBJECT_ID}" --role "Key Vault Secrets Officer" --scope /subscriptions/<subscription-id>/resourceGroups/aks-rg/providers/Microsoft.KeyVault/vaults/keyvault-aks-db
```

### 7. Create a Kubernetes Service Account for External Secrets
Create a Kubernetes service account for External Secrets with Azure Workload Identity annotations.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${USER_ASSIGNED_IDENTITY_CLIENT_ID}
    azure.workload.identity/tenant-id: ${TENANT_ID}
  name: external-secrets-sa
  namespace: external-secrets
```

Replace `${USER_ASSIGNED_IDENTITY_CLIENT_ID}` and `${TENANT_ID}` with the correct values.

### 8. Configure Federated Identity Credential
Federate the Azure Managed Identity with your AKS cluster by creating a federated identity credential.

```sh
export SERVICE_ACCOUNT_ISSUER="$(az aks show --resource-group aks-rg --name aks-demo --query 'oidcIssuerProfile.issuerUrl' -otsv)"
az identity federated-credential create --name "kubernetes-federated-credential" --identity-name access-keyvault --resource-group aks-rg --issuer "${SERVICE_ACCOUNT_ISSUER}" --subject "system:serviceaccount:external-secrets:external-secrets-sa"
```

### 9. Set Up the External Secrets Provider
Create a `ClusterSecretStore` resource to configure External Secrets to fetch secrets from Azure Key Vault.

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: azure-secret-store
spec:
  provider:
    azurekv:
      authType: WorkloadIdentity
      vaultUrl: "https://keyvault-aks-db.vault.azure.net"
      serviceAccountRef:
        name: external-secrets-sa
        namespace: external-secrets
```

### 10. Create an ExternalSecret Resource
Now, create an `ExternalSecret` resource to pull the secret from Azure Key Vault into Kubernetes.

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: mysql-db-password-secret
  namespace: employee
spec:
  refreshInterval: "1h"
  secretStoreRef:
    name: azure-secret-store
    kind: ClusterSecretStore
  target:
    name: mysql-db-password
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: secret/dbpassword
```

### 11. Verify the Setup
1. Ensure the External Secrets controller is running:

   ```sh
   kubectl get pods -n external-secrets
   ```

2. Verify the secret is created in the target namespace (`employee`):

   ```sh
   kubectl get secret mysql-db-password -n employee
   ```

3. Check the logs of the External Secrets controller for troubleshooting:

   ```sh
   kubectl logs -n external-secrets <external-secrets-pod-name>
   ```



