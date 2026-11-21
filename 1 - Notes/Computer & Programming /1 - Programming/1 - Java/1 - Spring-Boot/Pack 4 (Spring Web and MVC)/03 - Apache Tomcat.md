

 Tomcat is a web server that is built to run **Java web applications**. Its precise name is a **servlet container** (also called a **web container**). It listens for HTTP requests, hands them to your Java code (servlets), and sends your code's response back to the browser.

The twist is that people use "web server" for two different things. ***Some mean a program that serves files (HTML, images, CSS). Others mean a program that runs application code and answers requests.*** Tomcat can do both, but it really shines at the second. Once you see that split, most of the confusion around Tomcat, Nginx, Apache httpd, and Spring Boot goes away.

---

## Two meanings of "web server"

|Kind|What it does|Examples|
|---|---|---|
|**Static web server**|Reads a file from disk and sends it. Very fast, very light.|Nginx, Apache HTTP Server (httpd)|
|**Servlet container**|Receives a request, runs Java code, sends back what that code produced.|**Tomcat**, Jetty, Undertow|
|**Full application server**|A servlet container plus a lot more (transactions, messaging, EJB, and so on).|WildFly, Payara, WebLogic|

Tomcat sits in the middle. It can serve static files, but nobody picks it for that. People pick it because it implements the **Jakarta Servlet** specification, so your Java classes can answer HTTP requests.

A quick word on that name: **Servlet** is the Java standard for "a class that handles a web request." You will also see it written as `javax.servlet` (old) or `jakarta.servlet` (new). Oracle handed Java EE to the Eclipse Foundation, and the packages were renamed to `jakarta.*`.

---

## What Tomcat is made of

Tomcat is a set of nested parts. You can see them in its `server.xml` file:

```xml
<Server port="8005" shutdown="SHUTDOWN">
  <Service name="Catalina">

    <Connector port="8080" protocol="HTTP/1.1" />

    <Engine name="Catalina" defaultHost="localhost">
      <Host name="localhost" appBase="webapps">
      </Host>
    </Engine>

  </Service>
</Server>
```

Line by line:

- `<Server>` is Tomcat itself, the whole process. Port `8005` is a shutdown port. Sending the word `SHUTDOWN` to it stops Tomcat.
- `<Service>` groups connectors with one engine. `Catalina` is the internal name of Tomcat's servlet engine.
- `<Connector port="8080">` is the **ear**. It listens on port 8080, speaks HTTP, and turns raw network bytes into a request object.
- `<Engine>` is the **brain**. It receives requests from the connector and decides where each one goes.
- `<Host>` is a virtual host, meaning a domain name. `appBase="webapps"` means "look for applications in the `webapps` folder."

Inside a host live your applications, called **Contexts**. Inside a context live your **servlets**.

Here is the journey of one request:

```
Browser
  → Connector (port 8080)      reads the HTTP bytes
  → Engine → Host              picks the right domain
  → Context (your app)         picks the right application by URL path
  → Servlet                    your code runs
  ← response travels back the same way
```

---

## How you use Tomcat: two styles

### 1. Classic (standalone Tomcat)

You build a **WAR** file (Web Application Archive) and drop it into Tomcat's `webapps/` folder. Tomcat unpacks it and runs it. Many applications can live inside one Tomcat.

### 2. Embedded (what Spring Boot does)

Here the roles flip. Your app does not live inside Tomcat. **Tomcat lives inside your app.**

```java
@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

When this `main` method runs, Spring Boot creates a Tomcat object in memory, starts it, and registers Spring's `DispatcherServlet` inside it. You never install Tomcat. It arrives as a library through this dependency:

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

`spring-boot-starter-web` pulls in `spring-boot-starter-tomcat`, and that is where Tomcat comes from. This is why your Spring Boot app can start with `java -jar app.jar` and answer on port 8080.

You can configure the embedded Tomcat in `application.properties`:

```properties
server.port=9090
server.tomcat.threads.max=200
```

- `server.port=9090` changes the connector port from 8080 to 9090.
- `server.tomcat.threads.max=200` allows up to 200 requests to be handled at the same time. Tomcat keeps a **thread pool**, which is a group of ready-made workers. Each request borrows one worker until the response is sent.

Because Tomcat is only one choice, you can swap it. Exclude `spring-boot-starter-tomcat` and add `spring-boot-starter-jetty`, and your code works the same way. That shows what Tomcat really is in your app: a replaceable engine that carries HTTP to your code.

---

## Tomcat in front of the world

In production you usually do not expose Tomcat directly. A common layout is:

```
Internet → Nginx (port 80/443) → Tomcat (port 8080) → your app
```

Nginx handles HTTPS, serves static files quickly, and can balance load across several Tomcats. This is called a **reverse proxy**. It is a server that sits in front of other servers and forwards requests to them. Tomcat then focuses on running your Java code.

---

## What Tomcat is not

Tomcat does **not** implement all of Jakarta EE. It covers Servlet, JSP (Jakarta Pages), WebSocket, and a few related specifications. It does not include things like EJB or full JMS messaging. That is why people call it a _lightweight_ container, and why WildFly and Payara are called _full_ application servers. For most Spring applications this is plenty, because Spring supplies the rest.

---

## Related concept: Servlet

A **servlet** is a Java class that handles one kind of request. It receives a `request` object and fills in a `response` object. Tomcat creates the servlet once and reuses it for many requests, from many threads. In a Spring app, you almost never write servlets yourself. Spring's single `DispatcherServlet` receives everything and forwards it to your `@RestController` methods.

---

## Quick recap

- Tomcat is a web server in the sense of "runs Java web apps." Its exact name is **servlet container**.
- It is not a full application server, and it is not meant to be your fast static file server.
- Its main pieces are Connector (listens), Engine (routes), Host (domain), Context (your app), and Servlet (your code).
- You can run it standalone with WAR files, or **embedded** inside Spring Boot, which is how you most likely use it.




[[Spring Framework]]