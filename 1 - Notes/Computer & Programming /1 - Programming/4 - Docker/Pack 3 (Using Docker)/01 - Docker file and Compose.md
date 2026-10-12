

So far you've run images other people built. Now you'll build your own, and then run your Spring Boot app and its database together with one command.

## The Dockerfile

A **Dockerfile** is a text file of instructions that tells Docker how to build an image. Each instruction adds a layer, and Docker caches layers, which matters in a moment.

Here's a Dockerfile for a Spring Boot app built with Maven. Put it in your project root, next to `pom.xml`, and name it exactly `Dockerfile`:

```dockerfile
# Stage 1: build the jar
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN ./mvnw dependency:go-offline
COPY src src
RUN ./mvnw package -DskipTests

# Stage 2: run it
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Here's what each line does:

- `FROM` picks the starting image. `eclipse-temurin` is a widely used Java distribution. The `jdk` variant has the compiler and build tools, while the `jre` variant can only run programs, so it's smaller. Match the number (21) to the Java version your project uses.
- `WORKDIR` sets the folder inside the image where later commands run.
- `COPY` copies files from your machine into the image.
- `RUN` executes a command _while building_ the image, here to download dependencies and compile.
- `EXPOSE 8080` is documentation. It says "this app listens on 8080" but doesn't publish the port. You still need `-p` (or `ports:` in Compose) for that.
- `ENTRYPOINT` is the command that runs when a container starts.

**Why two stages?** This is called a multi-stage build. The first stage has Maven, the JDK, and all your source code, which you need to build but not to run. The second stage copies only the finished jar into a slim image. Your final image ends up much smaller. It's a bit like compiling a Java program and shipping only the `.class` files, though here Docker throws away the whole build environment for you.

**Why copy `pom.xml` before `src`?** Remember layer caching. Docker reuses a layer if nothing it depends on has changed. Your dependencies change rarely, but your source changes constantly. By downloading dependencies in an earlier layer, rebuilds after a code edit skip that slow download step.

Also create a file called `.dockerignore` so you don't copy junk into the build:

```
target
.git
.idea
```

Now build and run it:

```bash
docker build -t my-app:1.0 .
docker run -d --name my-app -p 8080:8080 my-app:1.0
```

`-t` tags the image with a name and version. The `.` at the end means "use the current folder as the build context." It's easy to forget, and Docker will complain if you do.

## Why Compose exists

Your app needs Postgres, so you'd run two containers with a pile of flags each, and you'd have to remember them every time. **Docker Compose** lets you describe the whole setup in one file and start it with one command.

On Debian, the Compose plugin may not come with `docker.io`. Try:

```bash
docker compose version
```

If that fails, install it with `sudo apt install docker-compose`. (On some Debian releases the package is named `docker-compose-v2`, so check `apt search docker-compose` if the first name isn't found.)

## A compose.yaml for your app and database

Create `compose.yaml` in the project root:

```yaml
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: appdb
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d appdb"]
      interval: 5s
      timeout: 3s
      retries: 10

  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://db:5432/appdb
      SPRING_DATASOURCE_USERNAME: app
      SPRING_DATASOURCE_PASSWORD: secret
    depends_on:
      db:
        condition: service_healthy

volumes:
  pgdata:
```

Everything you learned last time is here in another form. `image`, `environment`, `ports`, and `volumes` are the same ideas as `-e`, `-p`, and `-v`, just written as YAML. A few parts are new:

**`build: .`** tells Compose to build the app's image from the Dockerfile in this folder instead of pulling one.

**The hostname `db`.** This is the most important idea in this lesson. Compose puts all your services on a private network where each service is reachable by its _name_. So your app connects to `db:5432`, not `localhost:5432`. Inside a container, `localhost` means _that container itself_, so if your app used `localhost` it would look for Postgres inside the app container and find nothing. This is the number one thing that trips people up.

**`SPRING_DATASOURCE_URL`.** Spring Boot maps environment variables onto its properties, so `SPRING_DATASOURCE_URL` overrides `spring.datasource.url` from your `application.properties`. That lets the same code run on your machine with `localhost` and in Docker with `db`, without editing any files.

**`healthcheck` and `depends_on`.** Postgres takes a few seconds to be ready after its container starts. Plain `depends_on` only waits for the container to _start_, not for the database to _accept connections_, so your app could crash on boot. The healthcheck runs `pg_isready` repeatedly, and `condition: service_healthy` makes the app wait until it passes.

## Compose commands

```bash
docker compose up -d          # create and start everything, in the background
docker compose up -d --build  # rebuild your app's image first (after code changes)
docker compose ps             # what's running
docker compose logs -f app    # follow one service's logs
docker compose stop           # stop, but keep the containers
docker compose down           # stop and remove containers and the network
docker compose down -v        # same, and also delete volumes (your data!)
```

Be careful with that last one. `down` keeps your `pgdata` volume, so your database survives. Adding `-v` deletes the volume, and with it all your data. That's handy when you want a fresh start and painful when you didn't mean it.

Also notice that `up` doesn't rebuild your image when your code changes. Compose reuses the old image unless you pass `--build`. If you edit code and nothing seems to change, that's usually why.

## A note on that password

Putting `secret` directly in the file is fine for learning on your own machine. Once a project is shared or deployed, you'd move passwords into a separate `.env` file (which Compose reads automatically) and keep it out of Git. It's a good habit to start early.





[[Docker]]