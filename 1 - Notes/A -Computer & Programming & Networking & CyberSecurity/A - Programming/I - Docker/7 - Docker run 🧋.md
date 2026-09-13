
`docker run` creates and starts a new container from an image.

**Basic syntax:**

```bash
docker run [options] <image-name>
```

**Common examples:**

```bash
docker run ubuntu                       # run Ubuntu interactively (will exit immediately)
docker run -it ubuntu bash              # open Ubuntu shell interactively
docker run -d nginx                     # run Nginx in background (detached)
docker run -p 8080:80 nginx             # map container port 80 → host port 8080
docker run --name mydb -e POSTGRES_PASSWORD=123 postgres
```

**Useful options:**

- `-d` → run in background (detached mode)
    
- `-p host:container` → port mapping
    
- `--name name` → name your container
    
- `-e VAR=value` → set environment variable
    
- `-v host_path:container_path` → mount volume
    

You can list running containers with:

```bash
docker ps
```

And all (including stopped ones):

```bash
docker ps -a
```

##### Tags : [[1 - Docker 🧋]]