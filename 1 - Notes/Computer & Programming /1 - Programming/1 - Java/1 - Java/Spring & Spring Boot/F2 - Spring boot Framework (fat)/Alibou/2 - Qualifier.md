
# **@Qualifier in Spring — Full Breakdown**

## **1. What @Qualifier Is**

`@Qualifier` tells Spring **which specific bean to inject** when multiple beans share the same type.

It is used together with:

- `@Autowired`
    
- Constructor injection
    
- Method injection
    
- `@Bean` methods
    

Without it, Spring gets confused and throws:

```
NoUniqueBeanDefinitionException
```

---

# **2. Why You Need It**

If you have **two or more beans of the same type**, Spring doesn't know which one you want.

Example:

```java
@Component
class Dog implements Animal {}

@Component
class Cat implements Animal {}
```

Now Spring has **two Animal beans** → injection conflict.

---

# **3. How @Qualifier Works**

## **Option A – On the injection point**

```java
@Autowired
@Qualifier("cat")
private Animal animal;
```

## **Option B – With constructor injection**

```java
public Zoo(@Qualifier("dog") Animal animal) {
    this.animal = animal;
}
```

## **Option C – On @Bean methods**

```java
@Bean("secureDataSource")
public DataSource secureDS() { ... }

@Bean("loggingDataSource")
public DataSource loggingDS() { ... }
```

Inject it like this:

```java
public MyService(@Qualifier("secureDataSource") DataSource ds) {
    this.ds = ds;
}
```

---

# **4. How Bean Names Are Determined**

If you do:

```java
@Component
class Cat {}
```

Bean name becomes `cat`.

If you specify:

```java
@Component("persianCat")
class Cat {}
```

Bean name is `persianCat`, and you must use:

```java
@Qualifier("persianCat")
```

---

# **5. When You Must Use @Qualifier**

You **must** use it when:

### ✓ Multiple beans of the same type

Example: multiple `Animal`, multiple `UserRepository`, multiple `DataSource`.

### ✓ Same interface implemented by many classes

Spring cannot guess your choice.

### ✓ You want to choose between several strategies

Example: different payment processors.

---

# **6. Example You’ll See in Real Projects (Professional)**

### **Strategy Pattern**

```java
public interface PaymentService { void pay(); }

@Component("paypal")
class PayPalService implements PaymentService { ... }

@Component("stripe")
class StripeService implements PaymentService { ... }
```

Injecting:

```java
@Service
public class Checkout {

    private final PaymentService payment;

    public Checkout(@Qualifier("stripe") PaymentService payment) {
        this.payment = payment;
    }
}
```

This cleanly selects the strategy.

---

# **7. @Qualifier vs @Primary**

### **@Primary**

- Sets a bean as the **default**.
    
- Prevents Spring from complaining about multiple beans.
    

```java
@Primary
@Component
class Dog implements Animal {}
```

### **@Qualifier**

- Exactly specifies the bean by **name**.
    
- Overrides `@Primary`.
    

---

# **8. Summary Table**

|Feature|Explanation|Example|
|---|---|---|
|Purpose|Select a specific bean when multiple exist|`@Qualifier("cat")`|
|Works with|Autowired, constructor, method params, @Bean|`public Service(@Qualifier("x") Bean b)`|
|Bean name|By default class name (camelCase)|`cat`, `dogService`|
|Difference vs @Primary|@Qualifier is exact; @Primary is default|—|

---


###### Tags : [[0 - Spring Framework]]