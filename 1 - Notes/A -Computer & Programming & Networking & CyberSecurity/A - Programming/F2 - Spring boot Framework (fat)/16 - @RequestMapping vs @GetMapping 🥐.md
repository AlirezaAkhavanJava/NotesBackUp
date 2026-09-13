
`@RequestMapping` and `@GetMapping` both **map HTTP requests to handler methods** in Spring, but neither one _automatically calls_ a method.

Here’s the difference:

- `@RequestMapping` is **generic** — it can handle any HTTP method (GET, POST, PUT, DELETE, etc.) depending on what you specify.
    
    ```java
    @RequestMapping("/hello")
    public String sayHello() { ... }
    ```
    
    By default, it responds to **all HTTP methods**, unless you restrict it:
    
    ```java
    @RequestMapping(value="/hello", method=RequestMethod.GET)
    public String sayHello() { ... }
    ```
    
- `@GetMapping` is a **shortcut** for `@RequestMapping(method = RequestMethod.GET)`.
    
    ```java
    @GetMapping("/hello")
    public String sayHello() { ... }
    ```
    

So both get called **only when** an HTTP request hits that route.  
Nothing is “automatically called” — Spring just _routes_ the incoming request to the right method.

**Summary:**

- `@RequestMapping` = general-purpose.
    
- `@GetMapping` = specific for GET requests.
    
- Neither one “auto-calls” — they respond to requests coming to their mapped URL.
##### [[0 - Spring Framework]]