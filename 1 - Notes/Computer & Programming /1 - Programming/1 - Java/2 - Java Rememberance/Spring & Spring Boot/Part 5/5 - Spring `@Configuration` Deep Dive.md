


A ground-up tutorial covering everything used inside `@Configuration` classes: what each annotation/interface is, why it exists, and how it fits into Spring's bigger picture.

---

## 0. The foundation: IoC and the ApplicationContext

Before any of this makes sense, you need two core ideas:

- **IoC (Inversion of Control):** Instead of your code creating objects with `new`, you hand that responsibility to a framework (Spring). Spring creates and wires the objects for you.
- **ApplicationContext:** The container that holds all the objects Spring manages. These managed objects are called **beans**. When your app starts, Spring builds this container, populates it with beans, and injects them wherever they're needed (`@Autowired`, constructor injection, etc.).

`@Configuration` classes are one of the ways you tell Spring _what beans to create and how_.

---

## 1. `@Configuration` and `@Bean`

```java
@Configuration
public class AppConfig {

    @Bean
    public DataSource dataSource() {
        HikariDataSource ds = new HikariDataSource();
        ds.setJdbcUrl("jdbc:postgresql://localhost:5432/mydb");
        return ds;
    }
}
```

|Piece|What it is|
|---|---|
|`@Configuration`|Marks the class as a **source of bean definitions**. Spring scans it at startup and processes every method inside looking for `@Bean`.|
|`@Bean`|Marks a **method** whose return value gets registered in the `ApplicationContext` as a managed object. The method name becomes the bean's default name (`dataSource`).|

**Why `@Configuration` specifically (and not just any class)?** By default, `@Configuration` classes are **CGLIB-proxied**. Spring generates a subclass of your config class at runtime. This proxy intercepts calls between `@Bean` methods so that calling one from another returns the _same singleton_, not a new object:

```java
@Bean
public ServiceA serviceA() {
    return new ServiceA(dataSource()); // returns the SAME dataSource bean, not a new one
}
```

If you don't need that guarantee, you can disable it for a small performance gain:

```java
@Configuration(proxyBeanMethods = false)
```

---

## 2. `WebMvcConfigurer` — hooking into Spring MVC

`WebMvcConfigurer` is an **interface** full of default (empty) methods. Your `@Configuration` class implements it and overrides only what it needs. Spring detects any bean implementing this interface and calls its methods during MVC setup.

### 2a. CORS

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("http://localhost:3000")
                .allowedMethods("GET", "POST", "PUT", "DELETE");
    }
}
```

|Piece|What it is|
|---|---|
|**CORS** (Cross-Origin Resource Sharing)|A browser security rule that blocks a web page on one origin (e.g. `localhost:3000`) from calling an API on another origin (e.g. `localhost:8080`) unless the server explicitly allows it.|
|`addCorsMappings(CorsRegistry registry)`|Callback Spring invokes so you can register CORS rules.|
|`registry.addMapping("/api/**")`|Applies the rule to any URL matching this pattern.|
|`.allowedOrigins(...)`|Which frontend origins are permitted to call this API.|
|`.allowedMethods(...)`|Which HTTP verbs are permitted from those origins.|

### 2b. Interceptors

```java
@Override
public void addInterceptors(InterceptorRegistry registry) {
    registry.addInterceptor(new LoggingInterceptor());
}
```

|Piece|What it is|
|---|---|
|**Interceptor** (`HandlerInterceptor`)|A class that can run code **before**, **after**, or **around** a controller method executes — commonly used for logging, auth checks, or timing requests.|
|`addInterceptors`|Callback where you register interceptor instances and (optionally) restrict them to certain URL patterns via `.addPathPatterns(...)`.|

A minimal interceptor looks like:

```java
public class LoggingInterceptor implements HandlerInterceptor {
    @Override
    public boolean preHandle(HttpServletRequest req, HttpServletResponse res, Object handler) {
        System.out.println("Incoming request: " + req.getRequestURI());
        return true; // true = continue to the controller; false = stop here
    }
}
```

### 2c. Static resource handlers

```java
@Override
public void addResourceHandlers(ResourceHandlerRegistry registry) {
    registry.addResourceHandler("/uploads/**")
            .addResourceLocations("file:/data/uploads/");
}
```

|Piece|What it is|
|---|---|
|**Resource handler**|Maps a URL pattern to a physical location (filesystem, classpath) so Spring can serve static files (images, PDFs, uploaded files) directly.|
|`addResourceHandler("/uploads/**")`|The URL pattern browsers will hit, e.g. `GET /uploads/photo.png`.|
|`.addResourceLocations("file:/data/uploads/")`|Where on disk those files actually live. `file:` prefix = filesystem path; `classpath:` prefix = inside your packaged JAR.|

### 2d. View controllers

```java
@Override
public void addViewControllers(ViewControllerRegistry registry) {
    registry.addViewController("/login").setViewName("login");
}
```

|Piece|What it is|
|---|---|
|**View controller**|A shortcut for routes that just render a template with no logic — skips writing an actual `@Controller` method.|
|`addViewController("/login")`|When a `GET /login` request comes in...|
|`.setViewName("login")`|...render the `login` view (e.g. `login.html` in Thymeleaf) directly.|

---

## 3. Spring Security configuration

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(auth -> auth
                .requestMatchers("/public/**").permitAll()
                .anyRequest().authenticated());
        return http.build();
    }
}
```

