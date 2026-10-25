

A container is **not** a small computer. It doesn't have its own CPU, its own memory, or its own operating system. A running container is a normal process on your machine, wrapped in a few Linux features that make it _feel_ isolated. Docker doesn't reserve hardware for it ahead of time. The container uses CPU and RAM only while its process is actually running, and only as much as that process needs.

A container that has only been **created** has no process yet, so it uses almost nothing. It's just some files and settings on disk. The hardware starts to matter when you **start** it, and it stops mattering again when you **stop** it. Let's see exactly what happens at each stage.


A stopped Docker container does not actively consume CPU or application RAM, because its processes are not running. However, it still occupies storage space on your SSD or HDD because Docker keeps its writable filesystem layer, metadata, and any associated logs.

Here's the difference:

|Resource|Stopped container|Running container|
|---|---|---|
|CPU|No active usage|Uses CPU when processing|
|RAM|No application RAM usage|Uses RAM|
|SSD/HDD space|Yes|Yes|
|Disk I/O|No active container I/O|May read/write|
|Network|No active connections|Can use networking|
|Processes|None running inside|One or more running|

### Important: Docker images vs. containers

- Docker image: A stored template consisting of filesystem layers. It occupies disk space but doesn't execute anything.
    
- Stopped container: An instance of an image with its own writable layer and configuration, preserved on disk.
    
- Running container: A container whose processes are executing and consuming resources as needed.
    

### Check it yourself on Debian

```sh
# Show running containers
docker ps

# Show all containers, including stopped ones
docker ps -a

# Show Docker disk usage
docker system df

# Show resource consumption of running containers
docker stats

# Show live resource usage once, without continuous updates
docker stats --no-stream
```

One additional detail: Docker Engine itself may consume some CPU and RAM even when no containers are running, because the Docker daemon (`dockerd`) and related services can remain active.

The mental model: A stopped Docker container is similar to an installed application that isn't running: it occupies storage, but its application processes aren't consuming CPU or RAM.


---

## The problem it solves (and the common mix-up)

Many people picture a container as a mini virtual machine that grabs a slice of RAM and CPU the moment it exists. That picture leads to wrong worries, like "will 20 created containers slow my laptop?" or "is my port blocked even though nothing is running?"

The real picture is simpler and lighter.

||Virtual machine|Docker container|
|---|---|---|
|Has its own OS kernel?|Yes|**No**, shares your host's kernel|
|Reserves RAM when created?|Usually yes (fixed amount)|**No**|
|Startup time|Tens of seconds|Usually under a second|
|Overhead|Heavy|Very light|

---

## The parts of Docker (ASCII picture)

When you type a command, several programs cooperate. You rarely see them, but knowing the chain helps.

```
  YOU
   │  docker run / create / start ...
   ▼
┌──────────────┐
│ docker CLI   │   the command you type
└──────┬───────┘
       │ talks to
       ▼
┌──────────────┐
│ dockerd      │   the Docker daemon (background service):
│ (daemon)     │   images, networks, volumes, container records
└──────┬───────┘
       ▼
┌──────────────┐
│ containerd   │   manages container lifecycle
└──────┬───────┘
       ▼
┌──────────────┐
│ runc         │   actually creates the isolated process
└──────┬───────┘
       ▼
┌──────────────────────────────────────────┐
│ LINUX KERNEL features:                   │
│  • namespaces  → isolation (own view)    │
│  • cgroups     → limits CPU/RAM/etc.     │
│  • overlay fs  → layered file system     │
└──────────────────────────────────────────┘
       ▼
   YOUR HARDWARE (CPU, RAM, disk, network card)
```

The three kernel features do the real work:

|Feature|What it does|Simple way to think of it|
|---|---|---|
|**Namespaces**|Give the process its own private view of processes, network, files, hostnames.|Blinkers: the app only sees its own little world.|
|**cgroups** (control groups)|Measure and limit how much CPU, RAM, and disk I/O a process may use.|A meter and a cap on the process.|
|**Overlay filesystem**|Stacks the image's read-only layers and adds a thin writable layer on top.|Transparent sheets stacked on each other.|

