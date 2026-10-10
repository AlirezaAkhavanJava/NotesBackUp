
# Incoming vs. Outgoing: Request, Response, and Outgoing Requests

I'm reading this as the **direction** of data relative to your application. There are really three things here, and the third is the one people usually miss.

## 1. Core intuition

Think of a phone. Your app is the phone:

- **Incoming call** → someone calls you, and you answer (a client calls your endpoint).
- **Your reply** → what you say back during that call.
- **Outgoing call** → you dial someone else (your app calls another service's API).

||Who starts it|Your app is the...|Typical DTOs|
|---|---|---|---|
|Incoming request|The client|**Server**|Request DTO (deserialized)|
|Outgoing response|You, as the answer|**Server**|Response DTO (serialized)|
|Outgoing request|Your app|**Client**|Request DTO (serialized)|
|Incoming response|The other service|**Client**|Response DTO (deserialized)|

The pattern: **incoming data is deserialized (JSON → Java), outgoing data is serialized (Java → JSON).** Jackson does both, using the same annotations you've learned.

## 2. Incoming request (client → your app)

An HTTP request has five parts, and Spring has an annotation for each:

```java
@PostMapping("/users/{id}/orders")
public OrderResponse create(
        @PathVariable Long id,                          // from the URL path
        @RequestParam(defaultValue = "false") boolean express,   // ?express=true
        @RequestHeader("X-Request-Id") String requestId,         // header
        @Valid @RequestBody CreateOrderRequest body) {           // JSON body
    ...
}
```

**What happens before your method runs:**

1. `DispatcherServlet` receives the request and finds the matching controller method.
2. An `HttpMessageConverter` (Jackson, for JSON) reads the body and builds your `CreateOrderRequest`. This is where `@JsonProperty`, `@JsonCreator`, and `@JsonFormat` apply.
3. `@Valid` triggers Bean Validation.
4. Only then is your method called.

This explains the error codes you'll see **without writing any code**:

|Failure|Status|
|---|---|
|Malformed JSON, wrong type (`"age": "abc"`)|`400` (`HttpMessageNotReadableException`)|
|Validation failed (`@NotBlank` etc.)|`400` (`MethodArgumentNotValidException`)|
|Body sent as `text/plain` instead of JSON|`415` Unsupported Media Type|
|No matching URL/method|`404` / `405`|

**Key mindset:** incoming data is **untrusted**. That's the whole reason request DTOs exist and carry validation.

## 3. Outgoing response (your app → client)

Whatever your method returns is serialized by the same converter:

```java
@PostMapping
public ResponseEntity<UserResponse> create(@Valid @RequestBody CreateUserRequest req) {
    UserResponse created = service.create(req);
    return ResponseEntity
            .status(HttpStatus.CREATED)                       // 201, not the default 200
            .header("Location", "/users/" + created.id())
            .body(created);
}
```

Returning the plain object gives status `200`. Use `ResponseEntity` when you need control over the **status code or headers**. This is where `@JsonInclude`, `@JsonIgnore`, and the response DTO shape matter.

## 4. Outgoing request (your app → another service)

This is a different situation: **your app becomes the client.** Examples: calling a payment provider, a weather API, or another microservice.

The modern tool is **`RestClient`** (Spring 6.1+, so Spring Boot 3.2 and later). `RestTemplate` is the older style, and `WebClient` is for reactive apps.

```java
// Shape of the EXTERNAL API's data (not your own API's DTO)
public record WeatherResponse(
    @JsonProperty("city_name") String cityName,
    @JsonProperty("temp_c") double tempC
) {}

@Configuration
public class HttpClientConfig {
    @Bean
    RestClient weatherClient(RestClient.Builder builder) {
        return builder
                .baseUrl("https://api.example-weather.com")
                .defaultHeader("Authorization", "Bearer " + "...")
                .build();
    }
}

@Service
public class WeatherService {

    private final RestClient client;

    public WeatherService(RestClient weatherClient) {
        this.client = weatherClient;
    }

    public WeatherResponse getWeather(String city) {
        return client.get()
                .uri("/v1/current?city={city}", city)
                .retrieve()
                .body(WeatherResponse.class);     // JSON → Java via Jackson
    }

    public PaymentResult pay(PaymentRequest req) {
        return client.post()
                .uri("/v1/payments")
                .body(req)                          // Java → JSON via Jackson
                .retrieve()
                .body(PaymentResult.class);
    }
}
```

**Why this connects to everything you've learned:** the external API usually has its own naming style (`snake_case`, odd keys). That is exactly the job of `@JsonProperty`, `@JsonAlias`, and `@JsonIgnoreProperties(ignoreUnknown = true)`, only now pointed at **someone else's contract**, not your own.

## 5. The full picture of one request

A client calls your `/weather/Berlin` endpoint, and your app calls the weather API to answer:

```
Client ──(1 incoming request)──▶ Your Controller
                                      │
                                      ▼
                                 Your Service ──(2 outgoing request)──▶ Weather API
                                      │         ◀─(3 incoming response)──
                                      ▼
Client ◀──(4 outgoing response)── Your Controller
```

Four DTO shapes can be involved. **Don't reuse one class for all of them.** Your API and the weather API will evolve independently, so map between them:

```java
public WeatherDto getForClient(String city) {
    WeatherResponse external = weatherService.getWeather(city);     // their shape
    return new WeatherDto(external.cityName(), external.tempC());   // your shape
}
```

This is the same buffer idea from DTOs, applied on the outgoing side. If the weather provider renames a field, only one mapping line changes, not your public API.

## 6. Gotchas

1. **Timeouts on outgoing requests.** By default, a call to a slow service can hang a thread for a long time. Always configure connect and read timeouts, because a slow dependency will otherwise take down your app. This is the most common production mistake with outgoing calls.
2. **Error handling is different.** `RestClient` throws exceptions on `4xx`/`5xx` by default (`HttpClientErrorException`, `HttpServerErrorException`). Catch these or use `.onStatus(...)` to translate them into your own errors, instead of leaking the other service's failures to your client.
3. **Never forward untrusted input blindly** into an outgoing URL or body. Building `uri("/users/" + userInput)` by string concatenation can allow path injection. Use URI template variables (`{city}`) as shown, because they are encoded safely.
4. **Don't put secrets in code.** Load API keys from `application.properties` or environment variables.
5. **`@RequestBody` reads the stream once.** You can't read the body again in a filter and then in the controller without caching it. This confuses many beginners who add logging filters.
6. **GET requests shouldn't carry a body.** Data for GET goes in the path or query parameters.

## 7. Summary

- **Incoming** = deserialize and **validate** (untrusted).
- **Outgoing** = serialize and **shape** (what you choose to reveal).
- A request has a **direction relative to your app**, and the same app is a server for one and a client for the other.
- The same Jackson annotations work everywhere, and separate DTOs per boundary keep each contract independent.






[[Spring Framework]]