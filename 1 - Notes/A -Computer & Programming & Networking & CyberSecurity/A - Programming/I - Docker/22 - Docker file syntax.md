

## 🧠 Why a Spring Boot project needs a Dockerfile

When you build a Spring Boot project normally, it creates a `.jar` file that you run with:

```bash
java -jar myapp.jar
```

That works _on your local machine_ — but not everywhere.  
Different servers may have:

- No Java installed ☠️
    
- Wrong Java version
    
- Different OS or dependencies
    

Docker fixes this by **packing your entire app + environment + Java runtime** into a single container.

So the **Dockerfile** is like a **recipe** for building that container.

---

## 🧩 What a Dockerfile does

It tells Docker:

1. Which **base image** to start from (e.g., Java 17).
    
2. Which **files** from your project to include.
    
3. What **commands** to run to build and start your app.
    
4. Which **port** your app listens on.
    

---

## 🧱 Basic Syntax and Structure

Here’s a minimal, clean Dockerfile for a Spring Boot project that already has a built JAR:

```dockerfile
# Step 1: Choose base image (Java runtime)
FROM eclipse-temurin:17-jdk-alpine

# Step 2: Set working directory
WORKDIR /app

# Step 3: Copy the JAR into the container
COPY target/myapp.jar app.jar

# Step 4: Expose the port that Spring Boot runs on
EXPOSE 8080

# Step 5: Run the app
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

## 🧩 Explanation of Each Line

|Line|Command|What It Does|
|---|---|---|
|1|`FROM`|Starts from a base image that already has Java 17.|
|2|`WORKDIR`|Sets `/app` as the working folder inside the container.|
|3|`COPY`|Copies your built `.jar` file from your computer into the container.|
|4|`EXPOSE`|Documents the port the app uses (Spring Boot default = 8080).|
|5|`ENTRYPOINT`|Defines the command Docker will run when the container starts.|

---

## ⚙️ Build and Run

Once you have this Dockerfile in your **Spring Boot project root**, do:

```bash
# 1. Build the Spring Boot JAR
mvn clean package -DskipTests

# 2. Build Docker image
docker build -t myapp .

# 3. Run container (map container port 8080 → host port 8080)
docker run -p 8080:8080 myapp
```

Then visit 👉 `http://localhost:8080`

---

## 🧠 In short

|Concept|Meaning|
|---|---|
|**Dockerfile**|Recipe for how to package your Spring Boot app into an image.|
|**Image**|A ready-to-run template containing your app + Java.|
|**Container**|The running instance of that image — your app in action.|

---


## 🧩 What Is a Dockerfile?

A **Dockerfile** is a **script of instructions** that tells Docker how to **build an image**.  
Each line = one instruction (layer).  
When Docker builds it, it executes from **top to bottom**, caching each step.

---

## ⚙️ Basic Syntax Structure

Every Dockerfile is made of instructions like this:

```dockerfile
INSTRUCTION argument
```

Example:

```dockerfile
FROM ubuntu:22.04
RUN apt update
COPY . /app
CMD ["python3", "main.py"]
```

---

## 🧱 CORE COMMANDS (the ones you’ll use daily)

Let’s go one by one:

---

### 🧩 1. `FROM`

Defines the **base image** (the starting point).

```dockerfile
FROM eclipse-temurin:17-jdk-alpine
```

**Why:**  
Your app needs an environment — Java, Node, Python, etc.  
`FROM` tells Docker to start with an image that already has those tools.

---

### 🧩 2. `WORKDIR`

Sets the **current working directory** inside the container.

```dockerfile
WORKDIR /app
```

**Why:**  
All subsequent commands (like `RUN`, `COPY`, `CMD`) run relative to this folder.  
It’s like `cd /app`.

---

### 🧩 3. `COPY`

Copies files from your computer → into the image.

```dockerfile
COPY target/myapp.jar app.jar
COPY . /app
```

**Tip:**  
Always copy **specific files first** (like `pom.xml`) before copying all — improves caching and build speed.

---

### 🧩 4. `RUN`

