
`docker system` is a **management command group** — it lets you see and clean up Docker’s overall resources (containers, images, volumes, networks, etc.).

---

### 🧩 Common subcommands:

|Command|Description|
|---|---|
|`docker system df`|Shows disk space used by images, containers, and volumes|
|`docker system prune`|Removes **all unused** containers, networks, images, and build cache|
|`docker system info`|Shows detailed info about your Docker setup (version, storage, CPU, etc.)|
|`docker system events`|Streams real-time Docker events (create, start, stop, delete)|

---

### 🔍 Examples:

```bash
docker system df
```

→ See how much space Docker uses.

```bash
docker system prune
```

→ Clean up everything **not currently running** (asks for confirmation).

```bash
docker system prune -a
```

→ Remove **everything unused**, including images not tied to any container.  
⚠️ **Careful** — this deletes a lot.

---

✅ **In short:**  
`docker system` = “manage the whole Docker environment” — useful for checking usage, freeing disk space, and getting global info.

##### Tags : [[1 - Docker 🧋]]