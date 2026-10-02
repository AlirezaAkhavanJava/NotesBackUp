


### what makes an API "REST"?

**REST** stands for **Representational State Transfer**. It's not a technology or a protocol — it's an *architectural style*, a set of design rules described by Roy Fielding in his 2000 PhD dissertation.

> An API that follows these rules is called **RESTful**. The rules are:

### 1. Client–Server separation
The client (your app, browser, mobile phone) and the server (the database, business logic) are separate. Each can evolve independently.

[[4 - Seperation ☆]]

### 2. Statelessness
**Every request must contain everything the server needs to fulfill it.** The server does not remember your previous requests.

This is huge. It means:
- The server doesn't need to store session data between calls
- Any server in a fleet can handle any request
- It scales horizontally almost effortlessly

If you need to be "logged in," you send a token with *every single request*. The server doesn't remember you logged in earlier.

### 3. Everything is a Resource
Data is modeled as **resources** — nouns, not verbs — each identified by a URL.

```
/users          → the collection of all users
/users/42       → one specific user
/users/42/posts → all posts belonging to user 42
/posts/7        → one specific post
```

Notice: no `/getUser` or `/deletePost`. The URL names the *thing*; the HTTP method says what to *do* with it.

### 4. Uniform Interface (HTTP methods)

You act on resources using standard HTTP verbs:

| Method | Meaning | Example |
|--------|---------|---------|
| `GET` | Read a resource | `GET /users/42` |
| `POST` | Create a new resource | `POST /users` |
| `PUT` | Replace a resource entirely | `PUT /users/42` |
| `PATCH` | Update part of a resource | `PATCH /users/42` |
| `DELETE` | Remove a resource | `DELETE /users/42` |

This maps neatly onto CRUD: Create, Read, Update, Delete.

### 5. Representations
The server sends back a **representation** of the resource — usually JSON, sometimes XML or HTML. The resource itself (the row in the database) never leaves the server; you get a snapshot of it.

### 6. Cacheability & Layered System
Responses can be marked cacheable so clients don't re-fetch unchanged data. And clients don't need to know whether they're talking to the real server or a proxy/load balancer in between.



---

## A concrete example

Let's say you're building a blog. Here's what a REST API for it might look like.

**Get a user:**
```
GET /api/users/42 HTTP/1.1
Host: example.com
Accept: application/json
```

Response:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": 42,
  "name": "Ada Lovelace",
  "email": "ada@example.com"
}
```

**Create a new user:**
```
POST /api/users
Content-Type: application/json

{
  "name": "Alan Turing",
  "email": "alan@example.com"
}
```

Response:
```http
HTTP/1.1 201 Created
Location: /api/users/43
```

**Delete a user:**
```
DELETE /api/users/42
```
→ `204 No Content`

---

## Status codes matter

A big part of REST is using HTTP status codes correctly to say *what happened*:

- **2xx** — success
  - `200 OK` — here's your data
  - `201 Created` — I made the thing
  - `204 No Content` — done, nothing to return
- **4xx** — you messed up
  - `400 Bad Request` — malformed request
  - `401 Unauthorized` — who are you?
  - `403 Forbidden` — I know who you are, but no
  - `404 Not Found` — no such resource
  - `429 Too Many Requests` — slow down
- **5xx** — the server messed up
  - `500 Internal Server Error`
  - `503 Service Unavailable`

---

## What REST is *not*

A few common confusions worth clearing up:

- **REST ≠ HTTP.** REST is a style; HTTP is the protocol most people implement it with. You *could* do REST over something else, but in practice everyone means "REST over HTTP."
- **REST ≠ JSON.** JSON is just a popular representation format. REST APIs can return XML, HTML, plain text, etc.
- **Not every JSON API is RESTful.** Tons of APIs call themselves REST but are really just "JSON over HTTP with RPC-ish URLs" (e.g., `/getUserById?id=42`). They're *RESTish*, not REST.
- **REST ≠ GraphQL or SOAP.** Those are different approaches entirely.

---

## The part most APIs skip: HATEOAS

Fielding's original vision says responses should include **links** telling the client what it can do next — like a web page with hyperlinks. This is called **HATEOAS** (Hypermedia as the Engine of Application State):

```json
{
  "id": 42,
  "name": "Ada Lovelace",
  "_links": {
    "self":   { "href": "/users/42" },
    "posts":  { "href": "/users/42/posts" },
    "delete": { "href": "/users/42" }
  }
}
```

Almost nobody does this in practice, which is why people joke that **"REST" today just means "sane HTTP + JSON."** That's fine — just know the distinction exists.

---

## TL;DR

A REST API is a way to expose your data over HTTP where:

1. **Resources** are identified by URLs (`/users/42`)
2. **HTTP methods** say what to do (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`)
3. **Every request is self-contained** (stateless)
4. **Status codes** communicate outcomes
5. **Representations** (usually JSON) carry the data

Once you internalize "URLs are nouns, methods are verbs, every request stands alone," you basically get REST.




[[Spring Framework]]