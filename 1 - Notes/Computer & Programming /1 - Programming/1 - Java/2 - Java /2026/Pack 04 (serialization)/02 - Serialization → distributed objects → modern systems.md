

## 1. Clarifying your sentence

You said another JVM can create new objects "from an object, not a class". Close, but the more precise version has three separate things:

1. **Class**: the code (`Person.class`). It exists on both machines beforehand and never travels.
2. **Object**: a live instance in one JVM's memory. It can't leave that JVM.
3. **Bytes**: a snapshot of the object's field values. This is what travels.

The receiver does: _new empty `Person` from its own class, then fill the fields from the bytes._ So the new object is made from a class, with values from an object.

## 2. Distributed objects: the big idea

Once you can ship state between JVMs, an ambitious idea follows: **make a call to an object on another machine look exactly like a local call.**

```java
calc.add(2, 3);   // looks local, but runs on a server across the network
```

This is called **RPC** (remote procedure call), and its object-oriented form is **distributed objects**. Java's built-in version is **RMI** (Remote Method Invocation).

### How it works: the proxy (stub)

1. The client holds a **stub**, a fake object that implements the same interface.
2. You call `calc.add(2, 3)` on the stub.
3. The stub serializes the method name and arguments into bytes and sends them over the network.
4. The server deserializes them, calls the **real** object, and serializes the result.
5. The stub deserializes the result and returns it as if nothing special happened.

Serialization is the transport layer under the whole thing. Here is the code:

```java
// Shared by both sides: the CONTRACT
public interface Calculator extends Remote {
    int add(int a, int b) throws RemoteException;
}

// Server
public class CalculatorImpl extends UnicastRemoteObject implements Calculator {
    public CalculatorImpl() throws RemoteException {}
    public int add(int a, int b) { return a + b; }
}
// ...
Registry reg = LocateRegistry.createRegistry(1099);
reg.rebind("calc", new CalculatorImpl());

// Client (needs only the Calculator interface, not the implementation)
Registry reg = LocateRegistry.getRegistry("server-host", 1099);
Calculator calc = (Calculator) reg.lookup("calc");
int result = calc.add(2, 3);   // network call
```

`calc` on the client is a stub, not a `CalculatorImpl`. The client only knows the interface.

### The critical rule: pass by value vs pass by reference

This is where your earlier question connects back, because RMI uses two different rules:

|Argument/return type|What travels|Result|
|---|---|---|
|`Serializable` object|A **copy** of its state (serialization)|Receiver gets an independent object. Changes on one side are **not** seen on the other|
|`Remote` object|A **stub** pointing back to the original|Receiver calls methods that run on the **original machine**|
|Neither||`NotSerializableException`|

Example of the trap:

```java
Report r = server.getReport();   // Report is Serializable: you got a COPY
r.setTitle("New");               // changes only your local copy; the server never knows
```

In a local call, passing an object shares it. In a remote call, a `Serializable` object is **cloned**. Code that looks identical behaves differently, and that is the root of the problem with this whole approach.

## 3. Why "looks like a local call" turned out to be a trap

Distributed computing has failure modes that local calls don't:

1. **Latency:** a local call takes nanoseconds, a network call milliseconds, about a million times slower. Innocent-looking loops like `for (...) remote.getItem(i)` become disasters.
2. **Partial failure:** the server may run your method and then crash before replying. Did the payment happen or not? Locally this can't occur.
3. **No shared memory:** the copy semantics above.
4. **Version skew:** client and server run different class versions (the `serialVersionUID` problem, now across teams and deployments).
5. **Security:** the server deserializes bytes from the network, which is the attack surface from section 6 of the notes.

This is why `RemoteException` is a **checked** exception on every RMI method. Java forces you to admit the call might fail.

A correction to what I said earlier: RMI is not deprecated. It still exists, but it is rarely used for new work, remote class downloading is disabled by default, and RMI Activation was removed in Java 17.

## 4. Onwards: from distributed _objects_ to distributed _messages_

The industry's lesson was: **stop pretending remote things are objects. Send explicit data over an explicit contract.**

|Era|Approach|Idea|
|---|---|---|
|1990s|RMI, CORBA|Remote objects, hidden network|
|2000s|SOAP / web services|XML messages, contract in WSDL|
|2010s|**REST + JSON**|Plain HTTP and data, language-neutral|
|Now|**gRPC + Protobuf**|RPC again, but with an explicit schema and cross-language stubs|
|Now|**Messaging** (Kafka, RabbitMQ)|Fire-and-forget events, with Avro or JSON|

Key shifts:

- **The wire format is independent of any class.** JSON or Protobuf don't care whether the receiver is Java, Python, or JavaScript.
- **The contract is explicit.** An OpenAPI spec or `.proto` file defines the shape of the data, instead of whatever your Java class happens to look like.
- **You send DTOs, not domain objects.** A DTO (data transfer object) is a plain data carrier made for the wire.

## 5. What this looks like in Spring Boot

```java
// DTO: a record, the modern way. Pure data, no behavior.
public record PersonDto(String name, int age) {}

// Service A exposes it
@RestController
class PersonController {
    @GetMapping("/person/{id}")
    PersonDto get(@PathVariable long id) {
        return new PersonDto("Alice", 25);   // Jackson serializes to JSON
    }
}

// Service B calls it. This is the modern "stub".
@Service
class PersonClient {
    private final RestClient client = RestClient.create("http://service-a");

    PersonDto fetch(long id) {
        return client.get().uri("/person/{id}", id)
                     .retrieve().body(PersonDto.class);   // JSON becomes an object again
    }
}
```

Compare with RMI:

- Same pattern: serialize, send, deserialize.
- **Difference:** service B has its own `PersonDto` class, which may even be different from A's. Only the JSON shape has to match. That loose coupling is the whole improvement.
- The network call is **visible** (`RestClient`, `retrieve()`), so nobody mistakes it for a local call.

The stub idea didn't die, it came back with honesty. Spring Cloud OpenFeign and gRPC both generate client stubs from an interface or schema, but they treat failure, timeouts, and versioning as first-class concerns.

## 6. Gotchas for later

- **Never expose your JPA entities directly** as the wire format. A database schema change then silently breaks every client. Map them to DTOs.
- **Schema evolution:** adding an optional field is safe, while renaming or removing one breaks old clients. Protobuf and Avro have formal rules for this, and JSON relies on convention (`@JsonIgnoreProperties(ignoreUnknown = true)`).
- **Idempotency:** because of partial failure, retries are inevitable, so remote operations should be safe to repeat (for example, a payment request carrying a unique ID).
- **Native serialization isn't gone:** it survives inside things like HTTP session replication and some caches, which is why you still need to understand it.

## Mental model to keep

```
Local call:    object ──pointer──▶ object              (same memory)
Remote call:   object ──serialize──▶ bytes ──network──▶ bytes ──deserialize──▶ NEW object
```

Everything in distributed systems is a variation on the bottom line. The differences between RMI, REST, gRPC, and Kafka are the format of the bytes, how strict the contract is, and how honest the API is about the network.




[[Java]]
[[Serialization]]
