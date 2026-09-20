 `JpaRepository`’s `findById` **returns an `Optional<T>`**, not the entity itself.

---

### **Why Optional?**

- The entity with the given ID **might not exist**.
    
- `Optional` forces you to **handle the “not found” case**, avoiding `NullPointerException`.
    

---

### **Example**

```java
Optional<Gamers> gamerOpt = gamersRepository.findById(5L);

// Check if present
if (gamerOpt.isPresent()) {
    Gamers gamer = gamerOpt.get();
    // use gamer
} else {
    // handle not found
}
```

**Shortcut using orElseThrow():**

```java
Gamers gamer = gamersRepository.findById(5L)
                .orElseThrow(() -> new RuntimeException("Gamer not found"));
```

---

✅ **TL;DR:**

- `findById(ID)` → `Optional<Entity>`
    
- You must **unwrap the Optional** to get the entity safely.
    



##### Tags : [[0 - Spring Framework]]