

## The short version

An image is a **read-only, layered package** containing everything needed to start a container: a filesystem snapshot (OS files, runtime, libraries, your app) plus metadata describing how to run it (default command, environment variables, exposed ports, user).

It is a **template**. It doesn't run. When you start it, you get a container.

> Java analogy: image = class, container = object. Another good one: an image is like your **executable jar**, but it bundles the JRE and OS-level files too, not just your code.

## What's inside an image

An image is really two things:

1. **A stack of filesystem layers**: each layer is a compressed tarball (`.tar.gz`) of files that were added, changed, or deleted.
2. **A config (JSON)**: metadata such as `ENTRYPOINT`, `CMD`, `ENV`, `EXPOSE`, `USER`, `WORKDIR`, plus the list of layers and the build history.

Plus a **manifest**, a small JSON file that lists the config and layers by their hashes. The manifest is what a registry serves when you pull.

You can inspect all of it:

```bash
docker image inspect myapp
docker history myapp
```

## Layers: the core idea

Every instruction in a Dockerfile that changes the filesystem creates a new layer.

```dockerfile
FROM eclipse-temurin:21-jre     # layers from the base image
COPY target/app.jar app.jar     # new layer: just app.jar
ENTRYPOINT ["java","-jar","app.jar"]   # metadata only, no files
```

```
┌──────────────────────────┐
│ Layer: app.jar           │  ← yours (small, changes often)
├──────────────────────────┤
│ Layer: JRE               │  ← from base image
├──────────────────────────┤
│ Layer: OS libraries      │  ← from base image
├──────────────────────────┤
│ Layer: base OS files     │  ← from base image
└──────────────────────────┘
        all read-only
```

Key properties:

- **Read-only**: layers never change once built.
- **Content-addressed**: each layer is identified by a SHA-256 hash of its contents. Same content means same hash.
- **Shared**: if ten images use the same base layers, they're stored and downloaded once.
- **Cached**: if a Dockerfile step and everything before it is unchanged, Docker reuses the cached layer instead of rebuilding.

### Why layer order matters

Changing a layer invalidates every layer **above** it. So put things that change rarely at the bottom and things that change often at the top. This is exactly why Spring Boot's layered jars separate dependencies (rarely change) from your code (changes constantly).

```dockerfile
# Good: dependency list copied first, code later
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package
```

Edit a source file and only the last two steps rerun; the dependency download stays cached.

## How an image becomes a container

When you run an image, Docker:

1. Stacks the read-only layers using OverlayFS.
2. Adds a thin **writable layer** on top (copy-on-write).
3. Applies the config (entrypoint, env vars, etc.) and starts the process.

```
┌───────────────────────┐
│ Writable layer        │  ← unique per container, deleted with it
├───────────────────────┤
│ Image layers (RO)     │  ← shared by all containers of this image
└───────────────────────┘
```

**Copy-on-write**: if a container modifies a file from a lower layer, that file is first copied up to the writable layer and changed there. The image itself is never altered.

## Image names and tags

An image reference looks like this:

```
registry/namespace/name:tag
docker.io/library/postgres:16
ghcr.io/mycompany/myapp:1.4.2
```

- **Registry**: where it lives (Docker Hub by default).
- **Name**: the repository.
- **Tag**: a human-friendly label, usually a version. Defaults to `latest`.

Tags are **mutable pointers**: `myapp:latest` can point to a different image tomorrow. For reproducibility, you can reference an immutable **digest**:

```
myapp@sha256:3f2a...
```

Tip: avoid relying on `latest` in production. Pin a version tag or a digest.

## Where images come from

- **Build** from a Dockerfile: `docker build -t myapp .`
- **Pull** from a registry: `docker pull postgres:16`
- **Load** from a file: `docker load -i myapp.tar`

And you can publish yours:

```bash
docker tag myapp ghcr.io/me/myapp:1.0
docker push ghcr.io/me/myapp:1.0
```

## Base images and size

Every image starts `FROM` another one (or `FROM scratch`, which is empty). Choice of base affects size and security:

|Base|Typical size|Notes|
|---|---|---|
|`ubuntu` / `debian`|Large|Familiar, full tooling|
|`*-slim`|Medium|Trimmed Debian|
|`alpine`|Small|Uses musl libc; occasionally causes compatibility issues|
|`distroless`|Small|No shell or package manager; smaller attack surface|
|`scratch`|Minimal|Empty; used for static binaries (e.g. native images)|

For Spring Boot, `eclipse-temurin:21-jre` (JRE only, not JDK) is a solid default, and multi-stage builds keep build tools out of the final image.

## Useful commands

```bash
docker images                 # list local images
docker pull <image>           # download
docker build -t name:tag .    # build
docker history <image>        # see layers and sizes
docker image inspect <image>  # full metadata
docker rmi <image>            # delete
docker image prune            # remove unused images
```

## Image vs. container, side by side

||Image|Container|
|---|---|---|
|State|Static, read-only|Running or stopped, has a writable layer|
|Created by|`docker build` / `docker pull`|`docker run` / `docker create`|
|Analogy|Class / jar file|Object / running JVM process|
|Count|One|Many from the same image|

## Quick recap

An image is an **immutable, layered, content-addressed template** made of filesystem layers plus a JSON config. Layers are shared and cached, which makes builds and distribution efficient. Running an image adds a writable layer and starts a process, giving you a container.




[[Docker]]