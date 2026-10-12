

## 1. What Docker Engine Is

**Docker Engine** is the core software that builds and runs containers on a machine. When people say "Docker" on Linux, this is usually what they mean.

It's a **client-server application** made of three parts:

|Part|What it is|Role|
|---|---|---|
|**Docker CLI** (`docker`)|The command you type|A client that sends requests|
|**REST API**|An HTTP API|The language the client and daemon speak|
|**Docker daemon** (`dockerd`)|A long-running background service|Does the real work: images, containers, networks, volumes|

The nearest technical analogy is a database: `psql` is the client, and the PostgreSQL server does the work. When you type `docker run`, the CLI doesn't create a container itself. It sends a request to the daemon. Where the analogy breaks down: the daemon doesn't do _everything_ itself either. It hands the lower-level work to other components, which we'll meet in section 3.

## 2. How the Client Talks to the Daemon

By default the CLI and daemon talk through a **Unix socket**, a special file at `/var/run/docker.sock`. You can prove the CLI is just an API client by skipping it entirely:

```bash
curl --unix-socket /var/run/docker.sock http://localhost/version
```

That returns JSON from the daemon, the same data `docker version` formats nicely for you. The daemon can also listen over TCP, so a CLI on one machine can control an engine on another, but that needs TLS and careful setup.

> **Security note:** Access to that socket is effectively **root access to the host**, because whoever can talk to the daemon can start a container that mounts your whole filesystem. On Linux, adding a user to the `docker` group grants exactly that. It's convenient on your own dev machine, but never hand it out casually, and never mount the socket into containers you don't trust.

## 3. The Component Stack

Modern Docker Engine is a layered system, and each layer has a narrow job:

```
docker CLI
    │  (REST API over the socket)
    ▼
dockerd            ← API, builds, networks, volumes, image management
    │
    ▼
containerd         ← container lifecycle, image pulls and storage, snapshots
    │
    ▼
containerd-shim    ← one small process per container; stays alive with it
    │
    ▼
runc               ← creates the container, then exits
    │
    ▼
your process       ← a normal Linux process inside namespaces and cgroups
```

Here is what each layer does:

- **`dockerd`**: the front desk. It handles the API, builds images, sets up networking and volumes, and decides _what_ should happen.
- **`containerd`**: the container manager. It pulls and stores images, prepares each container's filesystem, and starts and stops containers. It's a separate project that other systems, like Kubernetes, use directly.
- **`containerd-shim`**: a tiny per-container babysitter. It keeps the container's input and output streams attached and reports its exit status. Because the shim is separate from the daemons, **containers can keep running while `dockerd` restarts** (with the `live-restore` setting enabled for dockerd).
- **`runc`**: the part that talks to the kernel. It reads a container description, creates the namespaces and cgroups, applies security settings, starts your process, and then **exits**. After that, nothing special is "running your container". It's just a process.

**Why split it up?** Each piece has one job, and standards connect them. `runc` follows the **OCI** (Open Container Initiative) runtime spec, so it can be replaced by another OCI runtime. The analogy to layered software is fine, with one caveat: the layers aren't just code organization. They're separate processes, which is why a crash or restart in one doesn't have to take down the others.

## 4. What Happens on `docker run`

Let's trace `docker run -d -p 8080:80 nginx` from start to finish:

1. The **CLI** sends a "create and start container" request to `dockerd`.
2. `dockerd` checks whether the `nginx` image exists locally. If not, it **pulls** it from a registry (Docker Hub by default), layer by layer, skipping layers it already has.
3. `dockerd` sets up the **network**: a virtual interface for the container, an IP address, and the port-forwarding rule for `8080 → 80`.
4. `containerd` assembles the container's **filesystem**: the image's read-only layers plus a fresh writable layer on top.
5. `containerd` starts a **shim**, which calls **`runc`**.
6. `runc` creates the **namespaces** and **cgroups**, applies security restrictions, and launches the nginx process.
7. `runc` exits. The shim and the nginx process keep running.

