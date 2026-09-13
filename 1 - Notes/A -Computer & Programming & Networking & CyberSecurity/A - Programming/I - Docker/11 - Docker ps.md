
`docker ps` lists all **running containers**.

**Example output:**

```
CONTAINER ID   IMAGE     COMMAND                  STATUS         PORTS                  NAMES
a1b2c3d4e5f6   nginx     "/docker-entrypoint.…"   Up 5 minutes   0.0.0.0:8080->80/tcp   mynginx
```

**Common options:**

- `docker ps` → show **running** containers
    
- `docker ps -a` → show **all** containers (running + stopped)
    
- `docker ps -q` → show only container **IDs**
    
- `docker ps --format "{{.Names}}: {{.Status}}"` → show custom info
    

So if you run:

```bash
docker ps
```

you’ll see which containers are active, their ports, and names.


##### Tags : [[1 - Docker 🧋]]