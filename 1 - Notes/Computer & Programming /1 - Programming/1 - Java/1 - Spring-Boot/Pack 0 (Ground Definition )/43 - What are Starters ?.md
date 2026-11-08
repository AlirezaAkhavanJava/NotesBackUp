

A **starter** is a ready-made bundle of dependencies for one job. Instead of hunting for every library a feature needs, picking versions that work together and adding them one by one, you add a single line to your build file. That one line pulls in everything the feature normally needs.

Think of it as ordering a meal set instead of buying each ingredient. If you want to build a web app, you add the web starter and get the web framework, an embedded server and JSON support. If you want a database layer, you add the JPA starter and get Hibernate, Spring Data and a connection pool. A starter contains no business logic and almost no code of its own. It is basically a list of dependencies with a good name.

## What is really inside a starter

A starter is a tiny Maven or Gradle module. Its job is to declare dependencies, so when you add it, your build pulls in all of them as _transitive dependencies_ (dependencies of your dependency).

Here is roughly what the web starter brings with it:

|What you get|What it does for you|
|---|---|
|The core `spring-boot-starter`|Spring itself, logging, YAML/properties support|
|Spring MVC|Controllers, `@RestController`, request mapping|
|Jackson|Turns Java objects into JSON and back|
|Tomcat|The server that runs inside your app, so there is no separate install|

This list is a simplification. The exact pieces change a little between Boot versions, but the idea stays the same.

## A line-by-line walkthrough

Here is a minimal `pom.xml` for a Boot 4 web app:

```xml
<parent>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-parent</artifactId>
  <version>4.0.6</version> <!-- use the latest from start.spring.io -->
</parent>

<dependencies>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webmvc</artifactId>
  </dependency>
</dependencies>
```

- **The `<parent>` block** makes your project inherit from `spring-boot-starter-parent`. That parent knows the correct version of hundreds of libraries and sets sensible build defaults.
- **The `<version>` inside the parent** is the only Spring Boot version you ever write. It decides the version of everything else.
- **The `<dependency>` block** adds the starter. Notice there is **no `<version>` tag** here. The parent already supplies it.
- **Result:** one line gives you a working web stack.

Why no version number? The parent includes a **BOM** (bill of materials). That is a tested list saying "these exact versions of Spring, Jackson, Tomcat and so on work together." Without it, you would need to check compatibility by hand.

## The other half: auto-configuration

A starter alone only puts jars on your classpath. The part that makes things work is **auto-configuration**, and the two always work as a pair.

At startup, Spring Boot looks at what is on your classpath and configures beans for you:

|You add|Boot sees|Boot sets up|
|---|---|---|
|web starter|Spring MVC and Tomcat jars|A `DispatcherServlet`, an embedded server on port 8080, JSON conversion|
|JPA starter + PostgreSQL driver|Hibernate and a JDBC driver|A `DataSource`, an `EntityManagerFactory`, transaction support|
|Security starter|Spring Security jars|A default filter chain that protects every endpoint|

So the starter says "here are the tools," and auto-configuration says "I see those tools, so I'll set them up with defaults." You then override only what you need, usually in `application.properties`. This is **convention over configuration** in action: you describe what is different, and Boot handles the rest.

## Naming and the common ones

Official starters follow one pattern: `spring-boot-starter-<technology>`. Third-party starters flip it to `<technology>-spring-boot-starter`, so you can tell them apart.

|Starter|Use it for|
|---|---|
|`webmvc`|REST APIs and web apps with Spring MVC|
|`data-jpa`|Databases with JPA/Hibernate|
|`security`|Authentication and authorization|
|`validation`|Bean Validation annotations like `@NotNull`|
|`actuator`|Health checks and metrics|
|`test` (and per-technology test starters)|Testing support|

## Spring Boot 4 changed the starters

If you follow older tutorials, you will hit this, so it matters. Boot 4 split its large auto-configuration jar into smaller modules, each tied to one technology. As part of that, `spring-boot-starter-web` became `spring-boot-starter-webmvc`, Flyway got its own starter, and test support was split into per-technology starters. The old web starter is now marked deprecated in favor of the new name.

Two practical effects:

- **Test starters match main starters.** Each main starter has a matching test starter, for example `webmvc` with `webmvc-test`, and a missing one can cause errors like missing `@WebMvcTest` or `MockMvc`.
- **Some features now need an explicit starter.** Things like the H2 console, Liquibase, `RestClient` and `WebClient` have their own starters instead of arriving through the web starter.

If you are migrating an old project quickly, Spring offers temporary "classic" starters that pull in everything the way Boot 3 did. They are only a bridge, so move to the specific starters when you can.

## Related concept in short: custom starters

Companies also build their own starters. A team can package shared logging, security or client code as a starter plus an auto-configuration class, so every service gets it by adding one dependency. It is the same idea, applied to your own code.

## Quick recap

- A starter is a named bundle of dependencies for one purpose.
- It carries almost no code, only a list of what to pull in.
- The parent POM's BOM supplies compatible versions, so you write none.
- Auto-configuration is what turns the jars into working, pre-configured beans.
- In Boot 4, use `webmvc` instead of `web`, and add the matching test starter for each main starter.






[[Spring Framework]]