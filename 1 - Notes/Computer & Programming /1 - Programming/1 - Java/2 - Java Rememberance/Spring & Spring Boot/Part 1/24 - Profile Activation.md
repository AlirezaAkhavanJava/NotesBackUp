


**Profile activation** = telling Spring Boot which profile(s) to use at runtime, so it knows which `@Profile`-annotated beans to create and which `application-{profile}.properties` file to load.

## Ways to activate a profile

**1. In `application.properties` / `application.yml`**

```properties
spring.profiles.active=dev
```

```yaml
spring:
  profiles:
    active: dev
```

Simple, but it hardcodes the profile into the jar — not great since you usually want _different_ profiles for different environments without rebuilding.

**2. Command-line argument (most common for deployments)**

```bash
java -jar app.jar --spring.profiles.active=prod
```

This overrides whatever is in `application.properties`.

**3. Environment variable**

```bash
export SPRING_PROFILES_ACTIVE=prod
java -jar app.jar
```

Spring Boot auto-relaxes the property name (`spring.profiles.active` → `SPRING_PROFILES_ACTIVE`). Very common in Docker/Kubernetes setups.

**4. JVM system property**

```bash
java -Dspring.profiles.active=prod -jar app.jar
```

**5. Programmatically, before the app starts**

```java
public static void main(String[] args) {
    SpringApplication app = new SpringApplication(MyApp.class);
    app.setAdditionalProfiles("dev");
    app.run(args);
}
```

**6. In tests**

```java
@SpringBootTest
@ActiveProfiles("test")
class MyServiceTests {
    // ...
}
```

This is the standard way to run integration tests against, e.g., an in-memory H2 database instead of your real prod DB.

**7. In IntelliJ / your IDE run config**  
Add `-Dspring.profiles.active=dev` as a VM option, or set the "Active profiles" field in the Spring Boot run configuration — useful while developing so you don't need the CLI.

## Multiple profiles at once

```bash
java -jar app.jar --spring.profiles.active=dev,debug
```

All beans matching **any** of these profiles get activated. Files `application-dev.properties` and `application-debug.properties` are both loaded (later one wins on conflicting keys, in the order listed).

## Precedence (who wins if set in multiple places)

Roughly highest → lowest:

1. Command-line argument (`--spring.profiles.active=...`)
2. `SPRING_PROFILES_ACTIVE` env var / `-D` system property
3. `spring.profiles.active` in `application.properties`

Command-line always wins — this is intentional, so ops/deployment scripts can override whatever's baked into the jar.

## `spring.profiles.active` vs `spring.profiles.default`

- `spring.profiles.active` — the profile(s) actually used. If set, `default` is ignored entirely.
- `spring.profiles.default` — fallback used **only if** no active profile is set anywhere. Handy for local dev defaults.

```properties
# application.properties
spring.profiles.default=dev
```

So a teammate who clones the repo and runs it with no config still gets sensible `dev` behavior, while your deployment scripts explicitly set `active=prod` and override it.

## Checking the active profile at runtime

```java
@Autowired
private Environment env;

public void check() {
    String[] active = env.getActiveProfiles();
    System.out.println("Active profiles: " + Arrays.toString(active));
}
```

## Rule of thumb

- **Local dev**: `spring.profiles.default=dev` in `application.properties`, or IDE run config VM option.
- **Deployment**: `--spring.profiles.active=prod` on the command line, or `SPRING_PROFILES_ACTIVE` env var (especially in Docker/K8s) — never bake `prod` into the jar's `application.properties`.
- **Tests**: `@ActiveProfiles("test")`.


[[Java]]
[[0 - Spring Framework]]
[[0 - Spring + Spring Boot]]