Executes shell commands **while building** the image (not at runtime).

```dockerfile
RUN apt update && apt install -y git
RUN mvn clean package -DskipTests
```

**Think:** "What setup steps do I need to prepare my app?"

Each `RUN` creates a **new image layer**.

---

### 🧩 5. `CMD`

Defines the **default command** that runs when a container starts.

```dockerfile
CMD ["java", "-jar", "app.jar"]
```

**Note:**  
You can override `CMD` when you run the container:

```bash
docker run myapp echo "hello"
```

---

### 🧩 6. `ENTRYPOINT`

Similar to `CMD` — but **harder to override**.  
Used for “this is the main app, always run this.”

```dockerfile
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Difference:**

- `CMD` → optional default
    
- `ENTRYPOINT` → fixed command
    

You can combine them:

```dockerfile
ENTRYPOINT ["java", "-jar", "app.jar"]
CMD ["--debug"]
```

→ Runs `java -jar app.jar --debug`

---

### 🧩 7. `EXPOSE`

Documents which port your app listens on.

```dockerfile
EXPOSE 8080
```

It **does not open** the port — it’s just metadata.  
You still need `-p 8080:8080` when running.

---

### 🧩 8. `ENV`

Sets environment variables inside the image.

```dockerfile
ENV SPRING_PROFILES_ACTIVE=prod
ENV DB_HOST=postgres
```

Used for configuration.  
You can override them at runtime with:

```bash
docker run -e SPRING_PROFILES_ACTIVE=dev myapp
```

---

### 🧩 9. `ARG`

Defines **build-time variables** (only exist while building).

```dockerfile
ARG JAR_FILE=target/myapp.jar
COPY ${JAR_FILE} app.jar
```

You can pass a different value when building:

```bash
docker build --build-arg JAR_FILE=target/test.jar -t myapp .
```

---

### 🧩 10. `VOLUME`

Creates a mount point for persistent data.

```dockerfile
VOLUME /data
```

It lets you attach storage:

```bash
docker run -v mydata:/data myapp
```

---

### 🧩 11. `USER`

Switches to a different user inside the container.

```dockerfile
USER appuser
```

**Why:**  
Security. Don’t run apps as root unless necessary.

---

### 🧩 12. `LABEL`

Adds metadata (author, version, description, etc.)

```dockerfile
LABEL maintainer="ethan@arcade.dev" \
      version="1.0" \
      description="Spring Boot backend API"
