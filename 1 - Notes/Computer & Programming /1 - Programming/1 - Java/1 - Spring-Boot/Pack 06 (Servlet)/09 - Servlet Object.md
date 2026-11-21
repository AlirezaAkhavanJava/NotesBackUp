
You can create a Servlet object using `new`, just like any other Java class. However, in a real web application, the Servlet Container (Tomcat) should normally create and manage the Servlet for you.

## 1. Creating a Servlet object manually

Suppose you have:

```java
@WebServlet("/servlet")
public class HelloServlet extends HttpServlet {

    @Override
    protected void doGet(
            HttpServletRequest req,
            HttpServletResponse resp
    ) throws IOException {

        resp.getWriter().println("Hello World");
    }
}
```

Technically, you can create an object:

```
HelloServlet servlet = new HelloServlet();
```

But there is a problem.

This creates an ordinary Java object. It does not automatically register that object with Tomcat.

Therefore, Tomcat will not automatically route HTTP requests to this manually created instance.

## 2. Let Tomcat create the Servlet (recommended)

In your Spring Boot project:

```java
@WebServlet("/servlet")
public class HelloServlet extends HttpServlet {

    @Override
    protected void doGet(
            HttpServletRequest req,
            HttpServletResponse resp
    ) throws IOException {

        resp.getWriter().println("Hello World");
    }
}
```

And in your application class:

```java
@SpringBootApplication
@ServletComponentScan
public class App {

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }
}
```

Now Spring Boot discovers `HelloServlet` and registers it with Tomcat.

Tomcat handles its lifecycle, including creating the instance and calling `init()`, `service()`, and `destroy()`.

## 3. Creating and registering a Servlet programmatically

You can also explicitly create a Servlet object and register it with the embedded Tomcat container through Spring Boot.

```java
import org.springframework.boot.web.servlet.ServletRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ServletConfig {

    @Bean
    public ServletRegistrationBean<HelloServlet> helloServlet() {

        HelloServlet servlet = new HelloServlet();

        return new ServletRegistrationBean<>(
                servlet,
                "/servlet"
        );
    }
}
```

Here:

1. `new HelloServlet()` creates the Java object.
    
2. `ServletRegistrationBean` registers that instance with the Servlet Container.
    
3. `"/servlet"` specifies its URL mapping.
    
4. Tomcat manages the registered Servlet's lifecycle.
    

For this approach, remove `@WebServlet` from `HelloServlet` or disable its component scanning to avoid duplicate registration.

## 4. The difference

|Approach|Creates object|Registers with Tomcat|
|---|---|---|
|`new HelloServlet()`|You|No|
|`@WebServlet` + `@ServletComponentScan`|Container|Yes|
|`ServletRegistrationBean`|You/Spring configuration|Yes|

## 5. The whole picture

A Servlet is still a Java object, but creating the object and registering it with a Servlet Container are two different operations.

```lua
Manual creation:

new HelloServlet()
        |
        v
Ordinary Java object
        |
        v
Not automatically accessible through HTTP
```

```
Container-managed Servlet:

Spring Boot starts
        |
        v
Servlet registration
        |
        v
Tomcat manages Servlet instance
        |
        v
HTTP GET /servlet
        |
        v
HelloServlet.doGet()
```

Remember: The Servlet Container doesn't make a Servlet special as a Java object. It provides the runtime infrastructure that allows the Servlet to participate in HTTP request processing.


[[Servlet]]