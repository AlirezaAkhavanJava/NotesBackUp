

# HTTP Basic Authentication in Spring Security

HTTP Basic Authentication is a simple authentication mechanism that allows a client to prove its identity by sending a username and password with an HTTP request.

Spring Security supports this mechanism through a security filter called `BasicAuthenticationFilter`.

Before learning the Spring Security implementation, you need to understand how Basic Authentication works at the HTTP level.

## The problem it solves

Imagine you have developed a Spring Boot REST API with this endpoint:

```
@GetMapping("/api/users")
public List<User> getUsers() {
    return userService.findAll();
}
```

- `@GetMapping` maps HTTP GET requests to this method.
    
- `/api/users` is the endpoint URL.
    
- `userService.findAll()` retrieves the users.
    

Without security, anyone who can reach this endpoint can potentially retrieve your users.

You want to allow only authenticated users to access it.

For example:

|Client|Credentials|Result|
|---|---|---|
|Alice|Valid|Allowed|
|Bob|Wrong password|Rejected|
|Anonymous|Missing|Rejected|

Basic Authentication provides a standard way for clients to send credentials and for servers to authenticate them.

## The analogy / big picture

Imagine a building with a security guard.

Every time you enter, the guard asks for your username and password. The guard checks them against an authorized list.

Even if you entered the building five minutes ago, you must show your credentials again when you return.

That is roughly how HTTP Basic Authentication works when used with a stateless REST API.

Unlike session-based authentication, Basic Authentication does not require the server to remember that you previously logged in.

## Part 1 — How Basic Authentication works

Basic Authentication is defined by the HTTP authentication framework, particularly RFC 7617.

The client sends credentials using the `Authorization` HTTP header.

### Step 1 — The client prepares its credentials

Assume your credentials are:

|Field|Value|
|---|---|
|Username|`alireza`|
|Password|`secret123`|

The client combines them into a single string, separated by a colon:

`alireza:secret123`

Then it encodes that string using Base64.

Base64 is an encoding format that represents binary data as printable text. It is not encryption.

You can experiment with it on Debian:

```
printf 'alireza:secret123' | base64
```

- `printf` prints the username and password without adding a newline.
    
- `|` sends that output to the next command.
    
- `base64` encodes the text.
    

The result is:

```
YWxpcmV6YTpzZWNyZXQxMjM=
```

This value is not secure by itself. Anyone who obtains it can decode the credentials.

### Step 2 — The client sends the HTTP request

```
GET /api/users HTTP/1.1
Host: localhost:8080
Authorization: Basic YWxpcmV6YTpzZWNyZXQxMjM=
```

- `GET /api/users` requests the protected resource.
    
- `Host` identifies the destination server.
    
- `Authorization` carries the authentication information.
    
- `Basic` identifies the authentication scheme.
    
- The remaining value is the Base64 representation of `username:password`.
    

### Step 3 — Spring Security intercepts the request

Before your controller receives the request, Spring Security processes it through its security filter chain.

A filter is a component that can inspect, modify, or reject HTTP requests before they reach a controller.

The relevant processing flow is:

HTTP Request

Spring Security Filter Chain

BasicAuthenticationFilter

AuthenticationManager

AuthenticationProvider

UserDetailsService + PasswordEncoder

Authenticated, or authentication fails

This is a simplified authentication path. Other Spring Security filters also participate in request processing.

Let's understand each component.

|Component|Responsibility|
|---|---|
|`BasicAuthenticationFilter`|Extracts and decodes Basic credentials|
|`AuthenticationManager`|Coordinates authentication|
|`AuthenticationProvider`|Performs a particular type of authentication|
|`UserDetailsService`|Loads user information|
|`PasswordEncoder`|Verifies the supplied password against the stored hash|
|`SecurityContextHolder`|Provides access to the current security context|

By default, a typical username/password configuration uses `DaoAuthenticationProvider`, which works with `UserDetailsService` and `PasswordEncoder`.

### Step 4 — Spring Security verifies the credentials

For example, suppose the database contains:

|Username|Stored password|
|---|---|
|alireza|BCrypt password hash|

Spring Security does not need to store plaintext passwords.

Instead, `PasswordEncoder.matches()` checks whether the supplied password matches the stored hash.

If authentication succeeds, Spring Security stores an authenticated `Authentication` object in the security context for the current request.

