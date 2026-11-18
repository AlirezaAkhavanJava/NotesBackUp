

Java's logging landscape is split into two layers on purpose: an **API layer** that your code talks to, and an **implementation layer** that actually does the writing. SLF4J is the API. Logback and Log4j 2 are two different implementations that can sit underneath it. You write code against SLF4J once, and which engine actually runs underneath is a dependency-and-config decision, not a code decision — that separation is the whole reason none of your classes ever say `import ch.qos.logback...` or `import org.apache.logging.log4j...` directly.

Here's why that split exists at all: before SLF4J, Java logging was fragmented — java.util.logging, Log4j 1, Commons Logging, each with incompatible APIs. A library author had to pick one and force it on everyone who used their library. SLF4J fixed that by giving every library a single, neutral API to code against, while leaving the actual engine as a pluggable choice made by whoever assembles the final application — in your case, that's you, via Spring Boot.

## SLF4J — the Facade

SLF4J (Simple Logging Facade for Java) defines the interface your code calls: `Logger`, `LoggerFactory`, methods like `info()`, `debug()`, `error()`. It does no actual writing itself — it has no idea where output goes or how it's formatted. At runtime, it looks for exactly one _binding_ on the classpath (a small jar that connects the SLF4J API to a real engine) and routes every call through it.

```java
private static final Logger logger = LoggerFactory.getLogger(OrderService.class);
logger.info("Order {} created for user {}", orderId, userId);
```

This is the only API your application code should ever touch, whether the real engine underneath is Logback or Log4j 2. That's the point — swap the engine, this line never changes.

## Logback — Spring Boot's Default Engine

Logback is a logging _implementation_: it's the thing that actually formats log lines, decides where they go (console, rolling file, network socket), and applies the level filtering. It was written by the same author as SLF4J and Log4j 1, designed specifically to implement the SLF4J API natively — no adapter layer needed, no performance cost for the translation.

Spring Boot pulls in Logback by default through `spring-boot-starter-logging`, which is itself a transitive dependency of `spring-boot-starter`. That's why a brand-new Spring Boot project logs to the console out of the box with zero logging configuration written by you — Logback is already there, already wired to SLF4J, with sensible defaults.

```xml
<!-- logback-spring.xml — Spring Boot recognizes this name specifically,
     because it lets Spring's own property placeholders resolve inside it -->
<configuration>
    <include resource="org/springframework/boot/logging/logback/defaults.xml"/>
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
    </root>
</configuration>
```

## Log4j 2 — the Apache Alternative

Log4j 2 is a separate implementation, a full rewrite by the Apache Software Foundation of the original Log4j (unrelated code to Logback despite the shared lineage in name only). It implements the same jobs — formatting, routing, filtering — but with a different internal design, and its standout feature is **async loggers** built on the LMAX Disruptor library: logging calls can be handed off to a separate thread so the calling thread barely pays any cost for the I/O, which matters under very high-throughput logging.

To use it in Spring Boot, you explicitly swap it in, because Logback is the default and the two shouldn't both be on the classpath:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter</artifactId>
    <exclusions>
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-logging</artifactId>
        </exclusion>
    </exclusions>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-log4j2</artifactId>
</dependency>
```

Its config file (`log4j2.xml` or `log4j2-spring.xml`) does the same job as `logback-spring.xml`, just with Log4j 2's own XML vocabulary:

```xml
<Configuration>
    <Appenders>
        <Console name="Console" target="SYSTEM_OUT">
            <PatternLayout pattern="%d{yyyy-MM-dd HH:mm:ss} %-5level %logger{36} - %msg%n"/>
        </Console>
    </Appenders>
    <Loggers>
        <Root level="INFO">
            <AppenderRef ref="Console"/>
        </Root>
    </Loggers>
</Configuration>
```

Your Java code — `LoggerFactory.getLogger(...)`, `logger.info(...)` — stays identical either way, because it was never talking to Logback or Log4j 2 directly; it was always talking to SLF4J.

## How the Three Fit Together in a Spring Boot App

```
Your code  -->  SLF4J (the only API you call)
                   |
                   v
           SLF4J binding jar
                   |
          +--------+--------+
          |                 |
      Logback            Log4j 2
   (default engine)    (swap-in engine)
```

Picking between Logback and Log4j 2 is almost always about operational needs rather than everyday code: Logback is simpler to configure and is what Spring Boot assumes you want, so unless you have a specific reason — very high log volume where async logging's throughput matters, or an existing Log4j 2 setup elsewhere in your infrastructure — staying on the default is the right call. The SLF4J layer is what makes that an easy decision to defer or reverse later, since it costs you a dependency swap and a new config file, not a line of application code.


[[Logger]]