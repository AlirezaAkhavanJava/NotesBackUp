

# **1️⃣ What is a Dockerfile?**

A **Dockerfile** is a **text file with instructions** telling Docker how to build an image.  
Think of it as a “recipe” for your app.

---

# **2️⃣ Basic Dockerfile syntax**

Each line in a Dockerfile is an **instruction**. Common instructions:

|Instruction|Purpose|
|---|---|
|`FROM`|Base image to start from (e.g., `openjdk:23-jdk`)|
|`WORKDIR`|Set working directory inside the container|
|`COPY`|Copy files from host to container|
|`RUN`|Run commands inside the container (like installing packages)|
|`ENV`|Set environment variables|
|`EXPOSE`|Declare the port the container will listen on|
|`CMD` / `ENTRYPOINT`|Command to run when container starts|

---

# **3️⃣ Example Dockerfile for a Spring Boot app**

```dockerfile
# 1. Use an OpenJDK base image
FROM openjdk:23-jdk

# 2. Set working directory in container
WORKDIR /app

# 3. Copy the JAR built by Maven/Gradle
COPY target/blackunicorn.jar /app/blackunicorn.jar

# 4. Expose the port your Spring Boot app runs on
EXPOSE 8080

# 5. Run the app when container starts
ENTRYPOINT ["java","-jar","blackunicorn.jar"]
```

---

# **4️⃣ Optional enhancements**

- **Environment variables**
    

```dockerfile
ENV SPRING_PROFILES_ACTIVE=prod
```

- **Reduce image size with a JRE-only image**
    

```dockerfile
FROM eclipse-temurin:23-jre
```

- **Build multi-stage for smaller images**
    

```dockerfile
# Stage 1: Build
FROM maven:3.9.0-openjdk-23 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Run
FROM eclipse-temurin:23-jre
WORKDIR /app
COPY --from=build /app/target/blackunicorn.jar /app/
EXPOSE 8080
ENTRYPOINT ["java","-jar","blackunicorn.jar"]
```

This builds your JAR inside the container and keeps the final image **small**.

---

# **5️⃣ Building and running**

```bash
# Build image
docker build -t demo/black:v1 .

# Run container
docker run -p 8080:8080 demo/black:v1
```

---

✅ **Summary**

- Dockerfile = instructions to build a container image.
    
- Main instructions: `FROM`, `WORKDIR`, `COPY`, `RUN`, `ENV`, `EXPOSE`, `ENTRYPOINT`.
    
- Multi-stage builds = smaller, cleaner images.
    




##### Tags : [[1 - Docker 🧋]]