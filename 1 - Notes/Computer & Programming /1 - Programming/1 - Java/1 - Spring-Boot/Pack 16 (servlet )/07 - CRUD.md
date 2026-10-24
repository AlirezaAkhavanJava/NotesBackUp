
# CRUD with Servlets

**Definition.** CRUD stands for **Create, Read, Update, Delete**, the four basic operations on any stored data. With servlets, you implement each operation as an HTTP method on a servlet. The HTTP verb tells the server what the client wants to do, and the URL tells it which item the operation applies to.

## The mapping from CRUD to HTTP

HTTP already has verbs that match the four operations. A CRUD servlet uses them directly:

|Operation|HTTP method|URL|Success status|
|---|---|---|---|
|Create|`POST`|`/books`|`201 Created`|
|Read all|`GET`|`/books`|`200 OK`|
|Read one|`GET`|`/books/{id}`|`200 OK`|
|Update|`PUT`|`/books/{id}`|`200 OK`|
|Delete|`DELETE`|`/books/{id}`|`204 No Content`|

The collection lives at `/books`. A single item lives at `/books/{id}`. This separation is the core design idea: the URL names the resource, and the method names the action.

## Why this design matters

Without a convention, you could write `/createBook`, `/deleteBook?id=3`, and `/updateBook`. Each endpoint would then need its own servlet and its own routing. With the HTTP verbs, one servlet handles the whole resource, and any client that knows HTTP can use it without reading your documentation.

The verbs also carry meaning that clients and caches rely on. `GET` must not change data. `PUT` and `DELETE` are **idempotent**, meaning that sending the same request twice leaves the server in the same state as sending it once. `POST` is not idempotent, which is why a double-submitted form can create two books.

## Step 1: The model

We will use an in-memory store for now, so you can focus on the servlet. Later you will replace it with a database.

```java
package com.example.demo.books;

public record Book(long id, String title, String author) {}
```

A `record` gives you a constructor, getters, `equals`, and `toString` automatically. Because the fields are final, an update creates a new `Book` rather than changing the old one. That is a deliberate choice and it keeps the code simple to reason about.

## Step 2: The repository

The repository holds the data and the operations on it. The servlet should only handle HTTP, not storage details.

```java
package com.example.demo.books;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

public class BookRepository {

    private final Map<Long, Book> books = new ConcurrentHashMap<>();
    private final AtomicLong sequence = new AtomicLong(0);

    public Book create(String title, String author) {
        long id = sequence.incrementAndGet();          // next ID, safe across threads
        Book book = new Book(id, title, author);
        books.put(id, book);
        return book;
    }

    public List<Book> findAll() {
        List<Book> result = new ArrayList<>(books.values());
        result.sort(Comparator.comparingLong(Book::id));
        return result;
    }

    public Optional<Book> findById(long id) {
        return Optional.ofNullable(books.get(id));
    }

    public Optional<Book> update(long id, String title, String author) {
        // computeIfPresent runs only when the key exists, atomically
        return Optional.ofNullable(
                books.computeIfPresent(id, (key, old) -> new Book(key, title, author)));
    }

    public boolean delete(long id) {
        return books.remove(id) != null;
    }
}
```

What each part does:

- `ConcurrentHashMap` allows several request threads to read and write at once without corrupting the map. A plain `HashMap` would not be safe here.
- `AtomicLong` produces unique IDs even when two `POST` requests arrive at the same moment. A plain `long` with `++` could hand out the same ID twice.
- The methods return `Optional` for lookups that may find nothing. This forces the caller to handle the missing case, which is where the 404 comes from.
- `update` uses `computeIfPresent`, which checks for the key and replaces the value in one atomic step. A separate "check then put" could race with a delete.

## Step 3: The servlet

This servlet handles all five operations on one URL pattern. The `/books/*` pattern matches both `/books` and `/books/anything`.

