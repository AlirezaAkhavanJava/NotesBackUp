

Docker has a lot of surface area, but day to day you'll use about a dozen commands. First, two words that everything else depends on.

## Image vs. container

An **image** is a packaged, read-only blueprint: an operating system layer, some software, and its configuration. A **container** is a running instance of that image.

Since you're learning Java, think of an image as a class and a container as an object. You can create many containers from one image, and each has its own state. The analogy breaks down in one important way: when you delete a container, anything it wrote inside itself is gone, unlike an object whose data you might serialize. We'll deal with that in the volumes section below.

## Installing Docker on Debian 13

The quickest route is Debian's own package:

```bash
sudo apt update
sudo apt install docker.io
```

By default only root can talk to Docker, so add yourself to the `docker` group and then log out and back in:

```bash
sudo usermod -aG docker $USER
```

Check that it works:

```bash
docker run hello-world
```

If you see a welcome message, Docker pulled an image, created a container, ran it, and printed the message. (Docker also publishes its own apt repository with newer versions, which you can switch to later if you need it. `docker.io` is fine for learning.)

## Getting an image

```bash
docker pull postgres:17
```

This downloads the image from Docker Hub. The part after the colon is the **tag**, usually a version. If you leave it off, you get `latest`, which can change under you, so pinning a version is a good habit. You don't strictly need `pull`, because `docker run` pulls automatically if the image isn't local.

To see what you've downloaded:

```bash
docker images
```

## Running a container

This is the command you'll type most, and it's worth understanding piece by piece. You already know PostgreSQL, so let's run one:

```bash
docker run -d --name my-postgres -e POSTGRES_PASSWORD=secret -p 5432:5432 postgres:17
```

- `-d` means "detached": run in the background instead of taking over your terminal.
- `--name my-postgres` gives the container a name you choose. Without it, Docker invents one like `quirky_turing`.
- `-e POSTGRES_PASSWORD=secret` sets an environment variable inside the container. This image requires it.
- `-p 5432:5432` maps a port as `host:container`. It means "traffic hitting port 5432 on my machine goes to port 5432 inside the container." Without it, the database runs but you can't reach it. If 5432 is already used on your machine, you could write `-p 5433:5432` and connect to 5433.
- `postgres:17` is the image to use, and it always comes last.

Your Spring Boot app could now connect to `localhost:5432` as if Postgres were installed on your machine.

## Looking at what's running

```bash
docker ps
```

This lists running containers. Add `-a` to include stopped ones:

```bash
docker ps -a
```

That second form matters more than it looks. A stopped container still exists, and it still holds its name. If you try to `docker run --name my-postgres` again, Docker will complain that the name is taken, because the old one is sitting there stopped.

To read a container's output, which is where you'll look when something fails to start:

```bash
docker logs my-postgres
docker logs -f my-postgres
```

The `-f` flag follows the log live, like `tail -f`.

## Stopping, starting, restarting

```bash
docker stop my-postgres
docker start my-postgres
docker restart my-postgres
```

Notice you use `start` here, not `run`. `run` creates a brand new container from an image. `start` wakes up an existing stopped one. Mixing those two up is the most common beginner confusion.

## Getting inside a running container

```bash
docker exec -it my-postgres psql -U postgres
```

`exec` runs a command inside a running container. The `-it` flags make it interactive so you can type, and here the command is `psql`, so you land in a Postgres prompt. To get a shell instead, use `bash` (or `sh` on minimal images):

```bash
docker exec -it my-postgres bash
```

## Removing things

```bash
docker rm my-postgres        # remove a stopped container
docker rm -f my-postgres     # force-remove, even if it's running
docker rmi postgres:17       # remove an image
```

Removing a container and removing an image are separate steps. You can't remove an image while a container (even a stopped one) still uses it, so remove the container first.

To clean up in bulk:

```bash
docker container prune    # removes all stopped containers
docker image prune        # removes unused dangling images
```

Both ask for confirmation, but read what they're about to delete before you say yes.

## The catch: data disappears with the container

Remember how I said a container's internal data vanishes when you remove it? For a database, that would be a disaster. The fix is a **volume**, which is storage managed by Docker that lives outside the container:

```bash
docker run -d --name my-postgres \
  -e POSTGRES_PASSWORD=secret \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  postgres:17
```

`-v pgdata:/var/lib/postgresql/data` means "mount a volume called `pgdata` at the path where Postgres stores its files." Now you can remove and recreate the container, and your data survives, because the volume is separate. Related commands:

```bash
docker volume ls
docker volume rm pgdata
```

## A cheat sheet to keep nearby

|Goal|Command|
|---|---|
|Download an image|`docker pull image:tag`|
|Create and start a container|`docker run -d --name x -p h:c image`|
|List running / all containers|`docker ps` / `docker ps -a`|
|Stop / start / restart|`docker stop x` / `docker start x` / `docker restart x`|
|View logs|`docker logs -f x`|
|Run a command inside|`docker exec -it x bash`|
|Remove a container / image|`docker rm x` / `docker rmi image`|




[[Docker]]