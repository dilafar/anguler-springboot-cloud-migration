# Full CI/CD pipelines for employee management application, a Java-based dynamic web application with a database.
# Employee Management Full-Stack Application

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

## 🚀 Setup & Installation

### 1️⃣ Clone the Repository

```sh
git clone https://github.com/your-repo/employee-management.git
cd employee-management
```

### 2️⃣ Backend Setup (Spring Boot)

#### 🔹 Build & Run Locally

```sh
cd backend
mvn clean install
mvn spring-boot:run
```

#### 🔹 Dockerize the Backend

```sh
docker build -t employee-management-backend .
docker run -p 8080:8080 employee-management-backend
```

### 3️⃣ Frontend Setup (Angular)

#### 🔹 Install Dependencies & Start

```sh
cd frontend
npm install
ng serve --open
```

#### 🔹 Dockerize the Frontend

```sh
docker build -t employee-management-frontend .
docker run -p 4200:80 employee-management-frontend
```

### 4️⃣ Deploying to Kubernetes (AWS EKS)

#### 🔹 Apply Kubernetes Manifests

```sh
kubectl apply -f k8s/
```

#### 🔹 Check Pod Status

```sh
kubectl get pods
```

### 5️⃣ AWS Load Balancer Controller Installation

#### 🔹 Create IAM Policy

```sh
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json
```

#### 🔹 Create IAM Service Account

```sh
eksctl create iamserviceaccount \  
    --cluster <CLUSTER_NAME> \  
    --namespace kube-system \  
    --name aws-load-balancer-controller \  
    --attach-policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \  
    --approve
```

#### 🔹 Install ALB Controller Using Helm

```sh
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \  
    --set clusterName=<CLUSTER_NAME> \  
    --set serviceAccount.create=false \  
    --set serviceAccount.name=aws-load-balancer-controller \  
    -n kube-system
```

### 6️⃣ Domain & DNS Management

#### 🔹 ExternalDNS Setup

```sh
kubectl apply -f external-dns.yaml
```

#### 🔹 Check ExternalDNS Logs

```sh
kubectl logs -f deployment/external-dns -n kube-system
```

### 7️⃣ TLS Certificate for HTTPS

#### 🔹 Request Certificate Using AWS Certificate Manager

```sh
kubectl apply -f cert-manager.yaml
```

### 8️⃣ Continuous Deployment with ArgoCD

#### 🔹 Install ArgoCD

```sh
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

#### 🔹 Access ArgoCD UI

```sh
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### 9️⃣ Monitoring & Logging Setup

#### 🔹 Install Prometheus & Grafana

```sh
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring
helm install grafana grafana/grafana -n monitoring
```

#### 🔹 Access Grafana

```sh
kubectl port-forward svc/grafana -n monitoring 3000:3000
```

## 🔐 Security & Compliance Checks

#### 🔹 Code Quality Analysis

```sh
checkstyle -c /google_checks.xml src/
nodejsscan -d frontend/
```

#### 🔹 SAST Scans

```sh
sonar-scanner
semgrep --config=auto .
```

#### 🔹 Vulnerability Scanning

```sh
trivy image employee-management-backend
kubescape scan framework nsa
```

#### 🔹 DAST Scanning

```sh
owasp-zap -daemon -host 0.0.0.0 -port 8080 -config api.key=12345
```

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






