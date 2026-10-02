`@RequestParam` is a Spring annotation used to extract **query parameters** or **form data** from an HTTP request.

Example:

```java
@GetMapping("/search")
public String search(@RequestParam String keyword, 
                     @RequestParam(defaultValue = "10") int limit) {
    return "Searching for: " + keyword + " with limit " + limit;
}
```

- If the client sends: `/search?keyword=java&limit=5`  
    → `keyword = "java"`, `limit = 5`.
    
- `defaultValue` sets a default if the parameter is missing.
    
- `required = false` makes the parameter optional.
    

💡 **Summary:**

- `@RequestParam` → **query parameters** (`?key=value`) or **form data**.
    
- `@PathVariable` → **URL path segments** (`/users/{id}`).
    

---
A **query parameter** is a part of a URL that comes **after the `?`** and is used to send data to the server. They usually follow the `key=value` format and multiple parameters are separated by `&`.

Example URL:

```
https://example.com/search?keyword=java&limit=10
```

Here:

- `keyword=java` → query parameter with key `keyword` and value `java`
    
- `limit=10` → query parameter with key `limit` and value `10`
    

💡 Notes:

- Everything after `?` is considered query parameters.
    
- Used for filtering, searching, pagination, or optional data in requests.
    
- Can be accessed in Spring with `@RequestParam`.
    
---
They serve **different purposes**, so in real applications you often use both:

- **`@PathVariable`** → for identifying a resource (required, part of the URL path)
    
    `/users/42`
    
    `42` → user ID
    
- **`@RequestParam`** → for optional filters, search criteria, or pagination (query parameters)
    
    `/users/42?sort=age&active=true`
    
    `sort=age` and `active=true` → query parameters
    

💡 **Rule of thumb:**

- Use **path variables** for **resource identification**.
    
- Use **query parameters** for **filtering, sorting, or optional info**.
    

In production, almost every API endpoint uses both sometimes.


- **`@PathVariable`** → “**Which resource?**”
    
    - Categories, IDs, usernames, etc.
        
    - Example: `/products/electronics` → `electronics` is the path variable.
        
- **`@RequestParam`** → “**How do I want it?**” (filters, options)
    
    - Sorting, limiting, searching, optional flags
        
    - Example: `/products/electronics?sort=price&limit=10` → `sort` and `limit` are query parameters.
        

So a real API might look like:

```java
@GetMapping("/products/{category}")
public List<Product> getProducts(
        @PathVariable String category,
        @RequestParam(required = false) String sort,
        @RequestParam(defaultValue = "20") int limit) {
    // fetch and return products in the category with sorting and limit
}
```

- `/products/electronics?sort=price&limit=10`  
    → Category = electronics, sorted by price, limit 10 items.
    

```java
URL: /products/electronics                   ?sort=price&limit=10
        |__________PathVariable__________|  |______Query Parameters______|
                 category                        sort=price, limit=10

```
##### Tags : [[0 - Spring Framework]]