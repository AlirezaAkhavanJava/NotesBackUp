

## Each piece gets its own container

Normally you don't cram your whole stack into one container. Your Spring Boot app runs in one, PostgreSQL in another, maybe a cache or a message broker in a third. Each one is its own isolated process, with its own filesystem, its own network namespace, and its own resource limits.

This is a convention, not a law. Docker will happily let you start several processes inside one container, but the habit is "one main process per container," because it gives you real benefits:

- You can restart, update, or scale one piece without touching the others. Swap Postgres 16 for 17 without rebuilding your app.
- Each container has a clean job, so its logs and its health are easy to read.
- If your app crashes, your database keeps running.

## Each container comes from an image

Also correct, with one extra detail: the images come from two places.

- **Ready-made images** for software you didn't write, like `postgres` or `redis`, which you pull from a registry (Docker Hub is the default one).
- **Images you build yourself** for your own code, using a Dockerfile like the Spring Boot one we looked at.

So your own application is also an image first, and then a container. And remember the class-and-object relationship: one image can produce many containers. If your app gets busy, you could run three containers from the same `myapp` image, and each would be a separate running instance.

## How they find each other

Separate containers need a way to talk, and this is where Docker Compose earns its place. You describe the whole set in one file:

```yaml
services:
  app:
    build: .                      # build my own image from the Dockerfile here
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://db:5432/appdb
      SPRING_DATASOURCE_USERNAME: appuser
      SPRING_DATASOURCE_PASSWORD: secret
    depends_on:
      - db

  db:
    image: postgres:17            # ready-made image from a registry
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: secret
    volumes:
      - dbdata:/var/lib/postgresql/data

volumes:
  dbdata:
```

Run `docker compose up` and Docker builds your image, pulls Postgres, creates a private network for both, starts the two containers, and wires up the volume.

Notice the database URL says `db`, not an IP address. Compose puts the containers on a shared network where each service name works as a hostname, thanks to Docker's built-in DNS. That's how your app container finds the database container.

One thing that trips people up: inside the `app` container, `localhost` means _the app container itself_, not your machine and not the database. So a connection string pointing at `localhost:5432` would fail there. You use the service name instead.

## Where the analogy to "one program" breaks down

It's tempting to think of this as one program split into pieces, but each container is really its own little machine-like environment that happens to be talking to its neighbors over a network. That's why you have to be deliberate about the connections: ports, hostnames, and shared volumes don't happen automatically the way function calls inside a single program do.





[[Docker]]