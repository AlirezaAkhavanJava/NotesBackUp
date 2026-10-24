

`HttpServletRequest` is one of the most important interfaces in Java web development. It represents an incoming HTTP request received by your Java web application.

When you work with Spring Boot, Spring MVC, Spring Security, authentication, cookies, sessions, and HTTP headers, you'll encounter `HttpServletRequest` frequently.

## The problem it solves

Imagine someone sends this HTTP request to your Spring Boot application:

```
GET /api/users/42?details=true HTTP/1.1
Host: localhost:8080
Authorization: Bearer eyJhbGciOi...
User-Agent: Mozilla/5.0
Accept: application/json
Cookie: JSESSIONID=abc123
```

Your application needs to answer several questions:

- Which endpoint was requested?
    
- Which HTTP method was used?
    
- What query parameters were provided?
    
- Did the client send an authentication token?
    
- Were any cookies included?
    
- What information is available about the client?
    

Instead of forcing you to manually parse the raw HTTP request, the Servlet API provides an object called `HttpServletRequest`.

Its job is to give your Java code access to the incoming HTTP request and its associated information.

## The analogy

Think of an HTTP request as a package delivered to an office.

The package contains an address, sender information, instructions, and sometimes documents.

`HttpServletRequest` is like a structured delivery form that lets you inspect everything associated with that package.

|Package analogy|HTTP equivalent|
|---|---|
|Delivery destination|Request URI|
|Delivery instructions|HTTP method|
|Package labels|HTTP headers|
|Attached documents|Request body|
|Extra options|Query parameters|
|Reference number|Cookies|

One important distinction: `HttpServletRequest` is not the request itself travelling across the network. It's a Java interface representing the request inside the server.

## Part 1 — Where does HttpServletRequest come from?

In modern Jakarta Servlet applications, the interface is:

```
import jakarta.servlet.http.HttpServletRequest;
```

- `jakarta.servlet` contains the Servlet API.
    
- `http` contains HTTP-specific Servlet interfaces and classes.
    
- `HttpServletRequest` provides methods for accessing HTTP request information.
    

Older Spring Boot applications may use `javax.servlet.http.HttpServletRequest`. Spring Boot 3 and newer use the Jakarta namespace.

### Who creates the object?

You don't normally create it yourself.

The Servlet container creates or provides the request object. A Servlet container is the server component responsible for running Servlets, managing incoming requests, and producing responses.

Spring Boot web applications commonly use embedded Tomcat.

Here is the simplified flow:

Client (Browser / Postman)

Sends an HTTP request

HTTP over network

Servlet Container (Tomcat)

Parses the incoming request and provides an HttpServletRequest implementation

Servlet Filters

Including Spring Security filters

DispatcherServlet

Spring MVC's front controller

@RestController

Your endpoint method

HTTP response

Client receives the response

A request can pass through several filters before it reaches your controller. Those filters can inspect the same request, modify certain request-related state, or wrap it with another implementation.

## Part 2 — How do we use it in Spring Boot?

Let's create a simple endpoint.

```
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class RequestController {

    @GetMapping("/request-info")
    public String requestInfo(HttpServletRequest request) {

        String method = request.getMethod();
        String uri = request.getRequestURI();
        String agent = request.getHeader("User-Agent");

        return "Method: " + method
                + "\nURI: " + uri
                + "\nUser-Agent: " + agent;
    }
}
```

### Line-by-line explanation

- `import jakarta.servlet.http.HttpServletRequest` imports the request interface.
    
- `@RestController` tells Spring to use the class for handling web requests and writing response bodies.
    
- `@GetMapping("/request-info")` maps HTTP GET requests to this method.
    
- `HttpServletRequest request` asks Spring MVC to provide the current request object as a method argument.
    
- `request.getMethod()` returns the HTTP method, such as `GET` or `POST`.
    
- `request.getRequestURI()` returns the request's URI path, including the context path if present.
    
- `request.getHeader("User-Agent")` reads the specified HTTP header.
    
- The `return` statement constructs the response body.
    

Notice that we never wrote `new HttpServletRequest()`.

Spring MVC resolves the method argument using the request that the Servlet container supplied.

If you open:

`http://localhost:8080/request-info`

You might receive:

```
Method: GET
URI: /request-info
User-Agent: Mozilla/5.0 ...
```

## Part 3 — Important methods of HttpServletRequest

`HttpServletRequest` gives you many methods. Some are declared directly on this interface, while others are inherited from `ServletRequest`.

### Request information

|Method|Purpose|Example|
|---|---|---|
|`getMethod()`|HTTP method|`POST`|
|`getRequestURI()`|Request URI path|`/api/users`|
|`getRequestURL()`|Reconstructed request URL|`http://localhost:8080/api/users`|
|`getQueryString()`|Raw query string|`page=2`|
|`getHeader("Name")`|HTTP header|`Bearer ...`|
|`getContentType()`|Request content type|`application/json`|
|`getRemoteAddr()`|Immediate remote peer address|`127.0.0.1`|
|`getCookies()`|Cookies supplied by client|`Cookie[]`|
|`getSession()`|Gets or creates HTTP session|`HttpSession`|

