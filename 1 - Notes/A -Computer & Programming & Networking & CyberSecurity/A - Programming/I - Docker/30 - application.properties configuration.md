

## **1️⃣ Understanding the pieces**

We have three main components:

1. **Spring Boot Application** – Your Java app.
    
2. **Docker** – Runs containers (isolated environments for apps or services).
    
3. **application.properties / application.yml** – Configuration for your Spring Boot app.
    

The goal: make Spring Boot **talk to services running in Docker**, like a database, via configuration.

---

## **2️⃣ Basics: Running a DB in Docker**

Example: PostgreSQL

```bash
docker run -d \
  --name mydb \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=mydb \
  -p 5432:5432 \
  postgres:15
```

Explanation:

- `-d` → run in background (daemon)
    
- `--name mydb` → container name
    
- `-e ...` → environment variables for DB credentials
    
- `-p 5432:5432` → maps container port 5432 to host port 5432
    
- `postgres:15` → the Docker image
    

Check it’s running:

```bash
docker ps
```

---

## **3️⃣ Connecting Spring Boot to Dockerized DB**

### **3a. If Spring Boot runs on host machine**

Use `localhost`:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=admin
spring.datasource.password=secret
spring.jpa.hibernate.ddl-auto=update
```

### **3b. If Spring Boot runs in a container**

`localhost` **won’t work**, because the container has its own network. You need **Docker networking**:

#### Step 1: Create a network

```bash
docker network create mynetwork
```

#### Step 2: Run containers in the same network

```bash
docker run -d --name mydb --network mynetwork \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=mydb \
  postgres:15

docker run -d --name myapp --network mynetwork my-springboot-image
```

#### Step 3: Use container name as hostname

In `application.properties`:

```properties
spring.datasource.url=jdbc:postgresql://mydb:5432/mydb
spring.datasource.username=admin
spring.datasource.password=secret
```

> Docker DNS resolves `mydb` to the DB container’s IP automatically.

---

## **4️⃣ Spring Boot Dockerization**

### **Dockerfile for Spring Boot**

```dockerfile
# 1. Use JDK image
FROM openjdk:17-jdk-slim

# 2. Add jar
ARG JAR_FILE=target/myapp.jar
COPY ${JAR_FILE} app.jar

# 3. Run the jar
ENTRYPOINT ["java","-jar","/app.jar"]
```

### Build Docker image:

```bash
mvn clean package
docker build -t my-springboot-app .
```

---

## **5️⃣ Advanced: Environment variables in application.properties**

Instead of hardcoding credentials, use **env variables**:

```properties
spring.datasource.url=jdbc:postgresql://${DB_HOST:localhost}:5432/${DB_NAME:mydb}
spring.datasource.username=${DB_USER:admin}
spring.datasource.password=${DB_PASS:secret}
```

- `${VAR:default}` → use environment variable `VAR`, or default if not set
    
- Example run:
    

```bash
docker run -d --name myapp --network mynetwork \
  -e DB_HOST=mydb \
  -e DB_NAME=mydb \
  -e DB_USER=admin \
  -e DB_PASS=secret \
  my-springboot-app
```

✅ This makes your app **portable** and environment-independent.

---

## **6️⃣ Quick checklist for Spring Boot + Docker**

-  Docker container running DB
    
-  Docker network for inter-container communication
    
-  Spring Boot configured to connect (via `application.properties` or env variables)
    
-  Spring Boot Docker image built
    
-  Run app container in the same network
    


---

## **1️⃣ Use proper `docker run` syntax**

Common mistake:

```bash
docker run -d-p9090:9090 - CONFIG_SERVER_URL=host.docker.internal -e EUREKA_SERVER_ADDRESS=http://host.docker.internal
```

❌ Issues here:

- `-d-p9090:9090` → should be `-d -p 9090:9090` (space missing)
    
- `- CONFIG_SERVER_URL=...` → wrong syntax, should be `-e CONFIG_SERVER_URL=...`
    

✅ Correct version:

```bash
docker run -d \
  -p 9090:9090 \
  -e CONFIG_SERVER_URL=http://host.docker.internal:8888 \
  -e EUREKA_SERVER_ADDRESS=http://host.docker.internal:8761/eureka \
  --name myapp \
  my-springboot-app
```

Explanation:

- `-d` → run in background
    
- `-p hostPort:containerPort` → expose ports
    
- `-e VAR=value` → environment variable inside container
    
- `--name myapp` → container name
    
- `my-springboot-app` → image name
    

---

## **2️⃣ Make sure your jar works**

If you try to run a container and it fails immediately:

```bash
docker logs myapp
```

Most common causes:

1. Jar not found (`COPY` in Dockerfile wrong)
    
2. Spring Boot config errors (bad `application.properties` or missing env variables)
    
3. DB not reachable (wrong hostname, network issue)
    

Fix jar issues:

```dockerfile
# Dockerfile
FROM openjdk:17-jdk-slim
ARG JAR_FILE=target/myapp.jar
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
```

---

## **3️⃣ DB connection issues**

- If app runs **on host**, DB in Docker → `spring.datasource.url=jdbc:postgresql://localhost:5432/mydb`
    
- If app **in Docker**, DB in another container → use **container name** and same **Docker network**
    

Create network:

```bash
docker network create mynetwork
```

Run DB:

```bash
docker run -d --name mydb --network mynetwork \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=mydb \
  postgres:15
```

Run app:

```bash
docker run -d --name myapp --network mynetwork \
  -e DB_HOST=mydb \
  -e DB_NAME=mydb \
  -e DB_USER=admin \
  -e DB_PASS=secret \
  -p 9090:9090 \
  my-springboot-app
```

✅ Now Spring Boot connects without errors.

---

## **4️⃣ Extra tips**

1. Always check logs:
    

```bash
docker logs -f myapp
```

2. Use `--rm` for temporary containers to avoid leftover conflicts:
    

```bash
docker run --rm ...
```

3. Map ports carefully — don’t use a port already in use on host.
    
4. If you want **live reload** during development, consider **volume mapping**:
    

```bash
docker run -v /path/to/target:/app -p 9090:9090 my-springboot-app
```

---


##### Tags : [[1 - Docker 🧋]]