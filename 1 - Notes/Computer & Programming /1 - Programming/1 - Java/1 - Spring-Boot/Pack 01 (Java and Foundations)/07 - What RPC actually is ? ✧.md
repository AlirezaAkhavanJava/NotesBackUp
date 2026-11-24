

RPC(**Remote Procedure Call**) means calling a function or method that lives on another machine, but writing the code as if you were calling a normal, local method. You call `userService.getUser(5)`, and underneath, a library packages that call, sends it over the network to another process (maybe on another server entirely), that process runs the real `getUser(5)`, and the result gets shipped back to you. The "remote" part is hidden from how you write the code — that's the whole point of RPC as a style.

This matters a lot once you split an app into microservices. Your order-service can't just call `inventoryService.checkStock(itemId)` directly anymore, because `InventoryService` is a completely separate running application, maybe on a different machine. RPC is one of the main ways services talk to each other to close that gap.

## RPC vs REST — the distinction that trips people up

REST and RPC are often talked about as rivals, but REST (as commonly implemented with JSON over HTTP) is really just _one way_ of doing network communication, and it's not truly "RPC-style" in the strict sense. The difference:

- **REST** thinks in terms of **resources** and HTTP verbs: `GET /users/5`, `POST /orders`. The client doesn't call a named function — it manipulates a resource using standard HTTP semantics.
- **RPC** thinks in terms of **actions/methods**: `getUser(5)`, `createOrder(orderData)`. It doesn't care about HTTP verbs or resource URLs — it's modeled after calling a function.

In practice, a lot of what people loosely call "RPC in Spring Boot" is really REST calls between services that are _written_ in an RPC-like style (a Java interface with methods), even though under the hood it's still HTTP GET/POST. True binary RPC (like gRPC) is a separate, stricter thing. You'll meet both, so it's worth knowing them as two different tools.

## Doing "RPC-style" calls in Spring Boot: Feign

The most common way Spring Boot projects fake the "just call a method" feeling over HTTP is **Spring Cloud OpenFeign**. You declare an interface, and Spring generates the HTTP client for you at runtime — you never write `RestTemplate` boilerplate.

```java
@FeignClient(name = "inventory-service", url = "${inventory.service.url}")
public interface InventoryClient {

    @GetMapping("/stock/{itemId}")
    StockResponse checkStock(@PathVariable("itemId") Long itemId);

    @PostMapping("/stock/{itemId}/reserve")
    void reserveStock(@PathVariable("itemId") Long itemId, @RequestBody ReservationRequest request);
}
```

Then anywhere in your code:

```java
@Service
@RequiredArgsConstructor
public class OrderService {

    private final InventoryClient inventoryClient;

    public void placeOrder(Long itemId) {
        StockResponse stock = inventoryClient.checkStock(itemId);
        if (stock.quantity() > 0) {
            inventoryClient.reserveStock(itemId, new ReservationRequest(1));
        }
    }
}
```

`checkStock(itemId)` _looks_ like a plain Java method call — that's the RPC illusion. Behind the scenes, Feign builds an HTTP GET request to `inventory-service`, sends it, deserializes the JSON response into `StockResponse`, and hands it back. If `inventory-service` is registered with Eureka (your service registry), you can skip the hardcoded `url` entirely and just use the service name — Feign resolves it through the registry.

To enable it, you need:

```java
@SpringBootApplication
@EnableFeignClients
public class OrderServiceApplication { }
```

## True RPC in Spring Boot: gRPC

If you want _actual_ RPC (not HTTP+JSON dressed up to look like it), that's **gRPC**. It uses Protocol Buffers (protobuf) — a compact binary format — instead of JSON, and HTTP/2 instead of HTTP/1.1, which makes it noticeably faster and smaller over the wire than REST/Feign. You define the contract in a `.proto` file:

```proto
service InventoryService {
    rpc CheckStock (StockRequest) returns (StockResponse);
}

message StockRequest {
    int64 item_id = 1;
}

message StockResponse {
    int32 quantity = 1;
}
```

A build plugin (like `protobuf-maven-plugin`) generates the Java client and server classes from that file — you implement the server side as a plain Java class, and the client side gets injected as a bean (with `grpc-spring-boot-starter`), so calling it still feels like calling a local method:

```java
@GrpcService
public class InventoryGrpcService extends InventoryServiceGrpc.InventoryServiceImplBase {

    @Override
    public void checkStock(StockRequest request, StreamObserver<StockResponse> responseObserver) {
        int quantity = lookupQuantity(request.getItemId());
        responseObserver.onNext(StockResponse.newBuilder().setQuantity(quantity).build());
        responseObserver.onCompleted();
    }
}
```

gRPC is the right call when performance between internal services really matters (high call volume, low latency needs) and you control both ends of the connection. Feign/REST is the right call when you want something simpler, more human-debuggable (you can literally curl it), or when the API needs to be consumed by things outside your own services (browsers, third parties).

## Where this fits with what you already know

You've already got the pieces this plugs into: a service registry (Eureka) is what lets Feign find `inventory-service` by name instead of a hardcoded URL, and if you've got an API gateway in front of things, that gateway is usually what external clients hit — while Feign/gRPC calls happen _between_ your internal services, behind the gateway.


[[Spring Framework]]