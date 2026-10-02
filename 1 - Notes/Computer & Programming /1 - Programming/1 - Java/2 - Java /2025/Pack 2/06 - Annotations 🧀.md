Date : 2025-09-04


# Java Annotations – Complete Guide (Up to Java 25)

This guide explains **all key Java annotations**, including built-in and custom annotations, their usage, examples, rules, advanced features, and real-world applications, from beginner to senior-level.

---

## 1. Introduction

- **Annotations:** Metadata providing additional information about the code.
    
- Introduced in **Java 5**, widely used for configuration, documentation, and code behavior.
    
- Do **not directly affect program semantics** but can influence compilation, runtime behavior, and code analysis.
    

**Tip:** Think of annotations as **tags that give instructions to the compiler, runtime, or frameworks**.

---

## 2. Built-in Annotations

### 2.1 `@Override`

- Indicates that a method overrides a method in a superclass.
    
- Helps compiler **catch errors**.
    

```java
class Parent {
    void show() {}
}
class Child extends Parent {
    @Override
    void show() { System.out.println("Child show"); }
}
```

### 2.2 `@Deprecated`

- Marks a method, class, or field as **obsolete**.
    
- Compiler gives a **warning**.
    

```java
@Deprecated
void oldMethod() {}
```

### 2.3 `@SuppressWarnings`

- Suppresses compiler warnings.
    
- Common values: `unchecked`, `deprecation`
    

```java
@SuppressWarnings("unchecked")
List rawList = new ArrayList();
```

### 2.4 `@SafeVarargs` (Java 7+)

- Suppresses warnings for **varargs of generic types**.
    
- Only for final/static methods or constructors.
    

```java
@SafeVarargs
static <T> void printAll(T... elements) {
    for(T e : elements) System.out.println(e);
}
```

### 2.5 `@FunctionalInterface` (Java 8+)

- Ensures interface has **exactly one abstract method**.
    
- Used for **lambda expressions**.
    

```java
@FunctionalInterface
interface Calculator { int add(int a, int b); }
```

### 2.6 `@Repeatable` (Java 8+)

- Allows an annotation to be applied **multiple times** on the same element.
    

```java
@Repeatable(Authors.class)
@interface Author { String name(); }
@interface Authors { Author[] value(); }

@Author(name="Alice")
@Author(name="Bob")
class Book {}
```

### 2.7 `@Documented`

- Marks that annotation should be included in **JavaDoc**.
    

### 2.8 `@Inherited`

- Allows **subclasses to inherit annotations** from parent class.
    

```java
@Inherited
@interface Role {}
```

### 2.9 `@Target`

- Specifies **kinds of elements** the annotation can be applied to.
    
- Values: `TYPE`, `METHOD`, `FIELD`, `PARAMETER`, etc.
    

### 2.10 `@Retention`

- Specifies **annotation lifecycle**.
    
- Values: `SOURCE`, `CLASS`, `RUNTIME`.
    

### 2.11 `@Native` (Java 8+)

- Marks constants to be included in **generated `@interface` constants**.
    

### 2.12 `@Repeatable` & Combining Annotations

- Can be applied multiple times using a **container annotation**.
    

---

## 3. Custom Annotations

- Defined using `@interface`.
    
- Can include elements with default values.
    
- Can be processed at **compile-time or runtime**.
    

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
@interface Info {
    String author();
    String date() default "2025-01-01";
}

class Test {
    @Info(author="Alice")
    void run() {}
}
```

**Tip:** Use `Retention` and `Target` to control annotation behavior.

---

## 4. Meta-Annotations

- Annotations applied on other annotations.
    
- Key meta-annotations: `@Target`, `@Retention`, `@Documented`, `@Inherited`, `@Repeatable`.
    

**Example:**

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
@interface MyAnnotation {}
```

---

## 5. Processing Annotations

### 5.1 Reflection (Runtime)

- Access annotations using **Reflection API**.
    

```java
Info info = Test.class.getMethod("run").getAnnotation(Info.class);
System.out.println(info.author());
```

### 5.2 Annotation Processing Tool (APT / Java 6+)

- Compile-time annotation processing.
    
- Generates code or validates annotations.
    
- Used in frameworks like **Spring, JPA, Lombok**.
    

---

## 6. Advanced Features (Java 8–25)

- **Type Annotations (Java 8):** Apply annotations to types (`@NonNull String s`).
    
- **Parameter Names (Java 8+):** Reflect parameter names at runtime.
    
- **Sealed Classes & Annotations (Java 17+):** Combine annotations with controlled inheritance.
    
- **Records & Lambdas:** Support annotations for compact data structures and functional interfaces.
    

---

## 7. Best Practices

1. Use **standard annotations** whenever possible.
    
2. Prefer `@Override` to catch mistakes.
    
3. Use `@Retention(RUNTIME)` for runtime reflection.
    
4. Combine `@Target` and `@Retention` for precise control.
    
5. Document custom annotations with `@Documented`.
    
6. Avoid excessive or unnecessary annotations.
    
7. Use **meta-annotations** for building framework-ready annotations.
    

---

## 8. Real-World Applications

- **Spring:** `@Autowired`, `@Component`, `@Service`, `@Repository`, `@Controller`.
    
- **JPA/Hibernate:** `@Entity`, `@Table`, `@Column`, `@Id`.
    
- **Testing:** `@Test`, `@BeforeEach`, `@AfterEach`.
    
- **Logging & Metrics:** Custom annotations for **AOP**.
    
- **Validation:** `@NotNull`, `@Size`, `@Email`.
    

**Tip:** Annotations enable **declarative programming, code readability, and framework integration**.

---

## 9. Summary

- Java annotations provide **metadata, declarative configuration, and compile/runtime instructions**.
    
- Key built-in annotations: `@Override`, `@Deprecated`, `@SuppressWarnings`, `@FunctionalInterface`, `@Repeatable`, `@Inherited`, `@Documented`.
    
- Custom annotations enhance code clarity and framework integration.
    
- Modern Java (up to 25) supports **type annotations, records, sealed classes, and functional programming**.
    
- Best practices ensure **maintainable, readable, and professional code**.
    

This guide ensures mastery of **Java Annotations from beginner to senior-level**, including all updates up to Java 25.



##### *Tags : [[Java]]