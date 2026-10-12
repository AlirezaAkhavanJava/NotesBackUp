
Containerization means packaging your application together with everything it needs to run (its runtime, libraries, and configuration) into one unit that behaves the same wherever you start it. That unit is called a container.

## The problem it solves

You've probably heard "but it works on my machine." Your Spring Boot app runs on your Debian 13 laptop with Java 21 and a particular PostgreSQL version. Then you deploy it to a server with Java 17, a different library setup, and a different config, and it breaks. Containers fix this by shipping the environment along with the app, so there's nothing left to differ.

## How it works

A container is just a normal Linux process that the kernel has fenced in. Two kernel features do the fencing:

- **Namespaces** give the process its own private view of the system: its own process list, network interfaces, hostname, and filesystem. Inside, it believes it's alone on the machine.
- **cgroups** limit how much CPU and memory it can use.

The container starts from an **image**, a read-only, layered snapshot of a filesystem plus instructions on what to run. A container is a running instance of an image, a bit like a class versus an object in Java. You build the image once and can start as many containers from it as you like.

## Containers vs. virtual machines

A common analogy is "a container is a lightweight virtual machine." It's a decent starting point, but it breaks in an important place. A VM runs its own full operating system kernel on emulated hardware. A container has no kernel of its own and shares your host's kernel. That's why containers start in about a second and use so little memory. It's also why a Linux container can't run a different OS kernel, and why isolation is a bit weaker than a VM's.

## What it looks like for you

For a Spring Boot app, the recipe is a short file called a Dockerfile:

```dockerfile
FROM eclipse-temurin:21-jre
COPY target/myapp.jar /app/myapp.jar
ENTRYPOINT ["java", "-jar", "/app/myapp.jar"]
```

This reads as: start from an image that already contains Java 21, copy in your built jar, and run it. Then:

```bash
docker build -t myapp .
docker run -p 8080:8080 myapp
```

The `-p 8080:8080` part maps a port on your machine to a port inside the container, since the container's network is otherwise walled off.

Once that clicks, the next useful trick is **Docker Compose**, which lets you describe several containers in one file. For example, your Spring Boot app and a PostgreSQL database can start together with a single `docker compose up`, with no need to install PostgreSQL on your system at all.

## Two things to know early

Containers are meant to be disposable. When one is removed, anything it wrote inside itself is gone, so data you care about (like a database's files) goes in a **volume**, which lives outside the container.

Also, **Docker** is the best-known tool, but containerization itself is a general idea. Podman is another tool that works almost identically, and on Debian you can install either.




[[Docker]]