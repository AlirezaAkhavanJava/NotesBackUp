


## The problem it solves

Imagine you are logged into your bank's website (`bank.com`) in your browser. Your browser holds a "session cookie" that proves you are logged in. 

Now, you open a new tab and visit a malicious site (`evil.com`). Hidden on `evil.com` is a tiny, invisible form that automatically submits to `bank.com/transfer-money`. 

Because your browser automatically attaches your `bank.com` session cookie to *every* request sent to `bank.com`, the bank's server thinks, "Ah, this is the user, and they want to transfer money!" The hacker just tricked your browser into making a request you did not authorize. This is a **CSRF (Cross-Site Request Forgery) attack**.

The `CsrfToken` solves this by adding a secret, unpredictable value to the request. The hacker at `evil.com` cannot guess this secret value, so the bank's server rejects the fake request.

## The analogy / big picture

Think of a CSRF token like a **secret, single-use VIP wristband** at an exclusive club.

1. When you walk into the club (load a webpage), the bouncer (the server) gives you a unique wristband.
2. The wristband has a secret barcode on it.
3. Every time you want to do something important, like buy a drink or change your profile (a state-changing request), the bartender checks your wristband.
4. If a hacker tries to buy a drink on your behalf from a different club, they cannot, because they do not have your physical wristband.

In Spring Security, the `CsrfToken` is the digital representation of that wristband.

## Part 1: The Interface and the Class

First, a quick clarification: **`CsrfToken` is an interface, not a class.** 

Spring uses this interface to define what a CSRF token looks like. The standard class that actually implements this interface is called `DefaultCsrfToken`. You will rarely create your own implementation; you will just use the interface in your code.

Here is what the `CsrfToken` interface looks like in plain terms:

```java
public interface CsrfToken extends Serializable {
    String getHeaderName();
    String getParameterName();
    String getToken();
}
```

*   `String getHeaderName();`: Returns the name of the HTTP header where the client should send the token (usually `X-CSRF-TOKEN`).
*   `String getParameterName();`: Returns the name of the form parameter where the client should send the token (usually `_csrf`).
*   `String getToken();`: Returns the actual secret string value (the "barcode" on our wristband).

| Method | What it does | Default Value |
| :--- | :--- | :--- |
| `getHeaderName()` | Tells the client which HTTP header to use for AJAX/REST requests. | `X-CSRF-TOKEN` |
| `getParameterName()` | Tells the client which HTML form field to use for standard form submissions. | `_csrf` |
| `getToken()` | The actual secret, randomly generated string. | A long random UUID/hex string |

## Part 2: How it flows (Step-by-Step)

Let us look at how Spring Security manages this wristband behind the scenes.

```text
[Browser / Client]                       [Spring Boot Server]
       |                                         |
       |  1. GET /profile (Load page)            |
       | --------------------------------------> |
       |                                         | 2. CsrfFilter generates a token.
       |                                         | 3. Saves it in HttpSession (The Vault).
       |  4. Returns HTML with the token         |    (via CsrfTokenRepository)
       | <-------------------------------------- |
       |                                         |
       |  5. POST /update-profile                |
       |  (Includes the token in form/header)    |
       | --------------------------------------> |
       |                                         | 6. CsrfFilter extracts the token.
       |                                         | 7. Compares it to the vault.
       |  8. Returns 200 OK (or 403 Forbidden)   |
       | <-------------------------------------- |
```

1.  **The Request:** You request a page.
2.  **Generation:** Spring's `CsrfFilter` intercepts the request. It asks the `CsrfTokenRepository` for a token.
3.  **Storage:** The repository (by default, `HttpSessionCsrfTokenRepository`) saves the token in your server-side HTTP Session.
4.  **Delivery:** The server sends the token to the browser, usually embedded in the HTML.
5.  **The Action:** You submit a form (POST, PUT, DELETE). The browser includes the token.
6.  **Extraction:** The `CsrfFilter` pulls the token out of the request header or parameter.
7.  **Validation:** It checks if the submitted token matches the one in the session.
8.  **Result:** If it matches, the request continues. If not, Spring blocks it with a `403 Forbidden` error.

