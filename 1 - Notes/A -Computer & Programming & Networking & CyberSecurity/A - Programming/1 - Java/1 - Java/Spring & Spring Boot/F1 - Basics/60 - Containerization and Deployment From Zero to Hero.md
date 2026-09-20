
## Table of Contents
1. [What is Containerization?](#what-is-containerization)
2. [Docker Basics](#docker-basics)
3. [Dockerizing Spring Boot Apps](#dockerizing-spring-boot-apps)
4. [Kubernetes Fundamentals](#kubernetes-fundamentals)
5. [Deploying to Kubernetes](#deploying-to-kubernetes)
6. [Helm Charts](#helm-charts)
7. [Advanced Deployment Strategies](#advanced-deployment-strategies)
8. [Practice Project: Todo App Deployment](#practice-project-todo-app-deployment)

## What is Containerization? 📦

Think of containerization like **shipping containers** for software! 🚢

**Without containers:** "It works on my machine!" 😠
**With containers:** "It works everywhere!" 😎

### Why Containers?
- **Consistency:** Same environment everywhere
- **Isolation:** Apps don't interfere with each other  
- **Portability:** Run anywhere (laptop, cloud, server)
- **Scalability:** Easy to scale up/down

## Docker Basics 🐳

### Docker Concepts Made Simple
1. **Docker Image** - Blueprint for your app (like a recipe)
2. **Docker Container** - Running instance of an image (like a cooked meal)
3. **Dockerfile** - Instructions to build the image (like cooking steps)
4. **Docker Hub** - App store for Docker images (like Google Play)

### Install Docker
```bash
# On Windows/Mac: Download Docker Desktop
# On Linux:
sudo apt-get update
sudo apt-get install docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Check installation
docker --version
```

### Basic Docker Commands
```bash
# See running containers
docker ps

# See all containers (including stopped)
docker ps -a

# See downloaded images
docker images

# Run a container
docker run hello-world

# Stop a container
docker stop <container-name>

# Remove a container
docker rm <container-name>

# Remove an image
docker rmi <image-name>
```

## Dockerizing Spring Boot Apps 🚀

### Step 1: Create a Dockerfile
Create a file named `Dockerfile` (no extension) in your project:

```dockerfile
# Use official Java runtime
FROM openjdk:17-jdk-alpine

# Who maintains this (optional)
LABEL maintainer="your-name@email.com"

# Create directory for app
WORKDIR /app

# Copy the JAR file into container
COPY target/my-springboot-app.jar app.jar

# Tell Docker about the port we'll use
EXPOSE 8080

# Command to run the app
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Step 2: Build the Docker Image
```bash
# Build the image (don't forget the dot at the end!)
docker build -t my-spring-app:1.0 .

# See your new image
docker images
```

### Step 3: Run the Container
```bash
# Run the container
docker run -p 8080:8080 my-spring-app:1.0

# Run in background (detached mode)
docker run -d -p 8080:8080 --name my-app my-spring-app:1.0

# See logs
docker logs my-app

# Stop the container
docker stop my-app
```

### Better Dockerfile for Spring Boot
```dockerfile
# Multi-stage build (smaller final image)
FROM openjdk:17-jdk-alpine as builder
WORKDIR /app
COPY . .
RUN ./mvnw package -DskipTests

# Final stage
FROM openjdk:17-jdk-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Docker Compose for Multiple Services
Create `docker-compose.yml`:
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/mydb
    depends_on:
      - db

  db:
    image: postgres:13
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

Run with:
```bash
docker-compose up -d
```

## Kubernetes Fundamentals ☸️

### Kubernetes Concepts Made Simple
1. **Pod** - Smallest unit (1+ containers)
2. **Deployment** - Manages pods (scaling, updates)
3. **Service** - Network access to pods
4. **ConfigMap** - Configuration data
5. **Secret** - Sensitive data (passwords, keys)
6. **Namespace** - Virtual cluster inside cluster

### Install Minikube (Local Kubernetes)
```bash
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube
minikube start

# Check status
minikube status

# Open Kubernetes dashboard
minikube dashboard
```

### Basic Kubectl Commands
```bash
# See nodes (computers in cluster)
kubectl get nodes

# See pods
kubectl get pods

# See services
kubectl get services

# See deployments
kubectl get deployments

# Get detailed info
kubectl describe pod <pod-name>

# See logs
kubectl logs <pod-name>
```

## Deploying to Kubernetes 🚀

### Step 1: Create Deployment YAML
Create `deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-app
  labels:
    app: todo-app
spec:
  replicas: 3  # Run 3 copies of our app
  selector:
    matchLabels:
      app: todo-app
  template:
    metadata:
      labels:
        app: todo-app
    spec:
      containers:
      - name: todo-app
        image: my-spring-app:1.0  # Your Docker image
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

### Step 2: Create Service YAML
Create `service.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: todo-service
spec:
  selector:
    app: todo-app  # Matches the deployment label
  ports:
    - protocol: TCP
      port: 80      # External port
      targetPort: 8080  # Container port
  type: LoadBalancer  # Makes it accessible from outside
```

### Step 3: Deploy to Kubernetes
```bash
# Apply the deployment
kubectl apply -f deployment.yaml

# Apply the service
kubectl apply -f service.yaml

# Check everything
kubectl get all

# Get the URL to access your app
minikube service todo-service --url
```

### Database Deployment Example
Create `database.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: "tododb"
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        ports:
        - containerPort: 5432
        volumeMounts:
        - mountPath: /var/lib/postgresql/data
          name: postgres-storage
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
  type: ClusterIP  # Only accessible inside cluster
```

## Helm Charts 📊

### What is Helm?
Helm is like a **package manager** for Kubernetes (like apt-get or npm for Kubernetes)

### Install Helm
```bash
# Download and install
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Check installation
helm version
```

### Create a Helm Chart
```bash
# Create new chart
helm create todo-chart

# See what was created
ls todo-chart/
```

### Chart Structure
```
todo-chart/
├── Chart.yaml          # Chart info
├── values.yaml         # Default values
├── templates/          # Kubernetes templates
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ...
└── charts/             # Sub-charts
```

### Customize values.yaml
```yaml
# values.yaml
replicaCount: 3

image:
  repository: my-spring-app
  tag: "1.0"
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 80

resources:
  requests:
    memory: 256Mi
    cpu: 250m
  limits:
    memory: 512Mi
    cpu: 500m

env:
  SPRING_PROFILES_ACTIVE: "prod"
```

### Deploy with Helm
```bash
# Install chart
helm install todo-app todo-chart/

# Upgrade deployment
helm upgrade todo-app todo-chart/

# See releases
helm list

# Uninstall
helm uninstall todo-app
```

## Advanced Deployment Strategies 🚀

### Blue-Green Deployment
```yaml
# blue-deployment.yaml (current version)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-app-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: todo-app
      version: blue
  template:
    metadata:
      labels:
        app: todo-app
        version: blue
    # ... container spec

# green-deployment.yaml (new version)
apiVersion: apps/v1
kind: Deployment  
metadata:
  name: todo-app-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: todo-app
      version: green
  template:
    metadata:
      labels:
        app: todo-app
        version: green
    # ... container spec

# service.yaml (switches between blue/green)
apiVersion: v1
kind: Service
metadata:
  name: todo-service
spec:
  selector:
    app: todo-app
    version: blue  # Change to green to switch
  # ... ports
```

### Rolling Updates (Default)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # How many extra pods during update
      maxUnavailable: 0  # How many can be unavailable
  # ... rest of spec
```

### Health Checks
```yaml
containers:
- name: todo-app
  # ... other config
  livenessProbe:
    httpGet:
      path: /actuator/health
      port: 8080
    initialDelaySeconds: 30
    periodSeconds: 10
    failureThreshold: 3
  
  readinessProbe:
    httpGet:
      path: /actuator/health/readiness
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 5
    failureThreshold: 1
```

## Practice Project: Todo App Deployment 📝

### Step 1: Dockerize Your Todo App
1. Create `Dockerfile` in your Spring Boot project
2. Build the image: `docker build -t todo-app:1.0 .`
3. Test locally: `docker run -p 8080:8080 todo-app:1.0`

### Step 2: Set Up Minikube
```bash
# Start Minikube
minikube start

# Enable ingress (optional)
minikube addons enable ingress
```

### Step 3: Create Kubernetes Files
Create `k8s/todo-deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: todo-app
  template:
    metadata:
      labels:
        app: todo-app
    spec:
      containers:
      - name: todo-app
        image: todo-app:1.0
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_DATASOURCE_URL
          value: "jdbc:h2:mem:testdb"
```

Create `k8s/todo-service.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: todo-service
spec:
  selector:
    app: todo-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer
```

### Step 4: Deploy to Kubernetes
```bash
# Apply configurations
kubectl apply -f k8s/

# Check status
kubectl get pods
kubectl get services

# Get access URL
minikube service todo-service --url

# Test your app
curl http://<minikube-ip>/api/todos
```

### Step 5: Create Helm Chart (Optional)
```bash
# Create Helm chart
helm create todo-chart

# Customize values.yaml and templates
# Install chart
helm install todo-app todo-chart/
```

### Step 6: Test Scaling
```bash
# Scale up
kubectl scale deployment todo-app --replicas=4

# Check pods
kubectl get pods

# Scale down
kubectl scale deployment todo-app --replicas=2
```

### Step 7: Update Your App
1. Make changes to your app
2. Build new image: `docker build -t todo-app:2.0 .`
3. Update deployment: `kubectl set image deployment/todo-app todo-app=todo-app:2.0`
4. Watch rolling update: `kubectl rollout status deployment/todo-app`

## Troubleshooting 🔧

### Common Issues
1. **Image not found**: Make sure image is available in cluster
   ```bash
   # Load image into Minikube
   minikube image load todo-app:1.0
   ```

2. **App not starting**: Check logs
   ```bash
   kubectl logs <pod-name>
   ```

3. **Can't connect to service**: Check service type and ports
   ```bash
   kubectl describe service todo-service
   ```

### Useful Commands
```bash
# Debug pod
kubectl exec -it <pod-name> -- /bin/sh

# See events
kubectl get events

# Delete everything
kubectl delete -f k8s/

# Restart deployment
kubectl rollout restart deployment/todo-app
```

## Congratulations! 🎉

You've now learned how to:
- ✅ Containerize Spring Boot apps with Docker
- ✅ Deploy to Kubernetes
- ✅ Use Helm for package management
- ✅ Implement advanced deployment strategies
- ✅ Deploy a real Todo app to Kubernetes

You're ready to deploy applications to production! 🚀

[[0 - Spring Framework]]