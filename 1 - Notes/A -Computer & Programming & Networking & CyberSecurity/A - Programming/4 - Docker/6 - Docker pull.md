
`docker pull` downloads an image from a Docker registry (usually Docker Hub) to your local system.

**Syntax:**

```bash
docker pull <image-name>
```

**Examples:**

```bash
docker pull ubuntu           # pulls the latest Ubuntu image
docker pull postgres:16      # pulls PostgreSQL version 16
docker pull nginx:alpine     # pulls the lightweight Alpine version of Nginx
```

You can check your pulled images with:

```bash
docker images
```

##### Tags : [[1 - Docker 🧋]]