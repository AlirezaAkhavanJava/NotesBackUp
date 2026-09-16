
## **1. WHAT ARE THEY?**

| Concept | Purpose | Method | Location |
|---------|---------|--------|----------|
| **Comparable** | Define *natural* ordering within a class | `compareTo()` | `java.lang` |
| **Comparator** | Define *custom* orderings separately | `compare()` | `java.util` |

---

## **2. COMPARABLE - NATURAL ORDERING**

**Comparable** lets a class define its **"natural"** sort order by implementing `compareTo()`.

### **2.1 Basic Example**

```java
public class Student implements Comparable<Student> {
    private int rollNo;
    private String name;
    private double gpa;

    public Student(int rollNo, String name, double gpa) {
        this.rollNo = rollNo;
        this.name = name;
        this.gpa = gpa;
    }

    // Natural ordering: by roll number
    @Override
    public int compareTo(Student other) {
        return Integer.compare(this.rollNo, other.rollNo);
    }

    @Override
    public String toString() {
        return rollNo + " - " + name + " (GPA: " + gpa + ")";
    }
}
```

**Usage:**
```java
List<Student> students = new ArrayList<>();
students.add(new Student(3, "Alice", 3.8));
students.add(new Student(1, "Bob", 3.5));
students.add(new Student(2, "Carol", 3.9));

Collections.sort(students); // Uses compareTo()

students.forEach(System.out::println);
```

**Output:**
```
1 - Bob (GPA: 3.5)
2 - Carol (GPA: 3.9)
3 - Alice (GPA: 3.8)
```

---

### **2.2 Understanding compareTo() Return Values**

```java
public int compareTo(Student other) {
    return Integer.compare(this.rollNo, other.rollNo);
}
```

| Return Value | Meaning |
|---|---|
| **Negative** | `this` comes before `other` |
| **Zero** | `this` equals `other` |
| **Positive** | `this` comes after `other` |

---

### **2.3 ⚠️ COMMON PITFALL - Subtraction Overflow**

```java
// ❌ WRONG - Can overflow for large integers
@Override
public int compareTo(Student other) {
    return this.rollNo - other.rollNo; // DANGER!
}

// ✅ CORRECT - Use Integer.compare()
@Override
public int compareTo(Student other) {
    return Integer.compare(this.rollNo, other.rollNo);
}
```

Example of overflow:
```java
int a = Integer.MAX_VALUE;
int b = -1;
System.out.println(a - b); // Overflow! Returns negative number
System.out.println(Integer.compare(a, b)); // Correct! Returns positive
```

---

---

## **3. COMPARATOR - CUSTOM ORDERINGS**

**Comparator** lets you define **multiple sort strategies** without modifying the class.

### **3.1 Using a Separate Comparator Class**

```java
// No need to implement Comparable
public class Student {
    private int rollNo;
    private String name;
    private double gpa;

    public Student(int rollNo, String name, double gpa) {
        this.rollNo = rollNo;
        this.name = name;
        this.gpa = gpa;
    }

    public int getRollNo() { return rollNo; }
    public String getName() { return name; }
    public double getGpa() { return gpa; }

    @Override
    public String toString() {
        return rollNo + " - " + name + " (GPA: " + gpa + ")";
    }
}

// Strategy 1: Sort by name
class NameComparator implements Comparator<Student> {
    @Override
    public int compare(Student s1, Student s2) {
        return s1.getName().compareTo(s2.getName());
    }
}

// Strategy 2: Sort by GPA (descending)
class GpaComparator implements Comparator<Student> {
    @Override
    public int compare(Student s1, Student s2) {
        return Double.compare(s2.getGpa(), s1.getGpa()); // Reversed
    }
}

// Strategy 3: Sort by roll number
class RollNoComparator implements Comparator<Student> {
    @Override
    public int compare(Student s1, Student s2) {
        return Integer.compare(s1.getRollNo(), s2.getRollNo());
    }
}
```

**Usage:**
```java
List<Student> students = new ArrayList<>();
students.add(new Student(3, "Alice", 3.8));
students.add(new Student(1, "Bob", 3.5));
students.add(new Student(2, "Carol", 3.9));

System.out.println("=== Sort by Name ===");
Collections.sort(students, new NameComparator());
students.forEach(System.out::println);

System.out.println("\n=== Sort by GPA (Descending) ===");
Collections.sort(students, new GpaComparator());
students.forEach(System.out::println);

System.out.println("\n=== Sort by Roll No ===");
Collections.sort(students, new RollNoComparator());
students.forEach(System.out::println);
```

