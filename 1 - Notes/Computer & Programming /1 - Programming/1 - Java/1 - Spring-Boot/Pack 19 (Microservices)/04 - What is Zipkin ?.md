

# Zipkin

Zipkin is a tool that collects and shows **traces**: the full path one request takes as it travels through your services. When a client calls the gateway, and the gateway calls order-service, and order-service calls inventory-service, Zipkin records each step with its start time and duration, and draws the whole journey on one timeline. Zipkin itself is a small server with a web UI. Your services send it small timing records, and it stores them and lets you search them.

It matters because in a microservices system one user action touches several services, and each service has its own logs. When a request is slow or fails, you can't tell from one service's log _where_ the time went or _which_ service broke. Zipkin answers two questions that are very hard to answer otherwise: "which service made this request slow?" and "what exactly happened during this one request?"

---

## The words you need: trace, span, and IDs

Zipkin has only a few concepts, and they build on each other.

A **trace** is the whole journey of one request across all services. It has one **trace ID**, and every service involved uses that same ID.

A **span** is one unit of work inside a trace, such as "order-service handled `POST /orders`" or "order-service called inventory-service." Each span has its own **span ID**, a start time, a duration, and a **parent span ID** that points to the span that caused it.

Here is one trace, written as a table:

|Span|Service|Parent|Start (ms)|Duration (ms)|
|---|---|---|---|---|
|A: `POST /orders`|gateway|none (root)|0|410|
|B: `POST /orders`|order-service|A|12|390|
|C: `GET /stock/{sku}` (client call)|order-service|B|30|340|
|D: `GET /stock/{sku}` (server side)|inventory-service|C|45|320|
|E: `SELECT ... FROM stock`|inventory-service|D|60|290|

Zipkin draws these as a waterfall, with each span as a bar, indented under its parent:

```
gateway            ████████████████████████████████████████ 410ms
 order-service      ███████████████████████████████████████ 390ms
  → inventory call   █████████████████████████████████ 340ms
   inventory-service  ███████████████████████████████ 320ms
    SELECT stock       ████████████████████████████ 290ms
```

Reading it takes a few seconds: the request took 410 ms, and almost all of it (290 ms) was a single database query in inventory-service. Without tracing, you might have blamed the network or the gateway. This is the kind of answer Zipkin gives you.

---

## How the trace ID travels

For the trace to connect across services, the trace ID must be passed along with every call. This is done with **HTTP headers**, the same place where the `Authorization: Bearer` header from your JWT lessons lives.

When order-service calls inventory-service, the tracing library adds headers to the outgoing request. Two common formats exist:

```
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
```

or the older B3 style:

```
X-B3-TraceId: 4bf92f3577b34da6a3ce929d0e0e4736
X-B3-SpanId: 00f067aa0ba902b7
X-B3-ParentSpanId: 05e3ac9a4f6e3b90
X-B3-Sampled: 1
```

The receiving service reads these headers, keeps the **same trace ID**, creates a **new span ID**, and records the incoming span ID as its parent. That is the entire trick that links the services together. The gateway starts the trace (it is the first service to see the request), and every service after it continues it.

The IDs are also placed in your log lines, so you can search all services' logs for one trace ID. We will see that below.

---

## How the pieces fit together

```
 client → gateway → order-service → inventory-service
              │           │                │
              └───────────┴────────────────┘
                          │  each service sends its spans (async, over HTTP)
                          ▼
                    Zipkin server (9411)
                    ├── collector  (receives spans)
                    ├── storage    (in memory, or a database)
                    └── UI + API   (search and show traces)
```

- Each service has a **tracing library** that creates spans automatically and attaches them to incoming and outgoing calls.
- Each service has a **reporter** that sends finished spans to Zipkin in the background. Because this is asynchronous, it adds very little delay to your requests.
- The Zipkin server **collects**, **stores**, and **displays** the spans.

---

## Running Zipkin

The easiest way is Docker, as in your Docker lesson:

```bash
docker run -d --name zipkin -p 9411:9411 openzipkin/zipkin
```

- `-d` runs it in the background.
- `-p 9411:9411` maps the container port to your machine. 9411 is Zipkin's standard port.
- Open `http://localhost:9411` to see the UI.

