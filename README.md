# 📝 Task Manager - Cloud-Native Application

A production-ready cloud-native Task Manager application built with **Java 21 + Spring Boot 3.x**, containerized with **Docker**, deployed on **AWS** using **Terraform**, and automated via **CI/CD (GitHub Actions)**.

---

## 🏗️ Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   GitHub        │────▶│   GitHub        │────▶│   AWS EC2       │
│   Repository    │     │   Actions       │     │   (Docker)      │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                         │
                                                         ▼
                                                ┌─────────────────┐
                                                │   AWS RDS       │
                                                │   (MySQL)       │
                                                └─────────────────┘
```

---

## 📁 Project Structure

```
.
├── src/
│   ├── main/
│   │   ├── java/com/taskmanager/
│   │   │   ├── TaskManagerApplication.java
│   │   │   ├── controller/
│   │   │   │   └── TaskController.java
│   │   │   ├── service/
│   │   │   │   └── TaskService.java
│   │   │   ├── repository/
│   │   │   │   └── TaskRepository.java
│   │   │   └── entity/
│   │   │       └── Task.java
│   │   └── resources/
│   │       ├── application.properties
│   │       └── static/
│   │           ├── index.html
│   │           ├── style.css
│   │           └── script.js
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── .github/
│   └── workflows/
│       └── deploy.yml
├── Dockerfile
├── .dockerignore
├── pom.xml
└── README.md
```

---

## 🛠️ Prerequisites

### Local Development
- **Java 21** (JDK)
- **Maven 3.9+**
- **MySQL 8.0+** (or Docker)

### Production
- **Docker**
- **Terraform 1.0+**
- **AWS CLI**
- **GitHub Account**

---

## ▶️ Run Instructions

### 🔹 Local Run (Development)

#### 1. Install Dependencies

```bash
# Check Java version
java -version

# Check Maven version
mvn -version
```

#### 2. Create Database

```bash
# Using MySQL CLI
mysql -u root -p

# In MySQL shell:
CREATE DATABASE taskdb;
```

#### 3. Set Environment Variables

```bash
# Windows (PowerShell)
$env:DB_URL="jdbc:mysql://localhost:3306/taskdb?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true"
$env:DB_USERNAME="root"
$env:DB_PASSWORD="your_password"

# Linux/Mac
export DB_URL="jdbc:mysql://localhost:3306/taskdb?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true"
export DB_USERNAME="root"
export DB_PASSWORD="your_password"
```

#### 4. Run Application

```bash
mvn spring-boot:run
```

#### 5. Access Application

Open browser: **http://localhost:8080**

---

### 🔹 Docker Run (Containerized)

#### 1. Build Application

```bash
mvn clean package
```

#### 2. Build Docker Image

```bash
docker build -t task-manager .
```

#### 3. Run Container

```bash
# With MySQL container
docker run -d --name mysql-db \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=taskdb \
  mysql:8.0

# Get MySQL container IP
MYSQL_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mysql-db)

# Run app container
docker run -d --name task-app \
  -p 8080:8080 \
  -e DB_URL="jdbc:mysql://${MYSQL_IP}:3306/taskdb?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true" \
  -e DB_USERNAME="root" \
  -e DB_PASSWORD="root" \
  --link mysql-db:mysql \
  task-manager
```

#### 4. Access Application

Open browser: **http://localhost:8080**

#### 5. View Logs

```bash
docker logs -f task-app
```

#### 6. Stop and Remove

```bash
docker stop task-app mysql-db
docker rm task-app mysql-db
```

---

### 🔹 Terraform Deploy (AWS Infrastructure)

#### 1. Install Terraform

```bash
# macOS
brew install terraform

# Windows (using Chocolatey)
choco install terraform

# Linux
sudo apt-get install terraform
```

#### 2. Configure AWS CLI

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter region: ap-south-1
# Enter output format: json
```

#### 3. Navigate to Terraform Directory

```bash
cd terraform
```

#### 4. Initialize Terraform

```bash
terraform init
```

#### 5. Create Variables File

Create `terraform.tfvars`:

```hcl
aws_region       = "ap-south-1"
project_name     = "taskmanager"
db_username      = "admin"
db_password      = "your_secure_password"
```

#### 6. Plan Deployment

```bash
terraform plan
```

#### 7. Apply Deployment

