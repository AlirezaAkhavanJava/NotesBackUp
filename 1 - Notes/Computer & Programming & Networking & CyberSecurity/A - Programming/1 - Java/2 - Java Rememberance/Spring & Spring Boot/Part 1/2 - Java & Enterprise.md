

## A normal (plain) Java application

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








[[0 - Spring + Spring Boot]]
[[0 - Spring Framework]]
[[Java]]