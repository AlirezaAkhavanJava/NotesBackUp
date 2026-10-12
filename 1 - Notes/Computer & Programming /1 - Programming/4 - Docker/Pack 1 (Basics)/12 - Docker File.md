

A Dockerfile is a recipe for building a Docker image. Since you're learning Java backend development, we'll use a Java application to understand each instruction and how Docker turns your source code into a runnable container.

## 1. The mental model

Dockerfile

Instructions for building the application image

Docker image

Packaged filesystem, runtime and application

Container

A running instance of the image

Think of it like Java:

- Dockerfile: the build instructions.
    
- Image: the packaged artifact, somewhat like a JAR in that it is a reusable build output.
    
- Container: a running instance of that packaged artifact, somewhat like a running Java process.
    

These are analogies, not exact equivalents. An image contains more than your application's compiled code.

## 2. Your first Dockerfile

Imagine this project:

```
hello-java/
├── Dockerfile
├── Hello.java
└── Hello.class
```

Create a file named `Dockerfile`:

```

FROM eclipse-temurin:25-jre

WORKDIR /app

COPY Hello.class .

CMD ["java", "Hello"]
```

This example assumes `Hello.class` has already been compiled and the image can run it with Java 25.

Build and run it on Debian:

```
docker build -t hello-java .
docker run --rm hello-java
```

The `.` tells Docker to use the current directory as the build context. We'll examine that concept shortly.

## 3. Understand every instruction

### `FROM` — choose the base image

```
FROM eclipse-temurin:25-jre
```

Every Docker build starts from a base image (unless using a special `FROM scratch` approach).

- `eclipse-temurin` is a Java runtime distribution.
    
- `25` is the Java major version.
    
- `jre` indicates a runtime-focused image rather than a full JDK.
    

Why it exists: your container needs an operating-system filesystem and the software required to run your application. The base image supplies that foundation.

For a precompiled Java application, a JRE image is often enough. If you compile Java inside the image, you'll generally need a JDK in the build stage.

### `WORKDIR` — set the working directory

```
WORKDIR /app
```

This creates `/app` if necessary and sets it as the working directory for subsequent instructions such as `RUN`, `COPY`, and `CMD`.

Similar to:

```
mkdir -p /app
cd /app
```

The important difference is that `WORKDIR` sets the directory inside the image, not your Debian host.

### `COPY` — transfer files into the image

```
COPY Hello.class .
```

The syntax is:

```
COPY <source> <destination>
```

The source is relative to the build context by default. The destination is inside the image.

For example:

```
COPY app.jar /app/app.jar
```

This copies `app.jar` from your build context into `/app/app.jar` in the image.

Important: `COPY` does not download files from the internet, and it cannot normally copy arbitrary files outside the build context.

### `RUN` — execute a build-time command

```
RUN apt-get update
```

`RUN` executes while Docker builds the image. Its resulting filesystem changes are captured in an image layer.

Typical uses include:

- Installing system packages.
    
- Compiling source code.
    
- Downloading dependencies.
    
- Creating required directories.
    

For example:

```
RUN mkdir -p /app/logs
```

This is different from `CMD`: `RUN` executes during the image build, while `CMD` specifies the default command when a container starts.

### `CMD` — define the default startup command

```
CMD ["java", "Hello"]
```

Docker uses this command by default when starting a container.

The JSON-array format is called exec form. It starts the executable directly instead of passing the command through a shell.

For Java applications, this is a common pattern:

```
CMD ["java", "-jar", "app.jar"]
```

You can override the default command:

```
docker run --rm hello-java java -version
```

Here, Docker runs `java -version` instead of the image's default `CMD`.

### `EXPOSE` — document the container's port

```
EXPOSE 8080
```

This documents that the application is expected to listen on port `8080` inside the container.

It does not publish the port to your host. To make it accessible from Debian, use:

```
docker run --rm -p 8080:8080 my-java-app
```

The format is:

```
-p HOST_PORT:CONTAINER_PORT
```

## 4. `RUN` vs `CMD` vs `ENTRYPOINT`

These instructions are easy to confuse, so learn the distinction early.

|Instruction|Purpose|When it acts|
|---|---|---|
|`RUN`|Build or modify the image|Image build|
|`CMD`|Default command or arguments|Container start|
|`ENTRYPOINT`|Main executable for the container|Container start|

A typical Java service uses:

```
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

This makes Java the main executable. You can supply additional arguments:

```
docker run --rm my-java-app --spring.profiles.active=prod
```

The arguments are appended to the entrypoint command.

Use `CMD` when you want an easily replaceable default command. Use `ENTRYPOINT` when the container is intended to behave like a particular executable.

## 5. Build context: a critical concept

When you execute:

```
docker build -t my-java-app .
```

Docker receives a build context: the files available to the build, usually the directory represented by `.`.

Suppose your directory looks like this:

```
my-java-app/
├── Dockerfile
├── app.jar
├── .env
└── .git/
```

You usually don't want `.git`, local configuration, or secrets sent as build-context files.

Create a `.dockerignore` file:

```

.git
.env
*.log
target/
build/
.idea/
```

Adjust it to your build strategy. For example, if your Dockerfile expects a JAR already built under `target/`, don't ignore that JAR.

Security rule: never bake database passwords, API keys, or other secrets into an image using `COPY` or `ENV`. Pass runtime configuration through an appropriate secret-management mechanism.

## 6. A practical Dockerfile for Spring Boot

Suppose you've built a Spring Boot application and its JAR is located at `build/libs/DoItLater-1.0.0.jar`.

A simple runtime Dockerfile would be:

```

FROM eclipse-temurin:25-jre

WORKDIR /app

COPY build/libs/DoItLater-1.0.0.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```

Build and run it from your project root:

```
./gradlew bootJar

docker build -t doitlater:1.0.0 .

docker run --rm \
  --name doitlater \
  -p 8080:8080 \
  doitlater:1.0.0
```

Your Spring Boot application should now be reachable at `http://localhost:8080`, assuming it starts successfully and listens on port 8080.

If it connects to PostgreSQL, remember that `localhost` inside the container refers to the container itself, not your Debian host. You'll need to configure the database hostname and network appropriately.

## 7. Professional practice: multi-stage builds

A more advanced technique is to separate compilation from runtime.

```

# Stage 1: Build the application
FROM eclipse-temurin:25-jdk AS build

WORKDIR /workspace

COPY gradlew .
COPY gradle gradle
COPY settings.gradle* build.gradle* ./
COPY src src

RUN chmod +x gradlew && ./gradlew bootJar --no-daemon

# Stage 2: Run the application
FROM eclipse-temurin:25-jre

WORKDIR /app

COPY --from=build /workspace/build/libs/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```

This assumes a conventional Gradle project that produces one executable Spring Boot JAR in `build/libs/`. Projects with multiple JARs or different build layouts need a more specific `COPY` instruction.

Why use two stages?

- The first stage contains the JDK and build tooling.
    
- The second stage contains the runtime and application JAR.
    
- Build-only files and tooling are excluded from the final image unless explicitly copied.
    

This often reduces the final image size and attack surface. The exact size reduction depends on the base images and dependencies.



[[Docker]]