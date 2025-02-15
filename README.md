# Full CI/CD pipelines for employee management application, a Java-based dynamic web application with a database.

## Overview

This project is a full-stack Employee Management System developed using **Spring Boot** for the backend and **Angular** for the frontend. It follows **DevSecOps** principles and is deployed on **GCP** using Kubernetes.

## 🛠 Technologies Used

### Backend

- **Spring Boot** (REST API)
- **MySQL** (Cloud SQL)
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

### GCP Services Used

- **Networking & Load Balancing**: cloud load balancing, cloud dns, google managed ssl sertificate, VPC networks, cloud external ip address
- **Compute & Container Management**: gke, Compute Engine
- **Storage & Secrets Management**: cloud sql, secret manager
- **Container Registry & CDN**: google artifact repository, cloud cdn

### External Secret Installation
#### To install the External Secret on GKE:

- A new IAM service account is created for External Secrets to securely access Google Secret Manager.
- The IAM service account needs permission to access secrets stored in Google Secret Manager. The `roles/secretmanager.secretAccessor` role is assigned to allow retrieval of secrets.
- A dedicated namespace is created to manage External Secrets components separately from other workloads.
- A Kubernetes service account is created in the `external-secret-ns` namespace, which will be linked to the Google Cloud IAM service account for authentication.
- The Kubernetes service account is bound to the IAM service account, enabling External Secrets to securely access Google Secret Manager using Workload Identity.
- A service account key is created and stored as a Kubernetes secret. This allows External Secrets to authenticate with Google Secret Manager.
- Annotations are added to the Kubernetes service account to associate it with the corresponding Google Cloud IAM service account, ensuring seamless authentication.
- The External Secrets Helm chart is added, and the deployment is installed with the necessary annotations and namespace settings. This ensures that External Secrets is correctly configured to fetch secrets from 
  Google Secret Manager.
- After deploying External Secrets, all related Kubernetes resources are checked to confirm successful installation and proper functionality.
- A `ClusterSecretStore` resource is created, specifying Google Cloud Secret Manager as the provider. This configuration allows External Secrets to retrieve secrets from Google Secret Manager securely.
- An `ExternalSecret` resource is created, specifying how secrets should be fetched from Google Secret Manager and stored within Kubernetes. This ensures that applications can retrieve secrets dynamically 
  without manually managing them.


### Domain & DNS Management

- The domain is registered on Google Cloud and hosted using Cloud DNS. This allows Kubernetes External DNS to manage DNS records dynamically in a cloud-native manner.
- Kubernetes ExternalDNS is configured to automatically create, update, and delete DNS records based on Kubernetes ingress and service resources, ensuring a cloud-agnostic approach.
- To handle Cloud DNS access securely, an IAM service account is created along with the necessary IAM policy. The appropriate IAM role (`roles/dns.admin`) is assigned to this service account, enabling -     
  ExternalDNS to manage DNS records.
- The ExternalDNS deployment is configured to use the Google Cloud IAM service account. This allows ExternalDNS to interact with Cloud DNS and manage DNS records dynamically through Kubernetes ingress or service 
  resources.
- Since the application uses a Google Cloud LoadBalancer, ExternalDNS manages DNS records by monitoring and updating Kubernetes ingress resources, ensuring proper routing and accessibility.
- TLS certificates are provisioned using Google Managed SSL Certificates. These certificates are integrated with Kubernetes ingress resources to enable secure HTTPS connections for applications running on GKE.
- The final step involves deploying the ExternalDNS application in the Kubernetes cluster. This ensures that DNS records are dynamically managed and kept up to date based on Kubernetes resources.

view the code on infrastructure-setup/gke/command.md

![aws-vault-cert](https://github.com/user-attachments/assets/873afc02-8386-4b46-a5fa-b4a5117a5df7)

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

![Server (4)](https://github.com/user-attachments/assets/3a4f0655-2c0e-43b5-94e2-6fb302685b83)

## 🧾 GKE Cluster 

![Frame 2 (5)](https://github.com/user-attachments/assets/9c54b075-e467-42ee-8f00-b79b1a14a856)

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


## 🧾 Prometheus and Grafana

![employee-prom](https://github.com/user-attachments/assets/c0509af9-585a-4a97-b487-3d5399b1b12b)

## 🧾 Secret Manager

![gcp-secret-manager](https://github.com/user-attachments/assets/b5465181-4f5d-452e-bb47-00adea258150)


## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## 📜 License

This project is licensed under the **MIT License**.
