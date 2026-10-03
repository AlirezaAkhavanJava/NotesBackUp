

```java
@Configuration  
@EnableWebSecurity  
public class WebSecurityConfig {  
  
    @Bean  
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {  
  
        http  
                .csrf(AbstractHttpConfigurer::disable) /*no csrf for now*/  
                .authorizeHttpRequests(  
                authorizeRequests -> authorizeRequests.anyRequest()  
                        .authenticated()) /*Authenticate any request*/  
                .formLogin(Customizer.withDefaults()) /*give a form login not pop up*/  
                .httpBasic(Customizer.withDefaults()) /*Authenticate with basic http*/;  
  
        return http.build();  
    }}
```

### 1️⃣ Class and Annotations

```java
@Configuration
@EnableWebSecurity
public class WebSecurityConfig {
```

- `@Configuration` → This class **provides beans** for Spring. Basically, Spring will look inside and use anything marked with `@Bean`.
    
- `@EnableWebSecurity` → **turns on Spring Security** for your app. Without this, your security config won’t even be used.
    

So this class is **where you configure security rules**.

---

### 2️⃣ Defining the SecurityFilterChain Bean

```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
```

- `@Bean` → Tells Spring: “Use the returned object as a bean in the application context.”
    
- `SecurityFilterChain` → This bean **defines how requests are filtered for security**.
    
- `HttpSecurity http` → Spring passes this object so you can **configure authentication, authorization, login forms, CSRF, etc.**
    

Basically, this method **builds the security rules for your app**.

---

### 3️⃣ Disabling CSRF

```java
http.csrf(AbstractHttpConfigurer::disable)
```

- CSRF = Cross-Site Request Forgery (security for web forms).
    
- Right now, you **disable it** because maybe you’re just testing or building an API.
    
- Later, if you make a real web app, you probably **want CSRF enabled** for forms.
    

---

### 4️⃣ Authorization Rules

```java
.authorizeHttpRequests(
        authorizeRequests -> authorizeRequests.anyRequest().authenticated())
```

- `.authorizeHttpRequests(...)` → Define **who can access what**.
    
- `anyRequest().authenticated()` → Every request **must be logged in** (authenticated) to access anything.
    

So right now, **any page you try to access will ask for login**.

---

### 5️⃣ Form Login

```java
.formLogin(Customizer.withDefaults())
```

- Enables **Spring Security’s default login form** (you don’t have to make your own HTML yet).
    
- When you go to any page, if you are not logged in, **Spring shows a login form**.
    
- `Customizer.withDefaults()` → Just “use the default behavior” (default login page, default login URL `/login`).
    

---

### 6️⃣ HTTP Basic Authentication

```java
.httpBasic(Customizer.withDefaults());
```

- HTTP Basic = a **popup login** in the browser (username/password).
    
- Useful for APIs or testing, but not very user-friendly for a web app.
    
- You **can have both** form login (HTML form) and HTTP basic (popup).
    

---

### 7️⃣ Build the Chain

```java
return http.build();
```

- After configuring `http`, you **build the `SecurityFilterChain`**.
    
- Spring will now use this chain for all incoming requests.
    

---

### 🔑 Summary of This Config

1. CSRF disabled.
    
2. Every request **requires authentication**.
    
3. Users can log in **via a web form or HTTP basic popup**.
    
4. SecurityFilterChain bean is created and used by Spring automatically.
    

So if you start the app now, **any page you visit will show a login form** (Spring default login page). Once you log in, Spring will keep track of your authentication via the **SecurityContext**.

---

💡 **Extra Beginner Tip**: Right now you haven’t defined **users** yet. Spring Security will **create a default user** automatically with a random password in the console when the app starts. Later, you’ll want to **define your own users and passwords**.

---

##### Tags : [[1 - Spring Security 🍌]]