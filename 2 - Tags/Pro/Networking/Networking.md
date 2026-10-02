**Networking** is how computers connect and exchange data. Everything you've just learned (REST, APIs) rides on top of it.

**Analogy:** The postal system. Every house has an **address** (IP), every apartment inside has a **number** (port), and there are agreed **rules** for packaging and delivering letters (protocols). Your computer is a house, and each running program is an apartment.

**Core building blocks:**

|Concept|Role|Example|
|---|---|---|
|**IP address**|Identifies a machine|`192.168.1.10`, `127.0.0.1` (yourself)|
|**Port**|Identifies a program on that machine|`8080` (Spring Boot default), `80` (HTTP), `443` (HTTPS)|
|**DNS**|Translates names to IPs|`google.com` becomes `142.250.x.x`|
|**Protocol**|Rules of communication|TCP, UDP, HTTP|
|**Client / Server**|Who asks vs. who answers|Browser asks, your Spring app answers|

**The layered model (simplified):**

1. **Application layer:** HTTP, the language your REST API speaks.
2. **Transport layer:** TCP or UDP, which moves data between programs.
3. **Network layer:** IP, which routes packets between machines.
4. **Physical layer:** Wi-Fi, cables, the actual signals.

Each layer only talks to the one above and below it, so HTTP doesn't care whether you're on Wi-Fi or Ethernet.

**TCP vs UDP:**

- **TCP:** reliable and ordered, with a connection handshake first. Used by HTTP, so REST uses it.
- **UDP:** fast but no delivery guarantee. Used for video calls and games.

**What happens when you call `http://localhost:8080/books/5`:**

1. `localhost` resolves to `127.0.0.1` (your own machine).
2. A TCP connection opens to port `8080`.
3. The client sends an HTTP request: `GET /books/5`.
4. Spring Boot's embedded server (Tomcat) receives it and runs your controller.
5. The response, with a status code and JSON, travels back over the same connection.

**Java example (a tiny HTTP client):**

```java
import java.net.URI;
import java.net.http.*;

public class Demo {
    public static void main(String[] args) throws Exception {
        HttpClient client = HttpClient.newHttpClient();
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:8080/books/5"))
                .GET()
                .build();

        HttpResponse<String> response =
                client.send(request, HttpResponse.BodyHandlers.ofString());

        System.out.println(response.statusCode()); // 200
        System.out.println(response.body());       // {"id":5,"title":"Clean Code"}
    }
}
```

**Useful on Debian 13:**

- `ip a` shows your IP addresses.
- `ss -tlnp` shows which ports are being listened on (you'll see `8080` when Spring Boot runs).
- `curl http://localhost:8080/books/5` makes the same request from the terminal.

**Gotchas:**

- Only one program can listen on a given port at once; starting two Spring apps on `8080` gives "Port already in use" (fix with `server.port=8081` in `application.properties`).
- `localhost` means "this machine" from the client's point of view, so another computer can't reach your app using `localhost`; it needs your real IP.
- HTTPS is HTTP wrapped in TLS encryption, not a different protocol.

[[Spring Framework]]
[[Java]]
[[C]]
[[Python]]
[[Java-Script]]
[[Rest-API]]
[[API]]
