
**Docker** is a tool that packages an application together with everything it needs to run (runtime, libraries, config) into a standard unit called a **container**, so it runs the same way on any machine.

**Analogy:** A shipping container. Before standard containers, cargo was loaded loosely and every ship, port, and truck handled it differently. A standard container holds anything inside, and every crane and ship handles it the same way. Docker does that for software: your app is the cargo, and any machine with Docker is the ship.

## The problem it solves

"It works on my machine." Your Spring Boot app needs Java 21, a specific PostgreSQL version, certain environment variables. A teammate or a server has different versions installed, and things break. With Docker, the environment travels _with_ the app.

## Core concepts

|Concept|Meaning|Analogy|
|---|---|---|
|**Image**|A read-only template containing the app and its environment|A recipe or blueprint|
|**Container**|A running instance of an image|A dish cooked from the recipe|
|**Dockerfile**|A text file describing how to build an image|The recipe's written steps|
|**Registry**|A place to store and share images (Docker Hub)|An app store for images|
|**Volume**|Storage that outlives a container|An external hard drive|

One image can start many containers, just as one class can create many objects in Java.

## Containers vs virtual machines

A **VM** emulates a whole computer, including its own full operating system, so it is heavy (gigabytes, minutes to boot). A **container** shares the host's Linux kernel and isolates only the process, so it is light (megabytes, starts in about a second).

```
VM:         App -> Guest OS -> Hypervisor -> Hardware
Container:  App -> Container runtime -> Host OS kernel -> Hardware
```

Under the hood, Docker uses Linux features: **namespaces** (each container sees its own processes, network, and files) and **cgroups** (limits on CPU and memory). That is why Docker is native on Debian, and why on Windows and macOS it runs inside a hidden Linux VM.

## Installing on Debian 13

```bash
sudo apt install docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER      # run docker without sudo (log out and in after)
docker run hello-world             # test
```

(Docker's own repository gives newer versions via the `docker-ce` package, but `docker.io` from Debian is fine for learning. Check Docker's official docs for the current install steps for Debian.)

## Everyday commands

```bash
docker pull postgres                  # download an image
docker run -d --name db -p 5432:5432 \
  -e POSTGRES_PASSWORD=secret postgres   # start a container
docker ps                             # list running containers
docker logs db                        # see output
docker exec -it db psql -U postgres   # open a shell/command inside
docker stop db && docker rm db        # stop and delete
```

Breaking down `run`:

- `-d` runs in the background
- `-p 5432:5432` maps **host port to container port** (this is the networking lesson: the container has its own isolated network, so you must publish a port to reach it)
- `-e` sets an environment variable

This is how you quickly got PostgreSQL, MySQL, and MongoDB in the earlier lessons without installing them on your system.

## A Dockerfile for a Spring Boot app

```dockerfile
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY target/app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

```bash
mvn package                       # Maven builds target/app.jar
docker build -t my-app .          # build the image
docker run -p 8080:8080 my-app    # run it
```

Each line is a **layer**. Docker caches layers, so unchanged steps are reused and rebuilds are fast. That is why you order a Dockerfile from least-changing to most-changing.

## Docker Compose: running several containers together

A real back-end is several pieces. Compose describes them all in one file, `compose.yaml`:

```yaml
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://db:5432/library
      SPRING_DATASOURCE_USERNAME: alireza
      SPRING_DATASOURCE_PASSWORD: secret
    depends_on:
      - db
  db:
    image: postgres:16
    environment:
      POSTGRES_USER: alireza
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: library
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

```bash
docker compose up -d     # start everything
docker compose down      # stop and remove
```

Notice the URL uses `db` as the host, not `localhost`. Compose gives each service a **DNS name** on a private network, so containers find each other by service name. Inside the `app` container, `localhost` means the app container itself.

## Where it fits in the real world

- **Development:** a teammate runs `docker compose up` and has the full stack in minutes.
- **Deployment:** the same image you tested is the one that runs in production.
- **CI/CD:** build pipelines build, test, and push images automatically.
- **Orchestration:** at scale, tools like **Kubernetes** run and manage thousands of containers across many servers.

This connects to the real-projects lesson: Docker is the "deployment" and "identical environments" part of the checklist.

## Gotchas

- **Containers are disposable.** Data written inside a container is lost when it is removed. Use **volumes** for anything that must persist (database files).
- **Port conflicts:** `-p 5432:5432` fails if PostgreSQL is already running on your host's port 5432. Change the left number (`-p 5433:5432`).
- **`localhost` confusion:** inside a container, `localhost` is the container itself, not your machine or other containers. Use service names in Compose.
- **Never bake secrets into images.** Anything in the image or Dockerfile can be extracted. Pass secrets at runtime (environment variables, secret managers), and don't commit them in `compose.yaml` for real projects.
- **Image vs container confusion:** deleting a container does not delete the image, and rebuilding an image does not update running containers; you must recreate them.
- **Pin versions:** `postgres:16` is safer than `postgres` (which means `latest` and can change under you).
- **Root access:** membership in the `docker` group is effectively root-level power on that machine, so be careful on shared systems.
- **Docker is not a security sandbox by default.** Containers share the host kernel, so they are isolated but not as strongly as VMs.
- **`depends_on` waits for start, not readiness.** The database container may be running but not yet accepting connections; real setups add health checks or retries.



[[Computer & Programming]]
[[Spring Framework]]
[[C]]
[[Python]]
[[Data-base]]
