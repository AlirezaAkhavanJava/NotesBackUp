

### What is `docker commit`?

`docker commit` is a Docker CLI command that **creates a new Docker image from a running (or stopped) container** by capturing its current state (filesystem changes, installed packages, modified files, etc.) as a new image layer.

It essentially "saves" the container as a new reusable image that you can later run with `docker run`, push to a registry, or share with others.

### Syntax
```bash
docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]
```

### Common Options
| Option              | Description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| `-a, --author`      | Specify an author (e.g., `"John Doe <john@example.com>"`)                  |
| `-m, --message`     | Commit message (similar to git commit)                                      |
| `-p, --pause`       | Pause the container during commit (default: true)                          |
| `--change, -c`      | Apply Dockerfile instructions (e.g., `CMD`, `ENTRYPOINT`, `ENV`, etc.) on commit |

### Example Usage

1. **Basic commit**
   ```bash
   docker commit my-running-container my-new-image:latest
   ```

2. **With author and message**
   ```bash
   docker commit -a "Alice" -m "Added nginx and configured sites" web-container mywebimage:v1.0
   ```

3. **Apply Dockerfile-like changes during commit**
   ```bash
   docker commit --change='CMD ["/usr/sbin/nginx", "-g", "daemon off;"]' web-container nginx-custom:latest
   ```

4. **Real-world scenario**
   ```bash
   # Start a container interactively
   docker run -it --name my-ubuntu ubuntu bash

   # Inside the container, install some tools
   apt update && apt install -y vim curl

   # Exit the container, then commit the changes
   docker commit my-ubuntu my-ubuntu-with-vim:latest

   # Now you can run new containers from this customized image
   docker run -it my-ubuntu-with-vim:latest bash
   ```

### Important Notes & Best Practices

- **Not recommended for production workflows**: `docker commit` creates opaque images (you lose build history and reproducibility). Prefer writing a **Dockerfile** and using `docker build` whenever possible.
- Useful for:
  - Quick debugging or prototyping
  - Saving a container state for inspection
  - Creating base images when you don't have the original Dockerfile
- The new image contains **all changes** made since the container started (deleted files are also removed).
- Running processes are **not preserved** in the committed image (except via `CMD`/`ENTRYPOINT`).

### Summary
`docker commit` = "Take a snapshot of a container and turn it into a new Docker image."

Use it sparingly for experimentation or recovery, but rely on Dockerfiles for reproducible, maintainable images in real projects.

###### Tags : [[1 - Docker 🧋]]