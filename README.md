# Full CI/CD pipelines for employee management application, a Java-based dynamic web application with a database.

## Overview

This project is a full-stack Employee Management System developed using **Spring Boot** for the backend and **Angular** for the frontend. It follows **DevSecOps** principles and is deployed on **AWS** using Kubernetes.

## 🛠 Technologies Used

### Backend

- **Spring Boot** (REST API)
- **MySQL** (AWS RDS)
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

### AWS Services Used

- **Networking & Load Balancing**: ALB, Route 53, AWS Certificate Manager, VPC
- **Compute & Container Management**: Amazon EKS, Amazon EC2
- **Storage & Secrets Management**: AWS RDS (MySQL), AWS Secrets Manager, AWS S3 Bucket
- **Container Registry & CDN**: Amazon ECR, Amazon CloudFront

### AWS Load Balancer Controller Installation
#### To install the AWS Load Balancer Controller:

- An IAM policy was created to grant the necessary permissions.
- An IAM service account was created and linked to the policy.
- The AWS Load Balancer Controller was installed using Helm, utilizing the created service account.

### Domain & DNS Management

- The domain was registered on Google Cloud and hosted on AWS Route 53.
- Kubernetes ExternalDNS was used to manage DNS records dynamically, ensuring a cloud-agnostic approach.
- To handle Route 53 access, an IAM policy and IAM service account were created, assigning the necessary IAM role to the Kubernetes service account.
- The ExternalDNS deployment was configured with the service account, allowing DNS record management through Kubernetes ingress or service resources.
- Since the application uses an Application Load Balancer (ALB), ExternalDNS manages DNS records via Kubernetes ingress resources.
- TLS certificates were provisioned using AWS Certificate Manager, ensuring secure HTTPS connections through Kubernetes ingress resources.

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

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## 📜 License

This project is licensed under the **MIT License**.




server
![6th one](https://github.com/user-attachments/assets/c6033846-b4f7-4395-963b-e213fd902442)


Architecture Diagram 

![2nd one  (2)](https://github.com/user-attachments/assets/830dd029-c67b-4ebe-a18d-57d9a9f3d226)



EKS Cluster 

![Frame 3 (6)](https://github.com/user-attachments/assets/1a39213c-f513-4564-b832-083188eea7a9)

Backup and Restore

![backup2](https://github.com/user-attachments/assets/c2ac3a8b-63bd-4698-a606-a35af3f9f95c)






