

## **1️⃣ Spring Boot `application.properties`**

```properties
# Server port
server.port=${SERVER_PORT:8080}

# Datasource (PostgreSQL example)
spring.datasource.url=jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:mydb}
spring.datasource.username=${DB_USER:admin}
spring.datasource.password=${DB_PASS:secret}
spring.datasource.driver-class-name=org.postgresql.Driver

# Hibernate
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
```

✅ How it works:

- `${VAR:default}` → use environment variable `VAR` if set, otherwise fallback to `default`.
    
- On host (no Docker), it uses defaults (`localhost`, `8080`, etc.)
    
- In Docker, you **pass environment variables** with `-e` to override defaults.
    

---

## **2️⃣ Example usage**

### **2a. Running on host (no Docker)**

Just run Spring Boot normally:

```bash
mvn spring-boot:run
```

Defaults apply:

- DB on `localhost:5432`
    
- Username `admin`, password `secret`
    

---

### **2b. Running in Docker**

```bash
docker run -d \
  --name myapp \
  -p 9090:9090 \
  -e SERVER_PORT=9090 \
  -e DB_HOST=mydb \
  -e DB_PORT=5432 \
  -e DB_NAME=mydb \
  -e DB_USER=admin \
  -e DB_PASS=secret \
  --network mynetwork \
  my-springboot-app
```

- Now the Spring Boot app connects to `mydb` container instead of localhost.
    
- `SERVER_PORT=9090` maps the app to port 9090 inside container.
    

---

### **3️⃣ Why this is “goat mode” 🐐**

- You **don’t need separate `application.properties`** for host vs Docker.
    
- It’s **portable**, works in **any environment**.
    
- Docker containers can run in any network and still pick up the correct DB.
    

---

If you want, I can make a **full working example project setup** with:

- `Dockerfile`
    
- `docker-compose.yml` (Spring Boot + PostgreSQL)
    
- `application.properties` ready for **both Docker and host**
    



---

## **1️⃣ Directory structure**

```
spring-docker-example/
│
├─ src/
│   └─ main/java/com/example/demo/  # Spring Boot code
│
├─ pom.xml
├─ Dockerfile
├─ docker-compose.yml
└─ application.properties
```

---

## **2️⃣ `application.properties`** (works for both Docker & host)

```properties
# Server port
server.port=${SERVER_PORT:8080}

# PostgreSQL datasource
spring.datasource.url=jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:mydb}
spring.datasource.username=${DB_USER:admin}
spring.datasource.password=${DB_PASS:secret}
spring.datasource.driver-class-name=org.postgresql.Driver

# Hibernate
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
```

✅ Defaults work on host, environment variables override for Docker.

---

## **3️⃣ Dockerfile for Spring Boot**

```dockerfile
# Use OpenJDK 17 slim image
FROM openjdk:17-jdk-slim

# Set working directory
WORKDIR /app

# Copy the built jar
ARG JAR_FILE=target/demo-0.0.1-SNAPSHOT.jar
COPY ${JAR_FILE} app.jar

# Expose port (default 8080)
EXPOSE 8080

# Run the Spring Boot app
ENTRYPOINT ["java","-jar","/app/app.jar"]
```

---

## **4️⃣ docker-compose.yml** (optional, makes it simpler)

```yaml
version: '3.8'
services:
  db:
    image: postgres:15
    container_name: mydb
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: mydb
    ports:
      - "5432:5432"

  app:
    build: .
    container_name: myapp
    environment:
      SERVER_PORT: 8080
      DB_HOST: db
      DB_PORT: 5432
      DB_NAME: mydb
      DB_USER: admin
      DB_PASS: secret
    ports:
      - "8080:8080"
    depends_on:
      - db
```

---

## **5️⃣ How to run**

### **On host (no Docker)**

```bash
mvn spring-boot:run
```

- Uses defaults in `application.properties`.
    

### **Using Docker (manual)**

```bash
# Build Spring Boot image
docker build -t my-springboot-app .

# Create network
docker network create mynetwork

# Run PostgreSQL container
docker run -d --name mydb --network mynetwork \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=mydb \
  -p 5432:5432 \
  postgres:15

# Run Spring Boot container
docker run -d --name myapp --network mynetwork \
  -e SERVER_PORT=8080 \
  -e DB_HOST=mydb \
  -e DB_PORT=5432 \
  -e DB_NAME=mydb \
  -e DB_USER=admin \
  -e DB_PASS=secret \
  -p 8080:8080 \
  my-springboot-app
```

### **Using Docker Compose (easiest)**

```bash
docker-compose up --build
```

- This will start **both DB and app**, already networked.
    
- Spring Boot connects automatically via `DB_HOST=db`.
    

---

✅ Now your Spring Boot app:

- Works on host (localhost)
    
- Works in Docker
    
- Can run multiple environments just by setting env variables
    



---

## **1️⃣ Minimum setup (just one file: Dockerfile)**

If you just want to Dockerize your **Spring Boot app**:

- Only need a **Dockerfile** for your app.
    
- Your `application.properties` can still contain defaults or environment variables.
    
- You can run your app container and connect to an **external DB** manually (host DB or separate container).
    

Example:

```
Dockerfile
application.properties
```

Then run:

```bash
docker build -t myapp .
docker run -d -p 8080:8080 -e DB_HOST=host.docker.internal myapp
```

✅ Works for basic Dockerized Spring Boot.

---

## **2️⃣ Adding a DB container (optional but recommended)**

If you want **Spring Boot + PostgreSQL** fully in Docker:

- Option A: Run DB manually in another container. You still need **just one Dockerfile** for your app, and pass env variables for DB host/user/password when running it.
    
- Option B (easiest): Use **docker-compose.yml** to start **both containers** automatically. This is optional but convenient.
    

---

## **3️⃣ `application.properties` vs Docker**

- `application.properties` is **always needed** for Spring Boot configs.
    
- It can work with **defaults for host** or **env variables for Docker**.
    
- No separate Docker-specific property file is required.
    

---

### ✅ TL;DR

|Goal|Required files|
|---|---|
|Just Dockerize Spring Boot|Dockerfile + application.properties|
|Dockerize Spring Boot + DB manually|Dockerfile + application.properties|
|Dockerize Spring Boot + DB with easy startup|Dockerfile + docker-compose.yml + application.properties|

So **three files are not required**, but `docker-compose.yml` makes managing multi-container setups easier.

---


##### Tags : [[1 - Docker 🧋]]