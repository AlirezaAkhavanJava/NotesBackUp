
`@RestController` is a Spring annotation that marks a class as a **RESTful controller** — meaning it handles web requests and automatically returns data (like JSON or text) instead of rendering a view (like an HTML page).

It’s basically a shortcut for:

```java
@Controller
@ResponseBody
```

So instead of writing:

```java
@Controller
public class HelloController {

    @ResponseBody
    @GetMapping("/hello")
    public String sayHello() {
        return "Hello, World!";
    }
}
```

You can just write:

```java
@RestController
public class HelloController {

    @GetMapping("/hello")
    public String sayHello() {
        return "Hello, World!";
    }
}
```

✅ **Key points:**

- Used in REST APIs.
    
- Automatically converts return values to JSON or text.
    
- Every method’s return value goes directly in the HTTP response body (no `@ResponseBody` needed).

##### Tags : [[0 - Spring Framework]]