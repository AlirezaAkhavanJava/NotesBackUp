


### **1. Definition**

- `@Transactional` is a **Spring annotation** that manages **database transactions** automatically.
    
- A transaction is a **unit of work** that must either **complete fully** or **roll back entirely** in case of errors.
    

---

### **2. Key Behavior**

1. **Begin transaction** when the method starts.
    
2. **Commit transaction** if the method completes successfully.
    
3. **Rollback transaction** automatically if an exception occurs (by default, on unchecked exceptions).
    

---

### **3. Usage**

```java
@Service
public class StudentService {

    @Autowired
    private StudentRepository studentRepository;

    @Transactional
    public void saveStudents(List<Students> students) {
        for (Students s : students) {
            studentRepository.save(s);
        }
        // If any exception occurs here, all inserts are rolled back
    }
}
```

- All saves are part of a single transaction.
    
- If one save fails, **none of the changes are applied** to the database.
    

---

### **4. Important Attributes**

|Attribute|Description|
|---|---|
|`propagation`|Defines how transactions behave when calling another transactional method (e.g., `REQUIRED`, `REQUIRES_NEW`)|
|`isolation`|Controls how changes in one transaction are visible to others (e.g., `READ_COMMITTED`, `SERIALIZABLE`)|
|`readOnly`|Optimizes for read-only operations (prevents accidental writes)|
|`rollbackFor`|Specify which exceptions should trigger a rollback|
|`noRollbackFor`|Specify exceptions that should **not** trigger a rollback|

---

### **5. Where to Use**

- Service layer is **most common**.
    
- Can also be used on repository or controller methods, but service layer is best practice.
    

---

### **6. Why It’s Important**

- Ensures **data consistency** and **integrity**.
    
- Handles **automatic rollback** without manual try-catch for DB operations.
    


---


### **1. Class-level vs Method-level**

- **Class-level `@Transactional`**
    
    ```java
    @Service
    @Transactional
    public class StudentService { … }
    ```
    
    - All public methods in the class are transactional by default.
        
    - You can **override** at the method level if needed.
        
- **Method-level `@Transactional`**
    
    ```java
    @Transactional
    public void saveStudent(Students s) { … }
    ```
    
    - Only that specific method participates in a transaction.
        
    - Useful for **fine-grained control**.
        

💡 **Rule of thumb:**

- Class-level is convenient when most methods are transactional.
    
- Method-level for exceptions or special behavior (e.g., read-only methods).
    

---

### **2. Propagation**

`propagation` defines **how a new transaction interacts with an existing one**.

|Propagation|Behavior|
|---|---|
|`REQUIRED`|Use existing transaction if present; otherwise start a new one. (default)|
|`REQUIRES_NEW`|Always starts a new transaction; suspends the existing one.|
|`SUPPORTS`|Executes within existing transaction if present; otherwise no transaction.|
|`NOT_SUPPORTED`|Executes without a transaction; suspends any existing transaction.|
|`MANDATORY`|Must run inside an existing transaction; throws exception if none exists.|
|`NEVER`|Must **not** run in a transaction; throws exception if one exists.|
|`NESTED`|Runs within a nested transaction if a transaction exists; otherwise acts like `REQUIRED`.|

---

### **3. Read-only Transactions**

- For queries that **don’t modify data**, use:
    

```java
@Transactional(readOnly = true)
public List<Students> getAllStudents() { … }
```

- Spring can optimize performance (e.g., avoid unnecessary flushing).
    

---

### **4. Rollback Behavior**

- By default, Spring **rolls back on unchecked exceptions** (`RuntimeException`)
    
- To roll back on checked exceptions:
    

```java
@Transactional(rollbackFor = Exception.class)
public void saveStudents(List<Students> students) { … }
```

- To prevent rollback for some exceptions:
    

```java
@Transactional(noRollbackFor = IllegalArgumentException.class)
```

---


##### Tags :[[0 - Spring Framework]]