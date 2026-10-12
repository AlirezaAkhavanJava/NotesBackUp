

So far we've treated the engine's layers as black boxes. This lesson opens them. By the end, you'll be able to say exactly which Linux system calls turn `docker run` into a running container, and you'll have built a small container yourself with no Docker involved.

The one-sentence version, so you know where we're heading: **a container is what you get when you call a handful of kernel features in the right order on an ordinary process, and Docker's real job is to do that reliably and repeatably.**

## 1. The Big Picture: Two Halves

Docker's work splits cleanly into two kinds of jobs:

|Half|Question it answers|Mostly handled by|
|---|---|---|
|**Preparing**|What files and settings should this container have?|`dockerd`, `containerd`: images, layers, networks, volumes|
|**Isolating and running**|How do I actually fence a process in?|`runc` and the kernel|

You know the first half from earlier lessons. This lesson is about the second, because that's where the kernel does the real work.

## 2. The Handoff Between Layers

When you run `docker run`, the request travels down the stack, and each layer talks to the next in a specific way:

1. The **CLI** sends an HTTP request to `dockerd` over the Unix socket.
2. `dockerd` talks to **containerd** over **gRPC** (another socket, `/run/containerd/containerd.sock`).
3. containerd starts a **shim** process and talks to it over **ttrpc**, a lightweight gRPC variant.
4. The shim runs **`runc`**, which makes **system calls** directly to the kernel.

The key artifact passed down to runc is an **OCI bundle**, which is just a directory with two things in it:

```
bundle/
├── config.json     ← the full description: process, mounts, namespaces, limits, caps
└── rootfs/         ← the container's root filesystem (the OverlayFS merged view)
```

That's the whole contract. `runc` doesn't know about images, registries, or networks. It reads `config.json`, looks at `rootfs/`, and builds a fenced-in process. The analogy to a compiler taking a source file and producing a binary works for the _shape_ of this (a precise description goes in, a result comes out). Where it breaks down: runc doesn't produce a lasting artifact. It sets things up and then gets out of the way, leaving a plain running process.

## 3. Step by Step: What `runc` Does

Here is the real sequence, in order. Each step is a system call or a small group of them.

**Step 1: Create the process in new namespaces.**  
runc starts its helper process using `clone()` (or `unshare()`) with flags that request fresh namespaces:

|Flag|Namespace|
|---|---|
|`CLONE_NEWPID`|Process IDs: the new process becomes PID 1|
|`CLONE_NEWNS`|Mounts: a private mount table|
|`CLONE_NEWUTS`|Hostname|
|`CLONE_NEWIPC`|Shared memory and message queues|
|`CLONE_NEWNET`|Network stack|
|`CLONE_NEWCGROUP`|A virtualized view of the cgroup tree|
|`CLONE_NEWUSER`|User and group IDs (only if configured, as in rootless mode)|

For the network namespace, Docker actually creates it _before_ the container starts, configures the veth pair and addresses from the host side, and then runc joins it using `setns()`. That's how the networking you learned about gets plugged in.

**Step 2: Join the cgroup.**  
The process is placed in its own cgroup, and the limits from `config.json` are written into it.

**Step 3: Build the filesystem view.**  
Inside the new mount namespace, runc:

- mounts the container's `rootfs` (marking mounts _private_ so nothing leaks back to the host),
- mounts a fresh **`/proc`**, **`/sys`**, a tiny **`/dev`** with only safe device nodes (`null`, `zero`, `urandom`, `tty`, and so on), `/dev/pts`, and `/dev/shm`,
- applies your volumes and bind mounts,
- **masks** sensitive paths such as `/proc/kcore` (hidden behind empty files) and makes others, like parts of `/proc/sys`, **read-only**.

**Step 4: Swap the root with `pivot_root`.**  
Now `pivot_root()` makes the container's `rootfs` the new `/`, and runc unmounts the old root so the host filesystem is _gone_ from the container's view, not just hidden. This is stronger than the older `chroot()`, which only changes where a process thinks `/` is and can be escaped with known tricks. We'll compare them hands-on shortly.

**Step 5: Set the hostname.** `sethostname()` inside the UTS namespace.

**Step 6: Strip privileges.** This is a big one, so it gets its own section next.

**Step 7: Wait for the signal to go.**  
runc has now built the whole container but hasn't started your program. It parks on a **named pipe (FIFO)**. When `runc start` is called, it opens the pipe, and the final step proceeds.

**Step 8: `execve()` your program.**  
runc replaces itself with your actual command (`nginx`, `java -jar app.jar`). From this moment, there is no "runc" and no "Docker" in the container. There's just your program, running as PID 1 inside its namespaces, with the restrictions already in place. This is exactly why we say `runc` creates the container and then exits.

## 4. Stripping Privileges: Three Locks on the Door

