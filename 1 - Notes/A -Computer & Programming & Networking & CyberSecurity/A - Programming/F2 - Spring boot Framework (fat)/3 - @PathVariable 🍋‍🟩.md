In Spring, `@PathVariable` is used to *extract values from the URI path itself.*

Example:

```java
@GetMapping("/users/{id}")
public User getUserById(@PathVariable Long id) {
    return userService.findById(id);
}
```

- If you call `/users/42`, Spring will pass `42` to the `id` parameter.
    
- It’s different from `@RequestParam`, which gets values from query parameters like `/users?id=42`.
    

So:

- **@PathVariable → from URL path**
    
- **@RequestParam → from URL query string**
    

Common in production for RESTful APIs.

---

`@PathVariable` **takes the value directly from the part of the URL that the client typed or accessed**. The server doesn’t look in query parameters or the body—just the URL path.

For example:

```java
@GetMapping("/products/{productId}")
public Product getProduct(@PathVariable int productId) {
    return productService.findById(productId);
}
```

- URL: `/products/101` → `productId` is `101`
    
- URL: `/products/202` → `productId` is `202`
    

It’s like saying: “Hey Spring, grab this piece of the URL and give it to my method parameter.”

It’s the standard way in REST APIs to make **clean, readable URLs**.

---

### 1️⃣ `@PathVariable` – when to use

- Use it when the value is **part of the URL hierarchy**.
    
- It identifies a **specific resource**.
    
- Makes URLs **RESTful and readable**.
    

**Example:**

```java
@GetMapping("/users/{id}")
public User getUser(@PathVariable Long id) { ... }
```

- URL: `/users/5` → fetch user with ID 5.
    

---

### 2️⃣ `@RequestParam` – when to use

- Use it for **filters, options, or query parameters**.
    
- Not part of the main resource path.
    
- Often **optional** or has a default.
    

**Example:**

```java
@GetMapping("/users")
public List<User> getUsers(@RequestParam(required = false) String country) { ... }
```

- URL: `/users?country=IR` → fetch users from IR.
    
- URL: `/users` → fetch all users.
    

---

✅ **Rule of thumb:**

- If the value **identifies the resource** → `@PathVariable`.
    
- If the value **modifies or filters the resource** → `@RequestParam`.
    



##### Tags : [[0 - Spring Framework]]