Authorization rules then decide whether the authenticated user is allowed to access the endpoint.

Authentication answers "Who are you?" Authorization answers "What are you allowed to access?"

## Part 2 — Configure Basic Authentication in Spring Boot

Let's build a minimal example using the modern `SecurityFilterChain` configuration style.

First, add the Spring Security starter dependency to your Spring Boot project.

For Maven:

```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

- `<dependency>` declares a project dependency.
    
- `<groupId>` identifies the Spring Boot project group.
    
- `<artifactId>` identifies the security starter artifact.
    

The starter provides Spring Security's core infrastructure and web security integration.

### Create the SecurityConfig class

```
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http)
            throws Exception {

        return http
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/public/**").permitAll()
                        .anyRequest().authenticated()
                )
                .httpBasic(Customizer.withDefaults())
                .build();
    }
}
```

Line-by-line explanation:

- `@Configuration`: Tells Spring this class defines configuration beans.
    
- `@EnableWebSecurity`: Enables Spring Security web security configuration; in typical Spring Boot applications, much of the web security setup is already auto-configured.
    
- `@Bean`: Registers the returned object in the Spring container.
    
- `SecurityFilterChain`: Defines the security rules and filters for HTTP requests.
    
- `HttpSecurity`: Provides the API for configuring web security.
    
- `authorizeHttpRequests()`: Configures authorization rules.
    
- `requestMatchers("/public/**").permitAll()`: Allows requests to matching public paths without requiring authentication.
    
- `anyRequest().authenticated()`: Requires authentication for every other request.
    
- `httpBasic(Customizer.withDefaults())`: Enables HTTP Basic Authentication with default settings.
    
- `build()`: Builds the configured security filter chain.
    

The important part is:

`httpBasic(Customizer.withDefaults())`

This enables Spring Security's Basic Authentication support.

Important: This configuration does not disable CSRF protection or automatically make the application stateless. Those are separate configuration decisions.

### Configure a test user

For learning, we can create an in-memory user.

```
@Bean
UserDetailsService userDetailsService(PasswordEncoder encoder) {

    UserDetails user = User.withUsername("alireza")
            .password(encoder.encode("secret123"))
            .roles("USER")
            .build();

    return new InMemoryUserDetailsManager(user);
}

@Bean
PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}
```

Line-by-line explanation:

- `@Bean`: Registers the objects in Spring.
    
- `UserDetailsService`: Defines how Spring Security retrieves user information.
    
- `PasswordEncoder encoder`: Injects the password encoder bean.
    
- `User.withUsername(...)`: Starts creating a Spring Security user.
    
- `.password(encoder.encode(...))`: Stores a password hash rather than plaintext.
    
- `.roles("USER")`: Assigns the `USER` role, represented internally as `ROLE_USER`.
    
- `.build()`: Creates the user.
    
- `InMemoryUserDetailsManager`: Stores the user in memory rather than a database.
    
- `passwordEncoder()`: Defines the encoder used for password verification.
    
- `BCryptPasswordEncoder`: Implements password hashing using BCrypt.
    

This is suitable for experimentation, not for production credential management. Never commit real passwords to source control.

## Part 3 — Test it yourself

Create a protected controller:

```
@RestController
public class TestController {

    @GetMapping("/api/hello")
    public String hello() {
        return "Hello, authenticated user!";
    }
}
```

- `@RestController`: Marks the class as a REST controller.
    
- `@GetMapping("/api/hello")`: Maps GET requests to the method.
    
- `hello()`: Returns the response text.
    

Now start Spring Boot and test the endpoint using your Debian terminal.

### Test 1 — Without credentials

```
curl -i http://localhost:8080/api/hello
```

- `curl` sends an HTTP request.
    
- `-i` includes response headers.
    
- The URL points to your protected endpoint.
    

Expected response status:

`401 Unauthorized`

Spring Security will normally also send a `WWW-Authenticate` challenge indicating that Basic Authentication is supported.

### Test 2 — With valid credentials

```
curl -i -u alireza http://localhost:8080/api/hello
```

- `-i` displays the response headers.
    
- `-u alireza` selects the Basic Authentication username and lets curl prompt for the password, avoiding putting it directly in shell history.
    
- Enter `secret123` when prompted.
    

Expected result:

`200 OK`

Response body:

`Hello, authenticated user!`

### Test 3 — With incorrect credentials

Run the same command, but enter an incorrect password.

Expected result:

`401 Unauthorized`

Spring Security rejects the authentication attempt.

## Part 4 — HTTP status codes

Two status codes are especially important when working with Spring Security.

|Status|Meaning|Example|
|---|---|---|
|`200 OK`|Request succeeded|Valid credentials and access granted|
|`401 Unauthorized`|Authentication required or failed|Missing or incorrect credentials|
|`403 Forbidden`|Access denied|Authenticated user lacks required permission|

A `401` response commonly includes `WWW-Authenticate: Basic ...`, which tells the client how to authenticate.

A `403` response means access is denied. In a typical configuration, this happens when authentication succeeded but authorization failed.

## Part 5 — Is Basic Authentication secure?

Basic Authentication is not inherently insecure, but it must be deployed correctly.

The critical issue is that Base64 is reversible. Anyone who obtains the encoded credentials can recover the username and password.

Therefore, Basic Authentication must use HTTPS in real applications.

HTTPS protects credentials while they travel between the client and the TLS endpoint.

Other considerations:

|Concern|Why it matters|Recommended practice|
|---|---|---|
|HTTP without TLS|Credentials can be intercepted|Enforce HTTPS|
|Repeated credentials|Every request may expose reusable credentials|Protect transport and client storage|
|Brute-force attacks|Attackers can try many passwords|Rate limiting and monitoring|
|Password storage|Plaintext leaks expose passwords|Use BCrypt or another suitable password hasher|
|Logout|No built-in token invalidation|Understand client credential caching|
|CSRF|Browsers may automatically attach cached credentials|Evaluate CSRF protection for browser clients|

Basic Authentication is often reasonable for internal tools, controlled service integrations, and simple development environments when HTTPS and appropriate operational controls are in place.

It is generally less suitable for modern public-facing applications that need user login flows, multifactor authentication, or delegated access.

## Part 6 — Basic Authentication vs JWT vs Sessions

|Feature|Basic Auth|Session Auth|JWT Bearer Auth|
|---|---|---|---|
|Client sends|Username/password|Session cookie|Token|
|Server-side session required|No|Usually yes|Not necessarily|
|Credentials verified|Typically each request|At login|During token issuance|
|Revocation|Change credentials|Invalidate session|Depends on token design|
|Typical use|Simple API authentication|Browser web apps|APIs and distributed systems|

A key difference: Basic Authentication carries reusable login credentials. JWT Bearer Authentication usually carries a token issued after authentication.

A JWT is not automatically encrypted, and JWT-based systems are not automatically more secure.

## Common mistakes

|Mistake|Why it hurts|How to fix|
|---|---|---|
|Thinking Base64 is encryption|Credentials are easily decoded|Always use HTTPS|
|Storing plaintext passwords|Database compromise reveals passwords|Use `PasswordEncoder`|
|Confusing `401` and `403`|Incorrect debugging|Separate authentication from authorization|
|Assuming Basic Auth creates sessions|Misunderstands authentication state|Configure session management explicitly|
|Disabling CSRF everywhere|Can expose browser-based applications|Assess the client's credential behavior|
|Using hardcoded production users|Secrets end up in source code|Use secure configuration and user storage|

## Related concept, briefly — Stateless authentication

A stateless authentication design does not depend on a server-side login session between requests.

HTTP Basic Authentication fits naturally into this design because the client can send credentials on every request.

However, enabling `.httpBasic()` does not automatically configure Spring Security to use `SessionCreationPolicy.STATELESS`.

## The whole picture

|Question|Answer|
|---|---|
|What is Basic Authentication?|An HTTP username/password authentication scheme|
|Why does it exist?|To let clients authenticate using a standard HTTP mechanism|
|How are credentials sent?|In the `Authorization: Basic` header|
|Are credentials encrypted?|No, Base64 only encodes them|
|Which filter processes them?|`BasicAuthenticationFilter`|
|Who checks the password?|An `AuthenticationProvider`, usually using a `PasswordEncoder`|
|Does it need a session?|No|
|Is HTTPS necessary?|Yes, for secure deployment|
|How do you enable it?|`.httpBasic(Customizer.withDefaults())`|
|Is it the same as JWT?|No, JWT-based Bearer Authentication sends a token rather than the username/password|




[[Spring Security]]