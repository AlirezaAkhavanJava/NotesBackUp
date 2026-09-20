

## 1. Definition

**Java Reflection API** is a part of Java that allows a program to **inspect and manipulate classes, interfaces, fields, methods, constructors, and other members at runtime**.

Normally, Java code knows what it is working with at **compile time**:

```java
User user = new User();
user.getName();
```

With reflection, you can discover information about `User` **at runtime**, even when you did not explicitly write the class's members in your code:

```java
Class<?> clazz = User.class;

System.out.println(clazz.getName());
```

Reflection is primarily provided by:

```text
java.lang.Class
java.lang.reflect
```

---

# 2. The Core Idea

Think of reflection as:

```text
Normal Java
──────────────────────────────
Source Code
    ↓
Compiler
    ↓
Bytecode
    ↓
JVM
    ↓
Objects / methods / fields

Reflection
──────────────────────────────
Running JVM
    ↓
Ask an object/class:
"What are you?"
"What fields do you have?"
"What methods do you have?"
"What constructors do you have?"
    ↓
Inspect / invoke / modify
```

Reflection lets your program examine the **structure of another program while it is running**.

---

# 3. The `Class<?>` Object

The most important reflection type is:

```java
Class<T>
```

Every loaded Java class has a corresponding `Class` object representing its runtime type.

There are several ways to obtain it.

### From a class

```java
Class<User> clazz = User.class;
```

### From an object

```java
User user = new User();

Class<?> clazz = user.getClass();
```

### By class name

```java
Class<?> clazz = Class.forName("com.example.User");
```

The last approach is particularly important for frameworks because the class can be discovered dynamically.

---

# 4. What Can Reflection Inspect?

Reflection can inspect things such as:

|Element|Reflection type|
|---|---|
|Class|`Class<?>`|
|Constructor|`Constructor<?>`|
|Method|`Method`|
|Field|`Field`|
|Modifier|`Modifier`|
|Parameter|`Parameter`|
|Annotation|`Annotation`|
|Record component|`RecordComponent`|

Conceptually:

```text
Class
 ├── Constructors
 ├── Methods
 ├── Fields
 ├── Interfaces
 ├── Superclass
 ├── Annotations
 ├── Modifiers
 └── Record components
```

---

# 5. Inspecting a Class

Suppose:

```java
public class User {

    private String name;
    private int age;

    public User() {
    }

    public User(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public void login() {
        System.out.println("Login");
    }

    public String getName() {
        return name;
    }
}
```

You can inspect it:

```java
Class<User> clazz = User.class;

System.out.println(clazz.getName());
System.out.println(clazz.getSimpleName());
System.out.println(clazz.getPackageName());
```

Possible output:

```text
com.example.User
User
com.example
```

---

# 6. Inspecting Fields

### `getFields()`

Returns **public fields**, including inherited public fields.

```java
Field[] fields = clazz.getFields();
```

### `getDeclaredFields()`

Returns fields **declared directly by the class**, including private fields.

```java
Field[] fields = clazz.getDeclaredFields();

for (Field field : fields) {
    System.out.println(field.getName());
}
```

Output:

```text
name
age
```

Important distinction:

```text
getFields()
        ↓
public fields
        +
inherited public fields

getDeclaredFields()
        ↓
fields declared by THIS class
        +
private/protected/package-private/public
```

---

# 7. Inspecting Methods

### Public methods

```java
Method[] methods = clazz.getMethods();
```

This includes inherited public methods.

### Declared methods

```java
Method[] methods = clazz.getDeclaredMethods();
```

This includes methods declared by the class regardless of visibility.

Example:

```java
for (Method method : clazz.getDeclaredMethods()) {
    System.out.println(method.getName());
}
```

---

# 8. Inspecting Constructors

```java
Constructor<?>[] constructors =
        clazz.getDeclaredConstructors();

for (Constructor<?> constructor : constructors) {
    System.out.println(constructor);
}
```

For:

```java
public User() {}

public User(String name, int age) {}
```

Reflection can discover both constructors.

---

# 9. Invoking a Method

This is where reflection becomes more powerful.

Suppose:

```java
User user = new User();
```

Find the method:

```java
Method method = User.class.getMethod("login");
```

Invoke it:

```java
method.invoke(user);
```

Conceptually:

```text
Method object
     ↓
"login"
     ↓
invoke(user)
     ↓
user.login()
```

You dynamically call a method without writing:

```java
user.login();
```

directly.

---

# 10. Passing Arguments

Suppose:

```java
public void sayHello(String name) {
    System.out.println("Hello " + name);
}
```

Get the method:

```java
Method method =
        User.class.getMethod("sayHello", String.class);
```

Invoke:

```java
method.invoke(user, "Alireza");
```

Equivalent to:

```java
user.sayHello("Alireza");
```

---

# 11. Getting Return Values

Suppose:

```java
public String getName() {
    return name;
}
```

Reflection:

```java
Method method =
        User.class.getMethod("getName");

Object result = method.invoke(user);

System.out.println(result);
```

Because reflection generally represents dynamically obtained values as `Object`, you may need casting:

```java
String name = (String) method.invoke(user);
```

---

# 12. Accessing Fields

You can obtain a field:

```java
Field field =
        User.class.getDeclaredField("name");
```

Then read it:

```java
Object value = field.get(user);
```

For a private field, modern Java strongly emphasizes access checks and encapsulation. You may encounter:

```java
field.setAccessible(true);
```

