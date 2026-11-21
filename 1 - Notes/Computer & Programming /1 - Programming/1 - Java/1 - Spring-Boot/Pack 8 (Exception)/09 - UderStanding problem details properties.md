
 `ProblemDetail` is one of the nicest things Spring provides for exception handling. And yes, this fellow can save you from writing a lot of repetitive error-response code.

Let's understand why it exists.

## **1. What is ProblemDetail?**

`ProblemDetail` is a Spring class that represents an HTTP API error response.

It's based on **RFC 9457 (Problem Details for HTTP APIs)**, a standard for communicating errors in REST APIs.

Instead of returning arbitrary error structures, you return a standardized format.

For example, imagine a user submits incorrect credentials.

Without `ProblemDetail`, you might return:

```
{
  "error": "Unauthorized",
  "message": "Invalid username or password"
}
```

With `ProblemDetail`:

```
{
  "type": "about:blank",
  "title": "Unauthorized",
  "status": 401,
  "detail": "Invalid username or password",
  "instance": "/api/auth/login"
}
```

Notice that the response has standardized fields.

## **2. Understanding its properties**

These are the important properties:

|Property|Purpose|
|---|---|
|`type`|URI identifying the type of problem|
|`title`|Short, human-readable summary|
|`status`|HTTP status code|
|`detail`|Explanation specific to this occurrence|
|`instance`|URI identifying the specific occurrence|

You can also add custom properties using `setProperty()`.

For example:

```
problemDetail.setProperty("timestamp", Instant.now());
```

This adds a `timestamp` field to the JSON response.

## **3. Creating a ProblemDetail**

Spring provides a static factory method:

```
ProblemDetail.forStatusAndDetail(
    HttpStatus.UNAUTHORIZED,
    "Invalid username or password"
);
```

Let's use it in a global exception handler.

```
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BadCredentialsException.class)
    public ProblemDetail handleBadCredentials(
            BadCredentialsException ex) {

        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.UNAUTHORIZED,
                "Invalid username or password"
        );

        problem.setTitle("Authentication Failed");

        return problem;
    }
}
```

That's it.

Spring converts the returned `ProblemDetail` into an HTTP response with the appropriate status and problem JSON representation.

HTTP 401

## **4. Adding custom properties**

This is where things get interesting.

Suppose you want to include additional information in your error response.

```
ProblemDetail problem = ProblemDetail.forStatusAndDetail(
        HttpStatus.BAD_REQUEST,
        "One or more fields contain invalid values"
);

problem.setTitle("Validation Failed");

problem.setProperty("errors", errors);

problem.setProperty("timestamp", Instant.now());
```

Your response could look like this:

```
{
  "type": "about:blank",
  "title": "Validation Failed",
  "status": 400,
  "detail": "One or more fields contain invalid values",
  "instance": "/api/users/register",
  "errors": {
    "username": "Username is required",
    "email": "Invalid email address"
  },
  "timestamp": "2026-11-21T08:30:00Z"
}
```

Notice that `errors` is a custom property. It doesn't have to be a `String`; it can contain a `Map`, a list, or another serializable object.

## **5. ProblemDetail vs. Map vs. Custom DTO**

|Approach|Advantages|Disadvantages|
|---|---|---|
|`Map<String, String>`|Simple and flexible|No predefined structure|
|Custom DTO|Full control and type safety|Requires defining your own class|
|`ProblemDetail`|Standardized HTTP error format|Less freedom over standard properties|

My recommendation: use `ProblemDetail` for your REST API's error responses.

## **6. One important Spring Boot detail**

Spring also provides `ResponseEntityExceptionHandler`.

It's a base class designed for handling Spring MVC exceptions.

You can extend it:

```
@RestControllerAdvice
public class GlobalExceptionHandler
        extends ResponseEntityExceptionHandler {
}
```

This gives you access to methods for customizing built-in exception handling, including validation errors.

For example, you can override `handleMethodArgumentNotValid()` instead of manually catching every `MethodArgumentNotValidException`.

## **7. What I want you to understand**

There are three separate responsibilities here:

- **Exception:** Represents the exceptional condition.
    
- **Exception handler:** Decides how to handle that condition.
    
- **ProblemDetail:** Represents the HTTP response describing the problem.
    

They are not the same thing.

Think of it like this:

```
BadCredentialsException
        |
        v
GlobalExceptionHandler
        |
        v
ProblemDetail
        |
        v
HTTP 401 Response
        |
        v
Frontend
```

**A final architectural tip:** Never expose internal exception messages directly to clients by blindly using `ex.getMessage()`. Some exceptions contain database details, SQL information, or internal implementation details. Prefer controlled, client-safe messages.

### **A question to test your understanding**

Suppose a user tries to register with an email that already exists.

You throw:

```
throw new EmailAlreadyExistsException("Email already exists");
```

Which HTTP status would you choose?

- `400 Bad Request`
    
- `401 Unauthorized`
    
- `409 Conflict`
    
- `500 Internal Server Error`
    

Choose `409 Conflict`, because the request conflicts with the current state of the resource.



[[Spring Framework]]