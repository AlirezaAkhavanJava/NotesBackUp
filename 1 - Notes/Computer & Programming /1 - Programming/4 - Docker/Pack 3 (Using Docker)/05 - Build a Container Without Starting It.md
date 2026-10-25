

`docker create` makes a new container from an image, with all its settings (name, ports, environment variables, volumes) fixed in place, but it does **not** start it. The container is left in a state called **Created**: it exists, it has an ID and a name, but nothing is running inside it yet.

If you already know `docker run`, you've used `create` without realising it. `docker run` is really two steps in one: **create** the container, then **start** it. `docker create` lets you do only the first step. It's a small command, but it helps you understand how Docker works, and it's handy when you want to prepare a container now and launch it later.

---

## The problem it solves

Sometimes you want a container ready but not running yet. A few real situations:

|Situation|Why `create` helps|
|---|---|
|You want to set everything up now and start it at a certain time|Create now, `docker start` later.|
|You need to copy files into a container before the app launches|You can use `docker cp` on a created container, then start it.|
|A script must check the container's settings before running it|`docker inspect` works on a created container.|
|You want to understand what `docker run` does step by step|Doing `create` then `start` shows each step.|

---

## Where it sits in the container life (ASCII picture)

```
                 docker create
   IMAGE  ─────────────────────────►  ┌─────────┐
     │                                │ CREATED │  (exists, not running)
     │                                └────┬────┘
     │                                     │ docker start
     │  docker run                         ▼
     │  (create + start together)     ┌─────────┐
     └──────────────────────────────► │ RUNNING │
                                      └─────────┘
```

So:

```
docker run  =  docker create  +  docker start
```

---

## The basic command

```bash
docker create --name web -p 8080:80 nginx
```

Line by line:

|Part|Meaning|
|---|---|
|`docker create`|Make a container, but don't start it.|
|`--name web`|Name the container `web`.|
|`-p 8080:80`|Map your port 8080 to port 80 inside the container. The mapping is saved now and takes effect when the container starts.|
|`nginx`|The image to build it from.|

Docker prints the new container's long ID and returns immediately. Nothing is running.

### See it

```bash
docker ps          # does NOT show it (only running containers)
docker ps -a       # shows it
```

Example output of `docker ps -a`:

```
CONTAINER ID   IMAGE   COMMAND                  STATUS    PORTS   NAMES
a1b2c3d4e5f6   nginx   "/docker-entrypoint.…"   Created           web
```

Look at the `STATUS` column. It says **Created**, which is exactly the state we're talking about. The `PORTS` column is empty because the port only becomes active once the container starts.

### Start it

```bash
docker start web
```

Now `docker ps` shows it as `Up`, and `http://localhost:8080` works.

---

## What if the image isn't downloaded yet?

`docker create` pulls the image automatically if it's missing, just like `docker run`. So the image download happens at create time, not at start time. That makes `create` a nice way to pre-download and prepare things in advance.

You can control this with `--pull`:

|Option|Behaviour|
|---|---|
|`--pull missing`|Default. Pull only if the image isn't local.|
|`--pull always`|Check the registry every time.|
|`--pull never`|Never pull. Fail if the image isn't local.|

---

## Most options are the same as `docker run`

`docker create` accepts nearly all the same options as `docker run`, because both are describing the same container. Here is a fuller example with PostgreSQL:

```bash
docker create \
  --name my-postgres \
  -e POSTGRES_PASSWORD=secret \
  -p 5433:5432 \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16
```

Line by line:

|Line|What it does|
|---|---|
|`--name my-postgres`|Names the container.|
|`-e POSTGRES_PASSWORD=secret`|Sets an environment variable inside it. The Postgres image needs a password.|
|`-p 5433:5432`|Your port 5433 goes to Postgres's 5432.|
|`-v pgdata:/var/lib/postgresql/data`|Attaches a **volume** called `pgdata` so your data survives if the container is removed.|
|`postgres:16`|The image and version.|

Then, whenever you're ready:

```bash
docker start my-postgres
```

### Options you'll commonly combine

|Option|Purpose|
|---|---|
|`--name`|Container name.|
|`-p HOST:CONTAINER`|Port mapping.|
|`-e KEY=VALUE`|Environment variable.|
|`-v VOLUME:/path`|Volume or folder mount.|
|`--restart unless-stopped`|Auto-restart policy.|
|`--network mynet`|Join a specific network.|
|`-it`|Keep input open and allocate a terminal (for interactive containers).|

Note: you don't need `-d` with `create`. The `-d` (detached) flag controls how a container **runs**, and `create` doesn't run anything.

---

## Useful things you can do while it's in the Created state

**1. Copy files into it before it starts**

```bash
docker cp ./app.conf web:/etc/nginx/conf.d/app.conf
docker start web
```

`docker cp` copies a file from your machine into the container. Doing this before the first start means the app sees your config from its very first second.

**2. Inspect its settings**

```bash
docker inspect web
```

This prints JSON with every setting: ports, env vars, mounts, the image, and so on. You can confirm everything is correct before starting.

**3. Start it and watch the output live**

```bash
docker start -a web
```

`-a` means "attach". It starts the container and connects your terminal to its output, so you see the logs right away. Press `Ctrl+C` to detach (and stop, in this mode).

**4. Start interactively**

```bash
docker create -it --name box debian:trixie
docker start -ai box
```

- `-it` on create sets the container up to accept a terminal.
- `-ai` on start means "attach" and "interactive". You land in a Debian shell. Type `exit` to leave.

---

## `create` vs `run` vs `start`

||`docker create`|`docker run`|`docker start`|
|---|---|---|---|
|Needs|An image|An image|An existing container|
|Makes a new container?|Yes|Yes|No|
|Starts it?|**No**|Yes|Yes|
|Typical use|Prepare now, launch later|First launch in one step|Wake up an existing container|

Quick memory trick:

- `create` = build the house.
- `start` = move in and turn the lights on.
- `run` = both, in one go.

---

## Common mistakes

|Symptom|Cause|Fix|
|---|---|---|
|`docker ps` shows nothing after `create`|`ps` only lists running containers.|Use `docker ps -a`.|
|Container starts but the port doesn't work|Port mapping was forgotten at create time.|Settings can't be changed with `start`. Remove it and create again with `-p`.|
|`container name already in use`|A container with that name already exists.|`docker rm name`, or pick another name.|
|Running `create` several times|Each call makes a **new** container.|Check with `docker ps -a` and remove extras.|
|Changing settings after create|Not possible for most options.|`docker rm` it and recreate. (A few, like restart policy, can be changed with `docker update`.)|

Remove a created-but-never-started container like any other:

```bash
docker rm web
```

---

## Related concepts, in short

- **`docker container create`:** the newer, longer name for the same command. `docker create` is a shortcut for it.
- **`docker start`:** takes an existing container (created or stopped) and starts it. It can't change settings.
- **`docker update`:** changes a few settings on an existing container, such as `--restart` or memory limits, without recreating it.
- **`docker cp`:** copies files between your machine and a container. It works on running, stopped, and created containers.

---

## Quick recap

1. `docker create` builds a container from an image but **doesn't start it**. Its status is `Created`.
2. `docker run` is simply `create` followed by `start`.
3. It takes the same options as `docker run` (name, ports, env vars, volumes), minus `-d`.
4. You need `docker ps -a` to see it, and `docker start name` to launch it.
5. Settings like ports are decided at creation. To change them, remove the container and create it again.




[[Docker]]