---

## Stage 1: Created (not started)

Run this:

```bash
docker create --name web -p 8080:80 nginx
```

Here is what exists and what doesn't.

|Resource|Used by a created container?|Detail|
|---|---|---|
|**CPU**|**No**|There is no process, so nothing to run.|
|**RAM**|**Practically none**|Only a tiny record kept by the Docker daemon.|
|**Disk**|**A little**|A new, nearly empty writable layer plus small config files, stored under `/var/lib/docker`. The image layers are **shared**, not copied.|
|**Network / IP address**|**No**|No network interface is attached yet, so it has no IP.|
|**Host port (8080)**|**No, not held**|The mapping is only a saved setting. Nothing listens on 8080.|
|**Name (`web`)**|**Yes, reserved**|No other container can use the name until you remove this one.|
|**Named volumes**|**Created if missing**|The volume exists on disk, but nothing is attached and running.|

So to your question: **a created container does not keep the port.** It remembers that you _want_ 8080 mapped to 80, but it doesn't claim it.

### Proof you can try yourself

```bash
docker create --name web1 -p 8080:80 nginx
docker create --name web2 -p 8080:80 nginx
```

Both commands succeed, even though they ask for the same port. Docker only checks the port when you start:

```bash
docker start web1      # works
docker start web2      # fails: port is already allocated
```

You can also see that nothing listens before starting:

```bash
ss -tlnp | grep 8080
```

Before `docker start web1`, this prints nothing. After it, you see a listener on 8080. (`ss` is a standard tool on Debian that lists open ports.)

---

## Stage 2: Running (after `docker start`)

```bash
docker start web
```

This is when things become real. Step by step:

```
 docker start web
      │
      ▼
 1. Docker creates namespaces + cgroup for the container
 2. Docker mounts the layered filesystem (image + writable layer)
 3. Docker creates a virtual network cable (veth) and gives an IP
 4. Docker sets up the port forwarding (8080 → container:80)
 5. runc launches the container's main process (PID 1)
      │
      ▼
 The app is now a normal process on your host
```

|Resource|Used by a running container?|Detail|
|---|---|---|
|**CPU**|**Only as the app uses it**|An idle Nginx uses close to 0%. A busy Java app can use a lot.|
|**RAM**|**Whatever the app actually uses**|No fixed reservation. Memory grows and shrinks with the process.|
|**Disk**|**Grows with writes**|Everything the app writes (logs, temp files) lands in the writable layer.|
|**Network**|**Yes**|It gets an IP on Docker's virtual network (often `172.17.x.x`).|
|**Host port (8080)**|**Yes, now held**|Docker sets up forwarding rules, and a small helper (`docker-proxy`) can also listen on the port. Another program can't use 8080 now.|

You can prove the "just a normal process" idea:

```bash
docker top web
```

This shows the container's processes as seen from the host. On your Debian machine, you can even find the same process with `ps aux | grep nginx`. It's a regular process, only isolated.

---

## Stage 3: Stopped

```bash
docker stop web
```

|Resource|After stopping|
|---|---|
|**CPU and RAM**|**Fully freed.** The process is gone.|
|**Host port**|**Freed.** Another program or container can use 8080 now.|
|**IP address**|Released.|
|**Disk (writable layer)**|**Kept.** Files the app wrote are still there.|
|**Name**|**Still reserved.**|

That's why stopped containers cost you **only disk space**. A pile of old stopped containers won't slow your CPU or RAM, but they do fill your disk, which is why we clean up with `docker container prune`.

---

## The whole life in one table

||Created|Running|Stopped|Removed|
|---|---|---|---|---|
|CPU|none|as used|none|none|
|RAM|none|as used|none|none|
|Disk|tiny|grows|kept|**freed**|
|IP address|none|yes|none|none|
|Host port held|**no**|**yes**|no|no|
|Name reserved|yes|yes|yes|no|

---

