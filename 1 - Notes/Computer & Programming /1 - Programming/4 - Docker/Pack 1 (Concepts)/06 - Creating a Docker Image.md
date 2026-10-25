


## The short version

You create an image by writing a **Dockerfile** (a list of build instructions) and running `docker build`. Docker executes each instruction in order, and each filesystem-changing step becomes a layer. The result is an image you can run, tag, and push.

There are several ways to create images, so we'll cover the main ones, focusing on Spring Boot.

## Method 1: Dockerfile + `docker build` (the standard way)

### The Dockerfile instructions you need

|Instruction|Purpose|Creates a layer?|
|---|---|---|
|`FROM`|Base image to start from|Yes (base layers)|
|`WORKDIR`|Set the working directory|Metadata only|
|`COPY`|Copy files from your machine into the image|Yes|
|`ADD`|Like `COPY`, plus URL download and tar auto-extract (prefer `COPY`)|Yes|
|`RUN`|Execute a command at **build time** (install packages, compile)|Yes|
|`ENV`|Set an environment variable|Metadata only|
|`ARG`|Build-time variable (not available at runtime)|Metadata only|
|`EXPOSE`|Document the port the app listens on|Metadata only|
|`USER`|Run as this user|Metadata only|
|`ENTRYPOINT`|The main command the container runs|Metadata only|
|`CMD`|Default arguments to `ENTRYPOINT` (or default command)|Metadata only|

> **Key distinction:** `RUN` executes while _building_ the image. `CMD`/`ENTRYPOINT` execute when the _container starts_.

### Step-by-step: a Spring Boot image

**1. Build your jar**

```bash
./mvnw clean package -DskipTests
```

**2. Create a file named `Dockerfile`** (no extension) in the project root:

```dockerfile
FROM eclipse-temurin:21-jre

WORKDIR /app

# Create and use a non-root user
RUN useradd --system --create-home appuser
USER appuser

COPY target/myapp.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
```

**3. Build it**

```bash
docker build -t myapp:1.0 .
```

- `-t myapp:1.0` names and tags the image.
- `.` is the **build context**: the directory sent to Docker. `COPY` can only see files inside it.

**4. Verify and run**

```bash
docker images
docker run -p 8080:8080 myapp:1.0
```

## What happens during `docker build`

```
Dockerfile instruction        What Docker does
─────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre → pull base image layers
RUN useradd ...             → start temp container, run command,
                              save filesystem changes as a new layer
COPY target/myapp.jar ...   → add the file as a new layer
ENTRYPOINT [...]            → record in the image config (no layer)
                              → final image gets a name and tag
```

For each `RUN`, Docker starts a temporary container from the layers so far, runs the command, captures the diff, and saves it as a layer. If a step and everything before it is unchanged, Docker uses the **cache** and skips it.

## Method 2: Multi-stage build (recommended)

This builds the jar _inside_ Docker, so anyone can build the image without Maven or a JDK installed, and the final image stays small.

```dockerfile
# ---------- Stage 1: build ----------
FROM eclipse-temurin:21-jdk AS build
WORKDIR /workspace

# Copy dependency definitions first (better caching)
COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN ./mvnw dependency:go-offline

# Then copy source and build
COPY src src
RUN ./mvnw clean package -DskipTests

# ---------- Stage 2: runtime ----------
FROM eclipse-temurin:21-jre
WORKDIR /app
RUN useradd --system --create-home appuser
USER appuser

COPY --from=build /workspace/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Why this works well:

- **Stage 1** has the JDK and Maven; **stage 2** has only the JRE and the jar. Only the last stage becomes the final image.
- **Caching**: the dependency download layer is reused until `pom.xml` changes. Editing source code only reruns the last build step.

## Method 3: Buildpacks (no Dockerfile)

```bash
./mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=myapp:1.0
```

Spring Boot uses Cloud Native Buildpacks to create an optimized, layered image with sensible JVM memory settings. For Gradle: `./gradlew bootBuildImage`. This requires Docker running locally.

## Method 4: Jib (no Docker daemon needed)

Google's Jib plugin builds optimized images straight from Maven/Gradle:

```bash
./mvnw compile jib:dockerBuild
```

It layers dependencies and classes separately automatically, and can push directly to a registry without Docker installed. You need to add the plugin to your `pom.xml` first.

## Method 5: Commit a container (avoid)

```bash
docker commit <container> myimage
```

This snapshots a running container into an image. It works, but it is **not reproducible** and nobody can see how the image was made. Use Dockerfiles instead.

## Choosing a method

|Method|Needs Dockerfile|Best for|
|---|---|---|
|Simple Dockerfile|Yes|Learning, quick builds|
|Multi-stage Dockerfile|Yes|Full control, reproducible builds|
|Buildpacks|No|Spring Boot defaults with minimal effort|
|Jib|No|CI pipelines, no Docker daemon|
|`docker commit`|No|Experiments only|

## Best practices

- **Use a `.dockerignore` file** so the build context stays small and secrets don't leak in:
    
    ```
    target/.git/.idea/*.log.env
    ```
    
- **Order instructions from least to most frequently changing** to maximize caching.
- **Combine related `RUN` commands** to avoid extra layers, and clean up in the same step:
    
    ```dockerfile
    RUN apt-get update && apt-get install -y curl \    && rm -rf /var/lib/apt/lists/*
    ```
    
- **Use exec form** for `ENTRYPOINT` (`["java","-jar","app.jar"]`, not a plain string) so Java receives stop signals directly and can shut down gracefully.
- **Pin base image versions** (`21-jre`, not `latest`).
- **Never put secrets in the image**; layers are permanent and inspectable, even if you delete the file in a later layer.
- **Prefer JRE over JDK** in the final stage.

## Troubleshooting tips

```bash
docker build --no-cache -t myapp .   # ignore the cache
docker history myapp                  # see layer sizes
docker run -it --entrypoint sh myapp  # poke around inside (if the image has a shell)
```

## Quick recap

You create an image by writing a **Dockerfile** and running **`docker build`**. Each instruction becomes a cached layer, `RUN` works at build time while `ENTRYPOINT`/`CMD` work at run time, and **multi-stage builds** keep the final image small. For Spring Boot, you can also skip the Dockerfile using **Buildpacks** or **Jib**.



[[Docker]]