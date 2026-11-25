
One of the main reasons we use DTOs (Data Transfer Objects) is to control which fields Jackson serializes into JSON and which fields it deserializes from JSON.


### **1. The problem with returning an Entity directly**

Imagine you have a JPA entity:

```java
@Entity
public class Account {

    @Id
    private Long id;

    private String username;

    private String password;

    private String email;

    private boolean admin;
}
```

If your controller returns this entity:

```java
@GetMapping("/account")
public Account getAccount() {
    return accountService.getAccount();
}
```

Spring MVC uses Jackson to serialize the returned object into JSON.

The result might be:

```json
{
  "id": 10,
  "username": "alireza",
  "password": "secret123",
  "email": "alireza@example.com",
  "admin": true
}
```

You probably **don't want to expose the password or administrative privileges** to the client.

Jackson doesn't inherently know which fields are sensitive or which fields belong in your public API. It serializes properties according to its configuration, annotations, and visibility rules.

### **2. The solution: DTO**

Create a DTO containing only the fields you want to expose:

``` java
public record AccountResponse(
        Long id,
        String username,
        String email
) {
}
```

Then return the DTO from your controller:

```java
@GetMapping("/account")
public AccountResponse getAccount() {

    Account account = accountService.getAccount();

    return new AccountResponse(
            account.getId(),
            account.getUsername(),
            account.getEmail()
    );
}
```

Now Jackson serializes the DTO:

```json
{
  "id": 10,
  "username": "alireza",
  "email": "alireza@example.com"
}
```

The password and admin flag are never included in this response because **they are not part of the DTO**.

### **3. DTOs also control incoming JSON**

Suppose a client sends a registration request:

```json
{
  "username": "alireza",
  "email": "alireza@example.com",
  "password": "secret123",
  "admin": true
}
```

You don't want clients to be able to assign themselves administrative privileges.

Instead of accepting your entity directly:

```java
@PostMapping("/register")
public Account register(@RequestBody Account account) {
    // Dangerous design
}
```

Use a request DTO:

```java
public record RegisterAccountRequest(
        String username,
        String email,
        String password
) {
}
```

And:

```java
@PostMapping("/register")
public void register(
        @RequestBody RegisterAccountRequest request
) {
    accountService.register(request);
}
```

Jackson deserializes the JSON into `RegisterAccountRequest`.

The `admin` field is not part of the request DTO, so it cannot be used through this DTO to assign administrative privileges.

You should still configure validation and authorization properly, but this design removes an unnecessary input path.

### **4. The architecture behind it**

**Client**

JSON Request / Response

**Controller + DTO**

API contract · Jackson serialization

**Service Layer**

Business logic

**JPA Entity**

Persistence model · Database

The important separation is:

- **Entity:** represents your persistence model.
    
- **Request DTO:** represents the data your API accepts.
    
- **Response DTO:** represents the data your API exposes.
    
- **Jackson:** converts JSON into Java objects and Java objects into JSON.
    

One more important point: DTOs are not only about hiding fields. They also prevent your API from becoming tightly coupled to your database schema. You can change your entity without necessarily breaking your API.

**Think of a DTO as a deliberate boundary between your internal application model and the outside world.**


[[Spring Framework]]