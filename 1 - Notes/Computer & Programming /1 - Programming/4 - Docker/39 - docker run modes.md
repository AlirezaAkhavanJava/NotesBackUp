

# ✅ 1) **Foreground Mode (default)**

Runs the container in the **foreground**, attached to your terminal.

```bash
docker run ubuntu
```

The terminal is busy until the container exits.

Useful for:

- Debugging
    
- Interacting with shells
    

---

# ✅ 2) **Detached Mode (`-d`)**

Runs the container in the **background** like a service.

```bash
docker run -d nginx
```

You get a container ID and your shell is free.

Useful for:

- Web servers
    
- Databases
    
- Any long-running service
    

---

# ✅ 3) **Interactive Mode (`-i`)**

Keeps STDIN open even if not attached.

```bash
docker run -i ubuntu
```

Used when you want to send input into the container.

---

# ✅ 4) **TTY Mode (`-t`)**

Allocates a pseudo-terminal.

```bash
docker run -t ubuntu
```

This gives you a terminal-like experience.

---

# 🟩 **Most Common Combo: Interactive Shell (`-it`)**

```bash
docker run -it ubuntu bash
```

This is the real “attach and work inside” mode.

---

# ✅ 5) **Auto-remove Mode (`--rm`)**

Container is deleted after it exits.

```bash
docker run --rm ubuntu echo hi
```

Useful for short-lived tasks.

---

# ✅ 6) **Name Mode (`--name`)**

Give the container a fixed name.

```bash
docker run --name mydb postgres
```

Avoids random names.

---

# ✅ 7) **Port Mapping Mode (`-p`)**

Expose container ports to the host.

```bash
docker run -p 8080:80 nginx
```

---

# ✅ 8) **Volume Mount Mode (`-v` or `--mount`)**

Attach host storage.

```bash
docker run -v /data:/var/lib/mysql mysql
```

---

# ✅ 9) **Environment Mode (`-e`)**

Pass configuration.

```bash
docker run -e MYSQL_ROOT_PASSWORD=123 mysql
```

---

# ✅ 10) **Restart Policy Mode (`--restart`)**

Defines how the container behaves on failure.

```bash
docker run --restart=always nginx
```

Modes:

- `no` (default)
    
- `on-failure`
    
- `always`
    
- `unless-stopped`
    

---

# ✅ 11) **Network Mode (`--network`)**

Choose how container networking works.

```bash
docker run --network=host nginx
```

Modes:

- `bridge` (default)
    
- `host`
    
- `none`
    
- `container:<name>`
    
- custom networks
    

---

# ✅ 12) **Privileged Mode (`--privileged`)**

Full access to host kernel features.

```bash
docker run --privileged ubuntu
```

Powerful but dangerous.

---

# ✅ 13) **Entry Command Override Mode**

Override the image CMD:

```bash
docker run ubuntu echo "hello"
```

Or override ENTRYPOINT:

```bash
docker run --entrypoint="/bin/sh" ubuntu
```

---

# 🧠 Summary Table

|Mode / Flag|Purpose|
|---|---|
|default|foreground|
|`-d`|background service|
|`-i`|keep stdin open|
|`-t`|interactive terminal|
|`-it`|interactive shell|
|`--rm`|auto-clean container|
|`--name`|custom container name|
|`-p`|port mapping|
|`-v` / `--mount`|volumes|
|`-e`|environment variables|
|`--restart`|auto restart rules|
|`--network`|network behavior|
|`--privileged`|full host access|
|`--entrypoint`|override default entrypoint|



###### Tags : [[1 - Docker 🧋]]