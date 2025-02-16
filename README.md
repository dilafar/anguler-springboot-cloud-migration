# Full CI/CD pipelines for employee management application, a Java-based dynamic web application with a database.

## Overview

This project is a full-stack Employee Management System developed using **Spring Boot** for the backend and **Angular** for the frontend. It follows **DevSecOps** principles and is deployed on **Azure** using Kubernetes.

## 🛠 Technologies Used

### Backend

- **Spring Boot** (REST API)
- **MySQL** (Azure MySql)
- **Maven** (Build tool)

### Frontend

- **Angular** (UI Framework)

### DevOps Tools

- **CI/CD & Configuration Management**: Jenkins, Ansible, GitHub
- **Containerization & Orchestration**: Kubernetes, Helm, Kustomize, Docker, Docker Compose
- **Security & Compliance**: Cosign, HashiCorp Vault, TruffleHog, Checkstyle, NodeJsScan, SonarQube, Semgrep, Trivy, Kubescape, Hadolint, Retire.js, Maven Dependency Check, OWASP ZAP, Open Policy Agent (OPA), DefectDojo
- **Artifact & Dependency Management**: Nexus Repository, Maven, ArtifactHub
- **Monitoring & Alerting**: Prometheus, Grafana, Alert Manager
- **Infrastructure as Code (IaC)**: Terraform
- **Continuous Deployment & GitOps**: ArgoCD
- **Certificate Manager**: lets encrypt

### Azure Services Used

- **Networking & Load Balancing**: Public IP Address , Azure LoadBalancer, Azure DNS, Azure Virtual Network
- **Compute & Container Management**: AKS, Azure VM
- **Storage & Secrets Management**: Azure Key Vault, Azure MySQL Database
- **Container Registry & CDN**: Azure Container Registry, Azure CloudFront

### Nginx Ingress Controller Installation
#### To install the Nginx Ingress Controller:

### 1. Retrieve Node Resource Group
To get the node resource group for your AKS cluster, run:
```sh
az aks show --resource-group aks-rg1 --name aksdemo1 --query nodeResourceGroup -o tsv
```
### 2. Create a Public IP Address for Ingress Controller
Create a static public IP address for the ingress controller:
```sh
az network public-ip create --resource-group MC_aks-rg_aks-demo_eastus --name AKSPublicIPForIngress --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv
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

### Domain & DNS Management

- **Azure Tenant ID**: Retrieve using `az account show --query "tenantId"`
- **Azure Subscription ID**: Retrieve using `az account show --query "id"`
- **The `azure.json` file contains authentication details for External DNS to interact with Azure DNS. It includes:
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
- **The `external-dns.yml` file contains Kubernetes resources required for deploying ExternalDNS:
   - **ServiceAccount**: Defines access permissions.
   - **ClusterRole & ClusterRoleBinding**: Grants necessary RBAC permissions.
   - **Deployment**: Deploys External DNS with the correct provider settings for Azure.
- **Create Managed Service Identity (MSI) for External DNS
- **Assign Azure Role to MSI
   - **Role**: `Contributor`
- take **Client ID** from the MSI **Overview** tab and update `azure.json` under `userAssignedIdentityID`.
- **Associate MSI with AKS Cluster Virtual Machine Scale Sets (VMSS)
- **Create Kubernetes Secret for the `azure.json` file and Deploy ExternalDNS

### Cert-Manager Installation and Configuration with Let's Encrypt
  
- **Install cert-manager
```sh
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.6.3/cert-manager.yaml
```
- **Once cert-manager is installed, you can configure a ClusterIssuer that uses Let's Encrypt's ACME protocol to request certificates. Below is an example of a ClusterIssuer configuration that uses the HTTP-01 challenge and the NGINX ingress controller.

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    email: fadhilahamed07@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: cert-manager-letsencrypt-key
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
```

### Setting Up Azure Key Vault with External Secrets on AKS

This guide outlines the steps to configure Azure Key Vault integration with External Secrets on Azure Kubernetes Service (AKS). This setup allows you to securely fetch secrets from Azure Key Vault into your Kubernetes workloads using Azure Workload Identity.

### Steps to Configure Azure Key Vault with External Secrets on AKS

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