|Piece|What it is|
|---|---|
|`@EnableWebSecurity`|Turns on Spring Security's web support and pulls in its default configuration classes.|
|`SecurityFilterChain`|A chain of **servlet filters** that intercept every HTTP request before it reaches your controllers — this is where auth, login forms, CSRF protection, etc. get wired in.|
|`HttpSecurity http`|A builder object Spring injects so you can configure security rules fluently.|
|`.authorizeHttpRequests(auth -> ...)`|Defines **which requests need authentication**.|
|`.requestMatchers("/public/**").permitAll()`|These URLs are open to everyone, no login required.|
|`.anyRequest().authenticated()`|Everything else requires a logged-in user.|
|`http.build()`|Finalizes the configuration into an actual filter chain object, returned as a bean.|

---

## 4. Class-scanning and import annotations

```java
@Configuration
@ComponentScan(basePackages = "com.example.services")
@Import({DataSourceConfig.class, CacheConfig.class})
@PropertySource("classpath:custom.properties")
public class AppConfig {
}
```

|Annotation|What it is|
|---|---|
|`@ComponentScan(basePackages = "...")`|Tells Spring where to **look** for classes annotated `@Component`, `@Service`, `@Repository`, `@Controller`, etc., and register them as beans automatically. Without this, Spring only knows about beans you declare explicitly. (Spring Boot's `@SpringBootApplication` already includes a component scan of your app's base package, so you usually only add this for extra packages.)|
|`@Import({A.class, B.class})`|Explicitly pulls in **other `@Configuration` classes**, merging their beans into this context. Useful for splitting config into logical files (`DataSourceConfig`, `CacheConfig`) while still loading them together.|
|`@PropertySource("classpath:custom.properties")`|Loads an additional `.properties` file (beyond the default `application.properties`) so its key/value pairs become available for `@Value` injection or `Environment` lookups.|

---

## 5. Conditional bean registration

```java
@Configuration
public class CacheConfig {

    @Bean
    @ConditionalOnProperty(name = "cache.enabled", havingValue = "true")
    public CacheManager cacheManager() {
        return new ConcurrentMapCacheManager();
    }

    @Bean
    @Profile("dev")
    public DataSource devDataSource() {
        return new EmbeddedDatabaseBuilder().build();
    }
}
```