`getRequestURL()` excludes the query string. Also, behind reverse proxies, the visible URL and remote address may not match what the original client used.

### Parameters and body

Suppose the client calls:

`GET /api/search?name=Alex&page=2`

You can access the parameters like this:

```
String name = request.getParameter("name");
String page = request.getParameter("page");
```

- `getParameter("name")` returns `"Alex"`.
    
- `getParameter("page")` returns `"2"`.
    
- Both values are strings. You must validate and convert them before treating them as typed application data.
    

A useful distinction:

|Concept|Location|How to access|
|---|---|---|
|Query parameter|URL after `?`|`getParameter()`|
|HTTP header|Header section|`getHeader()`|
|Cookie|`Cookie` header|`getCookies()`|
|JSON body|Request body|`getInputStream()` / Spring `@RequestBody`|
|Path variable|URL path|Spring `@PathVariable`|

`getParameter()` can also read form fields from a supported form-encoded request body. It does not automatically extract properties from arbitrary JSON.

## Part 4 — HttpServletRequest vs @RequestBody vs @RequestParam

You might be wondering:

"If Spring Boot already gives me `@RequestBody`, `@RequestParam`, and `@RequestHeader`, why would I need `HttpServletRequest`?"

Good question.

Spring MVC provides convenient annotations that extract specific parts of the incoming request.

Consider:

```
@GetMapping("/users")
public String findUser(
        @RequestParam String name,
        @RequestHeader("User-Agent") String agent,
        HttpServletRequest request) {

    return "Name: " + name
            + ", Agent: " + agent
            + ", Method: " + request.getMethod();
}
```

- `@GetMapping("/users")` registers a GET endpoint.
    
- `@RequestParam` extracts the `name` query parameter.
    
- `@RequestHeader` extracts the `User-Agent` HTTP header.
    
- `HttpServletRequest` provides access to the request object.
    
- `getMethod()` reads its HTTP method.
    

Both approaches work, but their purposes differ.

|Feature|Spring annotation|HttpServletRequest|
|---|---|---|
|Query parameters|`@RequestParam`|`getParameter()`|
|HTTP headers|`@RequestHeader`|`getHeader()`|
|JSON body|`@RequestBody`|`getInputStream()`|
|Cookies|`@CookieValue`|`getCookies()`|
|Session|`@SessionAttribute`|`getSession()`|
|Client address|No equivalent simple annotation|`getRemoteAddr()`|

Rule: In ordinary Spring MVC controllers, prefer the Spring annotations when you only need specific values. Use `HttpServletRequest` when you need lower-level request access.

## Part 5 — Request attributes vs HTTP session attributes

This is another important distinction.

`HttpServletRequest` allows you to attach arbitrary server-side values to a request.

For example:

```
request.setAttribute("username", "Alex");

String username =
        (String) request.getAttribute("username");
```

- `setAttribute()` stores an object under a name in the current request.
    
- `getAttribute()` retrieves the stored object.
    
- The cast to `String` is necessary because `getAttribute()` returns `Object`.
    

Request attributes can be useful for sharing information between filters, Servlets, and other server components processing the same request.

However, they are different from HTTP session attributes.

|Request attribute|Session attribute|
|---|---|
|Belongs to a request|Belongs to an HTTP session|
|Usually lasts for one request|Can survive multiple requests|
|Stored server-side|Stored server-side or in a configured session store|
|Accessed using `request.getAttribute()`|Accessed using `session.getAttribute()`|

A session can be accessed through the request:

```
HttpSession session = request.getSession();

session.setAttribute("theme", "dark");
```

- `request.getSession()` returns the current session or creates a new one.
    
- `session.setAttribute()` stores a value in that session.
    

To retrieve an existing session without creating one, use `request.getSession(false)`. It returns `null` when no session exists.

A session is not the same thing as a request, and a session cookie is not the session data itself.

## Part 6 — HttpServletRequest in Spring Security

This is where the interface becomes especially useful.

Remember that Spring Security uses a chain of Servlet filters to process requests.

A security filter may need to inspect the `Authorization` header before the request reaches your controller.

For example:

```
import jakarta.servlet.http.HttpServletRequest;

public String extractBearerToken(HttpServletRequest request) {

    String header = request.getHeader("Authorization");

    if (header == null || !header.startsWith("Bearer ")) {
        return null;
    }

    String token = header.substring(7).trim();

    return token.isEmpty() ? null : token;
}
```

- `getHeader("Authorization")` reads the authentication header.
    
- The `if` statement rejects missing headers or headers not beginning with `Bearer` .
    
- `substring(7)` removes the seven characters in `"Bearer "`.
    
- `trim()` removes surrounding whitespace.
    
- The final line rejects an empty token.
    

This is only a simplified token-extraction example, not a complete authentication implementation. A real application must validate the token's format, signature, expiry, intended audience, and other applicable claims.

Also, extracting a token does not mean the user is authenticated.

### Request flow during authentication