Namespaces hide things and cgroups limit things, but a root process inside a container would still be dangerous without more protection. runc applies several restrictions before `execve()`:

**Capabilities.** On Linux, "root" isn't one power but about 40 separate ones (called _capabilities_): binding low ports, changing file ownership, loading kernel modules, changing the system clock, and so on. Docker keeps a short default list (14 of them) and drops the rest. So root in a container _cannot_ load kernel modules or reconfigure the network, even though `whoami` says `root`. You can adjust this with `--cap-drop` and `--cap-add`.

**seccomp.** The kernel supports a filter that decides, for every system call, whether to allow it. Docker's default profile blocks a few dozen of the roughly 300+ syscalls, the rare and risky ones. A blocked call fails with an error instead of reaching the kernel's code. This shrinks the attack surface considerably.

**Mandatory access control (AppArmor).** Docker generates and applies a default AppArmor profile on systems that use it. Debian ships AppArmor support, though it's worth checking it's active on your setup. SELinux plays the same role on Red Hat-family systems.

There's also `no_new_privs`, a flag that prevents the process from gaining privileges later through setuid binaries.

A technical analogy: this is like layered defense in a web server. The namespace is the network boundary, capabilities are role permissions, seccomp is a firewall on the API surface, and AppArmor is a policy engine. Where it breaks down: all of these enforce _on the same kernel the host runs_, so a kernel vulnerability can bypass all of them at once. That's the fundamental isolation limit we discussed when comparing containers to VMs.

## 5. The Shim and Why Your Container Survives Restarts

Once runc execs your program, who is its parent process? Not runc (it exited), and not `dockerd`. It's the **containerd-shim**, which sits quietly beside it and does three jobs:

- **keeps stdin/stdout/stderr connected**, so `docker logs` and `docker attach` work,
- **collects the exit code** when the process ends (a parent must `wait()` for a child, or the child lingers as a zombie),
- **holds the container alive** independent of the daemons, which is why a container can keep running while `dockerd` restarts if live-restore is enabled.

You can see this relationship on your machine:

```bash
docker run -d --name demo nginx
ps -ef --forest | grep -B2 -A2 nginx
```

The tree shows `containerd-shim` as the parent of the container's main process.

## 6. PID 1: The Quirks of Being the First Process

Inside a PID namespace, your app is **PID 1**, and the kernel treats PID 1 specially. Two consequences matter in real life:

**Signals behave differently.** For a normal process, an unhandled `SIGTERM` or `SIGINT` kills it. For PID 1, the kernel _ignores_ signals that have no explicit handler. So if your program doesn't install a handler, `docker stop` sends SIGTERM, nothing happens, and after 10 seconds Docker gives up and sends `SIGKILL`. That's the "my container takes forever to stop" symptom.

**Zombie reaping.** When an orphaned child process exits, PID 1 is supposed to `wait()` on it. If your app doesn't do that, zombies accumulate.

The practical fixes are:

- Use the **exec form** of `ENTRYPOINT`, with square brackets, as in our Dockerfile (`["java", "-jar", "app.jar"]`). The shell form (`ENTRYPOINT java -jar app.jar`) wraps your program in `/bin/sh -c`, making the _shell_ PID 1, and the shell often doesn't forward signals to your app.
- Run with **`docker run --init`** (or `init: true` in Compose), which inserts a tiny init program (`tini`) as PID 1 to forward signals and reap zombies.

The JVM installs its own handlers for SIGTERM, so Spring Boot shuts down gracefully when it's PID 1 via exec form, which is one less thing to worry about.

## 7. cgroups in Detail

Docker Engine on modern Debian uses **cgroup v2**, a single unified tree under `/sys/fs/cgroup`. Each container gets a directory, and limits are just files you write numbers into:

|File|Controls|
|---|---|
|`memory.max`|Hard memory limit; exceeding it triggers the OOM killer|
|`memory.high`|Soft limit that throttles the process|
|`cpu.max`|CPU quota, written like `50000 100000` (50ms per 100ms period = half a core)|
|`pids.max`|Maximum number of processes, which protects against fork bombs|
|`io.max`|Disk bandwidth and IOPS limits|
|`cgroup.procs`|Which PIDs belong to this group|

The flags you pass map straight onto these files: `--memory=100m` becomes `memory.max`, `--cpus=0.5` becomes `cpu.max`, and `--pids-limit` becomes `pids.max`. There's no clever machinery beyond the kernel enforcing what's in those files.

## 8. Build a Container by Hand

Now the payoff. We'll recreate the essentials with no Docker running at all, just to get a root filesystem. (If you have Docker installed from earlier, it's the quickest way to get one.)

**Get a filesystem:**