---

### **3.2 Anonymous Classes (Old Java)**

```java
Collections.sort(students, new Comparator<Student>() {
    @Override
    public int compare(Student s1, Student s2) {
        return s1.getName().compareTo(s2.getName());
    }
});
```

---

### **3.3 Lambda Expressions (Java 8+)**

```java
// Sort by name
students.sort((s1, s2) -> s1.getName().compareTo(s2.getName()));

// Sort by GPA descending
students.sort((s1, s2) -> Double.compare(s2.getGpa(), s1.getGpa()));

// Sort by roll number
students.sort((s1, s2) -> Integer.compare(s1.getRollNo(), s2.getRollNo()));
```

---

---

## **4. SENIOR DEVELOPER PATTERNS - Comparator.comparing()**

### **4.1 Basic Comparator.comparing()**

The modern, readable way to create comparators:

```java
import java.util.Comparator;

// Single criterion
students.sort(Comparator.comparing(Student::getName));
students.sort(Comparator.comparing(Student::getRollNo));
students.sort(Comparator.comparing(Student::getGpa));
```

---

### **4.2 Multiple Criteria with thenComparing()**

Sort by department first, then by salary within each department:

```java
public class Employee {
    private String name;
    private String department;
    private double salary;

    public Employee(String name, String department, double salary) {
        this.name = name;
        this.department = department;
        this.salary = salary;
    }

    public String getName() { return name; }
    public String getDepartment() { return department; }
    public double getSalary() { return salary; }

    @Override
    public String toString() {
        return department + " - " + name + " ($" + salary + ")";
    }
}
```

**Usage:**
```java
List<Employee> employees = new ArrayList<>();
employees.add(new Employee("Alice", "Engineering", 95000));
employees.add(new Employee("Bob", "Sales", 70000));
employees.add(new Employee("Carol", "Engineering", 105000));
employees.add(new Employee("Dave", "Sales", 75000));

// Sort by department, then by salary within department
employees.sort(
    Comparator.comparing(Employee::getDepartment)
              .thenComparing(Employee::getSalary)
);

employees.forEach(System.out::println);
```

**Output:**
```
Engineering - Alice ($95000.0)
Engineering - Carol ($105000.0)
Sales - Bob ($70000.0)
Sales - Dave ($75000.0)
```

---

### **4.3 Reverse Ordering**

```java
// Descending order
employees.sort(Comparator.comparing(Employee::getSalary).reversed());

// Multiple criteria with reverse on one
employees.sort(
    Comparator.comparing(Employee::getDepartment)
              .thenComparing(Employee::getSalary, Comparator.reverseOrder())
);
```

---

### **4.4 Handling Nulls**

```java
// Put nulls first
employees.sort(
    Comparator.comparing(Employee::getName, Comparator.nullsFirst(String::compareTo))
);

// Put nulls last
employees.sort(
    Comparator.comparing(Employee::getName, Comparator.nullsLast(String::compareTo))
);
```

---

### **4.5 Complex Comparator Example - Senior Level**

```java
public class EmployeeService {
    
    private List<Employee> employees;
    
    // Reusable comparators
    private static final Comparator<Employee> BY_DEPARTMENT = 
        Comparator.comparing(Employee::getDepartment);
    
    private static final Comparator<Employee> BY_SALARY_DESC = 
        Comparator.comparing(Employee::getSalary).reversed();
    
    private static final Comparator<Employee> BY_NAME = 
        Comparator.comparing(Employee::getName);
    
    // Complex sorting: Department ASC, Salary DESC, Name ASC
    private static final Comparator<Employee> COMPLEX_ORDER = 
        BY_DEPARTMENT
            .thenComparing(BY_SALARY_DESC)
            .thenComparing(BY_NAME);
    
    public void sortEmployees() {
        employees.sort(COMPLEX_ORDER);
    }
    
    // Dynamic sorting based on criteria
    public List<Employee> sortBy(String criterion, boolean ascending) {
        Comparator<Employee> comparator = switch(criterion) {
            case "name" -> Comparator.comparing(Employee::getName);
            case "salary" -> Comparator.comparing(Employee::getSalary);
            case "department" -> Comparator.comparing(Employee::getDepartment);
            default -> throw new IllegalArgumentException("Unknown criterion");
        };
        
        if (!ascending) {
            comparator = comparator.reversed();
        }
        
        return employees.stream()
                        .sorted(comparator)
                        .toList();
    }
}
```