```java
package com.example.demo.books;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.net.URLDecoder;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@WebServlet("/books/*")
public class BookServlet extends HttpServlet {

    private final BookRepository repo = new BookRepository();

    // Converts a malformed ID such as /books/abc into a 400 response
    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            super.service(req, resp);                  // dispatches to doGet, doPost, ...
        } catch (IllegalArgumentException ex) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, ex.getMessage());
        }
    }

    // READ: GET /books or GET /books/{id}
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        Long id = idFromPath(req);
        resp.setContentType("text/plain");
        PrintWriter out = resp.getWriter();

        if (id == null) {
            for (Book book : repo.findAll()) {
                out.println(format(book));
            }
            return;
        }

        Optional<Book> book = repo.findById(id);
        if (book.isEmpty()) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "book " + id + " not found");
            return;
        }
        out.println(format(book.get()));
    }

    // CREATE: POST /books
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        if (idFromPath(req) != null) {
            resp.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED,
                    "POST goes to /books, not /books/{id}");
            return;
        }

        Map<String, String> form = readForm(req);
        String title = form.get("title");
        String author = form.get("author");
        if (isBlank(title) || isBlank(author)) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "title and author are required");
            return;
        }

        Book created = repo.create(title, author);
        resp.setStatus(HttpServletResponse.SC_CREATED);                 // 201
        resp.setHeader("Location", req.getRequestURI() + "/" + created.id());
        resp.setContentType("text/plain");
        resp.getWriter().println(format(created));
    }

    // UPDATE: PUT /books/{id}
    @Override
    protected void doPut(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        Long id = idFromPath(req);
        if (id == null) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "PUT needs /books/{id}");
            return;
        }

        Map<String, String> form = readForm(req);
        String title = form.get("title");
        String author = form.get("author");
        if (isBlank(title) || isBlank(author)) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "title and author are required");
            return;
        }

        Optional<Book> updated = repo.update(id, title, author);
        if (updated.isEmpty()) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "book " + id + " not found");
            return;
        }
        resp.setContentType("text/plain");
        resp.getWriter().println(format(updated.get()));
    }

    // DELETE: DELETE /books/{id}
    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        Long id = idFromPath(req);
        if (id == null) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "DELETE needs /books/{id}");
            return;
        }

        if (!repo.delete(id)) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "book " + id + " not found");
            return;
        }
        resp.setStatus(HttpServletResponse.SC_NO_CONTENT);              // 204, no body
    }

    // ---------- helpers ----------

    // Returns the ID from /books/{id}, or null for the collection URL /books
    private Long idFromPath(HttpServletRequest req) {
        String path = req.getPathInfo();          // null for /books, "/42" for /books/42
        if (path == null || path.equals("/")) {
            return null;
        }
        try {
            return Long.parseLong(path.substring(1));
        } catch (NumberFormatException ex) {
            throw new IllegalArgumentException("id must be a number, got: " + path.substring(1));
        }
    }

    // Reads key=value&key=value from the body for POST and PUT
    private Map<String, String> readForm(HttpServletRequest req) throws IOException {
        String body = new String(req.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        Map<String, String> form = new HashMap<>();
        if (body.isBlank()) {
            return form;
        }
        for (String pair : body.split("&")) {
            String[] parts = pair.split("=", 2);
            String key = URLDecoder.decode(parts[0], StandardCharsets.UTF_8);
            String value = parts.length == 2
                    ? URLDecoder.decode(parts[1], StandardCharsets.UTF_8)
                    : "";
            form.put(key, value);
        }
        return form;
    }

    private boolean isBlank(String s) {
        return s == null || s.isBlank();
    }

    private String format(Book b) {
        return b.id() + " | " + b.title() + " | " + b.author();
    }
}
```

## Walking through each operation

**The routing in `service`.** `HttpServlet.service` reads the HTTP method and calls the matching `doX` method. We override `service` only to catch the `IllegalArgumentException` thrown by `idFromPath` and turn it into a `400` response. This keeps the five `doX` methods free of repeated try-catch blocks.

**Reading the ID.** For a request to `/books/42`, `req.getPathInfo()` returns `"/42"`. The servlet strips the leading slash and parses the rest. For `/books`, the path info is `null`, which the code treats as "the whole collection." This is how one servlet distinguishes the two URL shapes.

**Create (`doPost`).** The method refuses `POST /books/42`, because creating a book with a chosen ID is not part of this design. It reads the form fields, validates them, and calls `repo.create`. On success it returns `201 Created` with a `Location` header pointing to the new resource. Clients use that header to find the item they just made. The body is the created book, so the client does not need a second request to see the result.

**Read (`doGet`).** One method serves two cases, selected by whether an ID is present. The collection case writes every book, one per line. The single-item case returns `404` when the ID does not exist. Note that `setContentType` comes before `getWriter()`, as we covered earlier.

