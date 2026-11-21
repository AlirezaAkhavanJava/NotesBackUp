

Java Enterprise means using Java to build the big, serious systems that businesses run on, like banking platforms, online stores and booking systems.

These systems have needs that a small program doesn't: many users at once, safe database transactions, security, and the ability to keep running and grow over time. In the early days, Java EE (now called Jakarta EE) was the official answer. It was a set of standards for things like web requests (Servlets), database access (JPA) and transactions, and it ran on heavy application servers. It worked, but it was verbose and hard to configure and test, so developers spent more time wiring things together than writing business logic. That's why you need the Spring ecosystem.

Spring lets you write plain Java classes and handles the wiring for you. Its container creates your objects, connects them to each other (dependency injection) and manages things like transactions and security around them. 

Spring Boot then removes most of the setup, with sensible defaults and an embedded server, so a working app starts in minutes. The result is the same enterprise power with far less boilerplate and much easier testing. This is also why Spring grew into a full ecosystem, with Spring Data for databases, Spring Security for protection, Spring Cloud for microservices and more, all built on the same simple idea.

---

A plain Java app is just your code plus the JVM. You:

- Write your own `main()` method as the entry point
- Manually create every object you need (`new UserService()`, `new DatabaseConnection()`, etc.)
- Manually wire dependencies together (if class A needs class B, you write the code that creates B and passes it into A)
- Handle things like configuration, logging, database connections, and networking yourself, usually by picking and integrating separate libraries
- If you want it to be a web application, you have to set up a server (like Tomcat) yourself, configure servlets, map URLs to code, etc. — a lot of boilerplate

It's fully under your control, but you're responsible for every piece of "plumbing."

## A Spring Boot enterprise application

Spring Boot is built on top of the **Spring Framework**, and it's designed to eliminate that plumbing so you can focus on business logic. Key differences:

|Aspect|Plain Java|Spring Boot|
|---|---|---|
|Object creation & wiring|You do it manually with `new`|Spring's **IoC container** creates and injects objects for you (Dependency Injection)|
|Entry point|Your own `main()`|Still a `main()`, but it calls `SpringApplication.run(...)` which bootstraps the whole framework|
|Web server|You configure Tomcat/Jetty yourself|**Embedded server** included — just run the app, it starts listening on a port|
|Configuration|Manual, scattered across code|Centralized in `application.properties`/`application.yml`, with sensible defaults ("convention over configuration")|
|Dependencies|You manually match compatible library versions|**Starter dependencies** (`spring-boot-starter-web`, `spring-boot-starter-data-jpa`, etc.) bundle compatible versions together|
|Boilerplate|High — lots of setup code|Low — annotations (`@RestController`, `@Service`, `@Autowired`, `@Entity`) replace manual wiring|
|Enterprise concerns (security, transactions, monitoring, data access)|You integrate each library separately|Built-in modules (Spring Security, Spring Data, Spring Actuator) designed to plug in with minimal config|

**The core idea:** in plain Java, _you_ control the flow and construct everything. In Spring Boot, the _framework_ controls the flow — it creates your objects, injects dependencies where needed, and calls your code at the right time. This is called **Inversion of Control (IoC)**, and it's the foundational concept the rest of Spring is built around.




[[Spring Framework]]
[[Java]]