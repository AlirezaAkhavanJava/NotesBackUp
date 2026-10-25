

## 🧠 1. What is a Dockerfile?

A **Dockerfile** is a text file with **instructions** that tell Docker how to build an image.  
It’s like a **recipe** for your app’s environment — what to install, how to run it, etc.

When you run:

```bash
docker build -t myapp .
```

Docker reads the `Dockerfile` (line by line) and creates an **image**.

Later, you can run that image as a **container**:

```bash
docker run -p 8080:8080 myapp
```

---

## ⚙️ 2. Why use Docker with Spring Boot?

Without Docker:

- You must install Java, Maven/Gradle, and dependencies manually.
    
- “It works on my machine” issues happen.
    

With Docker:

- Your app runs the same everywhere.
    
- You just need Docker installed — not even Java.
    

---

## 🧩 3. Structure of a Spring Boot project

Example layout:

```
my-spring-app/
├── pom.xml
├── src/
│   ├── main/
│   │   ├── java/...
│   │   └── resources/
└── Dockerfile
```

---

## 🚀 4. Creating the Dockerfile (Step by Step)

### 🧱 Step 1: Choose a base image

We need Java to run Spring Boot, so we use an official Java image:

```dockerfile
FROM eclipse-temurin:17-jdk-alpine
```

This means: start from a lightweight Linux image that has Java 17.

---

### 📁 Step 2: Set working directory

This is where your app will live inside the container.

```dockerfile
WORKDIR /app
```

---

### 📦 Step 3: Copy your JAR file

Assume you already built your Spring Boot JAR:

```bash
mvn clean package -DskipTests
```

Then copy it into the container:

```dockerfile
COPY target/*.jar app.jar
```

---

### 🚪 Step 4: Expose the app port

Spring Boot runs on port 8080 by default:

```dockerfile
EXPOSE 8080
```

---

### ▶️ Step 5: Run the app

This tells Docker how to start your app:

```dockerfile
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

✅ **Full simple Dockerfile:**

```dockerfile
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

## 🧰 5. Building and running it

**Step 1:** Build your JAR (from your Spring Boot project folder)

```bash
mvn clean package -DskipTests
```

**Step 2:** Build the Docker image

```bash
docker build -t my-spring-app .
```

**Step 3:** Run the container

```bash
docker run -p 8080:8080 my-spring-app
```

Now go to 👉 `http://localhost:8080`  
Your app is running inside Docker 🎉

---

## 🧩 Full Dockerfile (reference)

