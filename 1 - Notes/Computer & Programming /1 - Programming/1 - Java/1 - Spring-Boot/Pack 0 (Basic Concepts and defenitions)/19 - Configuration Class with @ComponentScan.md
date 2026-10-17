

## The mental model

Spring Boot needs two things to build your app's object graph: **where to look** for components, and **how to build** the ones that aren't simple annotated classes. `@ComponentScan` handles the first. `@Bean` methods handle the second. A `@Configuration` class is just a place to declare both.

You almost never need to write `@ComponentScan` yourself in Spring Boot — `@SpringBootApplication` already includes it, scanning your main class's package and everything below it. You reach for it manually only when components live outside that tree.

## The two mechanisms, side by side

||`@ComponentScan`|`@Bean`|
|---|---|---|
|Finds classes **you annotated** (`@Service`, `@Repository`, `@Controller`, `@Component`)|✅|❌|
|Registers objects **you construct manually** (third-party classes, conditional logic)|❌|✅|
|Where declared|On a `@Configuration` class|Inside a `@Configuration` class|

```java
@Configuration
@ComponentScan(basePackages = "com.arcade")
public class AppConfig {

    @Bean
    public GameRepository gameRepository() {
        return new GameRepository();
    }
}
```

`@ComponentScan` sweeps `com.arcade` for anything annotated `@Service`, `@Repository`, etc. The `@Bean` method hand-builds `GameRepository` explicitly — useful when the class isn't yours to annotate (a library class), or construction needs logic a bare `@Component` can't express.

## Why you rarely write this in Spring Boot

```java
@SpringBootApplication   // this already IS @Configuration + @ComponentScan + @EnableAutoConfiguration
public class ArcadeApplication {
    public static void main(String[] args) {
        SpringApplication.run(ArcadeApplication.class, args);
    }
}
```

If `ArcadeApplication` sits in `com.arcade`, everything under `com.arcade.*` gets scanned automatically. You'd only add a second `@ComponentScan` to reach a package _outside_ that tree:

```java
@Configuration
@ComponentScan(basePackages = "com.sharedlibrary.utils")
public class ExtraScanConfig {}
```

## The real gotchas (the doc buried these)

- **Duplicate scanning → duplicate/conflicting beans.** If two `@ComponentScan`s overlap the same package, you can get bean definition conflicts at startup. Don't re-scan what `@SpringBootApplication` already covers.
- **`basePackageClasses` > `basePackages` string.** `@ComponentScan(basePackageClasses = ArcadeApplication.class)` is typo-proof — a renamed/moved package breaks compilation instead of silently scanning nothing. The string version (`"com.Arcade"`) fails _silently_ if misspelled; no error, just missing beans.
- **Scanning too broadly slows startup.** `basePackages = "com"` walks your entire classpath tree. Keep it scoped.
- **`includeFilters`/`excludeFilters` exist but are rarely needed** — mainly for excluding test fixtures or scoping to one stereotype. Not something to reach for by default.

## When you'd actually use this in practice

Almost the only realistic case in a normal Spring Boot app: you have a **shared library module** (different Maven artifact, different package root) whose `@Component`-annotated classes your main app needs to pick up. Everything else — your own services, repos, controllers — just lives under your app's root package and gets found for free.

---

[[Spring Framework]]