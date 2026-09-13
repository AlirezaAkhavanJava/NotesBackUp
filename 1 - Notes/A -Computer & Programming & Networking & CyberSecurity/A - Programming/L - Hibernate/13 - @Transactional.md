
The **`@Transactional`** annotation in Spring/Hibernate is used to **manage database transactions declaratively** — without manually calling `beginTransaction()`, `commit()`, or `rollback()`.

---

## 🔹 1. **In theory**

- Marks a method or class so that all database operations inside it are **executed within a transaction**.
    
- If any exception occurs, the transaction is **rolled back automatically**.
    
- If everything succeeds, the transaction is **committed automatically**.
    

---

## 🔹 2. **Basic Usage**

```java
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class StudentService {

    @Transactional
    public void saveStudent(Student student) {
        studentRepository.save(student);
        // If any exception happens here, the save will be rolled back
    }
}
```

- Here, `saveStudent()` runs inside a **transaction managed by Spring**.
    
- You **don’t need to manually open sessions or transactions**.
    

---

## 🔹 3. **Key Attributes of @Transactional**

|Attribute|Description|Default|
|---|---|---|
|`propagation`|Defines how transactions relate to existing ones (e.g., `REQUIRED`, `REQUIRES_NEW`)|`REQUIRED`|
|`isolation`|Sets isolation level (e.g., `READ_COMMITTED`, `SERIALIZABLE`)|`DEFAULT`|
|`timeout`|Maximum time (seconds) before transaction rolls back|-1 (no limit)|
|`readOnly`|Optimizes transaction for read-only operations|`false`|
|`rollbackFor`|Exceptions that should trigger rollback|RuntimeException (unchecked)|
|`noRollbackFor`|Exceptions that should **not** trigger rollback|-|

---

## 🔹 4. **Example with Attributes**

```java
@Transactional(
    propagation = Propagation.REQUIRED,
    isolation = Isolation.READ_COMMITTED,
    rollbackFor = Exception.class
)
public void updateStudent(Student student) {
    studentRepository.save(student);
}
```

- `Propagation.REQUIRED` → joins existing transaction or starts a new one.
    
- `Isolation.READ_COMMITTED` → prevents dirty reads.
    
- `rollbackFor = Exception.class` → rolls back even for checked exceptions.
    

---

## 🔹 5. **Class-Level Usage**

You can put `@Transactional` on a class so **all methods** are transactional:

```java
@Service
@Transactional
public class StudentService { ... }
```

---

### 🧭 Summary

> `@Transactional` lets Spring automatically **handle transaction boundaries**, commit on success, and rollback on failure.  
> It replaces manual `Session`/`Transaction` management and integrates seamlessly with Hibernate or JPA.



##### Tags : [[1 - ORM 🍪]]