*Note: Spring only checks CSRF tokens for "unsafe" HTTP methods (POST, PUT, DELETE, PATCH). It ignores safe methods like GET, HEAD, OPTIONS, and TRACE, because those should not change data.*

## Part 3: Using it in Traditional Web Apps (Thymeleaf)

If you are building a standard Spring Boot web app with HTML templates (like Thymeleaf), Spring makes it incredibly easy.

Here is how you write the HTML form:

```html
<form action="/update-profile" method="post">
    <!-- Spring automatically adds the CSRF token here -->
    <input type="hidden" th:name="${_csrf.parameterName}" th:value="${_csrf.token}"/>
    
    <label for="bio">Bio:</label>
    <input type="text" id="bio" name="bio"/>
    
    <button type="submit">Save</button>
</form>
```

*   `<form action="/update-profile" method="post">`: Creates a standard HTML form that will send a POST request.
*   `<input type="hidden" ...`: Creates a hidden field so the user does not see it, but the browser sends it.
*   `th:name="${_csrf.parameterName}"`: Thymeleaf replaces this with `_csrf` (the default parameter name).
*   `th:value="${_csrf.token}"`: Thymeleaf replaces this with the actual secret string generated by the server.
*   `<label ...>` and `<input ...`: Standard form fields for your actual data.
*   `<button ...>`: The submit button.

When the user clicks "Save", the browser sends `_csrf=abc123xyz&bio=Hello`. Spring Security checks `abc123xyz` against the session, and lets it through.

## Part 4: Using it in REST APIs (AJAX / JavaScript)

If you are building a REST API and your frontend is a Single Page Application (React, Vue, or even just JavaScript `fetch`), you cannot use hidden HTML form fields. You must send the token in an HTTP header.

First, you need a way for the frontend to *get* the token. You can expose a simple endpoint in your Spring Boot controller:

```java
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CsrfController {

    @GetMapping("/api/csrf-token")
    public CsrfToken getCsrfToken(CsrfToken token) {
        return token;
    }
}
```

*   `@RestController`: Tells Spring this class handles REST API requests and returns JSON.
*   `@GetMapping("/api/csrf-token")`: Maps HTTP GET requests to this method.
*   `public CsrfToken getCsrfToken(CsrfToken token)`: Spring Security automatically injects the current `CsrfToken` object into this method parameter.
*   `return token;`: Spring converts the `CsrfToken` object into a JSON response like `{"headerName":"X-CSRF-TOKEN","parameterName":"_csrf","token":"abc123xyz"}`.

Then, in your JavaScript frontend, you fetch it and send it back:

```javascript
// 1. Get the token
fetch('/api/csrf-token')
  .then(response => response.json())
  .then(csrfData => {
    
    // 2. Send a POST request with the token in the header
    fetch('/api/update-profile', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        [csrfData.headerName]: csrfData.token // Adds "X-CSRF-TOKEN: abc123xyz"
      },
      body: JSON.stringify({ bio: 'Hello' })
    });
  });
```

*   `fetch('/api/csrf-token')`: Calls our new Spring controller to get the wristband.
*   `.then(response => response.json())`: Parses the JSON response.
*   `fetch('/api/update-profile', { ... })`: Makes the actual state-changing POST request.
*   `method: 'POST'`: Specifies this is a POST request (which requires CSRF protection).
*   `headers: { ... }`: Sets the HTTP headers.
*   `[csrfData.headerName]: csrfData.token`: Dynamically uses the header name (`X-CSRF-TOKEN`) and sets its value to the secret token.
*   `body: JSON.stringify(...)`: Sends the actual data.

## Part 5: The Big Gotcha - Stateless APIs (JWT)

Here is a crucial real-world detail. **If your API uses JWTs (JSON Web Tokens) stored in local storage, you do not need CSRF protection.**

Why? Because CSRF relies on the browser *automatically* sending cookies. Browsers do not automatically send custom HTTP headers (like `Authorization: Bearer <jwt>`). Therefore, a hacker at `evil.com` cannot trick the browser into sending your JWT.

