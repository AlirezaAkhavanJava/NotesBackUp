

 @RequestBody **converts JSON sent by the client into a Java object**.

### **How it works**

1. Client sends JSON in an HTTP request:
    

```json
{
  "GamerName": "Alex",
  "playingGame": "Chess"
}
```

2. Controller receives it:
    

```java
@PostMapping("/gamers")
public String createGamer(@RequestBody GamersDTO dto) {
    // dto is now a Java object created from the JSON
    return "Gamer created!";
}
```

3. Spring automatically:
    

- Reads the JSON from the request body
    
- Converts it into the **GamersDTO** object using **Jackson** (or another message converter)
    
- You can then use the DTO like a normal Java object
    

---

✅ **Key points:**

- `@RequestBody` = JSON → Java object (incoming)
    
- `@ResponseBody` = Java object → JSON (outgoing)
    
- Usually used with DTOs, **never with Entities directly** for API safety.
    


##### Tags : [[0 - Spring Framework]]