A module is a self-contained unit inside a project, with its own source code, its own dependencies, and its own build configuration. When you create an empty project and add several modules to it, the project is just a folder that holds everything together, and each module becomes one independent application. That is why modules are a convenient way to build microservices on one machine: you open one IDE window, but each module can be built, run, and deployed on its own.

## Project vs. module

In IntelliJ IDEA, the vocabulary is:

- **Project:** the top-level container. An empty project has no code of its own. It only holds settings and a list of modules.
- **Module:** a part of the project with its own `src` folder, its own dependencies, and usually its own `pom.xml` (Maven) or `build.gradle` (Gradle).

Think of the project as a building and each module as a separate apartment. They share the building, but each has its own door, its own utilities, and its own residents.

## A module is not a microservice by itself

This is the most common confusion. A module is a build and organization unit. A microservice is a deployment and runtime concept: a small application that runs in its own process, has its own port, ideally owns its own data, and talks to other services over the network.

You create a module for each service so that each one becomes an independently runnable Spring Boot application. The module is the container, and the microservice is what you put inside it.

## What it looks like

An empty project with three modules might look like this:

```
my-shop/                     <- the empty project
├── user-service/            <- module 1
│   ├── src/main/java/...
│   └── pom.xml
├── order-service/           <- module 2
│   ├── src/main/java/...
│   └── pom.xml
└── payment-service/         <- module 3
    ├── src/main/java/...
    └── pom.xml
```

Each module has its own `@SpringBootApplication` main class and its own `application.properties`, with a different port:

```properties
# user-service
server.port=8081
spring.application.name=user-service
```

```properties
# order-service
server.port=8082
spring.application.name=order-service
```

Now you can start all three at the same time, and each one runs as a separate process, just as it would in production.

## How to create them in IntelliJ

1. Go to File > New > Project and choose **Empty Project**.
2. Go to File > New > Module. You can pick **Spring Boot** (Spring Initializr) to generate a ready-made service, or a plain Maven module.
3. Repeat for each service, giving each a clear name and its own dependencies (for example, `user-service` might need Spring Web and Spring Data JPA).

## Optional: a parent POM

If you want one command to build everything, you can add a parent `pom.xml` at the root that lists the modules:

```xml
<project>
    <groupId>com.example</groupId>
    <artifactId>my-shop</artifactId>
    <version>1.0.0</version>
    <packaging>pom</packaging> <!-- a parent only aggregates, it has no code -->

    <modules>
        <module>user-service</module>
        <module>order-service</module>
        <module>payment-service</module>
    </modules>
</project>
```

Running `mvn clean install` at the root then builds every module. This setup is called a **multi-module project** (or monorepo when it holds many services).

## Rules that keep it a real microservice setup

- **Do not let one service depend directly on another's code.** If `order-service` imports classes from `user-service`, you have built a distributed monolith. Services should communicate through REST calls, messaging (Kafka, RabbitMQ), or similar.
- **Give each service its own database or schema.** Sharing tables couples the services together.
- **Use a different port for each service**, or they will fail to start together.
- **A shared module is allowed, but keep it small.** A `common` module holding things like shared DTOs or utility classes is fine. If it grows into a place where all business logic lives, the independence you wanted is gone.

## Summary

A module is a self-contained piece of a project with its own code and dependencies. In a microservice setup, you make one module per service inside an empty (or parent) project, so you can develop and run them side by side while they stay independent and communicate only over the network.





[[Java Back-End]]