A REST API is a way for programs to talk to each other over HTTP, where everything is treated as a **resource** (a user, a book, an order) identified by a URL, and you act on it using standard HTTP methods. REST stands for Representational State Transfer.

**Analogy:** Think of a restaurant. The URL is the menu item, the HTTP method is what you do with it (order, change, cancel), and the response is what the kitchen sends back. You don't need to know how the kitchen works; you only follow the agreed rules.

**Core mapping (CRUD to HTTP):**

|Action|Method|Example URL|
|---|---|---|
|Read all|`GET`|`/books`|
|Read one|`GET`|`/books/5`|
|Create|`POST`|`/books`|
|Update|`PUT` / `PATCH`|`/books/5`|
|Delete|`DELETE`|`/books/5`|

Data usually travels as JSON, and the server replies with a status code such as `200 OK`, `201 Created`, `404 Not Found`, or `500 Internal Server Error`.

**Key principles:**

- **Stateless:** each request carries everything the server needs; the server doesn't remember you between calls.
- **Resource-based URLs:** use nouns (`/books`), not verbs (`/getBooks`).
- **Uniform interface:** the same methods and conventions everywhere.

**In Spring Boot**, a REST API is a controller class:

```java
@RestController
@RequestMapping("/books")
public class BookController {

    @GetMapping("/{id}")
    public Book getBook(@PathVariable Long id) {
        return new Book(id, "Clean Code");
    }

    @PostMapping
    public ResponseEntity<Book> create(@RequestBody Book book) {
        return ResponseEntity.status(HttpStatus.CREATED).body(book);
    }
}

record Book(Long id, String title) {}
```

Spring automatically converts the `Book` object to JSON and back.

**Gotchas:**

- `PUT` replaces the whole resource, while `PATCH` changes only part of it.
- `GET` must never modify data; it should be safe to repeat.
- `PUT` and `DELETE` are idempotent (repeating them gives the same result), but `POST` is not.



[[API]]
[[Data-base]]
[[Java]]
[[C]]
[[Python]]
[[Java-Script]]