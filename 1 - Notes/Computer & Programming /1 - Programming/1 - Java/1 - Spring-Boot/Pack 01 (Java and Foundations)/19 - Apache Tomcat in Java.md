

Tomcat is a servlet container: a Java program that knows how to take an incoming HTTP request, find the right Java class to handle it, run that class, and send the response back. It is not a full Java EE application server — it implements just the web layer of that spec (servlets, JSP, WebSockets), which is exactly why it's lightweight enough to embed inside a Spring Boot app rather than run as a separate heavyweight process. You've already worked through the question of whether it counts as a "web server" in the HTTP sense, so this goes past that into how it's actually built and how a request moves through it.

## The components that make up Tomcat

Tomcat isn't one monolithic piece of software — it's several subsystems, each responsible for one part of the job:

- **Coyote** is the connector layer. It's the part that actually listens on a port, speaks HTTP/1.1 or HTTP/2, and hands the parsed request upward. This is the piece `server.tomcat.threads.max` and `server.port` configure.
- **Catalina** is the servlet container itself — it owns the lifecycle of your servlets, decides which one a given URL maps to, and manages the `Context` (a deployed app) that servlet belongs to.
- **Jasper** only matters if you use JSP. It compiles `.jsp` files into servlet classes the first time they're requested, then runs the compiled class on every request after that.

These three talk to each other in a pipeline: Coyote accepts the connection and parses the HTTP request, Catalina routes it to the correct servlet based on URL mapping, and if that servlet happens to be a JSP, Jasper's compiled output is what actually executes.

## What a request's path through Tomcat looks like

```java
@WebServlet("/hello")
public class HelloServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("text/html");
        resp.getWriter().println("<h1>Hello from Tomcat!</h1>");
    }
}
```

A request to `/hello` arrives at Coyote, which hands it to Catalina. Catalina looks at the registered mappings for the current `Context`, finds that `/hello` is bound to `HelloServlet`, and invokes `doGet` on it (Tomcat picks `doGet` vs `doPost` etc. based on the HTTP method — it never calls your servlet's methods directly by name, it dispatches through the `HttpServlet` base class). Your code writes to the `HttpServletResponse`, and Tomcat flushes that back out through Coyote to the client.

This is also why a plain servlet, unlike a Spring Boot `@RestController`, needs to be packaged as a WAR and dropped into Tomcat's `webapps/` folder — there's no embedded server bootstrapping it, Tomcat has to be running standalone and told where to find it.

## `Context`: what makes an "app" a thing Tomcat knows about

A `Context` is Tomcat's unit of deployment — one running web application, bound to a URL path, with its own servlet mappings, class loader, and session storage, isolated from any other app running in the same Tomcat instance. Historically this was declared in `web.xml`; with Jakarta EE and annotations like `@WebServlet`, you can skip that file entirely and let Tomcat discover the mapping from the annotation at startup.

When Spring Boot runs with embedded Tomcat, your whole application effectively _is_ one `Context`, created and configured programmatically rather than hand-written in XML — which is part of why `spring-boot-starter-web` can boot a working server with zero Tomcat-specific configuration from you.

## Jakarta EE and the `javax` → `jakarta` switch

Tomcat 10 and later implement Jakarta EE 9+, which means the package namespace changed from `javax.servlet` to `jakarta.servlet`. This isn't cosmetic — code written against `javax.servlet.*` will not run on Tomcat 10+ without migration, because the class names themselves changed package. If you're ever maintaining or reading older servlet code, that's the first thing to check when something that should work doesn't compile.

## Clustering and session replication

A single Tomcat instance keeps HTTP sessions in memory. The moment you run more than one instance behind a load balancer for availability, a user's session data only existing on one node becomes a problem if their next request lands on a different node. Tomcat's clustering support addresses this with session replication — session state gets copied across the cluster members, so any node can serve a request for any user's session. This matters less once you're using stateless authentication (which your JWT work already sidesteps this problem for), but it's the reason session replication exists as a Tomcat feature at all: classic session-based apps need it the moment they scale horizontally.

**Related, briefly:** the Tomcat Manager (`/manager`) is a bundled web app for deploying and monitoring other apps on the same instance — useful for standalone Tomcat, but irrelevant once you're on embedded Tomcat in Spring Boot, since there's no separate server process to manage through a UI.


[[Spring Framework]]