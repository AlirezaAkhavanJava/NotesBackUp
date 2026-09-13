
## What is REST?

**REST (Representational State Transfer)** is an architectural style for designing networked applications, particularly APIs. It leverages standard web protocols, primarily HTTP, to create scalable, stateless, and interoperable systems. RESTful APIs allow clients (e.g., web or mobile apps) to interact with server resources using well-defined operations.

**REST Philosophy**:

- **Stateless**: Each request contains all the information needed; the server does not store client state between requests.
- **Client-Server**: Separates client (UI) and server (data storage) concerns.
- **Uniform Interface**: Uses standard HTTP methods, status codes, and conventions.
- **Resource-Based**: Resources (e.g., users, orders) are identified by URLs and manipulated via HTTP methods.
- **Scalable**: Designed for distributed systems and microservices.

## Core REST Concepts

### 1. HTTP Methods

HTTP methods define the action to be performed on a resource identified by a URL.

|Method|Description|Example Use Case|
|---|---|---|
|`GET`|Retrieve a resource|Fetch user details: `GET /users/1`|
|`POST`|Create a new resource|Create a user: `POST /users`|
|`PUT`|Update an existing resource (full)|Update user: `PUT /users/1`|
|`PATCH`|Update part of a resource|Update user email: `PATCH /users/1`|
|`DELETE`|Remove a resource|Delete user: `DELETE /users/1`|

**Example**:

- `GET /api/users/1`: Retrieves user with ID 1.
- `POST /api/users`: Creates a new user with data in the request body.

### 2. HTTP Status Codes

Status codes indicate the result of an HTTP request.

| Code    | Category     | Description                                 | Example Use Case               |
| ------- | ------------ | ------------------------------------------- | ------------------------------ |
| **2xx** | Success      | `200 OK`: Request succeeded                 | Successful GET or POST         |
|         |              | `201 Created`: Resource created             | Successful POST                |
|         |              | `204 No Content`: Success, no body          | Successful DELETE              |
| **3xx** | Redirection  | `301 Moved Permanently`: Resource moved     | Redirect to a new URL          |
|         |              | `304 Not Modified`: Resource unchanged      | Cached resource is still valid |
| **4xx** | Client Error | `400 Bad Request`: Invalid request          | Malformed request syntax       |
|         |              | `401 Unauthorized`: Authentication required | Missing or invalid credentials |
|         |              | `403 Forbidden`: Access denied              | User lacks permission          |
|         |              | `404 Not Found`: Resource not found         | Invalid resource URL           |
| **5xx** | Server Error | `500 Internal Server Error`: Server failed  | Unexpected server issue        |
|         |              | `503 Service Unavailable`: Server down      | Server maintenance or overload |

**Example**:

- `200 OK`: Returned when fetching a user successfully.
- `404 Not Found`: Returned if a requested user ID does not exist.

### 3. JSON in REST APIs

**JSON (JavaScript Object Notation)** is the de facto standard for data exchange in REST APIs due to its simplicity and readability.

**Example JSON Payload** (for a POST request to create a user):

```json
{
    "username": "john_doe",
    "email": "john@example.com",
    "created_at": "2025-08-29T12:00:00Z"
}
```

**Response Example** (for a GET request):

```json
{
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "created_at": "2025-08-29T12:00:00Z"
}
```

**Key Points**:

- JSON is lightweight and language-agnostic.
- Use consistent naming conventions (e.g., camelCase or snake_case).
- Validate JSON schemas to ensure data integrity.

### 4. REST API Design Principles

- **Use Nouns for Resources**: URLs represent resources (e.g., `/users`, `/orders`).
- **Leverage HTTP Methods**: Map CRUD operations to HTTP methods (Create: POST, Read: GET, Update: PUT/PATCH, Delete: DELETE).
- **Version APIs**: Include versioning in URLs (e.g., `/api/v1/users`).
- **Use Query Parameters for Filtering**: E.g., `GET /users?role=admin`.
- **HATEOAS** (Hypermedia as the Engine of Application State): Include links in responses to guide clients.
    ```json
    {
        "id": 1,
        "username": "john_doe",
        "links": [
            { "rel": "self", "href": "/api/users/1" },
            { "rel": "orders", "href": "/api/users/1/orders" }
        ]
    }
    ```

[[0 - Spring Framework]]