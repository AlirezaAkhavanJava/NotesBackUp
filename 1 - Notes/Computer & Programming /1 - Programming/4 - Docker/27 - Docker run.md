

## 🧩 1️⃣ What `docker run` really does

`docker run` = **start a container** (an isolated mini-computer) from an image.

Example:

```bash
docker run hello-world
```

🟢 This runs a simple test container to check Docker works.

---

## 🧱 2️⃣ Typical command structure

```bash
docker run [OPTIONS] IMAGE [COMMAND]
```

**Example:**

```bash
docker run -d -p 8080:8080 --name myapp my-java-app
```

|Part|Meaning|
|---|---|
|`docker run`|Start a new container|
|`-d`|Detached mode (run in background)|
|`-p 8080:8080`|Map host port 8080 → container port 8080|
|`--name myapp`|Give the container a readable name|
|`my-java-app`|The image to run (you built it earlier with `docker build`)|

---

## 🌐 3️⃣ Port mapping (`-p host:container`)

Containers have their own internal network, so to access them from your computer you **map ports**.

Example:

```bash
docker run -p 9090:8080 my-java-app
```

|Side|Meaning|
|---|---|
|Left (9090)|Port on your computer (Docker host)|
|Right (8080)|Port inside the container where app listens|

✅ Then you can visit → [http://localhost:9090](http://localhost:9090/)

---

## 🧠 4️⃣ Environment variables (`-e`)

You can **pass values** to the container at runtime.  
Inside the container, the app reads them like normal environment variables.

Example:

```bash
docker run -e SPRING_PROFILES_ACTIVE=prod my-java-app
```

In Spring Boot, you can access this with:

```properties
spring.profiles.active=${SPRING_PROFILES_ACTIVE}
```

---

## 🧰 5️⃣ Combine them — multiple `-e` flags, ports, name

Example for a **Spring Cloud Gateway** microservice:

```bash
docker run -d \
  -p 9090:9090 \
  -e CONFIG_SERVER_URL=http://host.docker.internal:8888 \
  -e EUREKA_SERVER_ADDRESS=http://host.docker.internal:8761/eureka \
  --name cloudgateway \
  cloudgateway
```

Breakdown:

|Option|What it does|
|---|---|
|`-d`|Runs detached|
|`-p 9090:9090`|Maps port 9090 host → 9090 container|
|`-e CONFIG_SERVER_URL=...`|Passes Config Server URL to app|
|`-e EUREKA_SERVER_ADDRESS=...`|Passes Eureka Server URL|
|`--name cloudgateway`|Names container|
|`cloudgateway`|Image to run|

---

## 💡 6️⃣ Special address: `host.docker.internal`

Containers are isolated.  
When you say `localhost` **inside** a container, it refers to _itself_, not your Mac or PC.

So Docker gives a special DNS name:

```
host.docker.internal
```

➡️ It means **“the host machine running Docker”**.

That’s why:

```bash
-e CONFIG_SERVER_URL=http://host.docker.internal:8888
```

lets your container talk to a Config Server running on your host computer.

---

## ⚙️ 7️⃣ Verify container

```bash
docker ps
```

Shows running containers and their port mappings.  
Example output:

```
CONTAINER ID   IMAGE          PORTS                    NAMES
a12b3c4d5e6f   cloudgateway   0.0.0.0:9090->9090/tcp   cloudgateway
```

✅ Means:

- Host port 9090 → container port 9090
    
- Name: `cloudgateway`
    

Check logs:

```bash
docker logs cloudgateway
```

Stop it:

```bash
docker stop cloudgateway
```

Remove it:

```bash
docker rm cloudgateway
```

---

## 🧠 8️⃣ Typical use in microservices

You might have several containers:

|Service|Port|Runs on|
|---|---|---|
|Config Server|8888|Host|
|Eureka Server|8761|Host|
|Gateway|9090|Docker|
|User Service|8081|Docker|

Each container can talk to others using:

- `http://host.docker.internal:<port>` (if host)
    
- Or custom Docker network (advanced).
    

---

## 🧱 9️⃣ Summary (cheat sheet)

|Command|What it does|
|---|---|
|`docker run hello-world`|Test Docker installation|
|`docker run -p 8080:8080 myapp`|Map host:container port|
|`docker run -d --name myapp my-java-app`|Run in background with name|
|`docker run -e VAR=value myapp`|Set environment variable|
|`docker ps`|Show running containers|
|`docker logs <name>`|View logs|
|`docker stop <name>`|Stop a container|
|`docker rm <name>`|Remove it|

---

## 🧠 1️⃣ What is Docker Compose?

**Docker Compose** lets you define and run multiple containers together using **one YAML file** — instead of typing 5 long `docker run` commands.

It uses a file named:

```
docker-compose.yml
```

Then you just run:

```bash
docker compose up
```

and it starts **all your services** at once.

---

## 🧱 2️⃣ Basic structure of a `docker-compose.yml`

Example:

```yaml
version: "3.8"

services:
  myapp:
    image: my-java-app
    ports:
      - "8080:8080"
```

Run it:

```bash
docker compose up
```

✅ Now the same as `docker run -p 8080:8080 my-java-app`.

---

## ⚙️ 3️⃣ Add environment variables and container name

```yaml
version: "3.8"

services:
  cloudgateway:
    image: cloudgateway
    container_name: cloudgateway
    ports:
      - "9090:9090"
    environment:
      - CONFIG_SERVER_URL=http://host.docker.internal:8888
      - EUREKA_SERVER_ADDRESS=http://host.docker.internal:8761/eureka
```

This file is equal to:

```bash
docker run -d -p 9090:9090 \
  -e CONFIG_SERVER_URL=http://host.docker.internal:8888 \
  -e EUREKA_SERVER_ADDRESS=http://host.docker.internal:8761/eureka \
  --name cloudgateway cloudgateway
```

But much cleaner ✅

---

## 🌐 4️⃣ Adding multiple microservices

You can define them all in one file:

```yaml
version: "3.8"

services:
  config-server:
    image: config-server
    ports:
      - "8888:8888"

  eureka-server:
    image: eureka-server
    ports:
      - "8761:8761"

  cloudgateway:
    image: cloudgateway
    ports:
      - "9090:9090"
    environment:
      - CONFIG_SERVER_URL=http://config-server:8888
      - EUREKA_SERVER_ADDRESS=http://eureka-server:8761/eureka
    depends_on:
      - config-server
      - eureka-server
```

### 🧩 What happens here:

- Each service runs as a container.
    
- Docker Compose automatically creates a **network**.
    
- Containers can talk to each other using **their service names** (e.g., `config-server`, `eureka-server`).
    
- You no longer need `host.docker.internal`.
    

✅ Access them via:

- Config → `http://localhost:8888`
    
- Eureka → `http://localhost:8761`
    
- Gateway → `http://localhost:9090`
    

---

## 🧰 5️⃣ Useful Docker Compose commands

|Command|Purpose|
|---|---|
|`docker compose up`|Start all containers|
|`docker compose up -d`|Run in background|
|`docker compose down`|Stop and remove containers|
|`docker compose ps`|Show running containers|
|`docker compose logs`|Show logs|
|`docker compose logs -f cloudgateway`|Follow logs of one service|

---

## 🧠 6️⃣ Best practices

- Always use **lowercase names** for services.
    
- Use `depends_on` to start things in the right order.
    
- Put your JARs or built images in the same project folder.
    
- Use environment variables to link services (don’t hardcode IPs).
    
- You can define a **.env file** to store common variables like ports, DB credentials, etc.
    

Example `.env`:

```
EUREKA_PORT=8761
GATEWAY_PORT=9090
```

Then in `docker-compose.yml`:

```yaml
ports:
  - "${GATEWAY_PORT}:${GATEWAY_PORT}"
```

---

## 🚀 7️⃣ Run everything

When your file is ready:

```bash
docker compose up -d
```

✅ All microservices start.  
To stop:

```bash
docker compose down
```

---

## 🧩 8️⃣ Recap — Why use Compose?

|Feature|`docker run`|`docker compose`|
|---|---|---|
|Run one container|✅|✅|
|Run many containers|❌|✅|
|Reusable config|❌|✅|
|Built-in networking|❌|✅|
|Environment management|Manual `-e` flags|YAML & `.env`|
|Dependency order|Manual|`depends_on`|


##### Tags : [[1 - Docker 🧋]]