

Docker works with two kinds of things: **images** and **containers**. An image is a read-only package that holds your app and everything it needs to run. A container is a live, running copy made from an image. Almost every Docker command either manages images (list, download, build, delete) or manages containers (run, stop, start, remove).

Once you see which commands belong to which group, Docker stops feeling like a pile of random commands and starts feeling like a small, logical toolbox. This tutorial walks through all of them, in the order you'll actually use them, and ends with the habits that make someone a good Docker user.

---

## The problem it solves

"It works on my machine" is a classic headache. Your laptop has one Java version, the server has another, and the app breaks. Docker puts the app and its environment into one image, so it runs the same way everywhere. The commands below are how you handle those images and the containers made from them.

---

## The big picture 

```
                    ┌───────────────────────┐
                    │  REGISTRY             │
                    │  (Docker Hub, etc.)   │
                    └──────────┬────────────┘
                               │
                   docker pull │   ▲ docker push
                               ▼   │
 ┌────────────┐  docker build  ┌─────────┐
 │ Dockerfile │ ─────────────► │  IMAGE  │  (read-only recipe)
 └────────────┘                └────┬────┘
                                    │
                  docker create     │      docker run
                  (make only)       │   (create + start)
                                    ▼
                              ┌───────────┐
                              │ CONTAINER │  (running copy)
                              └───────────┘
```

And here is the life of one container:

```
                  docker create
   (image) ─────────────────────────►  ┌─────────┐
      │                                │ CREATED │
      │ docker run                     └────┬────┘
      │ (create + start)                    │ docker start
      │                                     ▼
      └──────────────────────────────►  ┌─────────┐ ◄── docker restart
                                        │ RUNNING │     (stop + start)
                                        └──┬───┬──┘
                          docker stop /    │   │  docker pause
                          docker kill      │   ▼
                                           │ ┌────────┐
                                           │ │ PAUSED │
                                           │ └────────┘
                                           ▼
                                      ┌─────────┐   docker start
                                      │ STOPPED │ ──────────────► RUNNING
                                      └────┬────┘
                                           │ docker rm
                                           ▼
                                      ┌─────────┐
                                      │ REMOVED │  (gone for good)
                                      └─────────┘
```

Keep this second picture in mind. Most commands are just arrows between these boxes.

> On Debian, if you get "permission denied", either put `sudo` in front of commands or add yourself to the `docker` group. On Windows with Docker Desktop, the commands are the same.

---

## Part 1: Working with images

### See the images you have

```bash
docker images
```

or the newer, equivalent form:

```bash
docker image ls
```

Example output:

```
REPOSITORY   TAG      IMAGE ID       CREATED        SIZE
nginx        latest   a1b2c3d4e5f6   2 weeks ago    190MB
postgres     16       f6e5d4c3b2a1   3 weeks ago    430MB
```

|Column|Meaning|
|---|---|
|REPOSITORY|The image name.|
|TAG|The version label. `latest` is the default.|
|IMAGE ID|A unique ID. You can use it instead of the name.|
|SIZE|Disk space used.|

### Download an image

```bash
docker pull nginx
docker pull postgres:16
```

- `docker pull nginx` downloads the `latest` tag.
- `docker pull postgres:16` downloads version 16 specifically.

By default, images come from **Docker Hub**, the public registry.

### Search for an image

```bash
docker search redis
```

This lists images on Docker Hub matching the name. In practice, most people browse hub.docker.com instead, because it shows documentation and tags. Prefer **Official Images** (marked on the site), since they are maintained and checked.

### Look inside an image

```bash
docker inspect nginx          # full details as JSON
docker history nginx          # the layers it is built from
```

### Remove an image

```bash
docker rmi nginx
docker rmi a1b2c3d4e5f6       # by ID also works
```

`rmi` means "remove image". It fails if a container (even a stopped one) still uses that image. Remove the container first.

---

## Part 2: Creating your own image

There are three ways to get an image. Two are common.

