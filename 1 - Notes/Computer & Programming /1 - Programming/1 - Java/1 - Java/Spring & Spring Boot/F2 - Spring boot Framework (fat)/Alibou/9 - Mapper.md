

A **Mapper** is simply **a converter**.  
It converts **one object type into another**, usually:

### **Entity ↔ DTO**

**Entity** = database model  
**DTO** = what you send to the client (API response / request objects)

A **Mapper** is the thing that copies data between them.

---

# ✅ Why do we need a Mapper?

Because:

- Entities contain **internal database stuff** (IDs, relations, lazy fields…)
    
- DTOs contain **clean, safe data** for the outside world
    
- You don’t want to expose your entire database structure to the frontend
    

So you write a mapper to transform between them.

---

# ✅ Example (Manual Mapper)

```java
public class UserMapper {

    public static UserDTO toDTO(User user) {
        return new UserDTO(
                user.getId(),
                user.getUsername(),
                user.getEmail()
        );
    }

    public static User toEntity(UserDTO dto) {
        User user = new User();
        user.setUsername(dto.getUsername());
        user.setEmail(dto.getEmail());
        return user;
    }
}
```

This is **a mapper**.  
A plain class with methods that **convert User → UserDTO and back**.

---

# ✅ MapStruct (Automatic Mapper)

Instead of writing those methods manually, you can use **MapStruct**, which generates the mapper for you at compile time.

Example:

```java
@Mapper(componentModel = "spring")
public interface UserMapper {

    UserMapper INSTANCE = Mappers.getMapper(UserMapper.class);

    UserDTO toDto(User user);

    User toEntity(UserDTO dto);
}
```

MapStruct creates the implementation automatically.  
This saves you tons of typing.

---

# 🔥 In short:

### **Mapper = Translator between objects.**

Entity → DTO  
DTO → Entity

That’s it. Nothing mystical. Just a clean way to avoid mixing your DB models with your API models.

---


###### Tags : [[0 - Spring Framework]]