```bash
mkdir -p ~/mycontainer/rootfs && cd ~/mycontainer
docker export $(docker create alpine) | tar -C rootfs -xf -
ls rootfs            # bin  etc  lib  usr ... a complete tiny Linux userland
```

**Isolate with namespaces and a new root:**

```bash
sudo unshare --pid --fork --mount --uts --ipc --net \
     --mount-proc=$PWD/rootfs/proc \
     chroot rootfs /bin/sh
```

Inside that shell, try:

```sh
hostname mybox     # changes only this namespace's hostname
ps                 # only a couple of processes; sh is PID 1
ls /               # Alpine's files, not your Debian ones
cat /etc/os-release
```

You're now in something that behaves a lot like a container. Notice that we used `chroot`, and I said earlier that runc uses `pivot_root` because `chroot` is weaker. That's a real difference. A root process can escape a plain chroot with a few well-known steps, which is why real runtimes do the stronger swap. For learning purposes, though, it shows the idea.

**Add a memory limit with cgroup v2.** In a separate terminal on the host:

```bash
sudo mkdir /sys/fs/cgroup/demo
echo 100M | sudo tee /sys/fs/cgroup/demo/memory.max
echo <PID-of-the-unshared-shell-as-seen-from-the-host> | sudo tee /sys/fs/cgroup/demo/cgroup.procs
```

To find that PID, run `ps -ef | grep 'chroot rootfs'` on the host. Now the shell, and everything it starts, is limited to 100 MB. (If the `memory.max` file doesn't exist, the memory controller isn't enabled for that part of the tree. Check `cat /sys/fs/cgroup/cgroup.controllers` and `cat /sys/fs/cgroup/cgroup.subtree_control`.) Clean up afterwards by exiting the shell and running `sudo rmdir /sys/fs/cgroup/demo`.

## 9. Use `runc` Directly

Since runc is installed alongside Docker, you can skip everything above it and run an OCI bundle yourself. This is the most honest view of the "isolating" half:

```bash
cd ~/mycontainer
runc spec                    # generates a default config.json in the current folder
```

Open `config.json`. Everything we discussed is a field in it: `process.args` (the command), `process.capabilities`, `linux.namespaces`, `linux.resources` (cgroup limits), `mounts`, `linux.maskedPaths`, `linux.readonlyPaths`, and `hostname`. Then run it:

```bash
sudo runc run demo           # starts a container named "demo" from this bundle
```

In another terminal, `sudo runc list` shows it, and `sudo runc state demo` prints its PID and status. You've just done what the whole Docker stack does, minus the images, registries, and networking.

## 10. Watch the System Calls Happen

For proof, trace runc's calls:

```bash
sudo strace -f -o trace.txt \
  -e trace=clone,clone3,unshare,setns,mount,pivot_root,sethostname,capset,seccomp,execve \
  runc run demo2
grep -E 'pivot_root|unshare|clone|sethostname|seccomp|execve' trace.txt | head -40
```

(Use a different container name than a running one. The output is long, so filtering helps.) You'll see the namespace creation, the mounts, the `pivot_root`, the capability and seccomp setup, and finally the `execve` of your program. It's the sequence from section 3, written by the kernel itself.

## 11. Rootless Mode: Taking This Further

Normally `dockerd` runs as root, which is why socket access is root-equivalent. **Rootless mode** runs the whole engine as an ordinary user, using a **user namespace**: the "root" inside the container maps to your unprivileged user ID on the host. A container escape then lands the attacker in an unprivileged account instead of root. The cost is some limitations, such as how networking and low ports work. It's an excellent topic for a later security lesson.

## 12. Quick Recap

- A container is built by **runc** from an **OCI bundle**: a `config.json` plus a `rootfs`.
- The key syscalls are **`clone`/`unshare`** (namespaces), **cgroup file writes** (limits), **`mount`** and **`pivot_root`** (filesystem), **`capset`**, **`seccomp`**, and finally **`execve`**.
- Isolation comes from **namespaces (what it sees)**, **cgroups (what it uses)**, and **capabilities, seccomp, and AppArmor (what it may do)**.
- After `execve`, runc is gone. The **shim** is the process's parent and keeps it connected and reaped.
- Your app is **PID 1**, so use the exec form of `ENTRYPOINT` and consider `--init`.
- All of it is visible in the kernel: `/proc`, `/sys/fs/cgroup`, and `strace`.

## Exercises

1. Do the hand-built container in section 8, then run `ps` and `hostname` inside and outside to confirm what's isolated.
2. Run `runc spec`, edit `config.json` to change the command to `sleep 300`, run it, and find its PID on the host with `runc state`.
3. Inside a Docker container, run `cat /proc/self/status | grep Cap` and compare it with the same on the host. The capability bitmasks differ.
4. Run `docker run --rm alpine sh -c 'echo $$'` and note the PID is 1, then run the same with `--pid=host` and compare.




[[Docker]]