|Annotation|What it is|
|---|---|
|`@ConditionalOnProperty(name = "...", havingValue = "...")`|Only creates this bean if the named property in `application.properties`/`application.yml` equals the given value. Lets you toggle features (like caching) via config without touching code.|
|`@Profile("dev")`|Only creates this bean when the active **Spring profile** is `dev` (set via `spring.profiles.active=dev`). Common pattern: an in-memory `devDataSource` for local development, a real PostgreSQL bean for `@Profile("prod")`.|
|`@ConditionalOnMissingBean` _(not shown above, but common)_|Only creates this bean if no other bean of that type already exists in the context — used a lot in auto-configuration to let user-defined beans override defaults.|

These conditional annotations go **on the `@Bean` method itself**, not the class — they control whether _that particular bean_ gets registered.

---

## 6. `@EnableXxx` — turning on Spring subsystems

```java
@Configuration
@EnableScheduling
@EnableAsync
@EnableCaching
@EnableJpaRepositories
public class AppConfig {
}
```

Each of these activates an entire feature area of Spring, usually by importing hidden configuration classes behind the scenes.

|Annotation|What it enables|
|---|---|
|`@EnableScheduling`|Lets you use `@Scheduled` on methods to run them on a timer (cron expressions, fixed rate/delay) — e.g. a nightly cleanup job.|
|`@EnableAsync`|Lets you use `@Async` on methods so they run on a separate thread instead of blocking the caller — e.g. sending an email without holding up the HTTP response.|
|`@EnableCaching`|Lets you use `@Cacheable`, `@CacheEvict`, `@CachePut` on methods so Spring automatically caches their return values.|
|`@EnableJpaRepositories`|Activates Spring Data JPA's repository scanning, so interfaces extending `JpaRepository` get auto-implemented at startup (Spring Boot usually does this for you automatically, but you'd use it explicitly in a multi-datasource setup).|

---

## 7. Plain, non-Spring helper code

```java
@Configuration
public class AppConfig {

    @Value("${app.db.host}")
    private String dbHost; // injected from application.properties

    private String buildUrl() {
        return "jdbc:postgresql://" + dbHost + ":5432/mydb";
    }

    @Bean
    public DataSource dataSource() {
        HikariDataSource ds = new HikariDataSource();
        ds.setJdbcUrl(buildUrl());
        return ds;
    }
}
```

|Piece|What it is|
|---|---|
|`@Value("${app.db.host}")`|Injects a single property value from your config file into a field — not a bean itself, just field injection.|
|`buildUrl()`|A regular private method. Spring never calls it directly or manages it; it's just plain Java used _inside_ a `@Bean` method.|

This is the point from your earlier question: nothing here becomes a bean except the method returning `DataSource`.

---

## Quick reference: what goes where

|You want to...|Use...|
|---|---|
|Register an object in the Spring context|`@Bean` method|
|Group and organize bean definitions|`@Configuration` class|
|Allow cross-origin requests|`WebMvcConfigurer.addCorsMappings`|
|Run code before/after every request|`WebMvcConfigurer.addInterceptors` + a `HandlerInterceptor`|
|Serve files from disk|`WebMvcConfigurer.addResourceHandlers`|
|Map a URL straight to a template, no controller|`WebMvcConfigurer.addViewControllers`|
|Configure auth rules|`@EnableWebSecurity` + `SecurityFilterChain` bean|
|Auto-register `@Component`/`@Service`/etc.|`@ComponentScan`|
|Pull in another config class|`@Import`|
|Load an extra properties file|`@PropertySource`|
|Create a bean only if a property is set|`@ConditionalOnProperty` on the `@Bean` method|
|Create a bean only in a certain environment|`@Profile` on the `@Bean` method|
|Turn on scheduled jobs|`@EnableScheduling` + `@Scheduled`|
|Turn on background/async methods|`@EnableAsync` + `@Async`|
|Turn on method-level caching|`@EnableCaching` + `@Cacheable`|
|Turn on JPA repository scanning|`@EnableJpaRepositories`|


[[Spring Framework]]