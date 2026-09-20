

# Java: Pass by Value (Simple Version)

## 1. Core Idea

Java is **always pass by value**.  
But when you pass an **object**, Java passes a **copy of the reference**, not the object itself — this is why people get confused.

---

## 2. Primitives

Primitives (int, boolean, etc.) are **copied**.  
Changes inside a method **never affect the original**.

```java
void update(int a) { a = 100; }

int x = 50;
update(x);
System.out.println(x); // 50
```

---

## 3. Objects

Objects behave differently because the **reference is copied**, not the object.

- Changing the object → affects original
    
- Reassigning the reference → does NOT affect original
    

```java
class Person { int age; }

void modify(Person p) {
    p.age = 30;      // affects original
    p = new Person(); // does not affect original reference
    p.age = 50;
}

Person person = new Person();
person.age = 20;
modify(person);
System.out.println(person.age); // 30
```

---

## 4. Common Mistakes

- Java **does NOT have pass-by-reference**.
    
- You can change an object’s fields, but you **cannot** replace the caller’s reference.
    

---

## 5. Examples

### Primitives

```java
void change(int num) { num += 10; }

int x = 5;
change(x);
System.out.println(x); // 5
```

### Objects

```java
class Box { int value; }

Box b = new Box();
b.value = 10;

void update(Box box) { box.value = 20; }
update(b);

System.out.println(b.value); // 20
```

---

## 6. Modern Java (21–25)

- **Records** → immutable, no accidental changes
    
- **Pattern Matching** → cleaner object access
    
- **Virtual Threads** → same pass-by-value rules apply
    

---

## 7. Best Practices

1. Avoid unexpected mutation in methods
    
2. Prefer immutable objects (records)
    
3. Document methods that modify objects
    
4. Use defensive copying if you want safety
    

---

## 8. Summary

- Java = **pass by value** only
    
- Primitives → actual value copied
    
- Objects → reference is copied
    
- Changing object = visible
    
- Reassigning reference = not visible
    

---

[[Java]]