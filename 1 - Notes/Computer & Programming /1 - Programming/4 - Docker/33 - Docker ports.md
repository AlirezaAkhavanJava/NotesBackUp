

## **1️⃣ Docker Ports Basics**

Docker containers have their **own internal ports**.

- Example: A Spring Boot app inside a container usually runs on **8080**.
    
- That port is **inside the container**, not directly accessible from your host machine.
    

**Port mapping** exposes the container port to the host:

```bash
-p <host_port>:<container_port>
```

- **host_port** → port on your machine
    
- **container_port** → port inside Docker container
    

Example:

```yaml
ports:
  - "8080:8080"  # Host 8080 maps to container 8080
```

- You can also do `"9090:8080"` → host uses 9090, container still 8080.
    

---

## **2️⃣ Common Ports for Spring Boot + Docker Stack**

|Service|Default Container Port|Typical Host Port|
|---|---|---|
|Spring Boot app|8080|8080 or 8081+|
|PostgreSQL|5432|5432|
|MySQL|3306|3306|
|Redis|6379|6379|
|Eureka|8761|8761|
|RabbitMQ|5672, 15672|5672, 15672|

**Tip:** Only map the ports you actually need to access from the host. For internal services (like DB for app only), you can skip host mapping and just let containers talk via Docker network.

---

## **3️⃣ How to avoid port conflicts**

- Check if port is free on host:
    

```bash
sudo lsof -i :8080
```

- Change host port if needed:
    

```yaml
ports:
  - "8081:8080"  # Avoid conflict with another 8080 app
```

- Multiple Spring Boot apps → increment host ports: 8081, 8082, etc., but container ports inside Docker stay 8080.
    

---

## **4️⃣ Advanced: Dynamic Ports**

You can let Docker choose a random host port:

```yaml
ports:
  - "8080"  # Docker will pick an available host port
```

Check which port it picked:

```bash
docker ps
```

---


## **1️⃣ Container Names**

By default, Docker auto-generates names like `adoring_morse`—useless in real setups.

You can explicitly set **container names** in `docker-compose.yml`:

```yaml
services:
  app:
    container_name: springboot_app
    build: ./app
    ports:
      - "8080:8080"
```

✅ **Rules:**

- Must be unique per Docker host
    
- Can use letters, numbers, `_` or `-`
    
- Avoid dots or spaces
    

**Why use names?**

- Easier to reference in logs: `docker logs springboot_app`
    
- Easier for `docker exec -it springboot_app bash`
    

---

## **2️⃣ Ports Configuration**

### **Syntax**

```yaml
ports:
  - "host_port:container_port"
```

- **host_port** → port you use to access container from your machine or network
    
- **container_port** → port the app inside container is listening on
    

Example for a Spring Boot app:

```yaml
services:
  app:
    container_name: springboot_app
    build: ./app
    ports:
      - "8080:8080"  # Host 8080 maps to container 8080
```

- You can map to a different host port if 8080 is busy:
    

```yaml
      - "8081:8080"  # Access via localhost:8081, app still runs on 8080 inside container
```

---

### **3️⃣ Ports for Multi-Service Stack (Spring Boot + DB + Redis + Eureka)**

```yaml
services:

  eureka:
    container_name: eureka_server
    build: ./eureka
    ports:
      - "8761:8761"

  app:
    container_name: springboot_app
    build: ./app
    ports:
      - "8080:8080"

  db:
    container_name: postgres_db
    image: postgres:15
    ports:
      - "5432:5432"

  redis:
    container_name: redis_cache
    image: redis:7
    ports:
      - "6379:6379"
```

✅ **Explanation:**

- Host ports: access from your laptop
    
- Container ports: where the service actually listens inside Docker
    
- Names: make commands like `docker logs springboot_app` easier
    

---

## **4️⃣ Optional Advanced Configs**

### **4.1 Dynamic Host Ports**

Docker can assign a random host port if you only specify the container port:

```yaml
ports:
  - "8080"  # Docker picks a free host port
```

Check the assigned port with:

```bash
docker ps
```

---

### **4.2 Expose Only for Internal Networking**

If a service doesn’t need host access (like DB for internal use), skip host mapping:

```yaml
services:
  db:
    image: postgres:15
    expose:
      - "5432"  # Only accessible to other containers in Docker network
```

---

### **4.3 Networks**

To make containers talk via names instead of IPs:

```yaml
networks:
  appnet:
    driver: bridge

services:
  app:
    networks:
      - appnet
  db:
    networks:
      - appnet
```

- `app` can access DB via `jdbc:postgresql://db:5432/mydb`
    
- Container names act as **DNS inside Docker network**
    

---


##### Tags : [[1 - Docker 🧋]]