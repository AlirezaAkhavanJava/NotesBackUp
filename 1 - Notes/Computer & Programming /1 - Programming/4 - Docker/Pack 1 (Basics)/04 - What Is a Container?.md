

## The short version

A container is **an ordinary process (or group of processes) running on the host's Linux kernel, wrapped in isolation and resource limits, with its own private filesystem built from an image**.

It is not a mini-computer. It is a process that has been told, by the kernel, "you only get to see _this_ slice of the system, and you may only use _this much_ of it."

## The mental model

Think of a normal process on Linux. By default it can:

- see every other process on the machine
- see the whole filesystem
- see all network interfaces
- use as much CPU and RAM as is available

A container takes that same process and applies three kinds of restrictions:

|Restriction|Mechanism|Effect|
|---|---|---|
|What it can **see**|Namespaces|Own process tree, network, hostname, mounts|
|What it can **use**|cgroups|Capped CPU, memory, I/O|
|What **files** it has|Image layers + OverlayFS|Its own root filesystem|

Add security filters on top (capabilities, seccomp, AppArmor/SELinux), and you have a container.

> **Container = process + namespaces + cgroups + layered root filesystem + security filters**

## Image vs. container

A frequent point of confusion, and a good analogy for a Java developer:

|Java world|Docker world|
|---|---|
|Class|**Image** (read-only template)|
|Object (instance)|**Container** (running instance)|

You can create many containers from one image, the way you create many objects from one class. Each container gets its own thin **writable layer** on top of the shared read-only image layers, so changes in one never affect another or the image itself.

## How a container is created, step by step

Say you run:

```bash
docker run -p 8080:8080 --memory=512m myapp
```

### Step 1: Prepare the filesystem

The image's read-only layers are stacked with OverlayFS, and a thin writable layer is added on top. The result is presented as one merged directory.

### Step 2: Create namespaces

The runtime (`runc`) asks the kernel to create a fresh set of namespaces. In practice this is the `clone()` or `unshare()` system call with flags like `CLONE_NEWPID`, `CLONE_NEWNET`, `CLONE_NEWNS`.

### Step 3: Create a cgroup

A cgroup is created with the limits you requested (512 MB of memory here), and the process is placed into it.

### Step 4: Switch the root filesystem

The process's root directory is changed (via `pivot_root`, similar to `chroot`) to the merged image filesystem. From inside, `/` is now the image's root. The host's files are invisible.

### Step 5: Wire up networking

Docker creates a **virtual ethernet pair** (veth): one end inside the container's network namespace, the other attached to a virtual bridge (`docker0`) on the host. Port mapping (`-p 8080:8080`) is implemented with NAT rules (iptables/nftables) that forward host port 8080 to the container.

### Step 6: Drop privileges

Linux capabilities are trimmed (the container can't, for example, load kernel modules), and a seccomp profile blocks dangerous system calls.

### Step 7: Start your process

Finally, `java -jar app.jar` is executed. It becomes **PID 1** inside the container's PID namespace.

No OS boot, no hardware emulation. Just a process launched under restrictions, which is why it takes milliseconds.

## Seeing the illusion yourself

You can prove the "it's just a process" idea on a Linux host:

```bash
docker run -d --name demo nginx
docker top demo          # processes, as the host sees them
ps aux | grep nginx      # the same processes appear in the host's list
```

Inside the container, `ps` shows nginx as PID 1. On the host, the same process has a normal, large PID. Same process, two views, which is exactly what the PID namespace does.

## Container lifecycle

```
 image ──create──► Created ──start──► Running ──stop──► Stopped ──rm──► (gone)
                                        │  ▲
                                     pause│  │unpause
                                        ▼  │
                                       Paused
```

- **Running** lasts as long as PID 1 is alive. If your main process exits, the container stops. This is why a container running `java -jar app.jar` stops when the app crashes or shuts down.
- **Stopped** containers still exist (with their writable layer) until removed.
- **Removing** a container deletes its writable layer. Anything not saved in a **volume** is lost.

## What a container is _not_

- **Not a VM**: no guest kernel, no virtual hardware.
- **Not a persistent machine**: treat containers as disposable; keep state in volumes or external services.
- **Not a strong security boundary by itself**: because the kernel is shared, a kernel-level exploit can cross the boundary. Hardened setups add rootless mode, user namespaces, or sandboxed runtimes like gVisor and Kata Containers.

## Where the standards fit in

Containers are not Docker-only. The **OCI (Open Container Initiative)** defines two specs: the **image format** and the **runtime**. `runc` is the reference runtime. This is why the same image can run under Docker, Podman, containerd, or Kubernetes. Docker popularized the idea, but the container itself is a Linux kernel concept plus an open standard.

## Quick recap

A container is a **regular Linux process** that the kernel isolates using **namespaces** (limited view), restricts using **cgroups** (limited resources), and gives a **private root filesystem** built from layered **image** files. It starts by having a runtime like `runc` set up those restrictions and then launch your command as PID 1. Image is to container what class is to object.




[[Docker]]