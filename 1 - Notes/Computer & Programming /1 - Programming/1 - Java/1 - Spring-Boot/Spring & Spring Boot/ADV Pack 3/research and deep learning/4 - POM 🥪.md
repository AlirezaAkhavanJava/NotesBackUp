
When you add **Spring Security** to your Spring Boot project (e.g., by including `spring-boot-starter-security` in your `pom.xml`), Spring Security **automatically enables** basic security features:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

This is what happens **by default**:

### 1. **HTTP Basic Authentication** is enabled
- Every endpoint (`/`, `/api/**`, etc.) becomes **protected**.
- A **login dialog** (browser popup) appears asking for **username** and **password**.
- You **cannot access anything** without credentials.

### 2. **Default user is automatically created**
Spring Security creates **one default user** with:

| Property          | Default Value                  |
|-------------------|--------------------------------|
| Username          | `user`                         |
| Password          | **Randomly generated at startup** (you'll see it in the console) |
| Role              | `USER`                         |

Example console output when you start the application:

```
Using generated security password: 0a7b9c2d-3e4f-5g6h-7i8j-9k0l1m2n3o4p
```

So the default credentials are:
- **Username**: `user`
- **Password**: whatever random string was printed in the console

### 3. Why is there a GUI popup asking for user/pass?
This is **HTTP Basic Authentication** — the browser automatically shows a simple dialog when it receives a `401 Unauthorized` response with `WWW-Authenticate: Basic` header.

Spring Security enables **Basic Auth** by default when no other authentication mechanism is configured.

### 4. How to see / change these defaults?

| What you want                     | How to do it                                                                                   |
|-----------------------------------|------------------------------------------------------------------------------------------------|
| See the random password           | Just look at the console when Spring Boot starts                                               |
| Set a fixed username/password     | Add to `application.properties` or `application.yml`:                                          |
|                                   | ```properties
| Disable the default security      | Create a `@Configuration` class extending `WebSecurityConfigurerAdapter` (Spring Boot 2.x) or use `SecurityFilterChain` bean (Spring Boot 3.x) |
| Turn off security completely      | Add `@EnableWebSecurity` and configure to permit all (not recommended for production)          |

### Quick example – disable security (for development only)

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .anyRequest().permitAll()   // ← allow everything
            )
            .csrf().disable();              // optional: disable CSRF for testing
        return http.build();
    }
}
```

### Summary – Where do they come from?

| Feature                    | Source / Origin                                      |
|----------------------------|------------------------------------------------------|
| Login dialog (GUI popup)   | Browser + HTTP Basic Auth (enabled by Spring Security) |
| Username `user`            | Default created by Spring Security auto-configuration |
| Random password            | Generated and printed to console by Spring Security   |
| Protection of all endpoints| Default behavior when `spring-boot-starter-security` is on the classpath |

So in short:  
*Spring Security adds protection + default user automatically as soon as you add the dependency.*

That's why you suddenly see a login popup and need credentials.

###### Tags : [[1 - Spring Security 🍌]]