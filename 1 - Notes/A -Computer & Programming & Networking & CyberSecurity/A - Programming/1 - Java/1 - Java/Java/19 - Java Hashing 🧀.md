Date : 2025-09-04




## 1. Introduction

- **Hashing:** Mapping data (objects) to integer values for quick retrieval.
    
- **hashCode():** Method that returns an integer representing an object.
    
- **equals():** Method to compare object contents for equality.
    
- **Comparable & Comparator:** Interfaces to define ordering of objects.
    

**Tip:** Think of hashing as a unique “ID” for objects used in hash-based collections like HashMap, HashSet.

---

## 2. hashCode() Method

### Beginner Level

- Default `hashCode()` comes from `Object` class.
    
- Use in **HashMap, HashSet, Hashtable**.
    

```java
String s1 = "Hello";
String s2 = "Hello";
System.out.println(s1.hashCode()); // same value
System.out.println(s2.hashCode()); // same value
```

**Tip:** Objects that are equal must have the same hashCode.

---

## 3. equals() Method

- Determines object equality.
    
- **Contract:**
    
    1. Reflexive: a.equals(a)
        
    2. Symmetric: a.equals(b) == b.equals(a)
        
    3. Transitive: if a.equals(b) and b.equals(c) then a.equals(c)
        
    4. Consistent: repeated calls give same result
        
    5. Non-nullity: a.equals(null) is false
        

```java
class Person {
    String name;
    int age;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Person)) return false;
        Person p = (Person) o;
        return age == p.age && name.equals(p.name);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, age);
    }
}
```

**Tip:** Always override `hashCode()` when overriding `equals()`.

---

## 4. Hash-based Collections

- **HashMap:** Key-value pairs using hashCode and equals.
    
- **HashSet:** Stores unique objects based on equals() and hashCode().
    
- **Hashtable:** Legacy synchronized version.
    

```java
Map<Person, String> map = new HashMap<>();
map.put(new Person("Alice", 25), "Developer");
```

**Tip:** Poor hashCode implementations lead to collisions and slower performance.

---

## 5. Comparable Interface

- Defines **natural ordering** of objects.
    
- Implement `compareTo()`.
    

```java
class Person implements Comparable<Person> {
    String name;

    @Override
    public int compareTo(Person p) {
        return this.name.compareTo(p.name);
    }
}

List<Person> list = new ArrayList<>();
Collections.sort(list); // uses compareTo
```

**Tip:** Comparable is used for **default sorting**.

---

## 6. Comparator Interface

- Defines **custom ordering**.
    
- Implement `compare()`.
    

```java
Comparator<Person> ageComparator = (p1, p2) -> Integer.compare(p1.age, p2.age);
Collections.sort(list, ageComparator);
```

- Can use **Comparator.comparing()** (Java 8+)
    

```java
list.sort(Comparator.comparing(Person::getAge));
```

**Tip:** Use Comparator for **multiple sorting criteria** or alternative orderings.

---

## 7. Hashing, equals, and Collections Together

- HashMap and HashSet use **hashCode first**, then **equals**.
    
- Priority:
    
    1. hashCode mismatch → different bucket
        
    2. hashCode match → equals() to confirm equality
        

**Tip:** Always implement **consistent equals() and hashCode()** for objects stored in hash-based collections.

---

## 8. Modern Java Features (21–25)

- **Records:** Auto-generate equals() and hashCode()
    
- **Pattern Matching:** Use with Comparator for concise comparison.
    
- **Streams API:** Sorting with Comparator chaining.
    
- **Virtual threads:** Collections maintain hashing performance in concurrent scenarios.
    

```java
records Person(String name, int surname) {}
List<Person> list = List.of(new Person("Alice", 25));
list.sort(Comparator.comparing(Person::name));
```

---

## 9. Best Practices

1. Always override **equals() and hashCode()** together.
    
2. Implement **Comparable** for natural ordering.
    
3. Use **Comparator** for custom or multiple criteria sorting.
    
4. Prefer **Objects.hash()** or **record default implementations** for hashCode.
    
5. Avoid mutable fields in hashCode/equals objects.
    

---

## 10. Real-World Usage

- HashMap/HashSet for caching, lookups, and unique collections.
    
- Sorting users or products using Comparable/Comparator.
    
- Records for clean and concise hashCode/equals implementation.
    

**Tip:** Correct implementation ensures **performance, correctness, and reliability** in enterprise systems.

---

## 11. Summary

- **hashCode:** unique integer ID for object.
    
- **equals:** compares object content.
    
- **Comparable:** natural ordering.
    
- **Comparator:** custom ordering.
    
- Modern Java features (records, streams, pattern matching) simplify and enhance hashing and sorting.
    

This guide ensures mastery of **hashing, equals, Comparable, Comparator** concepts from beginner to senior-level, including Java 25 enhancements.



##### *Tags : [[Java]]