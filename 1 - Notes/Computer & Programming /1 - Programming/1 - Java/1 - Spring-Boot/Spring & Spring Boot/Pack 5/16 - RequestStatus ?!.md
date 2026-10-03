


There is **no `@RequestStatus`**. A request doesn't _have_ a status; only a response does. The status code is the server's **answer** to "how did it go?", so it only exists on the way out.

```
Request  →  has: method, URL, headers, body        (no status)
Response →  has: STATUS, headers, body             (status lives here)
```

Think of mailing a letter: your letter has an address and contents, but no "delivered / rejected" stamp. That stamp is added by the post office when it replies.

## What the request has instead

The request side has its own "descriptors". Each one has an annotation or mapping attribute you already know:

|Request part|What it describes|How you read/restrict it|
|---|---|---|
|**Method** (GET, POST...)|the action wanted|`@GetMapping`, `@PostMapping`, `method =`|
|**URL path**|which resource|`@PathVariable`, `path =`|
|**Query string**|options / filters|`@RequestParam`, `params =`|
|**Headers**|metadata|`@RequestHeader`, `headers =`|
|**Cookies**|stored client data|`@CookieValue`|
|**Body**|the payload|`@RequestBody`, `consumes =`|

So the true mirror of `@ResponseStatus` is not a "status" at all. It's the **mapping attributes** (`method`, `consumes`, `params`, `headers`), which declare what kind of request a method accepts.

## The symmetry that does exist

|Direction|Reads / sets the body|Reads / sets metadata|Status|
|---|---|---|---|
|**IN** (request)|`@RequestBody`|`@RequestHeader`, `@RequestParam`, `@PathVariable`, `@CookieValue`|none|
|**OUT** (response)|`@ResponseBody`|`ResponseEntity` headers|`@ResponseStatus` / `ResponseEntity`|

The status is the one thing that has no input twin.

## Where the idea of "request status" comes from

Two things look like a request status but are not:

**1. The request line.** `GET /users/5 HTTP/1.1` is the first line of a request. It holds the method, path, and version. It looks like the response's status line (`HTTP/1.1 200 OK`) but contains no result code.

**2. The _outcome_ of checking a request.** When a request is invalid, the server answers with a 4xx **response**. So "bad request status" really means "the response status for a bad request":

|Request problem|Response status|
|---|---|
|Wrong verb|405|
|Unsupported body format (`consumes`)|415|
|Missing/invalid param, bad JSON, failed `@Valid`|400|
|Resource not found|404|

## If you want to track a request's progress

Sometimes you do want something like "status of my request", for example a long job. That's modeled as **data**, not as an HTTP feature:

```java
@PostMapping("/reports")
@ResponseStatus(HttpStatus.ACCEPTED)             // 202: "got it, working on it"
public Map<String, String> start() {
    String jobId = service.startReport();
    return Map.of("statusUrl", "/api/reports/" + jobId);
}

@GetMapping("/reports/{jobId}")
public JobStatus check(@PathVariable String jobId) {
    return service.status(jobId);                // {"state":"RUNNING"} / "DONE"
}
```

The "request status" is a resource the client polls, and the HTTP code (202, then 200) only describes each individual response.

## Nuances

**1. Status codes belong to responses by definition.** The HTTP spec defines them only for responses.

**2. The `Expect: 100-continue` header** is a request header that asks "may I send the body?", and the server replies with a `100 Continue` status. It's the closest thing to request/status interplay, but the status is still the server's.

**3. Don't confuse a request's _state_ in Spring.** Internally Spring tracks things like "handler found" or "exception raised", but that's framework plumbing, not something you annotate.




[[Spring Framework]]