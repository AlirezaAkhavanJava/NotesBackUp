

The `docker search` command lets you search for Docker images on **Docker Hub** (or a configured registry).

### Syntax:

```bash
docker search [OPTIONS] TERM
```

- **TERM** → the keyword to search for (e.g., `nginx`, `postgres`).
    

### Common Options:

- `--limit=N` → Limit the number of results (default: 25).
    
- `--filter=is-official=true` → Show only official images.
    
- `--filter=is-automated=true` → Show only automated build images.
    

### Example:

```bash
docker search nginx
```

Output columns include:

- **NAME** → image name
    
- **DESCRIPTION** → short description
    
- **STARS** → popularity on Docker Hub
    
- **OFFICIAL** → ✅ if it’s an official image
    
- **AUTOMATED** → ✅ if it’s automatically built
    

---


##### Tags : [[1 - Docker 🧋]]