Or add it to the Docker Compose file from the microservices lesson:

```yaml
services:
  zipkin:
    image: openzipkin/zipkin
    ports: ["9411:9411"]
```

By default Zipkin keeps traces **in memory**, so they disappear when it restarts. That is fine for learning. Production setups plug in Elasticsearch, Cassandra, or MySQL as storage.

---

## Adding tracing to a Spring Boot service

In Spring Boot 3 and later, tracing is done by **Micrometer Tracing**. (Older tutorials use **Spring Cloud Sleuth**, which no longer works with Boot 3. If you see Sleuth, the tutorial is outdated.)

Add these dependencies to each service (order-service, inventory-service, and the gateway):

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-brave</artifactId>
</dependency>
<dependency>
    <groupId>io.zipkin.reporter2</groupId>
    <artifactId>zipkin-reporter-brave</artifactId>
</dependency>
```

What each one does:

- `spring-boot-starter-actuator` brings Micrometer, the observation layer that Spring Boot uses for metrics and tracing.
- `micrometer-tracing-bridge-brave` connects Micrometer to **Brave**, the tracing library that creates spans and handles the trace headers.
- `zipkin-reporter-brave` sends the finished spans to a Zipkin server.

Then the settings:

```yaml
spring:
  application:
    name: order-service

management:
  tracing:
    sampling:
      probability: 1.0
  zipkin:
    tracing:
      endpoint: http://localhost:9411/api/v2/spans
```

Line by line:

- `spring.application.name` becomes the **service name** shown in Zipkin. This is the same name you used for the registry and the Config Server, so one name now identifies the service everywhere.
- `sampling.probability: 1.0` means "trace 100% of requests." The default is `0.1` (10%), which is why beginners often see an empty Zipkin and think it's broken. Use `1.0` while learning.
- `endpoint` is where spans are sent. `/api/v2/spans` is Zipkin's standard collector URL. (The exact property name can differ slightly between Spring Boot versions, so check the one that matches yours.)

If you use a Config Server, the shared `management.tracing` and `management.zipkin` lines are a perfect fit for the shared `application.yml`: write them once, and every service gets them.

### One important detail: use the injected builder

Spring can add tracing headers only to HTTP clients **that it created**. So order-service must get its `RestClient.Builder` from Spring, as we did in the registry lesson:

```java
public OrderController(RestClient.Builder builder) {
    this.inventoryClient = builder
            .baseUrl("http://inventory-service")
            .build();
}
```

If you wrote `RestClient.create()` or `new RestTemplate()` yourself, Spring would not instrument it, no trace headers would be added, and the trace would break into separate pieces at that call. This is the most common reason a trace stops halfway.

---

## Seeing the IDs in logs

With tracing on, Spring Boot adds the trace ID and span ID to every log line automatically (in recent 3.x versions):

```
INFO [order-service,4bf92f3577b34da6a3ce929d0e0e4736,00f067aa0ba902b7] Order received
INFO [inventory-service,4bf92f3577b34da6a3ce929d0e0e4736,9c1d2e3f4a5b6c7d] Checking stock
```

Notice the **same trace ID** in both services, and different span IDs. If you only have logs and no Zipkin open, you can still search every service's log for that one trace ID and rebuild the story. If your version doesn't add it, you can set it yourself:

```yaml
logging:
  pattern:
    level: "%5p [${spring.application.name:},%X{traceId:-},%X{spanId:-}]"
```

- `%X{traceId:-}` reads the trace ID from the **MDC** (a thread-local map used by Log4j and Logback, which you may know from logging) and prints nothing if it's absent.
- This is how your logs and your traces are connected: the tracing library puts the IDs into the MDC, and the log pattern prints them.

---

## Using the Zipkin UI

Send a few requests through the gateway, then open `http://localhost:9411` and:

1. Choose **Run Query** to list recent traces, or filter by service name (`order-service`), by minimum duration, or by tag.
2. Click a trace to see the waterfall like the one shown earlier.
3. Click a single span to see its **tags** (HTTP method, URL, status code) and its **annotations** (timestamps for events).
4. Open **Dependencies** to see a graph of which service calls which, built from the traces.