You can see the result from the host:

```bash
docker run -d --name web -p 8080:80 nginx
ps -ef --forest | grep -E 'dockerd|containerd|nginx'
```

You'll see the daemon, the shim, and the nginx process sitting in your normal process tree.

## 5. The Subsystems Inside the Engine

### Images and storage

- Images are stored as stacked **layers**, each identified by a content hash.
- A **storage driver** assembles them into a filesystem. The default on modern Linux is **`overlay2`**, which uses OverlayFS.
- Everything lives under the **data root**, `/var/lib/docker` by default: images, container layers, volumes, and more.
- Newer engine versions can use containerd's own image store instead. The idea is the same.

### Building

- **BuildKit** is the modern build engine. It runs build steps in parallel, caches layers smartly, and supports features like cache mounts and build secrets.
- `docker build` and `docker buildx build` use it.

### Networking

The engine includes several network **drivers**:

|Driver|What it does|Typical use|
|---|---|---|
|`bridge`|Private virtual network on the host (default)|Most single-host setups, Compose|
|`host`|Container shares the host's network stack|When you need raw performance or no port mapping|
|`none`|No networking|Fully isolated jobs|
|`overlay`|Spans multiple hosts|Multi-host clusters (Swarm)|
|`macvlan`|Container gets its own MAC address on your LAN|Making containers look like physical devices|

On user-defined bridge networks, the engine runs an **embedded DNS server**, which is how containers find each other by name.

### Volumes

- **Named volumes** are created and managed by the engine, stored under the data root.
- **Bind mounts** map a host path directly into the container.
- **tmpfs mounts** live only in memory.

### Logging

Each container's stdout and stderr are captured by a **logging driver**. The default writes JSON files on disk, which is what `docker logs` reads. Others can ship logs to syslog, journald, or external systems.

## 6. Engine vs. Docker Desktop vs. Compose

These names get mixed up, so here's how they differ:

- **Docker Engine**: the daemon and CLI described here. It runs natively on Linux. This is what you'd install on Debian.
- **Docker Desktop**: an app for macOS, Windows, and Linux that bundles the engine with a GUI and other tools. On macOS and Windows it runs the engine inside a lightweight Linux VM, because containers need a Linux kernel.
- **Docker Compose**: a plugin that reads a YAML file and tells the engine to create several containers, networks, and volumes together. It's a _client_ of the engine, not part of it.

## 7. Installing and Inspecting on Debian

For installation, follow the **official Docker Engine instructions for Debian** at `docs.docker.com`. The steps involve adding Docker's apt repository, and they can change between releases, so it's best to use the current page rather than copying commands from memory. The packages you'll end up with are roughly these: `docker-ce` (the engine), `docker-ce-cli`, `containerd.io`, and the `docker-buildx-plugin` and `docker-compose-plugin`.

Once it's running, these commands let you look under the hood:

```bash
sudo systemctl status docker      # the daemon is a normal systemd service
docker version                    # shows both Client and Server (daemon) sections
docker info                       # storage driver, data root, cgroup version, runtimes
docker system df                  # disk used by images, containers, volumes
sudo ls /var/lib/docker           # the data root
docker events                     # live stream of what the daemon is doing
```

Try running `docker events` in one terminal while you start and stop a container in another. Watching the daemon announce each step makes the flow in section 4 feel real.

## 8. Quick Recap

- Docker Engine is a **client-server system**: the CLI talks to `dockerd` over a REST API.
- `dockerd` delegates to **containerd**, which uses a **shim** and **runc** to create containers.
- `runc` sets up **namespaces and cgroups**, then exits. A container is just a process.
- The engine also manages **images (overlay2), builds (BuildKit), networks, volumes, and logs**.
- Access to the Docker socket is **root-equivalent**, so treat it carefully.




[[Docker]]