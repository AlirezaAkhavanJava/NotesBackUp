
# **@JsonProperty in Spring Boot (Jackson)**

## **1. Definition**

`@JsonProperty` is a **Jackson annotation** used to control:

- the **JSON field name** during serialization (Java → JSON)
    
- the **JSON field name** during deserialization (JSON → Java)
    
- optional behavior like marking something as required
    

It’s mainly used on **fields**, **getters**, **setters**, and **constructor params**.

---

# **2. Why It Exists**

Because:

1. Your Java variable names and JSON keys don't always match.
    
2. You want cleaner JSON but different internal names.
    
3. You need to map snake_case JSON to camelCase Java (very common).
    
4. You need to mark a field required.
    

---

# **3. How It Works (Core Concept)**

### **Serialization**

Java → JSON  
The annotation tells Jackson:  
**"When writing this field to JSON, use _this_ name."**

### **Deserialization**

JSON → Java  
Jackson will look for that JSON field when creating your object.

---

# **4. Basic Example**

### Java class:

```java
public class User {
    @JsonProperty("full_name")
    private String name;

    @JsonProperty("userAge")
    private int age;

    // getters and setters
}
```

### JSON produced:

```json
{
  "full_name": "Ethan",
  "userAge": 22
}
```

### JSON accepted:

```json
{
  "full_name": "Ethan",
  "userAge": 22
}
```

Notice Java fields `name` and `age` don’t matter. The JSON side obeys `@JsonProperty`.

---

# **5. Map snake_case → camelCase**

Very common when consuming APIs:

```java
public class Employee {

    @JsonProperty("first_name")
    private String firstName;

    @JsonProperty("last_name")
    private String lastName;
}
```

---

# **6. Using on Constructor Parameters (important)**

If you use a constructor to create the object, Jackson must know which JSON key matches which parameter:

```java
public class Person {
    private final String name;
    private final int age;

    public Person(@JsonProperty("full_name") String name,
                  @JsonProperty("age") int age) {
        this.name = name;
        this.age = age;
    }
}
```

---

# **7. Marking a Field as Required**

```java
@JsonProperty(value = "email", required = true)
private String email;
```

If "email" is missing in JSON, deserialization will fail.

---

# **8. Using on Setters / Getters**

If you prefer method-level annotations:

```java
private String username;

@JsonProperty("user_name")
public String getUsername() {
    return username;
}

@JsonProperty("user_name")
public void setUsername(String username) {
    this.username = username;
}
```

---

# **9. Advanced Behaviour**

### **a) Rename only for serialization**

```java
@JsonProperty(access = JsonProperty.Access.READ_ONLY)
```

Example: expose field only in responses, not allowed in requests.

### **b) Rename only for deserialization**

```java
@JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
```

Example: password field.

---

# **10. Real Spring Boot Example (DTO)**

```java
public class LoginRequest {

    @JsonProperty("user_email")
    private String email;

    @JsonProperty("user_pass")
    private String password;
}
```

POST JSON:

```json
{
  "user_email": "ethan@example.com",
  "user_pass": "1234"
}
```

---

# **Summary**

`@JsonProperty` lets you **control JSON names** for fields, getters, setters, or constructor params.  
It’s crucial for:

- handling different naming conventions (snake_case ↔ camelCase)
    
- defining API request/response formats
    
- controlling read/write access
    
- marking fields required
    

---

> *@JsonAlias*


###### Tags : [[0 - Spring Framework]]