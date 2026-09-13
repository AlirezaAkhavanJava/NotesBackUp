# ✅ What is CSRF?

**CSRF = Cross-Site Request Forgery.**  
An attacker tricks a logged-in user into sending a request to your website (e.g., changing password, sending money) **without their intention**.

Spring Security protects against this by default.


![[Pasted image 20251123121005.png]]

---

# ✅ How CSRF works in Spring Security (the truth)

- For **non-GET** requests (POST, PUT, DELETE, PATCH), Spring Security **requires a CSRF token**.
    
- If the token is missing or invalid → **403 Forbidden**.
    
- The token must be included in the form or AJAX request.
    

---

# 🔒 Default behavior in modern Spring Security (Spring Boot 3 / Spring Security 6)

**CSRF is enabled by default**, unless you explicitly disable it.

You do NOT need this unless you disable it:

```java
http.csrf().disable();
```

But don’t disable it unless you're building:

- a **public API** (no session)
    
- using **JWT tokens**
    
- using **stateless security**
    

---

# 🔑 Add CSRF token in a form (Thymeleaf example)

```html
<form action="/update-email" method="post">
    <input type="hidden" name="_csrf" th:value="${_csrf.token}">
    <button type="submit">Save</button>
</form>
```

---

# 🔑 Add CSRF token in AJAX (fetch example)

```javascript
const token = document.querySelector('meta[name="_csrf"]').content;
const header = document.querySelector('meta[name="_csrf_header"]').content;

fetch("/update", {
    method: "POST",
    headers: {
        [header]: token,
        "Content-Type": "application/json"
    },
    body: JSON.stringify({name: "Ethan"})
});
```

---

# 📌 CSRF for REST API?

If your API is **stateless + uses JWT** → disable CSRF:

```java
http
    .csrf(csrf -> csrf.disable());
```

---

# 📌 CSRF with Spring Security configuration (modern style)

```java
@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http
        .csrf(csrf -> csrf
            .ignoringRequestMatchers("/api/**") // no CSRF for REST API
        )
        .authorizeHttpRequests(auth -> auth
            .anyRequest().authenticated()
        );

    return http.build();
}
```



##### Tags : [[1 - Spring Security 🍌]]