**Update (`doPut`).** `PUT` replaces the whole resource, so the client sends both `title` and `author`. The method checks for existence through the `Optional` returned by `update`. If the book is missing, the client gets `404` and nothing is created. This is a deliberate difference from some APIs, which create the item if it does not exist.

**Delete (`doDelete`).** A successful delete returns `204 No Content`, meaning the request succeeded and there is nothing to send back. The repository's `delete` returns a boolean, which tells the servlet whether the item existed.

**Why `readForm` reads the body itself.** For `POST`, the container parses form fields, so `req.getParameter` works. For `PUT` and `DELETE`, the container does not parse the body into parameters, so `getParameter` returns `null`. Reading the raw body with `getInputStream()` works for both, so the code uses that for consistency. The `URLDecoder` step turns `%20` and `+` back into spaces and special characters.

## Testing with curl

Start the application and run these commands from a terminal on your Debian machine. The `-i` flag prints the status line and headers, so you can see the codes.

```bash
# CREATE two books
curl -i -X POST --data-urlencode "title=Dune" --data-urlencode "author=Frank Herbert" \
     http://localhost:8080/books
curl -i -X POST --data-urlencode "title=Neuromancer" --data-urlencode "author=William Gibson" \
     http://localhost:8080/books

# READ all, then one
curl -i http://localhost:8080/books
curl -i http://localhost:8080/books/1

# UPDATE book 1
curl -i -X PUT --data-urlencode "title=Dune Messiah" --data-urlencode "author=Frank Herbert" \
     http://localhost:8080/books/1

# DELETE book 2, then try to read it (expect 404)
curl -i -X DELETE http://localhost:8080/books/2
curl -i http://localhost:8080/books/2

# Bad input (expect 400)
curl -i http://localhost:8080/books/abc
```

`--data-urlencode` encodes the values for you, so spaces in names are safe.

## The same design in Spring Boot

Once you understand the servlet version, the Spring version is the same mapping expressed as annotations. Spring handles parameter extraction, status codes, and the body.

```java
@RestController
@RequestMapping("/books")
public class BookController {

    private final BookRepository repo;

    public BookController(BookRepository repo) {   // injected, not created here
        this.repo = repo;
    }

    @GetMapping
    public List<Book> all() {
        return repo.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Book> one(@PathVariable long id) {
        return repo.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Book> create(@RequestBody BookRequest body) {
        Book created = repo.create(body.title(), body.author());
        return ResponseEntity.created(URI.create("/books/" + created.id())).body(created);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Book> update(@PathVariable long id, @RequestBody BookRequest body) {
        return repo.update(id, body.title(), body.author())
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable long id) {
        return repo.delete(id)
                ? ResponseEntity.noContent().build()
                : ResponseEntity.notFound().build();
    }
}

public record BookRequest(String title, String author) {}
```

What this does: `@GetMapping`, `@PostMapping`, and the others replace the `doX` methods. `@PathVariable` replaces `idFromPath`, and `@RequestBody` replaces `readForm`, using JSON by default instead of form data. `ResponseEntity` replaces the manual status and header calls. The `BookRepository` is injected through the constructor, so the controller stays testable. Spring does the bean creation and the `DispatcherServlet` routing that our servlet did by hand.

## Common mistakes

- **Reading `PUT` or `DELETE` parameters with `getParameter`.** It returns `null` because the container only parses form bodies for `POST`. Read the raw body, as `readForm` does.
- **Forgetting `return` after `sendError`.** The method keeps running and tries to write into a committed response.
- **Using a plain `HashMap` or `long` counter.** Two simultaneous requests can corrupt the map or produce duplicate IDs. Use the concurrent types shown.
- **Mapping the servlet to `/*`.** This takes over every path, including the Spring controllers and the actuator endpoints. Keep it at `/books/*`.
- **Treating `POST` and `PUT` as interchangeable.** `POST` creates an item with a server-chosen ID. `PUT` replaces an item at a known URL. Clients depend on this distinction, especially for retries.
- **Expecting data to survive a restart.** The in-memory map is lost when the application stops. Persistence is the next step.
- **HTML forms cannot send `PUT` or `DELETE`.** Browsers support only `GET` and `POST` in forms. Spring offers a `HiddenHttpMethodFilter` for this, and you will meet it when you build pages with forms.




[[Servlet]]