
`docker images` shows all images stored locally on your system.

**Example:**

```
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
nginx         latest    6b914bbcb89e   2 weeks ago    187MB
postgres      16        3b4f9e8b3f8a   1 month ago    412MB
ubuntu        24.04     7e0aa2d69a15   3 months ago   77MB
```

**Common uses:**

- `docker images` → list all images
    
- `docker rmi <image-id>` → remove an image
    
- `docker pull <image>` → download one
    
- `docker image prune` → remove unused images
    

Each image is like a **template** for containers — you _run_ containers **from** these images.

##### Tags : [[1 - Docker 🧋]]