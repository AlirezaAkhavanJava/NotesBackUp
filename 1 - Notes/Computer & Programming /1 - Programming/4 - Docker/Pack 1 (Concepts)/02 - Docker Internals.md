


Your question has a small trap in it, and it's a good one: **Docker is not a VM**. Containers are something fundamentally different. Let's place all three things you know on one map.

## Three different "VM" ideas

||JVM|VirtualBox VM|Docker container|
|---|---|---|---|
|What it virtualizes|A **CPU/runtime** (executes bytecode)|**Hardware** (a whole computer)|**Nothing**: it's an isolated _process_|
|Has its own OS kernel?|No|Yes (guest OS)|No (shares host kernel)|
|Language-specific?|Yes (JVM languages)|No|No|
|Startup|Seconds|Minutes|Milliseconds to seconds|

The JVM is a _process virtual machine_ (it emulates an abstract machine for your bytecode). VirtualBox is a _system virtual machine_ (it emulates hardware). Docker does neither.

## The key insight

A container is **just a normal Linux process**, with restrictions placed on it by the kernel so that it _thinks_ it's alone on the machine.

Try this mentally: when you run a Spring Boot app in Docker, then run `ps aux` on the _host_, you will see your `java` process listed right there, like any other process. No hypervisor, no second kernel. The kernel simply lies to that process about what it can see and use.

## The three kernel features behind it

Docker is mostly a friendly wrapper around features built into the Linux kernel.

### 1. Namespaces: control what a process can _see_

Each namespace gives the process its own private view of one kind of resource:

|Namespace|The container sees its own...|
|---|---|
|`pid`|Process tree (your app is PID 1)|
|`net`|Network interfaces, IPs, ports|
|`mnt`|Filesystem mounts|
|`uts`|Hostname|
|`ipc`|Shared memory / message queues|
|`user`|User IDs (root inside ≠ root on host)|

That's why two containers can both listen on port 8080 internally without clashing: each has its own network namespace.

### 2. cgroups (control groups): control what a process can _use_

cgroups limit and measure resources:

```bash
docker run --memory=512m --cpus=1.5 my-spring-app
```

This tells the kernel: "this process group may use at most 512 MB RAM and 1.5 CPU cores." Exceed the memory and the kernel kills it (the dreaded OOMKilled).

> **Java-relevant note:** This matters for you. Old JVMs read the _host's_ total RAM and ignored container limits, causing OOM kills. Modern JVMs (Java 10+, and 8u191+) are _container-aware_ and respect cgroup limits when sizing the heap. You can tune it with `-XX:MaxRAMPercentage=75`.

### 3. Union filesystems (layered storage): efficient images

Images are built from **stacked read-only layers**, using something like OverlayFS:

```
┌──────────────────────────┐
│ Writable container layer │  ← changes at runtime
├──────────────────────────┤
│ Layer 4: COPY app.jar    │  ← read-only
├──────────────────────────┤
│ Layer 3: JRE install     │  ← read-only
├──────────────────────────┤
│ Layer 2: Libraries       │  ← read-only
├──────────────────────────┤
│ Layer 1: Base OS files   │  ← read-only
└──────────────────────────┘
```

Each Dockerfile instruction creates a layer. Layers are cached and shared, so if ten images use the same JRE layer, it's stored once. Rebuilding after changing only your jar re-does just the top layer.

## Docker's architecture

```
┌──────────────┐   REST API   ┌─────────────────┐
│ Docker CLI   │ ───────────► │  Docker Daemon  │
│ (docker run) │              │   (dockerd)     │
└──────────────┘              └────────┬────────┘
                                       │
                              ┌────────▼────────┐
                              │   containerd    │  (manages lifecycle)
                              └────────┬────────┘
                                       │
                              ┌────────▼────────┐
                              │      runc       │  (actually creates
                              └────────┬────────┘   the container)
                                       │
                              ┌────────▼────────┐
                              │  Linux kernel:  │
                              │ namespaces +    │
                              │ cgroups + overlayfs
                              └─────────────────┘
```

- **Docker CLI**: what you type into.
- **dockerd**: the daemon; manages images, networks, volumes.
- **containerd**: manages container lifecycle.
- **runc**: the low-level tool that calls the kernel to set up namespaces and cgroups and starts your process.

## What actually happens on `docker run`

1. The daemon checks for the image locally; pulls it from a registry if missing.
2. It stacks the image layers and adds a thin writable layer.
3. `runc` asks the kernel to create new namespaces and a cgroup.
4. The filesystem is switched to the image's layered root (`chroot`-like).
5. Your command (e.g. `java -jar app.jar`) starts as **PID 1 inside the container**.

No OS boots. That's why it's fast.

## "But I use Docker on Windows/Mac..."

Good catch if you've wondered about this. Containers need a **Linux kernel**. On Windows and macOS, Docker Desktop quietly runs a **lightweight Linux VM** (via WSL2, Hyper-V, or Apple's virtualization framework), and your containers run inside _that_. So on those platforms, there _is_ a VM involved, but it's one shared VM for all containers, not one per container. On a Linux server, there's no VM at all.

## Putting it in your Spring Boot terms

```dockerfile
FROM eclipse-temurin:21-jre      # layer: OS + JRE
COPY target/app.jar /app.jar     # layer: your app
ENTRYPOINT ["java", "-jar", "/app.jar"]
```

Here's the interesting stack: **your Java code runs on the JVM, which runs as a process inside a container, which is a restricted process on the host's Linux kernel**. The JVM and Docker are not competing ideas. They sit at different levels: the JVM virtualizes the _runtime_, Docker isolates the _process environment_.

## Trade-offs worth knowing

- **Weaker isolation than VMs**: containers share the host kernel, so a kernel vulnerability can affect all of them. VMs have a stronger boundary.
- **Linux containers need a Linux kernel**: you can't run a Windows container on a Linux host the same way.
- **Not a full OS**: images are minimal (often no systemd, no SSH).

## Quick recap

Docker is a **containerization tool**, not a VM. It uses Linux **namespaces** (isolation of what a process sees), **cgroups** (limits on what it uses), and **layered filesystems** (efficient images) to make an ordinary process behave as if it has its own machine. That's why a container starts in a blink while a VirtualBox VM boots a whole OS.




[[Docker]]