If you are using stateless JWT authentication, you should disable CSRF in your Spring Security configuration to avoid unnecessary overhead and bugs.

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            // Disable CSRF because we are using stateless JWTs
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth
                .anyRequest().authenticated()
            );
            
        return http.build();
    }
}
```

*   `@Configuration`: Marks this class as a source of bean definitions for the Spring application context.
*   `@Bean`: Tells Spring to manage the returned object as a bean in the container.
*   `public SecurityFilterChain filterChain(...)`: Defines the security rules for our app.
*   `.csrf(csrf -> csrf.disable())`: This is the magic line. It turns off the `CsrfFilter` entirely.
*   `.authorizeHttpRequests(...)`: Sets up the rest of the security rules (requiring authentication for all requests).
*   `return http.build();`: Compiles the configuration and returns the filter chain.

## Try it yourself

Let us test this on your Debian 13 machine using the terminal. 

Assuming you have a Spring Boot app running on `localhost:8080` with default CSRF protection enabled, try this:

**1. The Failed Attack (Missing Token)**
Open your terminal and run:
```bash
curl -X POST http://localhost:8080/update-profile -d "bio=hacked" -v
```
*   `-X POST`: Tells curl to use the POST method.
*   `-d "bio=hacked"`: Sends the form data.
*   `-v`: Verbose mode, so we can see the HTTP response codes.
*   *Result:* You will get a `403 Forbidden` and a message about "Invalid CSRF Token". The bouncer stopped the hacker!

**2. The Successful Request (With Token)**
First, get a valid token by visiting the login page or a page that generates one, and copy the `_csrf` value from the HTML or cookie. Then run:
```bash
curl -X POST http://localhost:8080/update-profile \
     -H "X-CSRF-TOKEN: your_copied_token_here" \
     -d "bio=hello_world" \
     -H "Cookie: JSESSIONID=your_session_id_here" \
     -v
```
*   `-H "X-CSRF-TOKEN: ..."`: Sends the secret wristband in the header.
*   `-H "Cookie: JSESSIONID=..."`: Sends the session cookie so the server knows which session to check the token against.
*   *Result:* You will get a `200 OK` or `302 Redirect`. The bouncer checked the wristband and let you in!

## Common mistakes

| Mistake | Why it hurts | How to fix it |
| :--- | :--- | :--- |
| **Disabling CSRF for everything** | Leaves session-based apps wide open to CSRF attacks. | Only disable it if you are 100% sure you are using stateless authentication (like JWT in headers). |
| **Using GET for state changes** | Spring does not check CSRF tokens for GET requests. A hacker can trigger a GET request via an `<img src="...">` tag. | Always use POST, PUT, PATCH, or DELETE for actions that change data. |
| **Forgetting the token in AJAX** | The frontend sends a POST request without the header. The server rejects it with a 403. | Ensure your frontend fetches the token and adds it to the `X-CSRF-TOKEN` header for every state-changing request. |
| **Token expires but page is still open** | If the user leaves the tab open for hours, the server session might expire, invalidating the token. | Handle 403 errors gracefully in the frontend, or configure your session timeout to be long enough. |

## Related concept, briefly

**CORS (Cross-Origin Resource Sharing):** While CSRF is about tricking a browser into making an unwanted request, CORS is a browser security feature that *blocks* a website from reading the response of a request made to a different domain. If `evil.com` tries to fetch data from `bank.com`, the browser blocks it unless `bank.com` explicitly allows it via CORS headers. CORS and CSRF work together to keep cross-origin interactions safe.

## The whole picture

| Question | Answer |
| :--- | :--- |
| **What is `CsrfToken`?** | An interface representing a secret token used to prevent CSRF attacks. |
| **What is the default implementation?** | `DefaultCsrfToken`. |
| **Where is it stored on the server?** | By default, in the HTTP Session (`HttpSessionCsrfTokenRepository`). |
| **How does the client send it back?** | In a hidden form field (`_csrf`) or an HTTP header (`X-CSRF-TOKEN`). |
| **Which HTTP methods require it?** | POST, PUT, DELETE, PATCH (any "unsafe" method). |
| **When should I disable it?** | When using stateless authentication like JWTs in custom headers. |





[[Spring Security]]