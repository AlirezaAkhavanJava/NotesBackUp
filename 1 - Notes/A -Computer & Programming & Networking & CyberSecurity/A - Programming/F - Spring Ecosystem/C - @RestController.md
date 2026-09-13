
`@RestController` and `@Controller` are both **Spring MVC annotations**, but they behave differently:

---

### **`@Controller`**

- Marks a class as a **Spring MVC controller**.
    
- Used in **web applications with views** (like Thymeleaf, JSP).
    
- Methods usually return a **View name** (HTML page) or a `ModelAndView`.
    
- If you want to return raw data (like JSON), you must also use `@ResponseBody`.
    

Example:

```java
@Controller
public class MyController {
    @GetMapping("/hello")
    public String hello(Model model) {
        model.addAttribute("msg", "Hello World");
        return "hello"; // returns hello.html (via Thymeleaf or JSP)
    }
}
```

---

### **`@RestController`**

- A shortcut for `@Controller + @ResponseBody`.
    
- Used in **REST APIs** (returning JSON/XML instead of views).
    
- All methods automatically serialize return values (Java object → JSON).
    

Example:

```java
@RestController
public class MyRestController {
    @GetMapping("/hello")
    public String hello() {
        return "Hello World"; // returns plain text or JSON
    }

    @GetMapping("/user")
    public User getUser() {
        return new User("Ethan", 25); 
        // will be converted to JSON: {"name":"Ethan","age":25}
    }
}
```

---

✅ **Main Difference:**

- `@Controller` → For web apps with **views (HTML, JSP, Thymeleaf)**.
    
- `@RestController` → For **REST APIs**, returns **JSON/XML directly**.
    



---

### **Source Annotation Composition**

If you check Spring’s source code:

```java
@Target(value=TYPE)
@Retention(value=RUNTIME)
@Documented
@Controller
@ResponseBody
public @interface RestController {
    @AliasFor(annotation = Controller.class)
    String value() default "";
}
```

---

### **What this means:**

1. **`@Controller` is inside it** → So the class is still treated as a Spring MVC controller.
    
2. **`@ResponseBody` is also inside it** → So every method in the class automatically has `@ResponseBody`.
    
    - That means Spring won’t look for a **view (HTML/JSP)**.
        
    - Instead, it **serializes the return value into the HTTP response** (usually JSON).
        

---

### **Key Takeaway**

- `@RestController = @Controller + @ResponseBody`
    
- Saves you from writing `@ResponseBody` on every method.
    

---
### Example Entity

```java
public class User {
    private String name;
    private int age;

    // constructor, getters, setters
    public User(String name, int age) {
        this.name = name;
        this.age = age;
    }
}
```

---

### **Case 1: Using `@Controller`**

```java
@Controller
public class MyController {

    // Returns a view (like hello.html)
    @GetMapping("/page")
    public String page(Model model) {
        model.addAttribute("msg", "Hello from Controller!");
        return "hello"; // resolves to hello.html (Thymeleaf/JSP)
    }

    // Must add @ResponseBody to return raw data
    @GetMapping("/user")
    @ResponseBody
    public User getUser() {
        return new User("Ethan", 25);
    }
}
```

👉 `/page` → Renders `hello.html` (view)  
👉 `/user` → Returns JSON: `{"name":"Ethan","age":25}` (because of `@ResponseBody`)

---

### **Case 2: Using `@RestController`**

```java
@RestController
public class MyRestController {

    // Automatically returns raw text
    @GetMapping("/page")
    public String page() {
        return "Hello from RestController!";
    }

    // Automatically returns JSON
    @GetMapping("/user")
    public User getUser() {
        return new User("Ethan", 25);
    }
}
```

👉 `/page` → Just returns text: `"Hello from RestController!"`  
👉 `/user` → Returns JSON: `{"name":"Ethan","age":25}`

---

✅ **So the difference:**

- With `@Controller`, Spring assumes **views** unless you force it with `@ResponseBody`.
    
- With `@RestController`, Spring assumes **JSON/XML** always.
    

---



##### Tags : [[0 - Spring Framework]]