---

---

## **5. STREAMS WITH SORTING**

### **5.1 Stream Sorting Examples**

```java
// Sort and collect
List<Student> sorted = students.stream()
    .sorted(Comparator.comparing(Student::getName))
    .collect(Collectors.toList());

// Sort and print
students.stream()
    .sorted(Comparator.comparing(Student::getGpa).reversed())
    .forEach(System.out::println);

// Sort by multiple criteria
students.stream()
    .sorted(Comparator.comparing(Student::getRollNo)
                      .thenComparing(Student::getName))
    .limit(5)
    .collect(Collectors.toList());
```

---

---

## **6. COMPARABLE VS COMPARATOR - DECISION MATRIX**

| Scenario | Use Comparable | Use Comparator |
|----------|---|---|
| Class has natural order (ID, Date, etc.) | ✅ | |
| Multiple sort strategies needed | | ✅ |
| Don't want to modify class | | ✅ |
| Sorting third-party classes | | ✅ |
| Default behavior everywhere | ✅ | |
| Complex, dynamic sorting | | ✅ |
| Immutable data structure | ✅ | |

---

---

## **7. BEST PRACTICES (SENIOR LEVEL)**

### **7.1 Consistency with equals()**

```java
public class Student implements Comparable<Student> {
    private int rollNo;
    private String name;

    @Override
    public int compareTo(Student other) {
        if (this.rollNo != other.rollNo) {
            return Integer.compare(this.rollNo, other.rollNo);
        }
        return this.name.compareTo(other.name);
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof Student)) return false;
        Student other = (Student) obj;
        return this.rollNo == other.rollNo && this.name.equals(other.name);
    }

    @Override
    public int hashCode() {
        return Objects.hash(rollNo, name);
    }
}
```

**Rule:** If `compareTo()` returns 0, `equals()` should return true.

---

### **7.2 Documentation**

```java
/**
 * Compares students by their natural order: roll number (ascending).
 * Students with lower roll numbers come first.
 * 
 * @param other the student to compare with
 * @return negative if this < other, 0 if equal, positive if this > other
 * @throws NullPointerException if other is null
 */
@Override
public int compareTo(Student other) {
    return Integer.compare(this.rollNo, other.rollNo);
}
```

---

### **7.3 Immutability Matters**

```java
// ❌ Problem: Mutable objects in sorted collections can break ordering
public class MutableStudent implements Comparable<MutableStudent> {
    private int rollNo;
    
    public void setRollNo(int rollNo) { // Setter changes ordering!
        this.rollNo = rollNo;
    }
    
    @Override
    public int compareTo(MutableStudent other) {
        return Integer.compare(this.rollNo, other.rollNo);
    }
}

// ✅ Solution: Use immutable objects or avoid modifying sorted objects
public class ImmutableStudent implements Comparable<ImmutableStudent> {
    private final int rollNo;
    
    // No setter - immutable
    
    @Override
    public int compareTo(ImmutableStudent other) {
        return Integer.compare(this.rollNo, other.rollNo);
    }
}
```

---

### **7.4 Unit Testing Comparators**

```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class StudentComparatorTest {
    
    @Test
    public void testComparableOrdering() {
        Student s1 = new Student(1, "Bob", 3.5);
        Student s2 = new Student(2, "Alice", 3.8);
        
        assertTrue(s1.compareTo(s2) < 0, "s1 should come before s2");
        assertTrue(s2.compareTo(s1) > 0, "s2 should come after s1");
    }
    
    @Test
    public void testComparatorByName() {
        Student s1 = new Student(1, "Bob", 3.5);
        Student s2 = new Student(2, "Alice", 3.8);
        
        Comparator<Student> byName = Comparator.comparing(Student::getName);
        assertTrue(byName.compare(s2, s1) < 0, "Alice should come before Bob");
    }
    
    @Test
    public void testMultipleComparators() {
        List<Student> students = Arrays.asList(
            new Student(2, "Bob", 3.5),
            new Student(1, "Alice", 3.8),
            new Student(3, "Alice", 3.6)
        );
        
        students.sort(
            Comparator.comparing(Student::getName)
                      .thenComparing(Student::getRollNo)
        );
        
        assertEquals(1, students.get(0).getRollNo());
        assertEquals(3, students.get(1).getRollNo());
        assertEquals(2, students.get(2).getRollNo());
    }
}
```

