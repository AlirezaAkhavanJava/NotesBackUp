**Date**: 2025-08-24  
**Tags**: [[0 - Spring Framework]]

## What is Apache Tomcat?

Apache Tomcat is an open-source **web server** and **servlet container** that runs Java-based web applications. It handles HTTP requests, executes Java **servlets**, and supports technologies like **JavaServer Pages (JSP)** and **WebSockets**. Tomcat is lightweight, easy to use, and widely used for deploying Java web apps, especially with frameworks like Spring Boot.

## Key Concepts

- **Web Server**: Responds to HTTP requests (e.g., from browsers) with content like HTML or JSON.
- **Servlet Container**: Manages Java servlets, which process HTTP requests and generate responses.
- **Servlet**: A Java class that handles HTTP requests (e.g., GET, POST).
- **JSP**: JavaServer Pages, which mix Java code with HTML for dynamic web pages.
- **WAR File**: A Web Application Archive, a packaged Java web app deployed to Tomcat.
- **Context**: A deployed web application in Tomcat, mapped to a URL path.

## Why Use Tomcat?

- Runs Java web apps (servlets, JSPs, Spring MVC).
- Lightweight and easy to set up compared to full Java EE servers.
- Supports Spring Boot’s embedded mode or standalone deployment.
- Handles HTTP, HTTPS, and WebSocket connections.
- Free, open-source, and widely supported.

## How Tomcat Works

1. **Start Tomcat**: Runs as a standalone server or embedded in an app (e.g., Spring Boot).
2. **Receive Requests**: Listens for HTTP requests (default port: 8080).
3. **Route to Servlet**: Matches the request URL to a servlet or JSP in a deployed app.
4. **Process**: Servlet or JSP generates a response (e.g., HTML, JSON).
5. **Send Response**: Tomcat sends the response back to the client.

## Main Components

- **Catalina**: The servlet container that manages servlets and JSPs.
- **Coyote**: Handles HTTP connections (e.g., HTTP/1.1, HTTP/2).
- **Jasper**: Compiles JSPs into servlets for execution.
- **Connector**: Configures how Tomcat listens for requests (e.g., HTTP, HTTPS).
- **Context**: Represents a single web app, defined in `web.xml` or annotations.

## Common Issues

- **Port Conflicts**: Tomcat fails to start if port 8080 is in use.
    - **Fix**: Change the port in `conf/server.xml` (e.g., to 8081).
- **Missing WAR File**: Deployed app not found.
    - **Fix**: Place the WAR file in the `webapps` folder or use the Tomcat Manager.
- **OutOfMemoryError**: Large apps exhaust memory.
    - **Fix**: Increase memory in `bin/setenv.sh` (e.g., `-Xmx1024m`).
- **Slow Startup**: Large apps or many dependencies slow Tomcat.
    - **Fix**: Optimize app size or use embedded Tomcat in Spring Boot.

## Best Practices

1. Use **Spring Boot** with embedded Tomcat for easier setup.
2. Deploy WAR files to the `webapps` folder for standalone Tomcat.
3. Secure Tomcat with HTTPS and user authentication (configure in `server.xml`).
4. Monitor performance using tools like VisualVM or Tomcat Manager.
5. Keep Tomcat updated to the latest version (e.g., 10.x for Jakarta EE 9+).
6. Test apps locally before deploying to production.

## Example Code

### Simple Servlet

```java
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/hello")
public class HelloServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("text/html");
        resp.getWriter().println("<h1>Hello from Tomcat!</h1>");
    }
}
```

### Spring Boot with Embedded Tomcat

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class App {
    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

    @GetMapping("/hello")
    public String hello() {
        return "Hello from Spring Boot with Tomcat!";
    }
}
```

**Note**:

- For the servlet, package it in a WAR file and deploy to Tomcat’s `webapps` folder.
- For Spring Boot, add `spring-boot-starter-web` (includes embedded Tomcat) and run the app.
- Access at `http://localhost:8080/hello` (adjust port if needed).
- For standalone Tomcat, download from `tomcat.apache.org` and configure `server.xml` if necessary.

## Advanced Notes

- **Jakarta EE Support**: Tomcat 10.x supports Jakarta EE 9+, using `jakarta.servlet` instead of `javax.servlet`.
- **Embedded Tomcat**: Spring Boot uses embedded Tomcat by default, configurable via `application.properties`:

```properties
server.port=8081
server.tomcat.threads.max=200
```

- **Clustering**: Tomcat supports session replication for high availability in clustered setups.
- **Tomcat Manager**: A web app (`/manager`) for deploying, monitoring, and managing apps.
- **Custom Configuration**: Edit `conf/server.xml` for connectors, ports, or SSL:
   
 ```xml
    <Connector port="8443" protocol="HTTP/1.1" SSLEnabled="true" ... />
    ```

## Summary

Apache Tomcat is a lightweight web server and servlet container for running Java web apps, including servlets, JSPs, and Spring Boot applications. It processes HTTP requests, manages servlets, and supports easy deployment via WAR files or embedded mode. Use annotations like `@WebServlet` or Spring Boot for simplicity, secure with HTTPS, and monitor performance. Tomcat is beginner-friendly for small apps and powerful for enterprise deployments.