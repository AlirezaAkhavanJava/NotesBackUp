


**Definition.** `@ServletComponentScan` is a Spring Boot annotation, in `org.springframework.boot.web.servlet`, that tells Spring to search your packages for classes annotated with `@WebServlet`, `@WebFilter`, or `@WebListener`, and to register them with the embedded servlet container. The correct spelling has a capital S in "Scan," so it is `ServletComponentScan`. You place it on a configuration class, usually the main application class.

## The problem it solves

The Servlet specification defines `@WebServlet`, `@WebFilter`, and `@WebListener` so that a container can discover them automatically. In a traditional deployment, Tomcat reads your WAR file, finds those annotations, and registers each class. That works because Tomcat owns the deployment.

Spring Boot works differently. It packages your application as an executable JAR and starts Tomcat from inside your own `main()` method. Tomcat does not scan the JAR for annotations, so a class marked `@WebServlet` is compiled and present but never registered. The annotation does nothing.

`@ServletComponentScan` closes that gap. It asks Spring to do the scanning and registration that the container would otherwise have done.

## What the failure looks like

Suppose you write this:

```java
@WebServlet("/hello")
public class HelloServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.getWriter().println("Hello from a servlet");
    }
}
```

You start the application, and it compiles and runs without any error. You then request `http://localhost:8080/hello` and get a 404 from Spring's error page. The reason is that the request reached `DispatcherServlet`, the only servlet Spring registered at `/`, and no `@RequestMapping` matched it. Your `HelloServlet` was never registered, so nothing claimed the path.

The silence is what makes this confusing. Nothing fails at startup, and the annotation looks correct, so the cause is easy to miss.

## How it works

The sequence has three steps.

```
Startup
  1. Spring reads @ServletComponentScan on your main class
  2. It scans the packages for @WebServlet, @WebFilter, @WebListener classes
  3. For each class found, it registers a servlet, filter, or listener
     with the embedded Tomcat before the server accepts traffic
```

Here is the minimal working setup:

```java
package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.servlet.ServletComponentScan;

@SpringBootApplication
@ServletComponentScan
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

What this does:

- `@SpringBootApplication` is the usual entry annotation. It turns on auto-configuration and component scanning.
- `@ServletComponentScan` adds a second scan, specifically for the three Servlet annotations. It works alongside the normal scan.
- Because the annotation has no arguments, it scans the package of `DemoApplication` and all its sub-packages. With the class above, `com.example.demo.web.HelloServlet` would be found, but `com.example.other.Something` would not.

With this in place, `/hello` returns `Hello from a servlet`.

## Controlling where it looks

If your servlets live in a different package tree, or you want to limit the scan, specify the packages:

```java
@SpringBootApplication
@ServletComponentScan(basePackages = {"com.example.demo.servlets", "com.example.demo.filters"})
public class DemoApplication {
    // main method unchanged
}
```

`basePackages` takes a list of package names as strings. Scanning fewer packages is slightly faster and avoids picking up classes you did not intend to register. A safer alternative is `basePackageClasses`, which takes class references, so the compiler checks that the package exists:

```java
@ServletComponentScan(basePackageClasses = HelloServlet.class)
```

Spring then scans the package that contains `HelloServlet`.

## Filters: the one case you may not need it for

The annotation matters for `@WebFilter`. For a filter, you have two choices.

With `@WebFilter`, you need `@ServletComponentScan`, and the filter is registered only through that path:

```java
@WebFilter("/*")
public class TimingFilter implements Filter {
    // doFilter(...) as before
}
```

With `@Component` instead, Spring registers any `Filter` bean automatically and needs no scan annotation. This is the style used in the `RequestLoggingFilter` earlier in this conversation:

```java
@Component
public class RequestLoggingFilter implements Filter {
    // doFilter(...) as before
}
```

The `@Component` approach is usually the better choice in Spring code. It gives the filter normal dependency injection, and it lets you control the order with `@Order`. A plain `@WebFilter` class does not get that treatment in the same way.

## The Spring-native alternative: registration beans

Many teams avoid `@ServletComponentScan` entirely and register servlets explicitly. This is more verbose, but every registration is visible in one place:

```java
@Configuration
public class ServletConfig {

    @Bean
    public ServletRegistrationBean<HelloServlet> helloServlet() {
        return new ServletRegistrationBean<>(new HelloServlet(), "/hello");
    }
}
```

What this does: `ServletRegistrationBean` pairs a servlet instance with its URL mapping. Spring hands the bean to the container at startup. You need no annotation on `HelloServlet` and no scan. Use this style when you want to see every servlet in one file, or when you need to set init parameters or the load-on-startup order.

Both approaches register the same kind of object with Tomcat. `@ServletComponentScan` is a shortcut, and `ServletRegistrationBean` is the explicit form.

## Two things to watch for

**URL conflicts with Spring MVC.** `DispatcherServlet` owns `/` in a Spring Boot app. A servlet mapped to an exact path, such as `/hello`, takes precedence over that default, so the two coexist. Mapping a servlet to `/*` would shadow every controller, and your `@RestController` methods would stop responding. Check the mapping whenever you add a servlet.

**Dependency injection is limited.** Servlets created by scanning are not ordinary Spring beans, so `@Autowired` fields inside them may be null. If a servlet needs a service or repository, use the `ServletRegistrationBean` form and pass the dependency into the constructor, or make the servlet a `@Component` and inject it into a registration bean.

## Common mistakes

- Adding `@WebServlet` and expecting it to work without `@ServletComponentScan`. The servlet compiles and silently does nothing.
- Putting the annotation on a class outside the main application's package tree, then wondering why nothing is found. Either move the class or use `basePackages`.
- Writing `@ServletComponentscan` or `@ServletComponentScanner`. The name is exactly `ServletComponentScan`, and the import must come from `org.springframework.boot.web.servlet`.
- Using the `javax.servlet` annotations with Spring Boot 3. Spring Boot 3 requires `jakarta.servlet.annotation.WebServlet`.




[[Servlet]]