A slow span stands out immediately as a long bar. A failed call shows as a red span with the error tag. Remember the timeouts from the microservices lesson: a call that waits for a 3-second read timeout shows up as a span that is exactly about 3 seconds long, and that pattern is easy to spot in Zipkin.

---

## Adding your own span

Automatic spans cover incoming and outgoing HTTP calls and database access. To measure a block of your own code, you can add a span by hand:

```java
@Service
public class PricingService {

    private final Tracer tracer;

    public PricingService(Tracer tracer) {
        this.tracer = tracer;
    }

    public double calculate(String sku) {
        Span span = tracer.nextSpan().name("calculate-price").start();
        try (Tracer.SpanInScope ws = tracer.withSpan(span)) {
            span.tag("sku", sku);
            return expensiveCalculation(sku);
        } catch (RuntimeException e) {
            span.error(e);
            throw e;
        } finally {
            span.end();
        }
    }
}
```

Line by line:

- `Tracer` is Micrometer's tracing entry point, injected by constructor like any other bean.
- `tracer.nextSpan().name(...).start()` creates a new span as a child of the current one, and starts its timer.
- `withSpan(span)` makes it the _current_ span inside the `try` block, so anything called inside (including other traced calls) becomes its child. The `try-with-resources` closes the scope automatically.
- `span.tag("sku", sku)` attaches searchable data. Never put passwords or personal data in tags, since they are stored and visible in the UI.
- `span.error(e)` marks the span as failed.
- `span.end()` stops the timer, and the span is sent to Zipkin. It must be in `finally` so it is always ended.

The annotation `@Observed` gives a shorter way for simple cases, but the manual version shows what is really happening.

---

## Costs and gotchas

|Issue|What to know|
|---|---|
|Empty UI|Sampling is 10% by default. Set `probability: 1.0` for testing.|
|Broken traces|An HTTP client created with `new` or `create()` isn't instrumented. Use the injected builder.|
|Overhead|Small, but not zero. In production, sample 1% to 10% of traffic.|
|Storage grows|Every span is stored. Use a retention policy with a real database.|
|Sensitive data|Tags and URLs are stored. Don't put secrets in them.|
|Async code|Trace context follows the thread. With your own thread pools, the context can be lost unless the executor is wrapped by Spring. This connects to your concurrency lessons.|
|Messaging|Kafka and RabbitMQ calls can be traced too, but need their own instrumentation to pass the headers.|

---

## Zipkin and its neighbors

|Tool|What it is|
|---|---|
|**Zipkin**|A simple, lightweight tracing backend and UI. Great for learning.|
|**Jaeger**|Similar tracing backend with a different UI, popular in Kubernetes setups.|
|**Grafana Tempo**|Tracing storage that works with Grafana dashboards.|
|**OpenTelemetry**|Not a backend: a standard for _producing_ traces, metrics, and logs, which can send them to Zipkin, Jaeger, or Tempo.|

---

## A related concept, very briefly

**Observability** is the umbrella idea: understanding a running system from the outside using three kinds of data. **Logs** say what happened in one service. **Metrics** (via Actuator and Micrometer) say how much and how fast, in numbers over time, such as requests per second. **Traces** (Zipkin) say how one request moved through many services. Each answers questions the others can't, and the trace ID in your log lines is the link between logs and traces.

---

## Summary

- Zipkin collects and displays **traces**: the journey of one request through all your services.
- A **trace** has one trace ID. It is made of **spans**, each with its own ID, a parent, a start time, and a duration.
- The trace ID travels in HTTP headers (`traceparent` or `X-B3-*`), so each service can continue the same trace.
- In Spring Boot 3+, add `actuator`, `micrometer-tracing-bridge-brave`, and `zipkin-reporter-brave`, then set `management.tracing.sampling.probability` and the Zipkin endpoint.
- Use the **injected** `RestClient.Builder`, or the trace will break at that call.
- Trace and span IDs appear in your logs, which links logs and traces together.
- Run Zipkin on port 9411 with Docker, and read the waterfall to find which service or query is slow.





[[Spring Framework]]