![[Spring Bean Scopes Infographic.png]]


A **bean** is an object that the Spring IoC container creates and manages for you. A **bean scope** is the rule that decides how many instances of that bean exist and how long they live. In short, it answers: _when someone asks for this bean, do they get the same object or a new one?_

Scopes belong to the core **Spring Framework**, so they work the same in Spring Boot. Most of your classes will use the default scope, and you only switch when a bean must hold data that belongs to one request, one user, or one connection.

```java
@Component
public class EmailService { }   // scope not written, so it is singleton
```

---

## The six scopes at a glance

|Scope|Instances|Lives until|Typical use|Web only?|
|---|---|---|---|---|
|`singleton` (default)|1 per container|The container closes|Services, repositories, controllers|No|
|`prototype`|New one on every request for the bean|You drop it (Spring does not destroy it)|Short-lived, stateful helper objects|No|
|`request`|1 per HTTP request|The request ends|Request ID, tenant, timing data|Yes|
|`session`|1 per HTTP session|The session ends or times out|Shopping cart, user preferences|Yes|
|`application`|1 per `ServletContext`|The web app stops|Global web-level data|Yes|
|`websocket`|1 per WebSocket session|The socket closes|Real-time chat state|Yes|

---

## 1. Singleton (the default)

One instance is created and **everyone shares it**.

```java
@Service
public class UserService { }
```

```java
UserService a = context.getBean(UserService.class);
UserService b = context.getBean(UserService.class);
System.out.println(a == b); // true
```

`@Scope("singleton")` is optional, because it is already the default. Services and repositories usually want exactly one object, so this fits them well.

**The rule to remember:** a singleton is shared by all users and all threads, so it should be **stateless** (or immutable).

```java
@Service
public class CounterService {
    private int count;                  // shared by every user, so this is a bug
    public void increase() { count++; }
}
```

Safer version, which keeps the data in method arguments and return values:

```java
@Service
public class CounterService {
    public int next(int value) { return value + 1; }
}
```

---

## 2. Prototype

Spring builds a **new object every time** the bean is requested (through `getBean()` or an injection point).

```java
@Component
@Scope("prototype")
public class ReportGenerator { }
```

```java
ReportGenerator a = context.getBean(ReportGenerator.class);
ReportGenerator b = context.getBean(ReportGenerator.class);
System.out.println(a == b); // false
```

Use it for objects with temporary state that should never be shared.

Two catches:

- Spring creates a prototype and then forgets it. `@PreDestroy` is **never called**, so you must clean up any resources yourself.
- If you inject a prototype into a singleton, the singleton receives **one** prototype, once, at startup. To get a fresh one each time, inject `ObjectProvider<ReportGenerator>` and call `.getObject()` when you need it.

---

## 3. Request scope (web)

One bean per HTTP request. Every class that uses it during that request sees the same object, and the next request gets a new one.

```java
@Component
@RequestScope
public class RequestContext {
    private final String requestId = UUID.randomUUID().toString();
    public String getRequestId() { return requestId; }
}
```

`@RequestScope` is a shortcut for `@Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS)`. You can use either one, but the shortcut is shorter and already includes the proxy (see the next section).

---

## 4. Session scope (web)

One bean per user session, so it survives across many requests from the same browser.

```java
@Component
@SessionScope
public class ShoppingCart {
    private final List<String> items = new ArrayList<>();
    public void add(String item) { items.add(item); }
}
```

User A and user B each get their own `ShoppingCart`. Since session data is kept in the HTTP session, make the bean `Serializable` if you run several servers.

---

## 5. Application and WebSocket scope (web)

```java
@Component
@ApplicationScope
public class AppSettings { }
```

`@ApplicationScope` is one bean per web application. It behaves like a singleton, but it is tied to the **Servlet Context** (a web concept) instead of the **Spring container**. In a normal single-context app you will not see a difference.

```java
@Component
@Scope("websocket")
public class ChatSession { }
```

`websocket` gives one bean per WebSocket session, and it only works when WebSocket support is configured.

---

## Why request and session beans need a proxy

A controller is a **singleton**, created once at startup. A request bean is created **per request**. So how can the controller hold it?

Spring injects a **proxy**, a stand-in object. On every method call, the proxy looks up the real bean for the _current_ request or session and forwards the call.

```
Controller (singleton) ──holds──> proxy ──finds──> real RequestContext (this request)
```

`@RequestScope` and `@SessionScope` set this up for you. With plain `@Scope("request")` and no `proxyMode`, you get an error such as _"Scope 'request' is not active for the current thread"_ when injecting into a singleton.

Also, web scopes only work **inside a web request**. In a background thread, a scheduled job, or a plain unit test, there is no request, and you get `No thread-bound request found`.

---

## What you will use in real projects

```
Controller, Service, Repository, Component, Configuration  ->  singleton
```

You reach for `request`, `session`, `prototype`, or `websocket` only when a bean must hold data tied to a specific request, user, or connection.

---

## What I fixed in your note

1. **Shopping cart under prototype:** prototype gives a new object per `getBean()` call, not per user. "Each user needs a different cart" is session scope, so I kept the cart only there. This also removed the duplicate.
2. **Prototype diagram:** it said "Request 1 / Request 2", which reads like HTTP requests. They are requests to the container for the bean.
3. **"In Spring Boot":** scopes come from the Spring Framework, not Boot specifically.
4. **Missing proxy explanation:** injecting a request or session bean into a singleton fails without a scoped proxy.
5. **Missing prototype destroy behavior and the singleton-injection catch.**
6. **Duplicated `@Scope("request")` and `@RequestScope` examples:** merged into one.
7. **"Singleton: one per container":** more precisely, one per bean definition per container. The container is the unit that matters here, so I kept the simpler wording.
8. **Removed filler:** the redundant `@Scope("singleton")` example on `UserService`, repeated "common use" bullet lists, and the long ASCII memory diagrams, which the table now covers.

[[Spring Framework]]