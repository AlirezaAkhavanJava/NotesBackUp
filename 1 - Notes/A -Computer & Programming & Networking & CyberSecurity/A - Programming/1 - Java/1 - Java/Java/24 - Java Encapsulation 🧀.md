Date : 2025-09-04


## 1. Introduction

- **Encapsulation:** Wrapping data (fields) and methods that operate on the data into a single unit (class), restricting direct access.
    
- Promotes **data hiding, modularity, and maintainability**.
    

**Tip:** Think of it as putting data inside a protective capsule, only accessible via controlled methods.

---

## 2. Basic Implementation

### 2.1 Fields as Private

- Declare class variables as `private`.
    

### 2.2 Getter and Setter Methods

- Provide `public` methods to read/write fields.
    

```java
class Person {
    private String name;
    private int age;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public int getAge() { return age; }
    public void setAge(int age) {
        if(age >= 0) this.age = age;
        else throw new IllegalArgumentException("Age cannot be negative");
    }
}

Person p = new Person();
p.setName("Alice");
p.setAge(25);
System.out.println(p.getName());
```

**Tip:** Validation logic can be placed in setters.



>  Encapsulation allows me to protect my class’s internal state by making fields private.  
Because no one can access the fields directly, any value has to pass through my setter methods.  
Inside the setter, I can validate the value—if it’s acceptable, I store it; if not, I reject it.  
This ensures my object never enters an invalid or inconsistent state.

---

## 3. Benefits of Encapsulation

1. **Data Hiding:** Protects fields from unauthorized access.
    
2. **Controlled Access:** Provides getter/setter logic.
    
3. **Maintainability:** Easier to modify internals without affecting other code.
    
4. **Reusability:** Class can be reused safely in multiple contexts.
    

**Tip:** Encapsulation is one of the four **OOP pillars**.

---

## 4. Advanced Features

### 4.1 Read-only or Write-only

- Only provide getter or setter as needed.
    

```java
public class Config {
    private final String appName = "MyApp";
    public String getAppName() { return appName; } // read-only
}
```

### 4.2 Encapsulation in Inheritance

- Use `protected` fields or methods if child classes need access.
    

```java
class Vehicle {
    protected int speed;
}
class Car extends Vehicle {
    void setSpeed(int s) { speed = s; }
}
```

### 4.3 Encapsulation in Packages

- Default/package-private access keeps fields/methods visible only within the same package.
    

**Tip:** Control access at class, package, and inheritance level.

---

## 5. Modern Java Features (21–25)

- **Records:** Encapsulate data immutably with automatically generated getters.
    
- **Sealed Classes:** Control subclass access and preserve encapsulation.
    
- **Pattern Matching:** Safely access data in records/interfaces without breaking encapsulation.
    

```java
record Point(int x, int y) {}
Point p = new Point(10,20);
System.out.println(p.x()); // getter
```

**Tip:** Use modern features to reduce boilerplate and maintain encapsulation.

---

## 6. Best Practices

1. Keep **fields private**; provide controlled access.
    
2. Validate inputs in setters.
    
3. Use **immutable classes** whenever possible.
    
4. Keep **encapsulation consistent** with OOP principles.
    
5. Use **records, sealed classes, and modern Java features** for clean, encapsulated designs.
    

---

## 7. Real-World Usage

- Employee class with private salary field.
    
- Configuration objects in enterprise applications.
    
- DTOs in APIs using records.
    
- Secure access to sensitive data with validation.
    

**Tip:** Encapsulation ensures **security, correctness, and maintainability** in production code.

---

## 8. Summary

- Encapsulation is about **hiding data and exposing controlled access**.
    
- Achieved using **private fields, getters, setters, and controlled visibility**.
    
- Modern Java features like **records and sealed classes** improve encapsulation.
    
- Best practices: validate data, use immutability, and control access at class/package/inheritance level.
    

This guide ensures mastery of **Java Encapsulation from beginner to senior-level**, including updates up to Java 25.



##### *Tags : [[Java]]