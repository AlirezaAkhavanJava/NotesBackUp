
# STEP 1 : 

### First steps of Spring Security

1. **Add Spring Security dependency**  
    Without the dependency, nothing works.  
    Maven:
    
    ```xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    ```
    
2. **Spring Security auto-config kicks in**  
    Once the dependency is added:
    
    - All endpoints become protected
        
    - Default login form appears
        
    - A random password is printed in logs  
        No config class needed yet.
        
3. **THEN you create `WebSecurityConfig`**  
    This is where you **override** the default behavior.
    
    Example (Spring Security 6+ / Spring Boot 3+):
    
    ```java
    @Configuration
    @EnableWebSecurity
    public class WebSecurityConfig {
    
        @Bean
        public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
            http
                .csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth
                    .requestMatchers("/public/**").permitAll()
                    .anyRequest().authenticated()
                )
                .formLogin();
    
            return http.build();
        }
    }
    ```
    


##### Tags : [[1 - Spring Security 🍌]]