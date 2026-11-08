
# Microservices

Microservices is a way of building one application as a set of small, separate programs instead of one big program. Each of these programs is called a **service**. Each service owns one clear business job (orders, payments, inventory, users), runs as its own process, has its own database, and talks to the other services over the network, usually through HTTP/REST or messages.

It matters because it changes how you build, deploy, scale, and fix a system. You can release one service without redeploying everything. You can scale only the busy part. And a crash in one service doesn't have to bring the whole app down. These benefits come with real costs, so this lesson covers both.

---

## Monolith vs microservices

The opposite of microservices is a **monolith**: one codebase, built into one JAR/WAR, deployed as one unit. Your Spring Boot projects so far are monoliths, and that's a perfectly good thing to be.

||Monolith|Microservices|
|---|---|---|
|Codebase|One project|Many small projects|
|Deployment|One JAR, all or nothing|One JAR per service, deployed separately|
|Database|Usually one shared database|One database per service|
|Calls between parts|Java method calls (in memory)|Network calls (HTTP, messaging)|
|Scaling|Copy the whole app|Copy only the service that is busy|
|A bug or crash|Can take down everything|Can stay contained to one service|
|Complexity|Inside the code|Between the services|

The most important row is **"calls between parts."** In a monolith, `orderService` calls `inventoryService.checkStock()` as a normal Java method. It is fast, and it either works or throws an exception. In microservices, that same call becomes a request over the network. Networks are slower and can fail, so almost every hard part of microservices comes from this one change.

---

## What it looks like in code

Take an online shop split into two services:

- **order-service** (port 8080) takes orders.
- **inventory-service** (port 8081) knows how much stock exists.

Each is its own Spring Boot project with its own `pom.xml` and its own `main` method.

### inventory-service

```java
@RestController
@RequestMapping("/stock")
public class StockController {

    private final StockRepository repo;

    public StockController(StockRepository repo) {
        this.repo = repo;
    }

    @GetMapping("/{sku}")
    public StockResponse getStock(@PathVariable String sku) {
        return repo.findById(sku)
                .map(s -> new StockResponse(s.getSku(), s.getQuantity()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
    }
}

record StockResponse(String sku, int quantity) {}
```

Line by line:

- `@RestController` and `@RequestMapping("/stock")` make this class answer HTTP requests that start with `/stock`.
- The constructor receives `StockRepository`. This is normal constructor injection, and this service reads from **its own** database through it.
- `@GetMapping("/{sku}")` handles `GET /stock/ABC123`. `@PathVariable` pulls `ABC123` out of the URL.
- `repo.findById(sku).map(...)` turns the database entity into a small response object. Notice that we return a DTO, not the entity. This matters even more here, because the entity is private to this service and the DTO is the **public contract** other services depend on.
- `orElseThrow(...)` returns a `404` if the SKU doesn't exist.

### order-service

```java
@RestController
@RequestMapping("/orders")
public class OrderController {

    private final RestClient inventoryClient;

    public OrderController(RestClient.Builder builder) {
        this.inventoryClient = builder
                .baseUrl("http://inventory-service:8081")
                .build();
    }

    @PostMapping
    public ResponseEntity<String> placeOrder(@RequestBody OrderRequest request) {
        StockResponse stock = inventoryClient.get()
                .uri("/stock/{sku}", request.sku())
                .retrieve()
                .body(StockResponse.class);

        if (stock == null || stock.quantity() < request.quantity()) {
            return ResponseEntity.status(409).body("Not enough stock");
        }
        return ResponseEntity.ok("Order placed");
    }
}

record OrderRequest(String sku, int quantity) {}
record StockResponse(String sku, int quantity) {}
```

Line by line:

- `RestClient` is Spring's HTTP client. It lets this service call another service.
- `.baseUrl("http://inventory-service:8081")` is the address of the other service. Here `inventory-service` is a hostname that Docker or your platform resolves. Hard-coding it is fine for learning, but real systems use service discovery or configuration properties.
- `placeOrder` is the old "method call" turned into a network call: `inventoryClient.get().uri(...).retrieve().body(...)` sends `GET /stock/{sku}` and converts the JSON reply into a `StockResponse`.
- `StockResponse` is declared again here. The two services share **no Java classes**. They share only the JSON shape. This is what keeps them independent.
- If stock is too low, we answer `409 Conflict`.

### Running them separately

With Docker, each service gets its own container and its own database:

```yaml
services:
  order-service:
    build: ./order-service
    ports: ["8080:8080"]
    depends_on: [orders-db]

  inventory-service:
    build: ./inventory-service
    ports: ["8081:8081"]
    depends_on: [inventory-db]

  orders-db:
    image: postgres:16
    environment:
      POSTGRES_DB: orders
      POSTGRES_PASSWORD: secret

  inventory-db:
    image: postgres:16
    environment:
      POSTGRES_DB: inventory
      POSTGRES_PASSWORD: secret
```

Notice there are **two** PostgreSQL containers. `order-service` must never read the inventory tables directly. If it needs stock data, it must ask `inventory-service` through its API. This rule is called **database per service**, and it is what truly separates the services. If both shared one database, a schema change in one would break the other, and you would only have a monolith with extra steps.