but this should **not** be treated as a normal way to bypass encapsulation. JPMS/module boundaries can prevent such access.

---

# 13. Creating Objects Dynamically

You can also use constructors.

```java
Constructor<User> constructor =
        User.class.getConstructor();

User user = constructor.newInstance();
```

For parameters:

```java
Constructor<User> constructor =
        User.class.getConstructor(
                String.class,
                int.class
        );

User user = constructor.newInstance(
        "Alireza",
        25
);
```

Conceptually:

```java
new User("Alireza", 25);
```

becomes:

```text
Find constructor
      ↓
Constructor object
      ↓
newInstance(...)
      ↓
User object
```

---

# 14. Inspecting Modifiers

Java modifiers can also be inspected.

```java
int modifiers = clazz.getModifiers();
```

Then:

```java
Modifier.isPublic(modifiers);
Modifier.isFinal(modifiers);
Modifier.isAbstract(modifiers);
```

For example:

```java
if (Modifier.isFinal(modifiers)) {
    System.out.println("Class is final");
}
```

---

# 15. Inspecting Inheritance

Superclass:

```java
Class<?> parent = clazz.getSuperclass();
```

Interfaces:

```java
Class<?>[] interfaces = clazz.getInterfaces();
```

Example:

```java
for (Class<?> i : clazz.getInterfaces()) {
    System.out.println(i.getName());
}
```

You can therefore dynamically determine:

```text
User
 ↓
Superclass?
 ↓
Interfaces?
 ↓
Methods?
 ↓
Fields?
```

---

# 16. Reflection and Annotations

This is one of the **most important real-world uses**.

Suppose:

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Command {
}
```

Then:

```java
@Command
public void execute() {
}
```

Reflection can inspect it:

```java
Method method =
        MyClass.class.getMethod("execute");

if (method.isAnnotationPresent(Command.class)) {
    System.out.println("This is a command");
}
```

This basic mechanism is heavily used by frameworks.

---

# 17. Why Frameworks Need Reflection

Reflection is a major building block behind frameworks and libraries.

For example, a framework may discover:

```java
@Service
class UserService {
}
```

and inspect:

```text
Class
 ↓
@Service?
 ↓
Constructors
 ↓
Dependencies
 ↓
Methods
 ↓
Annotations
```

Then it can construct and manage the object.

This is closely related to how dependency-injection frameworks such as Spring operate.

Other common uses include:

- Dependency injection
    
- Object serialization/deserialization
    
- ORM mapping
    
- Testing frameworks
    
- Annotation processing at runtime
    
- Plugin systems
    
- Dependency discovery
    
- JavaBeans/property inspection
    
- Framework configuration
    
- Dynamic method invocation
    

---

# 18. Reflection vs Normal Java

|Normal Java|Reflection|
|---|---|
|Mostly compile-time known|Runtime discovery|
|`user.getName()`|`method.invoke(user)`|
|`new User()`|`constructor.newInstance()`|
|`user.name`|`field.get(user)`|
|Compile-time type checking|Runtime checks|
|Generally faster|Generally more overhead|
|Easier to refactor|More fragile|
|Stronger encapsulation|Can interact with runtime-access mechanisms|

---

# 19. Reflection Is Dynamically Typed

Consider:

```java
Method method =
        User.class.getMethod("getName");

Object result = method.invoke(user);
```

The compiler doesn't know the result is necessarily a `String` from the `Object` reference.

You handle that at runtime:

```java
String name = (String) result;
```

If your assumption is wrong:

```java
Integer value = (Integer) result;
```

you can get:

```text
ClassCastException
```

Other reflection-related failures commonly appear as:

```text
NoSuchMethodException
NoSuchFieldException
IllegalAccessException
InvocationTargetException
ClassNotFoundException
```

---

# 20. Important Reflection Classes

The core API is worth memorizing:

```text
java.lang
└── Class

java.lang.reflect
├── AccessibleObject
├── Constructor
├── Field
├── Method
├── Modifier
├── Parameter
├── RecordComponent
├── Array
├── Proxy
└── InvocationHandler
```

The three you'll use most when learning reflection are:

```java
Class
Field
Method
```

followed by:

```java
Constructor
```

---

# 21. A Simple Mental Model

Think of reflection as a **runtime metadata API**:

```text
                    JVM
                     │
                     ▼
                 Class<T>
                     │
       ┌─────────────┼─────────────┐
       ▼             ▼             ▼
    Field          Method      Constructor
       │             │             │
       ▼             ▼             ▼
    get/set        invoke       newInstance
```

And annotations add another layer:

```text
Class
 │
 ├── Fields
 │     └── Annotations
 │
 ├── Methods
 │     └── Annotations
 │
 ├── Constructors
 │     └── Annotations
 │
 └── Class annotations
```

---

# 22. The Most Important Rule

**Reflection should generally be used when the structure of the program must be discovered dynamically.**

Don't use reflection merely because you can.

Prefer:

```java
user.getName();
```

over:

```java
User.class
    .getMethod("getName")
    .invoke(user);
```

when you already know the method at compile time.

Reflection becomes valuable when you **don't know the class/member beforehand**, such as:

```text
Framework
   ↓
Discover classes
   ↓
Inspect annotations
   ↓
Inspect constructors
   ↓
Create objects
   ↓
Inject dependencies
   ↓
Invoke methods
```

That is the fundamental reason Reflection is so important in **Spring, Hibernate, JUnit, serialization libraries, dependency injection, and many Java frameworks**.


[[Java]]