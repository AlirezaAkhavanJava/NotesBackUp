

**Docker Compose** is a tool that lets you **define and run multiple containers together** — like your **Spring Boot app + PostgreSQL + Redis** — all from **one configuration file** called `docker-compose.yml`.

---

### 🧱 Basic idea

Instead of typing a bunch of `docker run` commands, you write this **YAML** file once:

```yaml
version: "3.9"
services:
  app:
    image: my-spring-app:latest
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://db:5432/mydb
      SPRING_DATASOURCE_USERNAME: user
      SPRING_DATASOURCE_PASSWORD: pass
    depends_on:
      - db

  db:
    image: postgres:17
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

---

### ⚙️ Explanation

- **services:** defines each container (app, db, redis, etc.)
    
- **image:** which Docker image to use
    
- **ports:** maps container ports to your system ports
    
- **environment:** environment variables (for configs, passwords, etc.)
    
- **depends_on:** start order (app waits for db)
    
- **volumes:** named data storage (keeps DB data safe after restart)
    

---

### 🚀 Commands

|Command|Description|
|---|---|
|`docker compose up`|Start everything|
|`docker compose up -d`|Start in background (detached)|
|`docker compose down`|Stop and remove everything|
|`docker compose ps`|List running containers|
|`docker compose logs`|Show combined logs|
|`docker compose build`|Build images defined in the file|

---

### 💡 Example workflow

1. Write `docker-compose.yml`
    
2. Run `docker compose up -d`
    
3. Your app + DB start automatically
    
4. Visit `localhost:8080`
    

---




##### Tags : [[1 - Docker 🧋]]