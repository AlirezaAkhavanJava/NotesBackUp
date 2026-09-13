

# ✅ **1. Core Spring Security Dependency**

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

This gives you:

- AuthenticationManager
    
- ProviderManager
    
- AuthenticationProvider
    
- UserDetailsService
    
- PasswordEncoder
    
- SecurityFilterChain
    

---

# ✅ **2. Web + REST**

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

Needed to expose login endpoints, `/auth/login`, `/api/...`

---

# ✅ **3. JPA (if using DB to store users)**

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
```

---

# ✅ **4. JWT (JJWT – most common)**

Use **JJWT 0.12.x** because older 0.9.1 has security bugs.

```xml
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-api</artifactId>
    <version>0.12.5</version>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-impl</artifactId>
    <version>0.12.5</version>
    <scope>runtime</scope>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-jackson</artifactId>
    <version>0.12.5</version>
    <scope>runtime</scope>
</dependency>
```

Gives you:

- JWT creation
    
- JWT parsing
    
- Signature verification
    

---

# ✅ **5. Lombok (optional but recommended)**

```xml
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
</dependency>
```

---

# 🔥 **Minimum Required for JWT Security Setup**

If you're doing **authentication with username/password** + **JWT token generation** + **JWT filter**:

You need exactly these:

|Purpose|Dependency|
|---|---|
|Security|spring-boot-starter-security|
|JWT|jjwt-api, jjwt-impl, jjwt-jackson|
|DB user storage|spring-boot-starter-data-jpa|
|REST API|spring-boot-starter-web|
|Boilerplate reduction|Lombok|

---

# ⚙️ **Full Example POM Block**

If you want the full block ready to paste:

```xml
<dependencies>

    <!-- Spring Boot Web -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <!-- Spring Boot Security -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>

    <!-- JPA -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>

    <!-- JWT -->
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-api</artifactId>
        <version>0.12.5</version>
    </dependency>
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-impl</artifactId>
        <version>0.12.5</version>
        <scope>runtime</scope>
    </dependency>
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-jackson</artifactId>
        <version>0.12.5</version>
        <scope>runtime</scope>
    </dependency>

    <!-- Lombok -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
    </dependency>

</dependencies>
```



##### Tags : [[1 - Spring Security 🍌]]