|Way|Command|When to use|
|---|---|---|
|Download a ready-made one|`docker pull`|Databases, Nginx, Redis, base images.|
|Build from a Dockerfile|`docker build`|Your own apps. This is the standard way.|
|Save a container as an image|`docker commit`|Quick experiments only. Not repeatable.|

### Build from a Dockerfile

A **Dockerfile** is a plain text file of instructions. Docker reads it top to bottom and produces an image. Here is one for a Spring Boot app:

```dockerfile
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY target/app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Line by line:

|Line|What it does|
|---|---|
|`FROM eclipse-temurin:21-jre`|Start from an existing image that already has Java 21. Every Dockerfile starts with a base.|
|`WORKDIR /app`|Sets the working folder inside the image. Later commands run from `/app`.|
|`COPY target/app.jar app.jar`|Copies your built jar from your machine into the image.|
|`EXPOSE 8080`|Documents that the app listens on 8080. It does not publish the port by itself.|
|`ENTRYPOINT [...]`|The command that runs when a container starts.|

Now build it. Run this in the folder that contains the Dockerfile:

```bash
docker build -t my-spring-app:1.0 .
```

- `-t my-spring-app:1.0` gives the image a name and a tag.
- `.` (the dot) means "use the current folder as the build context", the files Docker is allowed to copy from.

Check that it exists:

```bash
docker images
```

### Give an image another name

```bash
docker tag my-spring-app:1.0 myuser/my-spring-app:1.0
```

This doesn't copy anything. It adds a second label to the same image, which you need before pushing to a registry.

---

## Part 3: Working with containers

### Run a container

```bash
docker run -d --name web -p 8080:80 nginx
```

|Part|Meaning|
|---|---|
|`-d`|Detached: run in the background.|
|`--name web`|Name it `web`.|
|`-p 8080:80`|Host port 8080 goes to container port 80.|
|`nginx`|The image.|

If the image isn't on your machine, `docker run` downloads it first.

### See containers (`ps` and `ps -a`)

```bash
docker ps          # only RUNNING containers
docker ps -a       # ALL containers, including stopped ones
```

This difference trips up a lot of beginners. You stop a container, run `docker ps`, and it seems to have vanished. It hasn't. It's stopped, and only `docker ps -a` shows it.

Handy variations:

```bash
docker ps -q        # only IDs (useful in scripts)
docker ps -a -q     # IDs of all containers
```

### Stop a container

```bash
docker stop web
```

Docker politely asks the app to shut down (SIGTERM) and waits up to 10 seconds. If the app doesn't quit, Docker forces it (SIGKILL).

To force it immediately:

```bash
docker kill web
```

### Start a stopped container

```bash
docker start web
```

### Restart a container

```bash
docker restart web
```

This is `stop` followed by `start` in one command. Use it after changing config the app reads at startup.

### Remove a container

```bash
docker rm web           # must be stopped first
docker rm -f web        # force: stops and removes in one step
```

A stopped container still takes up disk space and keeps its name until you remove it. This is why you sometimes see `container name already in use`.

### Look inside a running container

```bash
docker logs web            # see output
docker logs -f web         # follow it live
docker exec -it web sh     # open a shell inside
```

- `-i` keeps input open, and `-t` gives you a terminal. Together, `-it` lets you type commands inside.
- Use `bash` instead of `sh` if the image has it.

---

## Part 4: `docker run` vs `docker start`

This is one of the most common questions, so here is the clear answer.

||`docker run`|`docker start`|
|---|---|---|
|Works on|An **image**|An **existing, stopped container**|
|Creates a new container?|**Yes**, every time|**No**|
|Downloads image if missing?|Yes|No|
|Lets you set port, name, env vars?|Yes|No (already fixed)|
|Typical use|First launch|Wake up a stopped container|

Think of it like this:

- `docker run` is **buying a new phone and turning it on**.
- `docker start` is **turning on a phone you already own**.

Why this matters: if you run `docker run -p 8080:80 nginx` three times, you get **three separate containers** (and the second one will fail with a port clash). If you `docker start web` three times, you're still using the same one container.

Also, settings like `-p`, `-e`, and `--name` are decided when the container is **created**. You can't change them with `start`. To change a port, remove the container and run a new one.

```bash
docker run -d --name web -p 8080:80 nginx   # creates + starts
docker stop web                              # stops it
docker start web                             # starts the SAME container again
```

---

## Part 5: Cleaning up (clear everything)

Docker collects leftovers over time: stopped containers, old images, unused volumes. Here's how to tidy up, from gentle to aggressive.

|Goal|Command|
|---|---|
|Remove one container|`docker rm name`|
|Remove all **stopped** containers|`docker container prune`|
|Remove **dangling** images (untagged leftovers)|`docker image prune`|
|Remove **all unused** images|`docker image prune -a`|
|Remove unused volumes|`docker volume prune`|
|Remove stopped containers, unused networks, dangling images, and build cache|`docker system prune`|
|Same, but also all unused images|`docker system prune -a`|
|See what's using disk space|`docker system df`|

Remove **everything**, running or not, including containers:

```bash
docker rm -f $(docker ps -aq)
```

Walkthrough: `docker ps -aq` prints the IDs of every container, and `$(...)` feeds those IDs to `docker rm -f`.

Warning: `prune` commands ask for confirmation, but be careful with `-a` and with volumes. **Volumes hold your data**, such as a database's files. Pruning them deletes that data permanently. Run `docker system df` first so you know what you're about to remove.

---

## Cheat sheet

|I want to...|Command|
|---|---|
|List images|`docker images`|
|Download an image|`docker pull name:tag`|
|Build an image|`docker build -t name:tag .`|
|Delete an image|`docker rmi name`|
|Run a new container|`docker run -d --name x -p H:C image`|
|List running containers|`docker ps`|
|List all containers|`docker ps -a`|
|Stop|`docker stop x`|
|Start (existing)|`docker start x`|
|Restart|`docker restart x`|
|Remove container|`docker rm x`|
|Logs|`docker logs -f x`|
|Shell inside|`docker exec -it x sh`|
|Clean up|`docker system prune`|

---

## How to become a good Docker user

Knowing commands is step one. These habits are what separate a good Docker user from a beginner.

**1. Understand the image/container difference deeply.** If you can explain it to someone else, half the confusion disappears.

**2. Always name your containers and tag your images.** Use `--name` and `name:1.0`. Random names and `latest` everywhere make life hard.

**3. Pin versions.** `postgres:16` is safer than `postgres`. `latest` can change and break things without warning.

**4. Treat containers as disposable.** A container should be easy to delete and recreate. Don't store important data inside it. That leads to the next point.

**5. Learn volumes early.** A **volume** is storage that lives outside the container. If you delete a PostgreSQL container without a volume, your data goes with it.

```bash
docker run -d --name db -v pgdata:/var/lib/postgresql/data -e POSTGRES_PASSWORD=secret postgres:16
```

**6. Read the logs first.** When something fails, `docker logs name` solves most problems in seconds.

**7. Learn to write good Dockerfiles.** Know what each instruction does. Keep images small by using slim base images. Put rarely-changing steps at the top, because Docker caches each layer, so builds stay fast.

**8. Use a `.dockerignore` file.** It works like `.gitignore` and keeps junk (like `.git` or `target/`) out of your build context.

**9. Don't run as root, and don't bake secrets into images.** Pass passwords through environment variables or secrets, never through the Dockerfile.

**10. Learn Docker Compose.** Once you run more than one container, Compose is the natural next step.

**11. Clean up regularly.** Run `docker system df` now and then and prune what you don't need.

**12. Practise by containerising something you already know.** For you, a Spring Boot app talking to PostgreSQL is a perfect first project.

---

## Related concepts, in short

- **Registry:** a server that stores images. Docker Hub is the public one. You `pull` from it and `push` to it.
- **Volume:** storage that outlives a container. Needed for databases.
- **Network:** lets containers talk to each other by name. Docker creates a default one, and you can make your own.
- **Docker Compose:** one `compose.yaml` file that describes several containers, started together with `docker compose up -d`.
- **Layers:** an image is a stack of read-only layers. Docker reuses unchanged layers, which makes builds and downloads faster.





[[Docker]]