```bash
terraform apply
```

#### 8. Note Outputs

```
ec2_public_ip = "xx.xx.xx.xx"
rds_endpoint = "xxxx.xxxx.ap-south-1.rds.amazonaws.com:3306"
```

---

### 🔹 EC2 Manual Setup

If not using Terraform, manually set up EC2:

#### 1. Launch EC2 Instance

- AMI: Ubuntu 22.04 LTS
- Instance Type: t2.micro
- Security Group: Open ports 22 (SSH) and 8080

#### 2. SSH into EC2

```bash
ssh ubuntu@<EC2_PUBLIC_IP>
```

#### 3. Install Docker

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose
sudo systemctl start docker
sudo usermod -aG docker ubuntu
# Log out and log back in
```

#### 4. Run Application

```bash
docker run -d --name task-app \
  -p 8080:8080 \
  -e DB_URL="jdbc:mysql://<RDS_ENDPOINT>:3306/taskdb" \
  -e DB_USERNAME="admin" \
  -e DB_PASSWORD="your_password" \
  --restart unless-stopped \
  <DOCKER_HUB_USERNAME>/task-manager:latest
```

#### 5. Access Application

```
http://<EC2_PUBLIC_IP>:8080
```

---

### 🔹 CI/CD (GitHub Actions)

#### 1. Push Code to GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/<YOUR_USERNAME>/task-manager.git
git push -u origin main
```

#### 2. Add GitHub Secrets

Go to **Repository Settings → Secrets and variables → Actions** and add:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `DOCKER_USERNAME` | Docker Hub username | `myusername` |
| `DOCKER_PASSWORD` | Docker Hub password | `mypassword` |
| `EC2_HOST` | EC2 public IP | `13.234.56.78` |
| `EC2_USER` | SSH user | `ubuntu` |
| `EC2_KEY` | Private SSH key | `-----BEGIN RSA...` |
| `DB_URL` | RDS endpoint | `db.xxxx.ap-south-1.rds.amazonaws.com` |
| `DB_USERNAME` | RDS username | `admin` |
| `DB_PASSWORD` | RDS password | `mypassword` |

#### 3. Pipeline Triggers

The pipeline automatically runs on:
- Push to `main` branch
- Pull request to `main` branch

#### 4. Monitor Deployment

Go to **Actions** tab in GitHub to see deployment progress.

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/tasks` | Create a new task |
| `GET` | `/tasks` | Get all tasks |
| `DELETE` | `/tasks/{id}` | Delete a task |
| `GET` | `/actuator/health` | Health check |

### Example API Calls

```bash
# Create task
curl -X POST http://localhost:8080/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Docker"}'

# Get all tasks
curl http://localhost:8080/tasks

# Delete task
curl -X DELETE http://localhost:8080/tasks/1

# Health check
curl http://localhost:8080/actuator/health
```

---

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_URL` | `jdbc:mysql://localhost:3306/taskdb...` | Database connection URL |
| `DB_USERNAME` | `root` | Database username |
| `DB_PASSWORD` | `root` | Database password |
| `SERVER_PORT` | `8080` | Application port |

### application.properties

```properties
server.port=8080
spring.datasource.url=${DB_URL}
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}
spring.jpa.hibernate.ddl-auto=update
management.endpoints.web.exposure.include=health,info
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Database Connection Failed

```bash
# Check MySQL is running
docker ps | grep mysql

# Check logs
docker logs mysql-db

# Verify connection
docker exec -it task-app sh
# Inside container: nc -zv mysql-db 3306
```

#### 2. Port Already in Use

```bash
# Find process using port 8080
netstat -ano | findstr :8080

# Kill process
taskkill /PID <PID> /F  # Windows
kill -9 <PID>  # Linux
```

#### 3. Docker Build Failed

```bash
# Clean Maven cache
mvn clean

# Rebuild
mvn clean package -DskipTests
```

#### 4. EC2 Deployment Failed

```bash
# SSH into EC2
ssh ubuntu@<EC2_IP>

# Check Docker
docker ps
docker logs task-app

# Check application health
curl http://localhost:8080/actuator/health
```

---

## 📄 License

MIT License - Feel free to use this project for learning or production.

---

## 👤 Author

Built with ❤️ using Java 21, Spring Boot 3.x, Docker, Terraform, and GitHub Actions.