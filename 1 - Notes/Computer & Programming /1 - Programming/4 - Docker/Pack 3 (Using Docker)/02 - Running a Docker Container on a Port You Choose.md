

Docker lets you package an application and everything it needs (the runtime, libraries, config) into one unit called an **image**. When you start that image, you get a **container**: a live, isolated process running your app. You can think of the image as a recipe and the container as the meal made from it. You can cook the same recipe many times.

Containers are isolated, so by default nothing outside can reach them. If a web server runs inside a container on port 80, you can't just open your browser and see it. You have to tell Docker to connect a port on your machine to a port inside the container. That connection is called **port mapping**, and it's the heart of this lesson.

---

## The problem it solves

Say you want to run two web servers at once. Both listen on port 80 inside their own containers. On your machine, only one program can use port 80 at a time. Without port mapping, you'd have a clash.

With port mapping, each container keeps its own inside port, and you pick different outside ports:

|Container|Inside port|Your machine's port|You open|
|---|---|---|---|
|web-1|80|8080|`localhost:8080`|
|web-2|80|9090|`localhost:9090`|

No clash, and you choose the ports.

---

## The core command

```bash
docker run -d --name my-nginx -p 8080:80 nginx
```

Let's walk through it piece by piece.

|Part|What it means|
|---|---|
|`docker run`|Create a new container from an image and start it.|
|`-d`|"Detached." Runs in the background so your terminal stays free.|
|`--name my-nginx`|Gives the container a name you choose. Without it, Docker invents a random one.|
|`-p 8080:80`|Port mapping. Format is `HOST_PORT:CONTAINER_PORT`.|
|`nginx`|The image to use.|

### Reading `-p 8080:80` correctly

The **left** number is on your machine. The **right** number is inside the container.

```
-p  8080  :  80
     │       │
     │       └── port the app listens on INSIDE the container
     └────────── port you open on YOUR machine
```

So traffic to `localhost:8080` is forwarded to port 80 in the container. Open `http://localhost:8080` and you'll see the Nginx welcome page.

> Tip: the right-hand number is decided by the app, not by you. Nginx listens on 80, so the right side must be 80. Check the image's documentation to find which port it uses.

---

## What happens if the image isn't on your machine?

Docker looks for the image locally first. If it can't find it, it downloads (pulls) it from Docker Hub automatically. You'll see lines like `Pulling from library/nginx`. You can also pull it yourself ahead of time:

```bash
docker pull nginx
```

You can ask for a specific version by adding a **tag** after a colon:

```bash
docker run -d --name my-nginx -p 8080:80 nginx:1.27
```

If you leave the tag off, Docker uses `latest`. For real projects, pinning a version is safer because `latest` can change under you.

---

## Step by step: your first container

**1. Run it**

```bash
docker run -d --name my-nginx -p 8080:80 nginx
```

Docker prints a long ID. That means it worked.

**2. Check that it's running**

```bash
docker ps
```

You'll see something like:

```
CONTAINER ID   IMAGE   PORTS                  NAMES
a1b2c3d4e5f6   nginx   0.0.0.0:8080->80/tcp   my-nginx
```

The `PORTS` column confirms the mapping: port 8080 on your machine goes to port 80 in the container.

**3. Test it**

```bash
curl http://localhost:8080
```

Or open it in your browser. You should see the Nginx welcome HTML.

**4. Look at its logs**

```bash
docker logs my-nginx
```

**5. Stop and remove it**

```bash
docker stop my-nginx
docker rm my-nginx
```

---

## Create first, start later (two-step version)

`docker run` really does two things in one: **create** and **start**. You can do them separately:

```bash
docker create --name my-nginx -p 8080:80 nginx
docker start my-nginx
```

This is handy when you want to set everything up now and start later. Most of the time, `docker run` is what you want.

---

## Useful variations

**Let Docker pick a random free host port**

```bash
docker run -d -P nginx
```

Capital `-P` maps every exposed port to a random high port on your machine. Run `docker ps` to see which one it chose.

**Map more than one port**

```bash
docker run -d -p 8080:80 -p 8443:443 nginx
```

**Only allow access from your own machine**

```bash
docker run -d -p 127.0.0.1:8080:80 nginx
```

By default, `-p 8080:80` listens on all network interfaces, so other devices on your network can reach it too. Adding `127.0.0.1` restricts it to your machine only. This is a good habit for databases.

**Pass environment variables**

A real example with PostgreSQL, since you already know it:

```bash
docker run -d \
  --name my-postgres \
  -e POSTGRES_PASSWORD=secret \
  -p 5433:5432 \
  postgres:16
```

Line by line:

- `-e POSTGRES_PASSWORD=secret` sets an environment variable inside the container. The Postgres image requires a password.
- `-p 5433:5432` maps your port 5433 to Postgres's default 5432. Using 5433 on your side avoids a clash if Postgres is already installed on your machine.
- `postgres:16` uses version 16 of the image.

Then connect with `localhost:5433`.

**Spring Boot app example**

A Spring Boot app listens on 8080 by default, so:

```bash
docker run -d --name my-app -p 9000:8080 my-spring-app
```

You'd open `http://localhost:9000`.

---

## Common mistakes

|Symptom|Likely cause|Fix|
|---|---|---|
|`port is already allocated`|Something on your machine already uses that host port.|Pick another left-hand number, like `8081:80`.|
|Page doesn't load, but the container is running|Wrong right-hand port. The app listens on a different port than you mapped.|Check the image docs and `docker logs`.|
|Container exits immediately|The app inside crashed or needs required settings.|Run `docker logs <name>` to see why.|
|`container name already in use`|An old container still has that name.|`docker rm my-nginx` first.|
|Swapped the numbers (`80:8080`)|Host and container sides reversed.|Remember: host first, container second.|

---

## Handy commands to remember

|Goal|Command|
|---|---|
|List running containers|`docker ps`|
|List all containers, including stopped|`docker ps -a`|
|Stop a container|`docker stop <name>`|
|Start a stopped container|`docker start <name>`|
|Remove a container|`docker rm <name>`|
|Force-remove a running one|`docker rm -f <name>`|
|See logs live|`docker logs -f <name>`|
|Open a shell inside|`docker exec -it <name> sh`|
|Show port mappings|`docker port <name>`|

---

## A related concept: `EXPOSE` vs `-p`

You may see `EXPOSE 80` inside a Dockerfile. It's only documentation: it tells readers which port the app uses. It does **not** open anything to the outside. Only `-p` (or `-P`) actually makes a port reachable from your machine.

## A related concept: Docker Compose

If you run several containers together (say, an app and PostgreSQL), typing long `docker run` commands gets tiring. **Docker Compose** lets you write the same settings in a `compose.yaml` file:

```yaml
services:
  web:
    image: nginx
    ports:
      - "8080:80"
```

Then `docker compose up -d` starts it. The `ports` line uses the same `HOST:CONTAINER` format you just learned.

---

## Quick recap

1. An **image** is the recipe. A **container** is a running copy.
2. `docker run -d --name NAME -p HOST_PORT:CONTAINER_PORT IMAGE` is the whole pattern.
3. Left number = your machine. Right number = inside the container.
4. Use `docker ps` to confirm, `docker logs` to debug, `docker stop` and `docker rm` to clean up.



[[Docker]]
[[Docker]]