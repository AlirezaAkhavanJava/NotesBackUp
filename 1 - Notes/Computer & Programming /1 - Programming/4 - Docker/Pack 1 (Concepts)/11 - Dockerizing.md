
"Dockerizing" an app means packaging it so that it, along with everything it needs to run, lives in an image and runs as a container. A **dockerized app** is an app that has gone through that. The goal is a simple promise: _if the image runs on your machine, it runs the same way on a server, on a teammate's laptop, or in the cloud._

## The problem it fixes

Your app never runs alone. A Spring Boot app needs a particular Java version, maybe certain environment variables, a database at a known address, and files in the right places. Without Docker, all of that lives on the machine, and "it works on my machine" happens whenever two machines differ even slightly.

Dockerizing moves everything the app depends on _inside_ the image, so the machine only needs Docker. The nearest technical analogy is a statically linked binary or a Java fat JAR: you ship the dependencies along with the program. Where the analogy breaks down: a fat JAR still needs a JVM installed on the host, while an image carries the JVM and the OS-level files too. Only the kernel comes from the host.

## What changes in how you think

A dockerized app follows a few habits, and they matter more than the Dockerfile syntax.

**The container is disposable.** You never fix a running container by hand. You change the code or the image, rebuild, and replace the container. This works because nothing precious lives inside it.

**Configuration comes from outside.** Don't bake database passwords or URLs into the image. The same image should run in development and production, with only the settings changing. Spring Boot makes this easy, because an environment variable like `SPRING_DATASOURCE_URL` automatically overrides the `spring.datasource.url` property.

**Data lives outside.** Anything that must survive goes into a volume or an external database, never the container's writable layer.

**Logs go to the console.** Don't write log files inside the container. Print to stdout/stderr, and Docker collects them for you (`docker logs`). Spring Boot already does this by default, so you're in good shape.

**The app talks to others over the network by name.** As we saw with Compose, your app reaches the database at `db:5432`, not `localhost`.

## Dockerizing a Spring Boot app, step by step

Start with the Dockerfile, a slightly improved version of the earlier one:

```dockerfile
# ---- build stage ----
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app

# copy only what's needed to resolve dependencies first
COPY mvnw pom.xml ./
COPY .mvn .mvn
RUN ./mvnw dependency:go-offline

# now copy the source and build
COPY src ./src
RUN ./mvnw package -DskipTests

# ---- run stage ----
FROM eclipse-temurin:21-jre
WORKDIR /app

# run as a normal user, not root
RUN groupadd --system app && useradd --system --gid app app
USER app

COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

There's one clever thing here worth understanding: the dependency download is its own step, _before_ the source is copied. Docker caches each layer, and a layer is only rebuilt if its inputs changed. Your `pom.xml` rarely changes, but your source changes constantly. So after the first build, a rebuild after editing code reuses the cached dependency layer and skips re-downloading the whole internet. Ordering a Dockerfile from "changes least" to "changes most" is the core skill of making builds fast.

Next, add a `.dockerignore` file next to the Dockerfile, so you don't send junk into the build:

```
target/
.git/
.idea/
*.log
```

Without it, Docker sends your entire folder (including `target/` and `.git`) to the builder every time, which slows builds and can bake in files you didn't intend.

Then build and run it:

```bash
docker build -t myapp .
docker run -d --name myapp -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://host:5432/appdb \
  myapp
docker logs -f myapp
```

The `-e` flag injects configuration at run time, which is the "configuration from outside" habit in action.

## Making it a complete setup

Once the app is an image, you combine it with its neighbors using Compose, exactly like the file from before: your `app` service built from the Dockerfile, a `db` service from the `postgres` image, a named volume for the data. That one `docker compose up` gives anyone who clones your repo a working copy of the full system, with no installing Java, Postgres, or anything else by hand. That reproducibility is the biggest everyday payoff.

A couple of extras make an app feel production-ready:

- **Health checks.** Spring Boot's Actuator exposes `/actuator/health`, and you can tell Docker or Compose to poll it, so the platform knows whether the app is actually ready, not just started.
- **Memory awareness.** Modern JVMs read the container's cgroup limit, so if you run with `--memory=512m`, Java sizes its heap accordingly. Remember the cgroups lesson: that limit is enforced by the kernel, and exceeding it gets the process killed.
- **Pinned versions.** Use `postgres:17` or `eclipse-temurin:21-jre`, not `latest`, so a rebuild next month doesn't silently change what you're running.

## Common beginner stumbles

- Using `localhost` to reach another container. It points to the container itself.
- Storing data in the container, then losing it on `docker rm`.
- Putting secrets in the Dockerfile. They end up readable in the image layers forever. Pass them at run time (or use Compose secrets).
- Rebuilding slowly because `COPY . .` comes before the dependency step.
- Forgetting the `-p` flag, so the app runs but you can't reach it from your browser.

A good exercise is to take a small Spring Boot app, even a "hello world" with one endpoint, write the Dockerfile above, build it, run it, and hit it from your browser. Then break it on purpose: delete the `-p` flag, or change a line of code and watch the cache behavior in the build output. Seeing "CACHED" next to the dependency layer is a satisfying moment.





[[Docker]]