```

---

### 🧩 13. `HEALTHCHECK`

Tells Docker how to check if your container is still healthy.

```dockerfile
HEALTHCHECK CMD curl -f http://localhost:8080/actuator/health || exit 1
```

Docker will mark your container as **healthy** or **unhealthy** based on this.

---

### 🧩 14. `COPY --from=build`

Used in **multi-stage builds** (advanced).  
You can copy files from one build stage to another.

Example:

```dockerfile
COPY --from=build /app/target/*.jar app.jar
```

---

## 💡 Bonus: `.dockerignore`

Like `.gitignore`, it prevents unwanted files from being copied into your image.

Example `.dockerignore`:

```
target/
.git/
.idea/
*.log
```

---

## 🧠 Summary Table

|Command|Description|Stage|
|---|---|---|
|`FROM`|Start from a base image|All|
|`WORKDIR`|Set working directory|Build/Run|
|`COPY`|Copy files into image|Build|
|`RUN`|Execute commands during build|Build|
|`CMD`|Default runtime command|Run|
|`ENTRYPOINT`|Main process that always runs|Run|
|`EXPOSE`|Document container port|Run|
|`ENV`|Set environment variables|Both|
|`ARG`|Build-time variable|Build|
|`VOLUME`|Define mountable path|Run|
|`USER`|Set user context|Both|
|`LABEL`|Add metadata|Build|
|`HEALTHCHECK`|Define health check|Run|
|`COPY --from`|Copy from another stage|Build (multi-stage)|

---

## 🧱 Full Dockerfile (for a Maven-based Spring Boot project)

```dockerfile
# ------------------------------
# 🏗️ STAGE 1: Build the application
# ------------------------------
FROM maven:3.9.8-eclipse-temurin-17 AS build

# 1️⃣ Set working directory
WORKDIR /app

# 2️⃣ Copy pom.xml first (for dependency caching)
COPY pom.xml .

# 3️⃣ Pre-download all dependencies
RUN mvn dependency:go-offline

# 4️⃣ Copy the rest of the source code
COPY src ./src

# 5️⃣ Build the JAR file
RUN mvn clean package -DskipTests

# ------------------------------
# 🚀 STAGE 2: Run the application
# ------------------------------
FROM eclipse-temurin:17-jdk-alpine

# 1️⃣ Set working directory again
WORKDIR /app

# 2️⃣ Copy only the JAR from the build stage
COPY --from=build /app/target/*.jar app.jar

# 3️⃣ Set environment variables
ENV SPRING_PROFILES_ACTIVE=prod \
    JAVA_OPTS="-Xms256m -Xmx512m"

# 4️⃣ Expose Spring Boot default port
EXPOSE 8080

# 5️⃣ Define a simple health check
HEALTHCHECK CMD curl -f http://localhost:8080/actuator/health || exit 1

# 6️⃣ Run the app (use ENTRYPOINT so it can accept extra args)
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

---

## 🧩 Deep Explanation (line-by-line)

### 🧱 Stage 1: Build

This stage uses **Maven + JDK** to compile your project and package it into a JAR file.

|Line|What It Does|Why It Matters|
|---|---|---|
|`FROM maven:3.9.8-eclipse-temurin-17 AS build`|Uses a base image with Maven + Java 17|So you can build your app directly inside Docker|
|`WORKDIR /app`|Sets `/app` as working dir|Keeps file paths clean|
|`COPY pom.xml .`|Copy only pom.xml|So dependencies can be cached|
|`RUN mvn dependency:go-offline`|Downloads dependencies|Faster rebuilds|
|`COPY src ./src`|Copies code into container|You need this to build the JAR|
|`RUN mvn clean package -DskipTests`|Compiles and packages|Produces `/target/app.jar`|

After this stage, Docker has a ready `.jar` inside the container.

---

### 🚀 Stage 2: Run

This stage **only contains the final app + Java runtime** — clean, small, fast.

|Line|What It Does|Why It Matters|
|---|---|---|
|`FROM eclipse-temurin:17-jdk-alpine`|Start from a tiny Java image|Keeps image lightweight (~200MB smaller)|
|`WORKDIR /app`|Working directory|Container clarity|
|`COPY --from=build /app/target/*.jar app.jar`|Copies built jar from previous stage|Connects build → runtime|
|`ENV SPRING_PROFILES_ACTIVE=prod`|Sets active profile|Good for environment config|
|`ENV JAVA_OPTS="-Xms256m -Xmx512m"`|Memory tuning|Useful for small servers|
|`EXPOSE 8080`|Documents app port|Makes it discoverable|
|`HEALTHCHECK`|Checks Spring Boot’s health endpoint|Lets Docker know if app crashed|
|`ENTRYPOINT`|Defines how to start app|Can add extra args dynamically|

---

## 🧰 How to Build and Run

1️⃣ Build your Docker image:

```bash
docker build -t my-spring-app .
```

2️⃣ Run your app:

```bash
docker run -p 8080:8080 my-spring-app
```

3️⃣ Optional — change profile or memory:

```bash
docker run -p 8080:8080 -e SPRING_PROFILES_ACTIVE=dev -e JAVA_OPTS="-Xmx1G" my-spring-app
```

4️⃣ Check logs:

```bash
docker logs <container_id>
```

---

## 🧠 Why This Style Is “Professional”

✅ Uses **multi-stage build** (keeps image small)  
✅ Adds **environment config**  
✅ Includes **healthcheck** for monitoring  
✅ Caches **Maven dependencies**  
✅ Avoids copying `.git`, `target/`, etc.  
✅ Fully portable — works on any server

---



##### Tags : [[1 - Docker 🧋]]