![azure-ui](https://github.com/user-attachments/assets/754fa815-84d4-4d54-b9dc-d56a2163788a)


## 🚀 Setup & Installation
### Starting services locally without Docker

### 1️⃣ Clone the Repository

```sh
git clone https://github.com/dilafar/anguler-springboot-aws-migration.git
cd anguler-springboot-aws-migration
```

### 2️⃣ Backend Setup (Spring Boot)

#### 🔹 Build & Run Locally

```sh
cd employeemanager
mvn clean install
mvn spring-boot:run
```

### 3️⃣ Frontend Setup (Angular)

#### 🔹 Install Dependencies & Start

```sh
cd employeemanagerfrontend
npm install
ng serve --open
```

### Starting services locally with docker-compose

### 1️⃣ Start All Services

#### 🔹 Run the following command to start the application:

```sh
docker-compose up -d
```
The -d flag runs the services in detached mode.

![docker-compose-up](https://github.com/user-attachments/assets/13172c0b-ef56-48f6-a3d4-568025f24736)

### 2️⃣ Verify Running Containers

#### 🔹 Check the status of running containers:

```sh
docker ps
```

### 3️⃣ Access the Application

```sh
Frontend (Client UI): https://localhost
```

### 4️⃣ Stop Services

#### 🔹 To stop all running containers:

```sh
docker-compose down
```

### 🔍 Additional Notes

- The MySQL container has a health check configured to ensure it is ready before the backend services start.
- Nginx serves as a reverse proxy to route traffic between services.
- The backend services depend on the MySQL service to be healthy before they can start.
- The frontend communicates via Nginx, which handles routing and SSL termination.

  
## 🧾 Architecture diagram of the Employee Management Application

![4th one ](https://github.com/user-attachments/assets/6100fa5c-c928-4bc2-9d99-e3130c7be536)

## 🧾 AKS Cluster 

![Frame 4 (1)](https://github.com/user-attachments/assets/f0e8ddaa-1ff6-47dc-9e6e-6c197cdb7d09)

## 🧾 server provisioning & monitoring
![6th one](https://github.com/user-attachments/assets/c6033846-b4f7-4395-963b-e213fd902442)


## Database Configuration

### 🏢 Default Database (HSQLDB)
By default, the Employee Management application uses an **in-memory database (HSQLDB)**. This database is automatically populated with data at startup. 

### 🛠️ MySQL Configuration
If a persistent database is required, the application can be configured to use **MySQL**. The necessary **Connector/J (MySQL JDBC Driver)** dependency is already included in the `pom.xml` file.

### 🚀 Start a MySQL Database with Docker
You can start a MySQL database using **Docker** with the following command:

```sh
docker run -e MYSQL_ROOT_PASSWORD=petclinic \  
    -e MYSQL_DATABASE=petclinic \  
    -p 3306:3306 \  
    mysql:5.7.8
```

Alternatively, you can install **MySQL Community Server 5.7 GA** manually from the official [MySQL downloads page](https://dev.mysql.com/downloads/).

### 🔧 Configuring MySQL for Production
For **production deployment**, it is recommended to use **AWS RDS (Relational Database Service)** to ensure scalability and reliability.

### 1️⃣ Set Up an AWS RDS Database
- Create an **Amazon RDS instance** with **MySQL** as the database engine.
- Configure **username, password, and host** details.

### 2️⃣ Update `application.yml` with RDS Configuration
Modify the `application.yml` file to include the **AWS RDS** database configuration:

```yaml
spring:
  datasource:
    url: jdbc:mysql://<RDS_HOST>:3306/employeemanager
    username: <RDS_USERNAME>
    password: <RDS_PASSWORD>
    driver-class-name: com.mysql.cj.jdbc.Driver
  jpa:
    database-platform: org.hibernate.dialect.MySQL8Dialect
    hibernate:
      ddl-auto: update
```

### 3️⃣ Start the Application
Run the application with the configured **AWS RDS** database:

```sh
mvn spring-boot:run
```

Now, the Employee Management application is connected to a persistent **AWS RDS MySQL database** and ready for production deployment. 🚀

## 🧾 Argocd App

![argo-azure](https://github.com/user-attachments/assets/b7c3b041-61cf-4bb4-8c30-19c73934b611)

## 🧾 Prometheus and Grafana

![employee-prom-2](https://github.com/user-attachments/assets/de3c3eef-1a39-4c7a-a2dc-2f675744e698)

## 🧾 Azure Key Vault

![azure-key-vault](https://github.com/user-attachments/assets/f9c334c4-92f5-47b2-b7a8-00a347523c16)

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## 📜 License

This project is licensed under the **MIT License**.