## "Stress": limiting what a container can use

By default, a running container may use **as much CPU and RAM as the host allows**. One greedy container can slow everything else. You can cap it with limits, which use the cgroups feature mentioned earlier.

```bash
docker run -d --name web \
  --memory 512m \
  --cpus 1.5 \
  -p 8080:80 nginx
```

|Option|Meaning|
|---|---|
|`--memory 512m`|The container may use at most 512 MB of RAM.|
|`--cpus 1.5`|It may use at most the equivalent of 1.5 CPU cores.|

What happens when a limit is hit:

|Limit|Behaviour when exceeded|
|---|---|
|**CPU**|The process is **slowed down** (throttled). It isn't killed.|
|**Memory**|The kernel's **OOM killer** may kill the process, and the container stops. Check with `docker inspect web` and look for `"OOMKilled": true`.|

Java users, take note: modern JVMs read the container's memory limit and size their heap accordingly, but it's still wise to set limits and test.

Limits work with `docker create` too. The limits are saved and applied when you start it.

### Watch live usage

```bash
docker stats
```

Example output:

```
NAME   CPU %   MEM USAGE / LIMIT   MEM %   NET I/O         BLOCK I/O
web    0.02%   8.5MiB / 512MiB     1.66%   1.2kB / 0B      0B / 0B
```

|Column|Meaning|
|---|---|
|CPU %|Share of CPU the container is using right now.|
|MEM USAGE / LIMIT|Memory used vs the cap. Without `--memory`, the limit shown is your whole machine's RAM.|
|NET I/O|Data sent/received over the network.|
|BLOCK I/O|Data read/written to disk.|

`docker stats` shows **running** containers only, which fits the lesson: a created or stopped container has nothing to measure.

### See disk usage

```bash
docker system df
```

This shows how much space images, containers, volumes, and build cache take. Use it before cleaning up.

---

## A note about Windows vs Debian

You use both, and they behave a little differently.

||Debian (native Linux)|Windows (Docker Desktop)|
|---|---|---|
|Where containers run|Directly on your Linux kernel|Inside a **hidden Linux VM** (usually WSL 2)|
|Extra overhead|None|The VM itself uses some RAM, even with no containers|
|Memory limit|Whole machine|May be capped by the VM or `.wslconfig`|

So on Windows, there is a baseline cost from the VM. That cost exists because Docker needs a Linux kernel, and Windows doesn't have one. Individual containers inside it still follow all the rules above.

---

## Common misconceptions

|Belief|Reality|
|---|---|
|"A created container reserves my port."|No. Only a **running** container holds the port.|
|"A created container uses RAM and CPU."|No. It's just files and settings.|
|"A stopped container still uses memory."|No. Only disk space.|
|"Each container copies the whole image."|No. Containers **share** the image layers and only add a thin writable layer.|
|"Containers get a fixed slice of RAM."|No, not unless you set `--memory`.|
|"Deleting a container frees the image."|No. Images are separate. Use `docker rmi`.|

---

## Related concepts, in short

- **Image layers and copy-on-write:** many containers can share one image. When a container changes a file, only that change is copied into its writable layer.
- **OOM killer:** a Linux kernel feature that kills a process when memory runs out. It's what stops a container that exceeds `--memory`.
- **Restart policy:** `--restart unless-stopped` tells Docker to start the container again after a crash or reboot. The container then uses resources again automatically.
- **Healthcheck:** a command Docker runs regularly to check whether the app inside is actually working, not only running.

---

## Quick recap

1. A container is a **normal process with isolation**, not a mini computer. It shares your host's kernel.
2. **Created:** no CPU, no RAM, no IP, **no port held**. Just a bit of disk and a reserved name.
3. **Running:** uses CPU and RAM only as the app needs them, gets an IP, and **holds the host port**.
4. **Stopped:** CPU, RAM, and port are freed. The writable layer and name stay, costing only disk space.
5. Use `--memory` and `--cpus` to cap greedy containers, and `docker stats` to watch them.



[[Docker]]