
`@Configuration` classes are basically just a place to centralize setup logic, so besides `@Bean` methods, they commonly host these patterns:

## 1. CORS configuration (what you already know)

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

This works because `@Configuration` classes can **implement interfaces** like `WebMvcConfigurer` and override their callback methods — no `@Bean` needed here.

## 2. Implementing `WebMvcConfigurer` for other MVC customization

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new LoggingInterceptor());
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:/data/uploads/");
    }

    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        registry.addViewController("/login").setViewName("login");
    }
}
```

## 3. Security configuration (Spring Security)

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

Still uses `@Bean`, but it's worth mentioning since `@Configuration` + `@EnableWebSecurity` is such a common combo.

## 4. `@ComponentScan`, `@Import`, `@PropertySource`

```java
@Configuration
@ComponentScan(basePackages = "com.example.services")
@Import({DataSourceConfig.class, CacheConfig.class})
@PropertySource("classpath:custom.properties")
public class AppConfig {
}
```

- `@ComponentScan` — tells Spring where to look for `@Component`/`@Service`/`@Repository`.
- `@Import` — pulls in other `@Configuration` classes explicitly.
- `@PropertySource` — loads extra `.properties` files.

## 5. Conditional configuration

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

`@ConditionalOnProperty`, `@Profile`, `@ConditionalOnMissingBean`, etc. go on `@Bean` methods inside the config class to control _when_ they're registered.

## 6. `@EnableXxx` annotations

```java
@Configuration
@EnableScheduling
@EnableAsync
@EnableCaching
@EnableJpaRepositories
public class AppConfig {
}
```

These turn on entire Spring subsystems (scheduling, async execution, caching, JPA repos) — the actual bean wiring happens behind the scenes via imported configuration classes.

## 7. Plain helper/setup logic

Private methods, constants, or `@Value`-injected fields used to build beans — as in your original example. These aren't Spring-managed, they're just supporting code.

---

**Rule of thumb:** if it's a _method that returns an object you want in the context_ → `@Bean`. If it's _registering a customization callback, scanning packages, importing other configs, or toggling a feature_ → one of the annotations/interfaces above, often with no `@Bean` at all.



[[Spring Framework]]