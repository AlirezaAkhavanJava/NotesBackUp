
**Spring** and **Spring Boot** are related but not the same thing. Spring Boot is built **on top of** the Spring Framework.

### What is Spring?
**Spring** (usually “Spring Framework”) is a popular open-source framework for building Java/JVM applications, especially enterprise and web applications.

Its core idea is **Inversion of Control (IoC)** and **Dependency Injection (DI)**:
- Instead of your code creating and managing objects manually, Spring creates and wires them for you.
- These managed objects are called **beans**.
- Spring also provides many modules: Spring MVC for web apps, Spring Data for databases, Spring Security for authentication/authorization, Spring AOP, transaction management, testing support, etc.

In short: **Spring is the underlying framework and container that helps you build loosely coupled, testable Java applications.**

### What is Spring Boot?
**Spring Boot** is an opinionated extension/tool built on top of Spring. It makes it much faster and easier to create stand-alone, production-ready Spring applications.

It provides:
- **Auto-configuration** — automatically configures Spring based on the dependencies you add.
- **Starter dependencies** — e.g. `spring-boot-starter-web` brings in everything needed for a web app.
- **Embedded servers** — Tomcat, Jetty, or Undertow, so you can run your app as a normal Java program.
- **No XML boilerplate** — mostly annotation and Java-based configuration.
- **Production features** — Actuator for health checks, metrics, etc.
- **Executable JARs** — package and run with `java -jar app.jar`.

A typical Spring Boot app starts with:

```java
@SpringBootApplication
public class MyApp {
    public static void main(String[] args) {
        SpringApplication.run(MyApp.class, args);
    }
}
```

### Key difference
| | Spring | Spring Boot |
|---|---|---|
| What it is | The core framework and IoC container | A tool/extension on top of Spring |
| Main goal | Flexibility and comprehensive infrastructure | Speed, convenience, and sensible defaults |
| Configuration | Often manual | Mostly auto-configured |
| Server | You configure/deploy one | Embedded server included |
| Boilerplate | More | Much less |

**Analogy:** Spring is like an engine and chassis with many high-quality parts you can assemble yourself. Spring Boot is a preassembled car with sensible defaults—you can still customize it, but you can drive it much sooner.


[[Java]]