```dockerfile
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Now let’s go line by line 👇

---

## 🧱 1. `FROM eclipse-temurin:17-jdk-alpine`

### 💬 What it does:

This line sets the **base image** — the starting point of your Docker image.  
Everything you add later is built **on top of** this image.

### ⚙️ What it includes:

- A minimal **Linux OS** (Alpine Linux — small, fast).
    
- **Java Development Kit (JDK) 17** — required to run your Spring Boot app.
    

### 🤔 Why it’s needed:

Every Docker image must **start from something** (even if that’s just Linux).  
We use a **Java image** because Spring Boot apps need Java to run.

### 💡 Notes:

- `eclipse-temurin` is the official **OpenJDK** from the Eclipse Foundation (trusted, production-safe).
    
- `-alpine` = small and efficient (good for faster builds and smaller images).
    

---

## 📁 2. `WORKDIR /app`

### 💬 What it does:

Sets the **working directory** inside the container.

So every command (like `COPY` or `RUN`) after this happens in `/app`.

### ⚙️ What it includes:

Just creates a folder `/app` inside the container.

### 🤔 Why it’s needed:

Keeps the container organized — like saying

> “Okay Docker, move into this folder before doing anything else.”

Without this, files might go into random places.

---

## 📦 3. `COPY target/*.jar app.jar`

### 💬 What it does:

Copies your **Spring Boot JAR file** from your host (your computer) into the container.

So if your project built a JAR at:

```
/target/myapp-0.0.1-SNAPSHOT.jar
```

It becomes:

```
/app/app.jar  (inside the container)
```

### ⚙️ What it includes:

Your entire compiled application — all classes, resources, and dependencies packed in one `.jar`.

### 🤔 Why it’s needed:

When you run your container, Docker doesn’t have your source code or IDE — only what you **copy** into it.  
This step gives the container your runnable app.

---

## 🚪 4. `EXPOSE 8080`

### 💬 What it does:

Tells Docker that the app **listens on port 8080** inside the container.

### ⚙️ What it includes:

Just a metadata hint — it **doesn’t actually open** the port on your computer.

### 🤔 Why it’s needed:

Spring Boot apps by default start on port 8080, so this documents that for anyone running or linking containers.

When you run:

```bash
docker run -p 8080:8080 my-spring-app
```

The first `8080` (host) connects to the second `8080` (inside container).

---

## ▶️ 5. `ENTRYPOINT ["java", "-jar", "app.jar"]`

### 💬 What it does:

Defines the **default command** that runs when the container starts.

### ⚙️ What it includes:

- `java` → the Java runtime (provided by the base image)
    
- `-jar` → tells Java to run a JAR file
    
- `app.jar` → your Spring Boot application
    

### 🤔 Why it’s needed:

This is what actually **launches your app** when you start the container.

If you didn’t include it, Docker wouldn’t know what to execute — the container would start and then instantly stop.

---

## 🧠 Summary Table

|Line|Purpose|Why it matters|
|---|---|---|
|`FROM`|Choose base image (OS + Java)|Gives environment your app needs|
|`WORKDIR`|Set working folder|Keeps files organized|
|`COPY`|Move your built app inside|Provides the actual app to run|
|`EXPOSE`|Document the port|Lets you map it for access|
|`ENTRYPOINT`|Start the app|Runs your Spring Boot automatically|

---

## ⚡ Build and Run Recap

1. **Build your JAR file**
    
    ```bash
    mvn clean package -DskipTests
    ```
    
2. **Build the Docker image**
    
    ```bash
    docker build -t my-spring-app .
    ```
    
3. **Run the container**
    
    ```bash
    docker run -p 8080:8080 my-spring-app
    ```
    

Your app will now run in Docker, isolated, and portable across any system with Docker installed.

---



## 🧱 Full Multi-Stage Dockerfile

```dockerfile
# Stage 1: Build the JAR using Maven
FROM maven:3.9.8-eclipse-temurin-17 AS build
WORKDIR /app

# Copy pom.xml and download dependencies (for faster rebuilds)
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy the rest of the project and build the jar
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Run the app
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

## 🧩 Stage 1 — Build

### 🔹 `FROM maven:3.9.8-eclipse-temurin-17 AS build`

**What:**  
Uses an image that already has Maven **and Java 17** installed.

**Why:**  
We need Maven to compile the project and build the `.jar`.  
`AS build` names this stage so we can copy results later.

---

### 🔹 `WORKDIR /app`

Sets the working directory inside the build container — all build commands run here.

---

### 🔹 `COPY pom.xml .`

Copies only the `pom.xml` first.

**Why:**  
This lets Docker **cache dependencies**.  
If your source code changes but `pom.xml` doesn’t, Docker won’t re-download everything next time.

---

### 🔹 `RUN mvn dependency:go-offline`

Downloads all project dependencies now, so the next build is faster.

---

### 🔹 `COPY src ./src`

Copies your project’s source code (Java + resources).

---

### 🔹 `RUN mvn clean package -DskipTests`

Builds the Spring Boot JAR inside the container.  
It ends up at `/app/target/...jar`.

**Why:**  
Now you don’t need Maven or Java installed on your host — Docker builds everything.

---

## 🧩 Stage 2 — Runtime

### 🔹 `FROM eclipse-temurin:17-jdk-alpine`

Start a new, clean image — just Java, no Maven.

**Why:**  
Removes all build tools → smaller, faster, more secure final image.

---

### 🔹 `WORKDIR /app`

Create and switch to the working folder again.

---

### 🔹 `COPY --from=build /app/target/*.jar app.jar`

Copies the JAR built in stage 1 into this new image.  
This line links the two stages.

---

### 🔹 `EXPOSE 8080`

Documents that the app listens on port 8080.

---

### 🔹 `ENTRYPOINT ["java", "-jar", "app.jar"]`

Tells Docker what to run when the container starts → launches Spring Boot.

---

## ⚡ Advantages of Multi-Stage Build

|Benefit|Description|
|---|---|
|🧩 Clean separation|Build tools (Maven) stay in stage 1, runtime stays minimal.|
|🪶 Smaller image|Only Java + your app JAR in final image (~200 MB smaller).|
|🚫 No local setup|You don’t need Maven or JDK installed on your machine.|
|🔁 Cached builds|Dependencies are cached for faster rebuilds.|

---

## 🧰 How to Use It

1. **Place Dockerfile** in your project root (next to `pom.xml`).
    
2. **Build the image:**
    
    ```bash
    docker build -t my-spring-app .
    ```
    
3. **Run the container:**
    
    ```bash
    docker run -p 8080:8080 my-spring-app
    ```
    
4. Visit 👉 `http://localhost:8080`
    

---




##### Tags : [[1 - Docker 🧋]]