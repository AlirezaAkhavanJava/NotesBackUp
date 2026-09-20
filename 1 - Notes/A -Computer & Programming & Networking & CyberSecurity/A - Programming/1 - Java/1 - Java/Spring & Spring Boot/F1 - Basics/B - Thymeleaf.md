In **Spring Boot**, a _dependency_ is what you declare in your `pom.xml` (Maven) or `build.gradle` (Gradle) so Spring knows which libraries to include.

The **Thymeleaf dependency** is the one that brings **Thymeleaf template engine support** into your project. Thymeleaf is used to render dynamic HTML pages on the server side.

---

### Maven (pom.xml)

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
```

### Gradle (build.gradle)

```gradle
implementation 'org.springframework.boot:spring-boot-starter-thymeleaf'
```

---

### What it does:

- Adds **Thymeleaf engine** to the project.
    
- Auto-configures a `SpringTemplateEngine`.
    
- Looks for HTML templates in `src/main/resources/templates/` by default.
    
- Lets you use Thymeleaf expressions like `${}` to insert dynamic data into HTML.
    

---

### Example:

`src/main/resources/templates/index.html`

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <title>Hello</title>
</head>
<body>
    <h1 th:text="'Hello, ' + ${name}"></h1>
</body>
</html>
```

`Controller.java`

```java
@Controller
public class HomeController {
    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("name", "Ethan");
        return "index"; // looks for index.html in templates/
    }
}
```

👉 With the Thymeleaf dependency, Spring Boot knows how to render `index.html` with your model data.



### 1. **User makes a request (Browser → Spring Boot)**

- Example: User enters `http://localhost:8080/` in their browser.
    
- The request goes to the Spring Boot embedded server (Tomcat/Jetty).
    

---

### 2. **Spring Boot maps the request to a Controller**

`@Controller` methods listen for HTTP requests using `@GetMapping`, `@PostMapping`, etc.

```java
@Controller
public class HomeController {

    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("name", "Ethan");  // add data to model
        return "index"; // tells Spring to render index.html
    }
}
```

---

### 3. **Spring passes the Model to Thymeleaf**

- `model.addAttribute("name", "Ethan")` → makes a variable `name` available in the template.
    
- Spring Boot looks for `index.html` inside `src/main/resources/templates/`.
    

---

### 4. **Thymeleaf processes the template**

`src/main/resources/templates/index.html`

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <title>Welcome</title>
</head>
<body>
    <h1 th:text="'Hello, ' + ${name}"></h1>
</body>
</html>
```

- Thymeleaf sees `${name}` and replaces it with `"Ethan"`.
    
- Output becomes:
    

```html
<h1>Hello, Ethan</h1>
```

---

### 5. **Response sent back to the browser**

- Spring Boot returns the **final HTML page** to the browser.
    
- User sees:
    

📄 **Browser Output**

```
Hello, Ethan
```

---

👉 **In short (flow recap):**  
**Browser Request → Spring Boot Controller → Model with Data → Thymeleaf Template → Rendered HTML → Browser Response**


## 1. **HTML form (Thymeleaf template)**

`src/main/resources/templates/form.html`

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <title>Form Example</title>
</head>
<body>
    <h2>Enter your name</h2>
    <form th:action="@{/greet}" method="post">
        <input type="text" name="username"/>
        <button type="submit">Submit</button>
    </form>
</body>
</html>
```

- `th:action="@{/greet}"` → form submits to `/greet` (POST request).
    
- The input field is named `username`.
    

---

## 2. **Spring Boot Controller**

```java
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
public class FormController {

    // Show the form
    @GetMapping("/form")
    public String showForm() {
        return "form";  // renders form.html
    }

    // Handle the form submission
    @PostMapping("/greet")
    public String greet(@RequestParam String username, Model model) {
        model.addAttribute("name", username);
        return "greeting";  // renders greeting.html
    }
}
```

- `@RequestParam String username` → gets the input value from the form.
    
- We put it into the `Model` for Thymeleaf.
    

---

## 3. **Thymeleaf Response Template**

`src/main/resources/templates/greeting.html`

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <title>Greeting</title>
</head>
<body>
    <h1 th:text="'Hello, ' + ${name} + '!'"></h1>
</body>
</html>
```

---

## 4. **Flow in Action**

1. User visits → `http://localhost:8080/form`
    
2. Spring Boot shows **form.html**
    
3. User types `"Ethan"` and submits
    
4. Spring Boot handles POST `/greet`, extracts `"Ethan"`, adds it to model
    
5. Thymeleaf renders **greeting.html** →
    
    ```html
    <h1>Hello, Ethan!</h1>
    ```
    
6. Browser displays:
    

📄 **Output**

```
Hello, Ethan!
```

---

✅ That’s the **full request/response cycle with form input**.

Great 👍 let’s level this up and use a **Java object (User)** instead of just one string.

---

## 1. **Java Model Class**

We create a simple POJO for the form data:

```java
public class User {
    private String name;
    private String email;

    // Getters and Setters
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }
    public void setEmail(String email) {
        this.email = email;
    }
}
```

---

## 2. **Controller**

We bind the form directly to a `User` object.

```java
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
public class UserController {

    // Show the form
    @GetMapping("/register")
    public String showForm(Model model) {
        model.addAttribute("user", new User()); // empty User object for form
        return "register"; // renders register.html
    }

    // Handle form submit
    @PostMapping("/register")
    public String processForm(@ModelAttribute User user, Model model) {
        model.addAttribute("user", user);
        return "result"; // renders result.html
    }
}
```

- `@ModelAttribute User user` → Spring automatically maps form fields to the `User` object.
    
- Example: `<input name="name"/>` → calls `user.setName(...)`.
    

---

## 3. **Form Template**

`src/main/resources/templates/register.html`

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <title>User Registration</title>
</head>
<body>
    <h2>User Registration</h2>

    <form th:action="@{/register}" th:object="${user}" method="post">
        <label>Name:</label>
        <input type="text" th:field="*{name}" /> <br/>

        <label>Email:</label>
        <input type="email" th:field="*{email}" /> <br/>

        <button type="submit">Register</button>
    </form>
</body>
</html>
```

- `th:object="${user}"` → binds the form to the `User` object.
    
- `th:field="*{name}"` → links input field to `user.name`.
    

---

## 4. **Result Template**

`src/main/resources/templates/result.html`

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <title>Result</title>
</head>
<body>
    <h2>Registration Successful!</h2>
    <p>Name: <span th:text="${user.name}"></span></p>
    <p>Email: <span th:text="${user.email}"></span></p>
</body>
</html>
```

---

## 5. **Flow in Action**

1. User visits → `http://localhost:8080/register`
    
2. Sees **form** (register.html) with fields for Name + Email
    
3. Fills it out:
    
    ```
    Name: Ethan
    Email: ethan@example.com
    ```
    
4. Submits → POST `/register`
    
5. Spring Boot creates a `User` object with values, passes it to Thymeleaf
    
6. Thymeleaf renders **result.html** with data:
    

📄 **Output**

```
Registration Successful!
Name: Ethan
Email: ethan@example.com
```

---

✅ That’s the **end-to-end flow with an object** bound to a Thymeleaf form.

##### Tags : [[0 - Spring Framework]]