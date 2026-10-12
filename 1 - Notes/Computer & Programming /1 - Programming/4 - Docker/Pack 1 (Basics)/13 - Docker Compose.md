

Docker Compose lets you define and run multiple connected containers using one YAML file.

For backend development, this is especially useful when your Spring Boot application depends on PostgreSQL, Redis, or other services.

## 1. The mental model

Without Compose, you might start your application and database separately:

```
docker run -d --name database postgres:18
docker run -d --name backend my-backend
```

You must configure networking, credentials, ports, persistence, and startup behavior yourself.

With Compose, you describe the whole application in `compose.yaml`:

compose.yaml

Services · Networks · Volumes · Configuration

Spring Boot

Container · Port 8080

PostgreSQL

Container · Persistent database volume

Compose creates and manages the application's containers and network.

The key distinction:

- Dockerfile describes how to build an image.
    
- Docker Compose describes how multiple services run together.
    
- Docker Engine runs the containers.
    

Compose is not a replacement for Dockerfiles. They solve different problems.

## 2. Your first Compose project

Let's begin with PostgreSQL alone, so you can understand Compose before adding Spring Boot.

Create a directory:

```
mkdir compose-lab
cd compose-lab
```

Create `compose.yaml`:

```

services:
  database:
    image: postgres:18
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: change-this-password
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql

volumes:
  postgres_data:
```

This is a learning configuration. For a real deployment, don't commit passwords to version control; use an appropriate secrets mechanism.

### Understand the YAML

`services`

Defines the containers Compose manages. Here, `database` is the service name.

`image`

```
image: postgres:18
```

Tells Docker which image to use. Compose pulls it if needed.

`environment`

```
environment:
  POSTGRES_DB: appdb
  POSTGRES_USER: appuser
  POSTGRES_PASSWORD: change-this-password
```

Provides environment variables to the PostgreSQL container. The official PostgreSQL image uses these variables to initialize a new database cluster.

`ports`

```
ports:
  - "127.0.0.1:5432:5432"
```

The format is `HOST_IP:HOST_PORT:CONTAINER_PORT`. Binding to `127.0.0.1` limits host access to your own machine.

`volumes`

```
volumes:
  - postgres_data:/var/lib/postgresql
```

Preserves PostgreSQL data outside the container's writable layer. For the official PostgreSQL 18 image, the mount target above is intentional: it uses `/var/lib/postgresql` for the data layout.

At the bottom, `volumes:` declares the named volume Compose manages.

## 3. Run and manage your application

Run these commands from the directory containing `compose.yaml`.

Start the database in the background:

```
docker compose up -d
```

Check the service status:

```
docker compose ps
```

Read the logs:

```
docker compose logs database
```

Follow logs live:

```
docker compose logs -f database
```

Stop and remove the container and network:

```
docker compose down
```

Your named volume remains, so the database data is normally preserved.

To remove the named volumes too:

```
docker compose down -v
```

Warning: `-v` deletes the Compose-managed named volumes. Do not use it if you need to preserve your database data.

## 4. How services communicate

Suppose you add a Spring Boot service called `backend`.

Inside the Compose network, your backend connects to PostgreSQL using:

```
spring.datasource.url=jdbc:postgresql://database:5432/appdb
spring.datasource.username=appuser
spring.datasource.password=${DB_PASSWORD}
```

Why `database`?

Compose provides service-name-based DNS on its default network. The backend resolves `database` to the database container's address.

The address depends on where the client runs:

|Client|Database hostname|
|---|---|
|Spring Boot running in Compose|`database`|
|Java running directly on your Debian host|`localhost`|
|Another machine|A configured reachable host/address|

This is one of the most important networking concepts in Compose: inside a container, `localhost` means that same container.

## 5. Add your Spring Boot application

Your project might look like this:

```
doitlater/
├── Dockerfile
├── compose.yaml
├── .dockerignore
├── build.gradle
├── settings.gradle
├── gradlew
├── gradle/
└── src/
```

Use a multi-stage Dockerfile to build the JAR, then define both services in `compose.yaml`:

```

services:
  backend:
    build: .
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://database:5432/appdb
      SPRING_DATASOURCE_USERNAME: appuser
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD:?Set DB_PASSWORD}
    depends_on:
      database:
        condition: service_healthy

  database:
    image: postgres:18
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: ${DB_PASSWORD:?Set DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser -d appdb"]
      interval: 5s
      timeout: 3s
      retries: 10

volumes:
  postgres_data:
```

Set the password in your shell before starting the application:

```
export DB_PASSWORD='your-local-development-password'

docker compose up --build -d
docker compose ps
docker compose logs -f backend
```

This example assumes your Dockerfile is compatible with `docker compose build` and your Spring Boot application reads the standard datasource environment variables.

### What did we add?

- `build: .` tells Compose to build the backend image from the current directory.
    
- `depends_on` with `service_healthy` waits for the database health check to pass before starting the backend.
    
- `healthcheck` tests whether PostgreSQL is ready to accept connections.
    
- `${DB_PASSWORD:?...}` makes Compose fail if the required variable is missing.
    

Note that `depends_on` does not automatically make your backend recover from a database failure after startup. Production applications should also handle connection failures and retries.

## 6. Essential Compose commands

|Command|Purpose|
|---|---|
|`docker compose up -d`|Start services in the background|
|`docker compose up --build`|Build images and start services|
|`docker compose down`|Remove containers and Compose network|
|`docker compose ps`|Show service containers|
|`docker compose logs -f`|Follow logs|
|`docker compose restart backend`|Restart the backend service|
|`docker compose exec database sh`|Open a shell inside the database container|
|`docker compose config`|Validate and render the resolved configuration|
|`docker compose pull`|Pull service images|
|`docker compose build`|Build services configured with `build`|

One important distinction: `docker compose stop` stops containers but keeps them, whereas `docker compose down` removes the containers and the Compose-managed network.

## 7. The professional mental model

Think of Compose as a small application orchestration tool for one Docker host.

- Services define how containers are created and run.
    
- Images provide the filesystem and software.
    
- Networks provide communication between services.
    
- Volumes preserve state beyond container replacement.
    
- Environment variables and secrets supply configuration.
    
- Health checks report whether a service meets a defined readiness test.
    

Compose does not replace Kubernetes for large distributed deployments, but it is excellent for local development, integration testing, and many small deployments.



[[Docker]]