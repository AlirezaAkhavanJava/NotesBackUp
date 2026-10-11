

## Definitions first

**Image**: an immutable, read-only bundle made of two things: a stack of filesystem layers (the files) and a JSON config (how to start it). It sits on disk or in a registry. Nothing is executing.

**Container**: an instance created from an image. It is a Linux process (or group of processes) isolated by namespaces, limited by cgroups, and given the image's files as its root filesystem plus one thin writable layer on top.

Rule to memorize: **you build, store, and ship images. You run containers.**

## Mental model: program file vs running process

The most accurate analogy for you is not class/object but **an executable on disk vs the process it spawns**.

- `/usr/bin/java` is a file. Running it ten times gives ten processes, each with its own memory, all backed by the same file.
- An image is that file, except it holds a whole filesystem. Running it ten times gives ten containers, each with its own writable layer and process, all backed by the same read-only layers.

Where it breaks down:

1. An executable is one file. An image is a complete directory tree (OS libraries, JRE, your jar, config) plus metadata.
2. A process dies and leaves nothing behind. A container, even stopped, keeps its writable layer until you `docker rm` it.
3. A class/object comparison also works for "one template, many instances," but it hides that images are _filesystems_, not code.

A second analogy for the naming side: an image is like a **Git commit**. It is immutable and identified by a hash, and a tag like `myapp:1.0` is like a branch or tag name, a movable label pointing at a hash. The break: Git commits are history-linked snapshots, while image layers are stacked file diffs applied in order.

## Mechanics: what physically exists

### The image

Three kinds of objects, each addressed by a SHA-256 hash:

- **Layers**: tar archives of filesystem changes (added, modified, deleted files).
- **Config**: JSON holding `ENTRYPOINT`, `CMD`, `ENV`, `USER`, `WORKDIR`, and the ordered list of layer hashes.
- **Manifest**: JSON listing the config hash and layer hashes. A registry serves this when you pull.

Look at it on your Debian machine:

```bash
docker image inspect myapp:1.0 --format '{{json .RootFS.Layers}}'
```

- `docker image inspect` prints the image's metadata as JSON.
- `--format '{{json .RootFS.Layers}}'` is a Go template that extracts only the layer hash list.
- Each entry is a `sha256:...` identifying one layer. Same content gives the same hash, which is how layers get shared between images.

### The container

When Docker creates a container it adds:

- A **writable layer**: a directory on the host, merged with the image layers by OverlayFS.
- A **container config**: the image reference plus your overrides (ports, env vars, limits).
- On start, the **process** with its namespaces and cgroup.

```
IMAGE (read-only, shared)           CONTAINER A      CONTAINER B
┌──────────────────────┐          ┌───────────┐    ┌───────────┐
│ layer 4: app.jar     │◄─────────│ writable  │    │ writable  │
│ layer 3: JRE         │◄─────────│ layer +   │    │ layer +   │
│ layer 2: libs        │◄─────────│ process   │    │ process   │
│ layer 1: base OS     │◄─────────└───────────┘    └───────────┘
└──────────────────────┘      both mount the SAME layers
```

The mechanism is **copy-on-write**. If container A modifies a file that lives in a lower layer, Docker first copies that file into A's writable layer, then modifies the copy. B and the image never see it.

## Why the split exists

If the thing you ship and the thing that runs were the same object, you would be shipping mutable machines. Splitting them gives you:

- **Reproducibility**: the same immutable image runs on your laptop, in CI, and in production.
- **Cheap instances**: ten containers cost ten thin writable layers, not ten copies of the filesystem.
- **Safe rollback**: a bad release means starting containers from the previous image. Nothing was mutated, so nothing needs undoing.
- **Disposability**: since containers are cheap and replaceable, you replace them instead of patching them.

## Example 1: one image, two containers

```bash
docker build -t myapp:1.0 .
docker run -d --name app1 -p 8080:8080 myapp:1.0
docker run -d --name app2 -p 8081:8080 myapp:1.0
docker images
docker ps -a
```

Line by line:

1. `docker build -t myapp:1.0 .` reads the Dockerfile in the current directory (`.` is the build context) and produces one image tagged `myapp:1.0`. No process exists.
2. `docker run -d --name app1 -p 8080:8080 myapp:1.0` creates and starts container 1. `-d` runs it in the background. `-p 8080:8080` maps host port 8080 to container port 8080.
3. The second `run` creates container 2 from the same image. It uses host port 8081 because two processes can't bind the same host port. Inside, both apps listen on 8080 with no conflict, because each container has its own network namespace.
4. `docker images` shows one `myapp:1.0`.
5. `docker ps -a` shows two containers. The `-a` includes stopped ones.

## Example 2: proving writable layers are separate

```bash
docker exec app1 sh -c "echo hello > /tmp/note.txt"
docker exec app1 cat /tmp/note.txt
docker exec app2 cat /tmp/note.txt
```

1. `docker exec app1 ...` runs a command inside the running container 1. The `echo` writes `note.txt` into container 1's writable layer.
2. Reading it back from container 1 works.
3. Reading from container 2 fails with "No such file or directory". Container 2 has its own writable layer, and the image was never modified.

This requires a shell in the image. Distroless images have none, so this exact test would fail there.