```
Client
  |
  | Authorization: Bearer <token>
  v
Tomcat
  |
  | HttpServletRequest
  v
Spring Security Filter Chain
  |
  | Read Authorization header
  | Validate credentials/token
  | Establish authenticated identity
  v
DispatcherServlet
  |
  v
@RestController
  |
  v
HTTP Response
```

Spring Security also provides specialized mechanisms for authentication, such as HTTP Basic, form login, and OAuth2 Resource Server support. In a production application, prefer those built-in implementations rather than writing authentication logic from scratch.

### Related detail: HttpServletRequest and HttpServletResponse

A Servlet filter commonly receives both objects:

```
@Override
protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain filterChain)
        throws ServletException, IOException {

    String method = request.getMethod();

    System.out.println("Incoming method: " + method);

    filterChain.doFilter(request, response);
}
```

- `doFilterInternal()` is a method you override when extending Spring's `OncePerRequestFilter`.
    
- `request` represents the incoming request.
    
- `response` represents the outgoing response.
    
- `filterChain` allows processing to continue through the remaining filters and eventually the target Servlet.
    
- `request.getMethod()` reads the HTTP method.
    
- `System.out.println()` prints that information.
    
- `filterChain.doFilter()` passes processing onward.
    

This example shows only the method body and assumes a correctly configured `OncePerRequestFilter` subclass.

One critical detail: failing to call `filterChain.doFilter()` can prevent the request from reaching subsequent filters or the controller. That can be intentional when rejecting a request, but not for ordinary logging.

## Part 7 — Can we read the request body multiple times?

Normally, no.

The request body is typically exposed as an input stream, which is a sequence of bytes read from the incoming request.

Once the stream has been consumed, another component cannot simply assume the original body is still available.

For example, imagine a filter reads the entire JSON body. Later, Spring MVC tries to deserialize the same body using `@RequestBody`.

Without appropriate handling, Spring may find that the stream has already been consumed.

This matters when implementing logging, auditing, request inspection, or custom filters.

Spring provides `ContentCachingRequestWrapper`, but it has specific caching behavior and does not magically make every consumed request body independently rereadable.

## Common mistakes

|Mistake|Why it hurts|Better approach|
|---|---|---|
|Using `getParameter()` for JSON fields|JSON is not parsed as Servlet parameters|Use `@RequestBody`|
|Trusting `getRemoteAddr()` as the user's identity|IP addresses can be shared, proxied, or change|Use real authentication|
|Storing request objects in singleton fields|Concurrent requests may overwrite each other's state|Use method parameters|
|Reading the body in a filter without planning ahead|Downstream body parsing may fail|Use an appropriate wrapper or processing strategy|
|Using `getSession()` just to check for a session|It may create a new session|Use `getSession(false)`|
|Trusting headers without validation|Client-controlled headers can contain malicious data|Validate and enforce security policies|
|Logging tokens or session IDs|Sensitive credentials can leak to logs|Redact secrets|

A particularly important rule for security: never treat `User-Agent`, forwarded IP headers, or arbitrary request parameters as proof of identity.

## Try it yourself

Start your Spring Boot application with the `/request-info` endpoint from Part 2.

Then, on Debian, run:

```
curl -i \
  -H "User-Agent: MyJavaClient/1.0" \
  http://localhost:8080/request-info
```

- `curl` sends an HTTP request.
    
- `-i` displays response headers along with the response body.
    
- `-H` adds a custom HTTP header.
    
- `http://localhost:8080/request-info` is your endpoint.
    

You should see the method, URI, and your custom `User-Agent` returned by the controller.

Try changing the `User-Agent` value, then modify the controller to access additional request information.

## Related concept, briefly

`HttpServletResponse` represents the outgoing HTTP response. It allows server code to control properties such as status codes, headers, cookies, and response content.

`DispatcherServlet` is Spring MVC's central Servlet. It receives requests after the relevant Servlet filters, selects the appropriate controller handler, coordinates argument resolution, and processes the result.

## The whole picture

|Question|Answer|
|---|---|
|What is `HttpServletRequest`?|An interface representing an incoming HTTP request|
|Who provides it?|The Servlet container|
|Where does it belong?|Jakarta Servlet API|
|Does Spring Boot create it?|Normally the Servlet container creates or supplies the implementation|
|What information does it expose?|Method, URL, headers, parameters, cookies, body, session access, etc.|
|Can it store temporary data?|Yes, using request attributes|
|Can it access HTTP sessions?|Yes, through `getSession()`|
|Is it used by Spring Security?|Yes, extensively in its Servlet filter chain|
|Should every controller use it?|No; prefer specific Spring MVC annotations when appropriate|
|Is it the same as `HttpServletResponse`?|No; one represents the incoming request, the other the outgoing response|

The key mental model: `HttpServletRequest` is the Servlet API's representation of an HTTP request that has arrived at your server. Spring MVC builds higher-level conveniences on top of the Servlet infrastructure, while Spring Security uses that same infrastructure to inspect and secure requests.




[[Spring Security]]