---

## How services talk to each other

There are two main styles.

**Synchronous (request and wait):** The caller sends a request and waits for the answer. This is what the `RestClient` above does. It is simple and easy to follow, but if the other service is slow or down, the caller is stuck too.

**Asynchronous (send a message and move on):** The caller puts a message on a broker such as Kafka or RabbitMQ, and the other service handles it when it's ready. For example, `order-service` publishes an `OrderPlaced` event. `inventory-service` and `email-service` each react to it separately. The sender doesn't know who is listening, which keeps services loosely coupled, the same idea you saw with coupling in Java, now at the system level.

||Synchronous (REST)|Asynchronous (events)|
|---|---|---|
|Caller waits?|Yes|No|
|If the other service is down|The call fails|The message waits in the broker|
|Easy to debug|Yes|Harder|
|Best for|"I need the answer now"|"Something happened, others can react"|

---

## The supporting pieces

Once you have many services, a few extra components usually appear:

- **API Gateway:** One public entry point (for example Spring Cloud Gateway, or Nginx). Clients call the gateway, and it routes `/orders/**` to order-service and `/stock/**` to inventory-service. It's also a good place for authentication, such as checking the JWT once for all services.
- **Service discovery:** Services register themselves, so others can find them by name instead of by fixed IP and port.
- **Centralized configuration:** One place for settings, instead of one `application.properties` copy per service.
- **Resilience:** Timeouts, retries, and circuit breakers, so one slow service doesn't drag everything down.
- **Observability:** Central logs, metrics, and tracing, so you can follow one request across five services.

Here is the simplest form of resilience, a timeout, because a call with no timeout can hang a thread forever:

```java
var factory = new SimpleClientHttpRequestFactory();
factory.setConnectTimeout(Duration.ofSeconds(2));
factory.setReadTimeout(Duration.ofSeconds(3));

RestClient client = RestClient.builder()
        .requestFactory(factory)
        .baseUrl("http://inventory-service:8081")
        .build();
```

- `setConnectTimeout(2s)` gives up if the connection can't even be opened in 2 seconds.
- `setReadTimeout(3s)` gives up if the connection opened but no answer arrives in 3 seconds.
- Without these, a dead inventory-service could freeze every order request waiting on it.

---

## Why it matters

Here are the real benefits:

1. **Independent deployment.** Fix a bug in inventory-service and deploy only that. Your CI/CD pipeline (such as Jenkins) can have one pipeline per service, each running fast and small.
2. **Independent scaling.** If checking stock is the heavy part, run five copies of inventory-service and one of everything else.
3. **Fault isolation.** If email-service crashes, orders can still be placed, as long as you designed it to cope.
4. **Technology freedom.** One service can use PostgreSQL, another Redis, and another can even be written in a different language.
5. **Team autonomy.** Different teams own different services, and they only need to agree on the API.
6. **Smaller codebases.** Each project is easier to understand, build, and test.

---

## The costs

Microservices are not free. You are trading **code complexity** for **system complexity**.

|Cost|What it means|
|---|---|
|Network failures|Every call can be slow, fail, or time out. You must handle it.|
|No simple transactions|`@Transactional` works inside one database. It can't span two services.|
|Data consistency|Data lives in many databases, so it is often only _eventually_ consistent.|
|Harder testing|You need to test services together, not only one by one.|
|Operations work|Many deployments, many logs, many configs, usually containers.|
|Debugging|One user action can touch five services.|

The transaction problem is the biggest surprise for most people. In a monolith, "save order and reduce stock" is one `@Transactional` method, so either both happen or neither does. In microservices those are two databases. If the order is saved but the stock call fails, you must undo the order yourself.

---

## When to use microservices, and when not to

Microservices pay off when you have several teams, parts of the system with very different scaling needs, and a need to deploy parts independently. They hurt when you have a small team, a new project whose boundaries are still unclear, or a simple app.

A common, sensible path is to **start with a well-organized monolith** and split out a service only when there is a clear reason. Splitting too early often creates a "distributed monolith": many services that all depend on each other and must be deployed together, which gives you the costs without the benefits.

---

## Two related concepts, very briefly

**Modular monolith:** One deployable application, but internally split into clear modules (`orders`, `inventory`) with strict boundaries between them. You get much of the organization of microservices without the network problems. It is often the best first step, and it makes a later split easier.

**Saga pattern:** The standard answer to "no transactions across services." Instead of one big transaction, each service does its own local step and publishes an event. If a later step fails, a **compensating action** undoes the earlier steps. For example, if payment fails, `order-service` runs a "cancel order" step. You'll meet this when you go deeper into event-driven design.

---

## Summary

- A microservice is a small, independently deployable service that owns one business capability and its own data.
- Services talk over the network, using REST (wait for the answer) or events (send and move on).
- The main benefits are independent deployment and scaling, fault isolation, and team autonomy.
- The main costs are network failures, no cross-service transactions, and operational complexity.
- Start simple. Move to microservices when the size of your system or team makes a single deployable unit hard to manage.




[[Spring Framework]]