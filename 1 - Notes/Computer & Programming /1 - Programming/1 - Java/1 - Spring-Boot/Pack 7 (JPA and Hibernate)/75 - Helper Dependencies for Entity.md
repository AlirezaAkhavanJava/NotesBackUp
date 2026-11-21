

**What this lesson covers:** Many of the helper annotations we used (Lombok's `@Builder`, Hibernate's `@UuidGenerator`, Spring Data's `@CreatedDate`, and so on) don't work until a library is on the classpath and, in some cases, a configuration switch is turned on. This lesson lists every dependency those annotations need, explains what each library provides, shows the Maven coordinates, and notes where Spring Boot manages the version for you. Earlier lessons already covered Spring Data JPA, Spring Security, validation, Flyway, and PostgreSQL, so they appear here only for completeness.

## Why dependencies matter

An annotation is just a marker. Java compiles it whether or not the library that defines it is present, but nothing acts on it at runtime. A `@Builder` with no Lombok on the compiler path produces a compile error, while a `@CreatedDate` with no auditing listener compiles and then silently does nothing. Knowing which library owns each annotation helps you debug both kinds of failure.

## The dependency map

|Annotation or feature|Library|Maven artifact|Extra setup|
|---|---|---|---|
|`@Entity`, `@Id`, `@Column`, `@Version`, `@Transient`, lifecycle callbacks|Jakarta Persistence (JPA)|`spring-boot-starter-data-jpa`|None|
|`@UuidGenerator`, `@CreationTimestamp`, `@UpdateTimestamp`, `@Immutable`, `@DynamicInsert`, `@DynamicUpdate`, `@SoftDelete`, `@SQLRestriction`, `@NaturalId`, `@BatchSize`, `@Formula`, `@Generated`, `@ColumnTransformer`, `@JdbcTypeCode`, `@Cache`|Hibernate|included in the JPA starter|`@Cache` needs a cache provider|
|`@CreatedDate`, `@LastModifiedDate`, `@EntityListeners(AuditingEntityListener.class)`|Spring Data Commons and Spring Data JPA|included in the JPA starter|`@EnableJpaAuditing`|
|`@CreatedBy`, `@LastModifiedBy`|Spring Data|included|An `AuditorAware` bean|
|`@EnableJpaAuditing`|Spring Data JPA|included|None|
|`@Builder`, `@SuperBuilder`, `@Getter`, `@Setter`, `@Value`, `@With`, `@Singular`, `@NonNull`, `@Slf4j`, `@Data`, `@RequiredArgsConstructor` and other Lombok annotations|Lombok|`lombok`|IDE annotation processing|
|`@Valid`, `@NotBlank`, `@NotEmpty`, `@Size`, `@Min`, `@Max`, `@Email`|Jakarta Bean Validation|`spring-boot-starter-validation`|None|
|`@PreAuthorize`, `@AuthenticationPrincipal`, `SecurityFilterChain`|Spring Security|`spring-boot-starter-security`|`@EnableMethodSecurity` for `@PreAuthorize`|
|`Clock` injection|Java standard library|none|Declare a `Clock` bean|
|Flyway migrations|Flyway|`flyway-core` and `flyway-database-postgresql`|Migration scripts|
|Second-level cache for `@Cache`|Hibernate with JCache and Caffeine or Ehcache|`hibernate-jcache`, `caffeine`, `cache` (JCache API)|Cache settings in `application.properties`|
|SHA-256 hashing for tokens|Java standard library (`MessageDigest`)|none|None|
|BCrypt password hashing|Spring Security Crypto|included in the security starter|Declare a `PasswordEncoder` bean|

## The Maven setup

Here's a `pom.xml` fragment that brings in everything the lessons used. Spring Boot manages the versions of all the Spring, Hibernate, and Flyway artifacts through the parent POM, so you don't specify them:

```xml
<dependencies>
    <!-- JPA, Hibernate, Spring Data JPA, auditing support -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>

    <!-- Bean Validation: @NotBlank, @Size, @Min, @Valid, and so on -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>

    <!-- Spring Security: login, BCrypt, @PreAuthorize -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>

    <!-- Flyway core engine: runs versioned SQL migrations at startup -->
    <dependency>
        <groupId>org.flywaydb</groupId>
        <artifactId>flyway-core</artifactId>
    </dependency>

    <!-- Flyway support for PostgreSQL; required since Flyway 10 -->
    <dependency>
        <groupId>org.flywaydb</groupId>
        <artifactId>flyway-database-postgresql</artifactId>
    </dependency>

    <!-- PostgreSQL JDBC driver: needed at runtime only -->
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
        <scope>runtime</scope>
    </dependency>

    <!-- Lombok: generates getters, builders, constructors at compile time -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>

    <!-- Second-level cache for @Cache (optional, add only if you use caching) -->
    <dependency>
        <groupId>org.hibernate.orm</groupId>
        <artifactId>hibernate-jcache</artifactId>
    </dependency>
    <dependency>
        <groupId>com.github.ben-manes.caffeine</groupId>
        <artifactId>caffeine</artifactId>
    </dependency>
    <dependency>
        <groupId>javax.cache</groupId>
        <artifactId>cache-api</artifactId>
    </dependency>

    <!-- Test support -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

A few notes on this file:

- **`lombok` uses `<optional>true</optional>`.** That keeps Lombok out of anything that depends on your project. It's needed only while compiling.
- **`flyway-database-postgresql` is separate.** Flyway 10 moved database-specific support into its own modules, so a PostgreSQL project without it fails at startup with a message about an unsupported database.
- **The three cache artifacts work together.** `hibernate-jcache` connects Hibernate to the JCache standard, `cache-api` is the JCache interface, and `caffeine` is the actual cache implementation. You can swap Caffeine for Ehcache by changing the implementation artifact.
- **`spring-boot-starter-test`** includes JUnit, AssertJ, and Mockito, which you'll use when testing the `Clock` behavior and the factory methods from the earlier lessons.

## Configuration that some annotations need

Dependencies alone aren't always enough. These switches must also be set:

**Auditing.** A Java configuration class is needed:

```java
@Configuration
@EnableJpaAuditing
public class JpaConfig {

    @Bean
    public Clock clock() {                // Used by services that inject Clock
        return Clock.systemUTC();
    }
}
```

`@EnableJpaAuditing` turns on the listener that fills `@CreatedDate` and `@LastModifiedDate`. `@CreatedBy` and `@LastModifiedBy` also need an `AuditorAware<Long>` bean that returns the current user's ID, usually read from Spring Security's context.

**Method security.** `@PreAuthorize` is ignored until you add this to a configuration class:

```java
@Configuration
@EnableMethodSecurity   // Activates @PreAuthorize and @PostAuthorize
public class MethodSecurityConfig {
}
```

**Password hashing.** BCrypt needs a `PasswordEncoder` bean, which we declared in the security lesson:

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder(12);
}
```

**Second-level cache.** Put these in `application.properties` so Hibernate uses the cache:

```properties
spring.jpa.properties.hibernate.cache.use_second_level_cache=true
spring.jpa.properties.hibernate.cache.region.factory_class=jcache
spring.jpa.properties.hibernate.javax.cache.provider=com.github.benmanes.caffeine.jcache.spi.CaffeineCachingProvider
```

Without `use_second_level_cache=true`, `@Cache` on an entity does nothing, even with all the jars present.

## Lombok in your IDE

Lombok is the dependency most often misconfigured. Maven builds may work while the IDE shows red errors on `getId()` or `builder()`. Fix it this way:

- **IntelliJ IDEA:** install the Lombok plugin if it isn't bundled, then enable _Settings → Build, Execution, Deployment → Compiler → Annotation Processors → Enable annotation processing_.
- **VS Code:** install the Lombok extension or the Java extension pack, which includes Lombok support.
- **Eclipse:** run the Lombok jar installer once, then restart Eclipse.

On Debian 13, if the IDE is installed from a package, check that it's running with the same Java version your project targets. Lombok breaks on mismatched JDK versions.

## Verifying your setup

Run this on your terminal to confirm the dependencies resolved:

```bash
./mvnw dependency:tree | grep -E "hibernate|lombok|flyway|validation|caffeine"
```

Each line you expect should appear. If one is missing, check that you added it under `<dependencies>` and not under `<dependencyManagement>`, and that the `<optional>` and `<scope>` tags are correct.

You can also check at startup. If `@EnableJpaAuditing` is missing, timestamps stay `null`. If `@EnableMethodSecurity` is missing, `@PreAuthorize` silently allows every request. Test those behaviors directly, because a missing configuration switch often produces no error at all.

## Common mistakes

1. **Using a helper annotation without the dependency.** For `@Builder` or `@Slf4j`, the compiler reports "cannot find symbol," which is the easy case. For `@CreatedDate`, nothing reports an error and the value stays `null`.
2. **Adding Lombok without `optional` or with the wrong scope.** Lombok belongs at compile time only.
3. **Forgetting `flyway-database-postgresql`.** Flyway starts, reports an unsupported database, and stops.
4. **Expecting `@Cache` to work with only the jars.** The `use_second_level_cache` setting is also required.
5. **Forgetting `@EnableMethodSecurity`.** `@PreAuthorize` is silently ignored, which is a serious security gap.
6. **Declaring versions by hand for Spring-managed artifacts.** Let the Spring Boot parent manage them, so the library versions stay compatible.

## Try it yourself

1. Remove `@EnableJpaAuditing` from your project, save an entity, and observe what happens to `createdAt`. Then add it back and compare.
2. Run `./mvnw dependency:tree` and find which artifact brings in `jakarta.validation`. Explain why you didn't need to add it directly.
3. Temporarily remove `lombok` from the POM and count the compile errors. Then restore it and explain why Lombok annotations fail at compile time, while a missing auditing configuration fails silently at runtime.


[[Spring Framework]]
[[Maven]]