## Example 3: the lifecycle and where data dies

```bash
docker stop app1
docker start app1
docker exec app1 cat /tmp/note.txt
docker rm -f app1
docker run -d --name app1 -p 8080:8080 myapp:1.0
docker exec app1 cat /tmp/note.txt
```

1. `docker stop app1` ends the process, but the container still exists with its writable layer.
2. `docker start app1` restarts the same container.
3. `cat` succeeds. The file survived stop/start.
4. `docker rm -f app1` deletes the container and its writable layer. The file is gone.
5. The new `docker run` creates a fresh container from the image. This is a different container that happens to have the same name.
6. `cat` fails. Only data in a **volume** would have survived. This is the most common source of "where did my data go?"

## Example 4: a rebuilt image does not change running containers

```bash
docker build -t myapp:1.0 .        # after editing code
docker ps
docker images
```

After the rebuild, the tag `myapp:1.0` points to the new image. The old image loses its tag and shows as `<none>` (a dangling image). But `app2`, still running, uses the **old** image's layers, because a container is bound to the specific image ID it was created from, not to the tag. To deploy the change, create a new container:

```bash
docker rm -f app2
docker run -d --name app2 -p 8081:8080 myapp:1.0
```

Or with Compose, `docker compose up -d` detects the changed image and recreates the container for you. The principle: **you replace containers, you don't update them.**

## Example 5: seeing the writable layer on your Debian host

Because you run Linux natively, you can look at the real files:

```bash
docker inspect app1 --format '{{.GraphDriver.Data.UpperDir}}'
sudo ls "$(docker inspect app1 --format '{{.GraphDriver.Data.UpperDir}}')"
```

1. `docker inspect app1` prints the container's config. The format string extracts `UpperDir`, the host path of the container's writable layer. In OverlayFS terms, _upper_ is the writable directory and _lower_ are the read-only image layers.
2. `sudo ls` lists that directory (root is needed because `/var/lib/docker` is root-owned). You will see only what this container changed, such as `tmp/note.txt`, not the whole OS. That is copy-on-write, visible directly.

On Windows or macOS this wouldn't work, because Docker runs inside a hidden VM there.

## What you actually ship

You have two "big packages" in a Spring Boot project, and mixing them up is the source of the confusion.

||Spring Boot fat jar|Docker image|
|---|---|---|
|Contains|Your classes, dependencies, embedded Tomcat|The jar **plus** JRE, OS libraries, config, start command|
|Target machine needs|A compatible JRE|A container runtime only|
|Role|Application artifact|Deployment artifact|

```
source → mvn package → fat jar → docker build → IMAGE → push → registry
                                                  ▲                  │
                                      you ship this                  ▼
                                              pull → docker run → CONTAINER
```

The jar lives inside one layer of the image. The image is what travels between environments.

### How it travels

```bash
docker tag myapp:1.0 ghcr.io/alireza/myapp:1.0
docker push ghcr.io/alireza/myapp:1.0
```

1. `docker tag` adds a second name to the same image. It copies nothing, just adds a label to the same hash.
2. `docker push` uploads the manifest, the config, and **only the layers the registry doesn't already have**. After a small code change, only the top layer (your jar) uploads. The JRE and OS layers are already there.

Pull works the same way in reverse: the server downloads only the layers it lacks. So an image looks large in `docker images`, but the _incremental_ transfer is small. That is why layer order in your Dockerfile matters.

Air-gapped alternative, shipping as a single file:

```bash
docker save myapp:1.0 -o myapp.tar
docker load -i myapp.tar
```

`save` writes the image (all layers, config, tags) to one tar file. `load` restores it on another machine with no registry involved.

## Edge cases that bite

- **Tags are mutable, digests are not.** `myapp:latest` can point somewhere new tomorrow. `myapp@sha256:...` is the image's real identity. Pin digests when reproducibility matters.
- **Deleting an image a container uses** is refused unless forced, because the container's filesystem depends on those layers.
- **`docker rm` and `docker rmi` are separate.** Deleting a container never deletes its image, and vice versa.
- **Deleting a file in a later layer doesn't shrink the image.** Layers are append-only, so the old bytes still exist in the earlier layer. This is why secrets copied into an image stay recoverable even if you `rm` them in a later step.
- **A container exits when PID 1 exits.** The container's lifetime equals the lifetime of your `java` process.

## Alternatives to shipping an image

|Approach|Trade-off|
|---|---|
|Ship the jar to a server with a JRE|Simplest, but environment drift is your problem again|
|Ship a VM image (AMI, VMDK)|Same immutability, but carries a full OS and kernel, so it's heavier and slower to start|
|GraalVM native executable|One binary, no JRE, fast startup, but long builds. Often still placed in a small image|
|Buildpacks / Jib|Still produce an image, just without you writing a Dockerfile|

Container-based routes all produce an **OCI image**, so the same artifact runs under Docker, Podman, or Kubernetes.

## Related parts you haven't asked about yet

- **`ENTRYPOINT` vs `CMD`**: how the image's config decides which process the container starts.
- **Volumes**: how to keep data beyond `docker rm`.
- **Tags, digests, and registries**: naming, versioning, and securing what you ship.



[[Docker]]