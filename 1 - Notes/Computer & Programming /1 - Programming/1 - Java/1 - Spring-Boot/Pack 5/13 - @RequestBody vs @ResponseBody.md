


- **`@RequestBody`**: data coming **IN** to your method (client → server)
- **`@ResponseBody`**: data going **OUT** of your method (server → client)

The verbs (GET/POST) don't decide it. A single POST uses **both**:

```
POST /api/users
{ "name": "Ali" }   ──►  @RequestBody  ──► your method ──► @ResponseBody ──►  { "id": 7, "name": "Ali" }
      (IN)                                                      (OUT)
```

## Mental model: a customs counter

Your method is a customs counter at a border.

- `@RequestBody` = the **inbound lane**: a parcel arrives as raw text (JSON), and Spring unpacks it into a Java object.
- `@ResponseBody` = the **outbound lane**: you hand over a Java object, and Spring packs it into raw text (JSON) and sends it back.

The **same translator** (`HttpMessageConverter` / Jackson) works at both lanes, one direction each:

||Direction|Converter does|Position in code|
|---|---|---|---|
|`@RequestBody`|JSON → Java|**deserialize**|on a **parameter**|
|`@ResponseBody`|Java → JSON|**serialize**|on a **method** (or class)|

## Why your "GET vs POST" guess feels right (and where it breaks)

It feels right because the common cases line up:

|Typical request|`@RequestBody`?|`@ResponseBody`?|
|---|---|---|
|`GET /users/5`|no (no body sent)|**yes** (returns the user)|
|`POST /users`|**yes** (new user data)|**yes** (returns created user)|
|`PUT /users/5`|**yes**|**yes**|
|`DELETE /users/5`|no|usually no (204 empty)|

Where it breaks: **POST/PUT use both**, so it isn't "one for GET and one for POST". The better rule is:

- Does the client send a JSON body to me? → `@RequestBody`
- Do I return data in the body? → `@ResponseBody` (already on for you via `@RestController`)

## In code

```java
@RestController                                   // ← includes @ResponseBody for every method
@RequestMapping("/api/users")
public class UserController {

    // IN only: no body returned
    @PostMapping("/import")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void importUser(@RequestBody UserDto dto) { ... }

    // OUT only: no body received
    @GetMapping("/{id}")
    public UserDto getOne(@PathVariable Long id) { ... }

    // BOTH
    @PostMapping
    public UserDto create(@RequestBody UserDto dto) {
        return service.create(dto);
    }
}
```

## Key differences

||`@RequestBody`|`@ResponseBody`|
|---|---|---|
|Direction|in|out|
|Placed on|method **parameter**|**method** or class|
|Conversion|JSON → Java object|Java object → JSON|
|Chosen by header|`Content-Type` of the request|`Accept` of the request|
|Failure status|400 bad JSON, 415 wrong content type|406 can't produce that type, 500 can't serialize|
|Mapping attribute|`consumes`|`produces`|
|Needed in `@RestController`?|**Yes**, always write it|**No**, automatic|
|Can be omitted?|No (without it, Spring won't read the body)|Only in `@RestController`|
|How many per method|only one|one return value|

The last two rows are the most practical: `@RestController` gives you `@ResponseBody` for free, but `@RequestBody` you must always write yourself.

## Nuances and gotchas

**1. The `consumes`/`produces` pairing makes this easy to remember.** `consumes` = what the method **consumes** (the request body → `@RequestBody`). `produces` = what the method **produces** (the response body → `@ResponseBody`).

**2. Different headers pick the format.** The converter for `@RequestBody` is chosen by the request's `Content-Type`, but the one for `@ResponseBody` is chosen by `Accept`. So a client can send JSON and ask for XML back (if an XML converter exists). Mismatched cases produce 415 (can't read what you sent) or 406 (can't give what you want).

**3. Different types are fine on each side.** This is the good design:

```java
@PostMapping
public UserResponse create(@RequestBody UserRequest req) { ... }
```

In and out are separate DTOs, so a client can't send `id`, and you never leak internal fields back.

**4. `ResponseEntity` replaces `@ResponseBody`, not `@RequestBody`.** `ResponseEntity<T>` is another way to describe the **outgoing** side, with status and headers added. `@RequestBody` has no such replacement, because it's the only way to read the body. A similar wrapper for the incoming side exists (`HttpEntity<T>`, which gives you the body **and** the request headers), but it is rarely used.

**5. A method can have neither.** `GET /api/ping` returning `void` has no body in, none out.

**6. Don't confuse with `@RequestParam`.** That also brings data _in_, but from the query string/form, not the body. Three "in" annotations (`@PathVariable`, `@RequestParam`, `@RequestBody`), one "out" annotation (`@ResponseBody`).

## Quick memory trick

```
Request  → data arriving   → @RequestBody   → parameter
Response → data leaving    → @ResponseBody  → method
```




[[9 - Spring Container]]