

**Jakarta EE** is a collection of official rules and standards for building enterprise Java applications. Think of it as a common set of instructions that tells developers how things like Servlets, JPA, Bean Validation, and Dependency Injection should work. Different companies can create their own implementations of these standards, and developers can use them without being locked into one specific vendor.

**Spring Framework**, on the other hand, is a framework that provides its own tools and approach for building enterprise Java applications. It handles things like creating and managing objects (IoC), building web applications (Spring MVC), working with databases, and securing applications (Spring Security).

So, **Spring is not an implementation of Jakarta EE**. They are separate technologies, but they can work together. Spring even uses several Jakarta EE standards under the hood instead of reinventing everything. In simple terms, Jakarta EE defines standards, while Spring provides its own programming model and tools to build applications. They sometimes solve the same problems, but they can also complement each other.

---

Spring uses some Jakarta EE APIs directly, ignores others, and replaces some with its own versions.

|Job|Jakarta EE standard|What Spring does|
|---|---|---|
|Web layer|Servlet|**Uses it.** Spring MVC is built on the Servlet API; `DispatcherServlet` is a servlet.|
|Database ORM|Jakarta Persistence (JPA)|**Uses it.** Spring Data JPA wraps it; Hibernate is the usual implementation.|
|Input validation|Jakarta Bean Validation|**Uses it.** `@Valid`, `@NotNull`, `@Size` come from here.|
|Transactions|Jakarta Transactions (JTA)|**Optional.** Spring has its own `@Transactional`; JTA is used only for distributed transactions.|
|Dependency injection|Jakarta CDI / Jakarta Inject|**Replaces it** with Spring's own container, but understands `@Inject` as an alternative to `@Autowired`.|
|REST APIs|Jakarta REST (JAX-RS)|**Replaces it** with Spring MVC (`@RestController`).|
|Messaging|Jakarta Messaging (JMS)|**Supports it** through `JmsTemplate` and `@JmsListener`.|
|Mail|Jakarta Mail|**Uses it** through `JavaMailSender`.|

The pattern is that Spring happily uses Jakarta EE for the low-level plumbing (servlets, JPA, validation) but keeps its own programming model for the parts developers touch most (DI and web controllers).

---

## A bit of history: from J2EE to Spring to Jakarta

1. **Early 2000s, J2EE.** Enterprise Java was powerful but heavy: lots of XML, EJBs, and a big application server to deploy to.
2. **2002–2004, Spring appears.** Rod Johnson's book and framework said, "You can build enterprise apps with plain Java objects (POJOs) and a lightweight [^1]container." Spring grew in part as a reaction to J2EE's complexity.
3. **J2EE became Java EE**, and Java EE copied many of Spring's ideas (annotations, CDI, simpler persistence).
4. **2017–2018, Oracle handed Java EE to the Eclipse Foundation.** Oracle kept the "Java" trademark, so the platform was renamed **Jakarta EE**.
5. **Namespace change.** Because of the trademark, Jakarta EE 9 renamed all packages from `javax.*` to `jakarta.*`.
6. **Spring Framework 6 / Spring Boot 3 (late 2022)** moved to Jakarta EE 9+ and the `jakarta.*` packages.

That last step is the one you'll feel as a developer.

---

## What changed in your code: `javax` to `jakarta`

**Before (Spring Boot 2.x / Spring 5):**

```java
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.validation.constraints.NotBlank;
import javax.servlet.http.HttpServletRequest;
```

**After (Spring Boot 3.x+ / Spring 6+):**

```java
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.validation.constraints.NotBlank;
import jakarta.servlet.http.HttpServletRequest;
```

Line by line, only the package prefix changed: `javax` became `jakarta`. The classes, annotations, and behavior are the same. But a library compiled against `javax.servlet` will not work with a container expecting `jakarta.servlet`, because to the JVM they are different packages entirely.

Note that not everything under `javax` moved. Packages that belong to the JDK itself (like `javax.sql`, `javax.crypto`, `javax.net.ssl`) stay as they are. Only the enterprise APIs that moved to Eclipse got renamed.

If you've worked with a JWT filter in Spring Boot 3, the `HttpServletRequest` and `FilterChain` you import are `jakarta.servlet` types. That's Jakarta EE inside Spring.

---

## Which Spring version goes with which Jakarta EE?

|Spring Framework|Spring Boot|Jakarta EE baseline|
|---|---|---|
|5.x|2.x|Java EE 8 (`javax.*`)|
|6.0 / 6.1|3.0 / 3.x|Jakarta EE 9/10 (`jakarta.*`)|
|7.x|4.x|Jakarta EE 11|

Check the exact baseline versions in the official release notes when you start a project, since they move with each release.

---

## Spring vs. Jakarta EE as a whole platform

Here is the biggest difference in _how you run_ things:

**Traditional Jakarta EE:** you write your app and deploy it to an **application server** (WildFly, Payara, Open Liberty, GlassFish). The server provides the implementations of the specs.

**Spring Boot:** you create a self-contained JAR with an **embedded servlet container** (Tomcat by default, or Jetty/Undertow). Tomcat only implements the Servlet part of Jakarta EE (plus a couple of related specs such as WebSocket), not the full platform. Spring then brings everything else on its own, and you pull in Hibernate (for JPA) and Hibernate Validator (for Bean Validation) as libraries.

So a Spring Boot app is a bit like building your own small Jakarta EE stack from the parts you need, instead of renting a whole one.

---

## Can they be mixed?

Yes, and it's common:

- A Spring app that uses `@Entity` (JPA), `@Valid` (Bean Validation), and servlets is _already_ mixing them.
- Spring understands `@Inject` and `@Named` (Jakarta Inject), so code written for CDI-style injection can often run in Spring.
- Spring can run **inside** a Jakarta EE application server as a WAR file, which is how many older enterprise apps were deployed.

---

## Quick summary of a related concept: CDI

**CDI (Jakarta Contexts and Dependency Injection)** is Jakarta EE's answer to Spring's IoC container. It lets you write `@Inject` and define scopes like `@RequestScoped`, `@ApplicationScoped`. It solves the same kind of problem as Spring's container, but it's a _standard_ with multiple implementations (Weld, OpenWebBeans), whereas Spring's container is one specific product.

## Quick summary of another: MicroProfile and Quarkus

**MicroProfile** is a set of lightweight specs for microservices (config, health checks, metrics) that sits next to Jakarta EE. **Quarkus** and **Helidon** are frameworks that build on Jakarta EE and MicroProfile standards, and they are the closest "standards-based" competitors to Spring Boot.

---

## Takeaways

- Spring is **not** Jakarta EE, but it **depends on** several Jakarta EE specs (Servlet, JPA, Bean Validation).
- Spring **competes with** parts of Jakarta EE (CDI vs. Spring DI, JAX-RS vs. Spring MVC).
- Since Spring 6 / Boot 3, those dependencies use the `jakarta.*` namespace. That's the breaking change behind most "my old library doesn't work" errors after upgrading.
- A spec is a contract. Hibernate, Tomcat, and Hibernate Validator are implementations. Spring sits on top and ties them together with its own model.





[[Spring Framework]]

[^1]: In Java, a container is a piece of software that creates, manages, and controls the objects (usually called beans) inside your application. Instead of creating objects yourself using `new`, you let the container create them, keep track of them, and provide them to other objects when needed. For example, in Spring, the IoC Container creates your classes, manages their dependencies, and decides when they should be initialized or destroyed. Think of it as a manager responsible for the objects in your application.
