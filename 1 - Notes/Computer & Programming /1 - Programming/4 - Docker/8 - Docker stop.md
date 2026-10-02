

`docker stop` stops a running container gracefully.

**Syntax:**

```bash
docker stop <container-id or name>
```

**Examples:**

```bash
docker stop mydb          # stop by name
docker stop 3e5f2c9a1d3b  # stop by container ID
```

To stop **all running containers**:

```bash
docker stop $(docker ps -q)
```

You can check which containers are running with:

```bash
docker ps
```

##### Tags : [[1 - Docker 🧋]]