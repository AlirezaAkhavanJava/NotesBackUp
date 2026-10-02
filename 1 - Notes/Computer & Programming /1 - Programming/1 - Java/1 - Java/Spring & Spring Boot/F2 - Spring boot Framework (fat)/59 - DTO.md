

# 1️⃣ DEFINITIONS

## **Entity**

An **Entity** is a **persistent domain object managed by JPA/Hibernate**.  
It represents a table in the database.

- Annotated with `@Entity`
    
- Exists to be **saved**, **updated**, **deleted**, **queried**
    
- Has JPA/Hibernate annotations: `@Id`, `@Column`, `@ManyToOne`, etc.
    
- Part of the persistence layer
    

Think: **Entity = database representation**.

---

## **DTO (Data Transfer Object)**

A **DTO** is a **plain data object used to transfer data between layers** or across the network (API).

- Not tied to DB
    
- No JPA annotations
    
- Used to shape data for controllers, requests, or responses
    
- Focused only on what _should be exposed_ or _taken as input_
    

Think: **DTO = communication representation**.

---

# 2️⃣ RELATED COMPONENTS

### a) **Repository Layer**

- Works directly with **Entities**
    
- Cannot use DTOs for persistence
    
- Example: `CustomerRepository.save(Customer entity)`
    

### b) **Service Layer**

- The "business logic” layer
    
- Converts **Entity → DTO** or **DTO → Entity**
    
- Makes decisions and coordinates logic
    

### c) **Controller Layer**

- The layer where HTTP input/output happens
    
- Must NEVER expose Entities — this leaks your database schema
    

### d) **Mapper**

- Optional but recommended
    
- Automates transforming Entities ↔ DTOs
    
- Examples: MapStruct, ModelMapper, manual conversion
    

---

# 3️⃣ EXAMPLES

## Example 1 — Entity

```java
@Entity
@Table(name = "customers")
public class Customer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String email;

    @ManyToOne
    private Address address;
}
```

### Explanation:

- This class matches a database table.
    
- Hibernate manages it.
    
- It should NOT be exposed directly as API output.
    

---

## Example 2 — DTO

### DTO for output (Response DTO)

```java
public class CustomerResponseDTO {
    private Long id;
    private String name;
    private String email;
}
```

### DTO for input (Request DTO)

```java
public class CustomerRequestDTO {
    private String name;
    private String email;
}
```

### Explanation:

- Request DTO: only fields client is allowed to send
    
- Response DTO: only fields client is allowed to see
    
- You control your API shape independent from the DB
    

---

## Example 3 — Service Layer Conversion

```java
@Service
@RequiredArgsConstructor
public class CustomerService {

    private final CustomerRepository repo;

    public CustomerResponseDTO createCustomer(CustomerRequestDTO dto) {
        Customer entity = new Customer();
        entity.setName(dto.getName());
        entity.setEmail(dto.getEmail());

        Customer saved = repo.save(entity);

        return new CustomerResponseDTO(
            saved.getId(),
            saved.getName(),
            saved.getEmail()
        );
    }
}
```

### Explanation:

- Input DTO → converted to Entity → saved
    
- Resulting Entity → converted to Output DTO → sent to caller
    
- Entity never leaves the service layer
    
- DTO never enters the repository layer
    

---

# 4️⃣ METHODS & RULES YOU MUST KNOW

## ✔ Entities – what they can do:

- Be persisted (`save`, `find`, `delete`)
    
- Contain JPA relationships (e.g., `@OneToMany`)
    
- Hold internal domain logic if needed (DDD style)
    

## ❌ Entities – what they must NOT do:

- Be exposed directly to the client
    
- Receive request data
    
- Contain presentation logic
    
- Contain sensitive internal fields that might leak
    

---

## ✔ DTOs – what they can do:

- Shape API request/response
    
- Validate input (with `@NotNull`, `@Email`)
    
- Hide internal details from clients
    

## ❌ DTOs – what they must NOT do:

- Be persisted
    
- Have JPA annotations
    
- Contain business logic
    

---

# 5️⃣ PROFESSIONAL / ADVANCED DEPTH

### **Why exposing Entities is dangerous**

- You leak internal DB structure
    
- Changes to your DB BREAK your API
    
- Lazy-loaded relationships cause serialization failure
    
- You may accidentally expose sensitive fields
    
- Entities often contain relationships → infinite recursion (`@OneToMany` loops)
    

### **Why DTOs scale better**

- API layer stays stable when database changes
    
- Better security
    
- Clear separation of concerns
    
- Cleaner versioning
    
- You define EXACTLY what the client can send or receive
    
- Perfect for microservices and distributed systems
    

---

# 6️⃣ THE REAL WORKFLOW (FULL PIPELINE)

🔥 **This is the exact workflow used in real production systems.**

---

### **🔸 Step 1: Client sends JSON**

```json
{
  "name": "Ethan",
  "email": "ethan@example.com"
}
```

---

### **🔸 Step 2: Controller receives DTO**

```java
@PostMapping("/customers")
public CustomerResponseDTO create(@RequestBody CustomerRequestDTO dto) {
    return service.createCustomer(dto);
}
```

- Controller knows ONLY about DTO
    
- It never touches any Entity
    

---

### **🔸 Step 3: Service converts DTO → Entity**

```java
Customer customer = mapper.toEntity(dto);
```

---

### **🔸 Step 4: Repository saves Entity**

```java
Customer saved = repo.save(customer);
```

---

### **🔸 Step 5: Service converts Entity → Response DTO**

```java
CustomerResponseDTO response = mapper.toDto(saved);
```

---

### **🔸 Step 6: Controller returns DTO to client**

```json
{
  "id": 15,
  "name": "Ethan",
  "email": "ethan@example.com"
}
```

Client NEVER sees the entity structure.  
DB changes NEVER break the API.  
Clean and correct engineering.

---

# SUMMARY: WHEN TO USE WHICH?

|Layer|Use Entity?|Use DTO?|
|---|---|---|
|Controller|❌ Never|✔ Always|
|Service|✔—internally|✔ For communication|
|Repository|✔ Required|❌ Never|
|Database|✔ Entity maps|❌ Not used|

---




##### Tags : [[0 - Spring Framework]]