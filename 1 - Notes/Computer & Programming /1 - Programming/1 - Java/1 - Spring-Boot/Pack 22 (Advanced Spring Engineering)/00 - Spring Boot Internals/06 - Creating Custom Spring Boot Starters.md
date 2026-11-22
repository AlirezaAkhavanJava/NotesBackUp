You already built the autoconfigure module last time — the actual `@AutoConfiguration` class, conditions, properties. This lesson is specifically about the **starter module** itself: the second half of that two-module convention you saw mentioned, and the thing a consumer actually types into their `pom.xml`. It sounds like it should be the "real" work, but its defining feature is that it's almost empty on purpose.

## What a starter actually is

A starter contains **no Java code at all** — ideally zero `.java` files. It exists purely as a dependency-aggregation POM. Its entire job is: when someone adds one dependency, pull in everything needed to make that feature work — the autoconfigure module, the underlying client library, and any transitive pieces — so the consumer doesn't have to figure out and list five separate dependencies themselves.

```xml
<!-- acme-spring-boot-starter/pom.xml -->
<project>
    <groupId>com.acme</groupId>
    <artifactId>acme-spring-boot-starter</artifactId>
    <packaging>jar</packaging>

    <dependencies>
        <dependency>
            <groupId>com.acme</groupId>
            <artifactId>acme-spring-boot-autoconfigure</artifactId>
            <version>${project.version}</version>
        </dependency>
        <dependency>
            <groupId>com.acme.client</groupId>
            <artifactId>acme-java-client</artifactId>
            <version>2.3.1</version>
        </dependency>
    </dependencies>
</project>
```

That's it — no `src/main/java` directory needed at all. A consumer now writes:

```xml
<dependency>
    <groupId>com.acme</groupId>
    <artifactId>acme-spring-boot-starter</artifactId>
</dependency>
```

and transitively gets your autoconfigure module, your `AcmeClient` library, and — because the autoconfigure module itself depends on `spring-boot-autoconfigure` — the hooks into the mechanism you built last time.

## Naming conventions (this one has an actual rule, not just a preference)

Spring's own convention, stated explicitly in their documentation, is a naming split that exists to avoid trademark/namespace confusion:

- **`spring-boot-starter-*`** — reserved for starters maintained by the official Spring team (`spring-boot-starter-web`, `spring-boot-starter-data-jpa`, etc.). Don't name a third-party starter this way.
- **`*-spring-boot-starter`** — the convention for everyone else, with your project/company name as the prefix: `acme-spring-boot-starter`, `mybatis-spring-boot-starter` (a well-known real example). The autoconfigure module mirrors this: `acme-spring-boot-autoconfigure`.

This isn't just politeness — some tooling (and definitely human expectation) treats the `spring-boot-starter-*` prefix as an implicit "this is official" signal, so following the inverted convention for your own avoids misleading consumers.

## Why the split matters: avoiding forced bytecode/version coupling

Here's the practical reason the two-module split exists rather than just shipping one jar with code and dependencies together: some consumers want your auto-configuration _logic_ without your opinionated choice of underlying client version or extra transitive dependencies — for example, another starter author building on top of yours, or a project that needs a newer version of the client library than you've pinned. By keeping the autoconfigure module dependency-light and letting the starter module be the only place that pins concrete versions, those consumers can depend on `acme-spring-boot-autoconfigure` directly and manage the client dependency themselves.

## Version alignment with a BOM

If you're maintaining several related starters (common in larger internal platforms), the usual pattern is a parent BOM (Bill of Materials) POM that centralizes version numbers, so every starter and autoconfigure module in your family stays in lockstep:

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.acme</groupId>
            <artifactId>acme-spring-boot-dependencies</artifactId>
            <version>1.4.0</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

Consumers import this BOM once and then omit `<version>` tags on individual `acme-*` dependencies — exactly the pattern `spring-boot-dependencies` itself uses to keep every official starter's transitive versions compatible with each other.

## Packaging test support as its own module (optional but common)

For larger starters, a third module sometimes appears: `acme-spring-boot-starter-test`, containing test-only utilities — mock servers, `@AcmeTest` custom test annotations, test fixtures — kept separate so production consumers don't pull test dependencies transitively. This isn't required for a small starter, but it's why you'll see things like `spring-boot-starter-test` exist as its own artifact in the official family rather than being bundled into `spring-boot-starter`.

## Getting picked up by Spring Initializr-style tooling

This part is optional and mostly relevant if you're distributing the starter widely rather than just internally: Spring maintains a registry (`spring-configuration-metadata.json` additions aside) that lets third-party starters appear as options in Spring Initializr, but this requires a submission process to Spring's starter catalog — not something that happens automatically from correct packaging. For an internal company starter, this step is simply skipped; consumers just add the Maven/Gradle coordinate directly.

## Verifying the whole thing end to end

With both modules built, the real integration test is creating a throwaway Spring Boot app that depends only on the starter artifact and confirming the bean shows up with zero manual configuration:

```java
@SpringBootApplication
public class SmokeTestApplication {
    public static void main(String[] args) {
        var context = SpringApplication.run(SmokeTestApplication.class, args);
        System.out.println(context.getBean(AcmeClient.class)); // should just work
    }
}
```

If this fails, the usual suspects are the ones from your last two lessons: a missing or misplaced `AutoConfiguration.imports` file, a `@ConditionalOnClass` check failing because the client jar wasn't actually pulled in transitively, or a typo in the fully-qualified class name inside the imports file — none of which throw a build error, since the whole mechanism is designed to fail silently (just absent) rather than loudly, which is exactly why the `--debug` conditions report from your earlier lessons is the right first move when a custom starter "does nothing."

[[Spring Framework]]