---

---

## **8. REAL-WORLD EXAMPLE - E-COMMERCE Order Sorting**

```java
public class Order {
    private String orderId;
    private LocalDateTime createdAt;
    private double totalAmount;
    private String status;
    private String customerName;

    public Order(String orderId, LocalDateTime createdAt, double totalAmount, 
                 String status, String customerName) {
        this.orderId = orderId;
        this.createdAt = createdAt;
        this.totalAmount = totalAmount;
        this.status = status;
        this.customerName = customerName;
    }

    public String getOrderId() { return orderId; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public double getTotalAmount() { return totalAmount; }
    public String getStatus() { return status; }
    public String getCustomerName() { return customerName; }

    @Override
    public String toString() {
        return String.format("%s - %s - $%.2f - %s", orderId, customerName, totalAmount, status);
    }
}

public class OrderSortingService {
    
    private List<Order> orders;
    
    // Sort by most recent orders first
    public List<Order> getRecentOrders() {
        return orders.stream()
            .sorted(Comparator.comparing(Order::getCreatedAt).reversed())
            .collect(Collectors.toList());
    }
    
    // Sort by highest value orders
    public List<Order> getHighValueOrders() {
        return orders.stream()
            .sorted(Comparator.comparing(Order::getTotalAmount).reversed())
            .collect(Collectors.toList());
    }
    
    // Sort pending orders by date
    public List<Order> getPendingOrders() {
        return orders.stream()
            .filter(o -> "PENDING".equals(o.getStatus()))
            .sorted(Comparator.comparing(Order::getCreatedAt))
            .collect(Collectors.toList());
    }
    
    // Complex sorting: Pending first, then by date, then by amount
    public List<Order> getOrdersByPriority() {
        Comparator<Order> byPriority = Comparator
            .comparing((Order o) -> "PENDING".equals(o.getStatus()) ? 0 : 1)
            .thenComparing(Order::getCreatedAt)
            .thenComparing(Order::getTotalAmount, Comparator.reverseOrder());
        
        return orders.stream()
            .sorted(byPriority)
            .collect(Collectors.toList());
    }
}
```

**Usage:**
```java
public class Main {
    public static void main(String[] args) {
        List<Order> orders = Arrays.asList(
            new Order("O1", LocalDateTime.now().minusDays(5), 250.00, "COMPLETED", "Alice"),
            new Order("O2", LocalDateTime.now().minusDays(1), 500.00, "PENDING", "Bob"),
            new Order("O3", LocalDateTime.now().minusHours(2), 150.00, "PENDING", "Carol"),
            new Order("O4", LocalDateTime.now().minusHours(12), 1200.00, "COMPLETED", "Dave")
        );
        
        OrderSortingService service = new OrderSortingService();
        
        System.out.println("=== Recent Orders ===");
        service.getRecentOrders().forEach(System.out::println);
        
        System.out.println("\n=== High Value Orders ===");
        service.getHighValueOrders().forEach(System.out::println);
        
        System.out.println("\n=== Pending Orders ===");
        service.getPendingOrders().forEach(System.out::println);
        
        System.out.println("\n=== Orders by Priority ===");
        service.getOrdersByPriority().forEach(System.out::println);
    }
}
```

---

---

## **SUMMARY TABLE**

| Aspect | Comparable | Comparator |
|--------|------------|------------|
| **Interface** | `Comparable<T>` | `Comparator<T>` |
| **Method** | `compareTo(T o)` | `compare(T o1, T o2)` |
| **Package** | `java.lang` | `java.util` |
| **Parameters** | 1 (implicit this) | 2 |
| **Use Cases** | Natural order | Custom/multiple orders |
| **Lambdas** | Limited | Full support (Java 8+) |
| **Modifies Class** | Yes | No |
| **Multiple Impl.** | No | Yes (unlimited) |

---

## **KEY TAKEAWAYS FOR SENIORS**

✅ **Use `Comparable`** for single, natural ordering in domain models  
✅ **Use `Comparator`** for flexibility, multiple strategies, and functional programming  
✅ **Prefer `Comparator.comparing()`** over manual implementations  
✅ **Chain with `thenComparing()`** for multi-level sorts  
✅ **Always use `Integer.compare()`, not subtraction** to avoid overflow  
✅ **Keep comparators **consistent with `equals()`** for use in sorted collections  
✅ **Document** the ordering behavior clearly  
✅ **Test** comparators thoroughly with edge cases  





[[Java]]