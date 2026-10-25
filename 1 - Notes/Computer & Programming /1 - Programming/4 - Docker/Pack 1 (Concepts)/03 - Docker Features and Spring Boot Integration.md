


## Part 1: Docker's core features

|Feature|What it gives you|
|---|---|
|**Portability**|Build once, run on any machine with Docker (laptop, CI server, cloud)|
|**Isolation**|Each container has its own filesystem, network, and process space|
|**Layered images + caching**|Fast rebuilds; shared layers save disk and bandwidth|
|**Resource control**|Limit CPU and memory per container via cgroups|
|**Networking**|Containers talk to each other by name over virtual networks|
|**Volumes**|Persistent data that outlives a container|
|**Docker Compose**|Define and run multi-container apps from one YAML file|
|**Registries**|Push and pull images (Docker Hub, GitHub Container Registry, AWS ECR, etc.)|
|**Immutability**|An image never changes; to update, you build a new one|
|**Fast startup**|Containers start in about a second, ideal for scaling and CI|

A few deserve a closer look.

### Networking

Containers on the same user-defined network resolve each other by **service name**. Your Spring app can connect to `jdbc:postgresql://db:5432/mydb`, where `db` is simply the name of the database container. No IP addresses to hard-code.

### Volumes

Container filesystems are disposable. Anything you want to keep (database files, uploads) goes in a volume:

```bash
docker run -v pgdata:/var/lib/postgresql/data postgres:16
```

### Docker Compose

One file describes your whole stack, and one command starts it all. This is where Spring Boot developers feel the most benefit.

## Part 2: Compatibility with Spring Boot

Spring Boot and Docker fit together very naturally, for three reasons:

1. **Self-contained executable jar**: Boot packages your app plus an embedded Tomcat/Netty into a single jar. The container only needs a JRE and that one file. No external application server to install.
2. **Externalized configuration**: Boot reads settings from environment variables, which is exactly how Docker passes configuration. `SPRING_DATASOURCE_URL` automatically maps to `spring.datasource.url`.
3. **Stateless, 12-factor friendly design**: Boot apps are easy to run as disposable containers.

On top of that, modern Java is container-aware: the JVM respects cgroup memory and CPU limits, as we covered earlier.

## Part 3: Three ways to containerize a Spring Boot app

### Option 1: A simple Dockerfile

```dockerfile
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY target/myapp.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

```bash
./mvnw clean package
docker build -t myapp .
docker run -p 8080:8080 myapp
```

Simple, but it has a weakness: the whole jar is one layer, so any code change re-uploads all your dependencies too (often 50 MB or more).

### Option 2: Multi-stage build with layered jars (recommended)

Spring Boot supports **layered jars**, which split the jar into layers ordered by how often they change: dependencies rarely, your code constantly.

```dockerfile
# Stage 1: build
FROM eclipse-temurin:21-jdk AS build
WORKDIR /workspace
COPY . .
RUN ./mvnw clean package -DskipTests
RUN java -Djarmode=tools -jar target/*.jar extract --layers --destination extracted

# Stage 2: runtime
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /workspace/extracted/dependencies/ ./
COPY --from=build /workspace/extracted/spring-boot-loader/ ./
COPY --from=build /workspace/extracted/snapshot-dependencies/ ./
COPY --from=build /workspace/extracted/application/ ./
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Why this is better:

- **Multi-stage**: the final image contains only the JRE, not Maven or the JDK, so it's much smaller.
- **Layered**: when you change only your code, Docker rebuilds just the small `application` layer. Dependencies stay cached.

_Note:_ the exact layer-extraction command and folder names have changed between Spring Boot versions (older ones use `-Djarmode=layertools extract`). Check the docs for your version.

### Option 3: Buildpacks, with no Dockerfile at all

Spring Boot's build plugins can create an optimized image directly:

```bash
./mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=myapp
```

This uses **Cloud Native Buildpacks**. It picks a JRE, layers the jar, configures memory settings for containers, and follows security best practices automatically. It's a great default when you don't want to maintain a Dockerfile.

## Part 4: Docker Compose with Spring Boot

A typical stack: your app plus a PostgreSQL database.

```yaml
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://db:5432/mydb
      SPRING_DATASOURCE_USERNAME: postgres
      SPRING_DATASOURCE_PASSWORD: secret
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16
    environment:
      POSTGRES_DB: mydb
      POSTGRES_PASSWORD: secret
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      retries: 5

volumes:
  pgdata:
```

```bash
docker compose up
```

Notice how everything we discussed shows up: the service name `db` as hostname (networking), `pgdata` (volume), environment variables overriding Spring properties (externalized config).

## Part 5: Spring Boot's built-in Docker Compose support

Since **Spring Boot 3.1**, there's a dependency that makes local development even smoother:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-docker-compose</artifactId>
    <scope>runtime</scope>
    <optional>true</optional>
</dependency>
```

With a `compose.yaml` in your project root, when you start your app (`./mvnw spring-boot:run` or from your IDE), Boot will:

1. Run `docker compose up` for you
2. Detect the services (e.g. Postgres)
3. **Auto-configure the connection** to them, with no URL or credentials in `application.properties`
4. Stop them when the app stops (configurable)

Similarly, **Testcontainers** support lets your integration tests spin up real databases in throwaway containers instead of using H2, so tests run against the same database type as production.

## Part 6: Practical tips for Spring Boot in containers

- **Memory**: set `-XX:MaxRAMPercentage=75.0` (via `JAVA_TOOL_OPTIONS`) so the heap scales with the container limit.
- **Health checks**: add Spring Boot Actuator and use `/actuator/health`. Orchestrators like Kubernetes use it to know when your app is ready.
- **Graceful shutdown**: set `server.shutdown=graceful` so in-flight requests finish when the container gets a stop signal.
- **Don't run as root**: add a non-root user in the Dockerfile.
- **Don't bake secrets into images**: pass them as environment variables or use a secrets manager.
- **Slow startup**: Spring apps start in seconds, not milliseconds. Options to improve this include Spring Boot's CDS/AOT support or **GraalVM native images** (millisecond startup, lower memory, but longer builds).
- **Use `.dockerignore`**: exclude `target/`, `.git/`, and IDE files from the build context.

## How it all fits together

```
Source code ──► Maven/Gradle ──► Boot jar ──► Docker image ──► Registry
                                                                 │
                           Compose (local) / Kubernetes (prod) ◄─┘
```

## Quick recap

Docker fits Spring Boot well because Boot apps are **self-contained jars with externalized configuration**. You can containerize via a **plain Dockerfile**, a **multi-stage layered build**, or **Buildpacks**. **Docker Compose** orchestrates your app with its dependencies, and Spring Boot 3.1+ can even manage Compose and Testcontainers for you during development.




[[Docker]]
[[Spring Framework]]