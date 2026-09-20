
## 1. CRUD

**CRUD** = the four fundamental operations performed on persistent data.

|Operation|Meaning|HTTP|Spring example|
|---|---|---|---|
|**C**reate|Create new data|`POST`|`POST /users`|
|**R**ead|Retrieve data|`GET`|`GET /users/42`|
|**U**pdate|Modify existing data|`PUT` / `PATCH`|`PATCH /users/42`|
|**D**elete|Remove data|`DELETE`|`DELETE /users/42`|

In a typical Spring Boot application:

```text
HTTP Request
     ↓
Controller
     ↓
Service
     ↓
Repository
     ↓
Database
```

Example:

```java
@PostMapping("/users")
public User createUser(@RequestBody User user) {
    return userService.create(user);
}
```

The repository might then use Spring Data JPA:

```java
public interface UserRepository
        extends JpaRepository<User, Long> {
}
```

`JpaRepository` already provides many CRUD operations:

```java
save()
findById()
findAll()
deleteById()
existsById()
```

**Mental model:** CRUD is the basic data-management layer of most backend applications.

---

# 2. OCR

**OCR = Optical Character Recognition**

OCR is **not primarily a Spring concept**. It is a technology used by a Spring application to extract text from images or scanned documents.

For example, your **receipt/warranty tracker** could work like this:

```text
Receipt Image
     ↓
Spring Boot
     ↓
OCR Engine
     ↓
"Samsung Galaxy S25"
"€899"
"2026-09-20"
     ↓
Java objects
     ↓
PostgreSQL
```

Suppose the user uploads:

```text
receipt.jpg
```

Your Spring controller could receive it:

```java
@PostMapping("/receipts")
public Receipt upload(@RequestParam MultipartFile file) {
    // send image to OCR service
    // extract text
    // save receipt
}
```

The OCR itself might be provided by something such as **Tesseract**, Google Cloud Vision, AWS Textract, or another OCR API.

So:

> **Spring Boot handles the web/API/business logic; an OCR engine performs the image → text recognition.**

---

# 3. Auth

**Auth** is commonly used as shorthand for **authentication and authorization**, although technically they are two different concepts.

### Authentication

**"Who are you?"**

Example:

```text
POST /login

email: alice@example.com
password: ********
```

The backend verifies the credentials.

```text
Client
  ↓
Spring Security
  ↓
UserRepository
  ↓
Database
  ↓
Credentials verified
```

The application may then issue a **session cookie** or **JWT**.

---

### Authorization

**"What are you allowed to do?"**

For example:

```text
Alice → ROLE_USER
Bob   → ROLE_ADMIN
```

Then:

```text
GET /receipts/123
        ↓
USER → allowed

DELETE /users/123
        ↓
USER → denied
ADMIN → allowed
```

In Spring, this is primarily handled by **Spring Security**.

For example:

```java
@PreAuthorize("hasRole('ADMIN')")
@DeleteMapping("/users/{id}")
public void deleteUser(@PathVariable Long id) {
    userService.delete(id);
}
```

### The important distinction

```text
Authentication
     ↓
Who are you?
     ↓
Authorization
     ↓
What can you do?
```

A typical Spring application therefore looks like:

```text
                 Spring Boot
                     │
        ┌────────────┼────────────┐
        ↓            ↓            ↓
       CRUD         OCR          Auth
        │            │            │
   JPA/Database   OCR Engine   Spring Security
```

**In short:**

- **CRUD** → manipulate application data.
    
- **OCR** → extract text/data from images or documents.
    
- **Auth** → establish identity and control access to resources.


[[Java]]