

**Java Reflection** is the mechanism that allows a Java program to **inspect and manipulate classes, fields, methods, constructors, and other program elements at runtime**.

Normally, Java code knows what it is working with at compile time:

```java
User user = new User("Ali");
user.getName();
```

Reflection allows you to discover things **at runtime**:

```java
Class<?> clazz = user.getClass();

System.out.println(clazz.getName());
```

You can then ask:

```text
What class is this?
What fields does it have?
What methods does it have?
What constructors does it have?
What annotations does it have?
What interfaces does it implement?
Can I invoke this method?
Can I create an instance?
Can I read/write this field?
```

---

# 1. The fundamental idea

Normally:

```text
SOURCE CODE
    ↓
COMPILE
    ↓
BYTECODE
    ↓
JVM
    ↓
EXECUTION
```

The compiler knows:

```java
User user = new User("Ali");
user.getName();
```

Reflection introduces another path:

```text
RUNNING PROGRAM
      ↓
   Class object
      ↓
 inspect metadata
      ↓
 fields / methods / constructors
      ↓
 manipulate them
```

So reflection is fundamentally about **runtime metadata and runtime access**.

---

# 2. The `Class` object

The central object in Java Reflection is:

```java
java.lang.Class
```

Every loaded Java type has an associated `Class` object.

For example:

```java
String.class
```

returns the `Class` object representing `String`.

You can also obtain it from an object:

```java
String text = "Hello";

Class<?> clazz = text.getClass();
```

Or by class name:

```java
Class<?> clazz = Class.forName("java.lang.String");
```

These are three important ways to obtain a `Class` object:

```java
String.class
object.getClass()
Class.forName("...")
```

---

# 3. What exactly is `Class<?>`?

Consider:

```java
Class<?> clazz = String.class;
```

`Class` represents a Java type.

The `<?>` means:

> "I have a `Class`, but I don't know which specific type it represents."

For example:

```java
Class<String> a = String.class;
Class<Integer> b = Integer.class;
Class<User> c = User.class;
```

But:

```java
Class<?> clazz = ...
```

can represent any of them.

---

# 4. Reflection hierarchy

The important reflection classes are in:

```text
java.lang
java.lang.reflect
```

The core structure is roughly:

```text
                    Class
                      │
          ┌───────────┼───────────┐
          │           │           │
        Field       Method    Constructor
          │           │           │
       fields      methods    constructors
```

You'll frequently work with:

```java
Class
Field
Method
Constructor
Modifier
Parameter
```

And with annotations:

```java
Annotation
```

---

# 5. Inspecting a class

Suppose:

```java
public class User {

    private String name;
    private int age;

    public User() {}

    public User(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public String getName() {
        return name;
    }

    public void sayHello() {
        System.out.println("Hello");
    }
}
```

You can inspect it:

```java
Class<User> clazz = User.class;

System.out.println(clazz.getName());
```

Output:

```text
User
```

You can ask:

```java
clazz.getSuperclass();
clazz.getInterfaces();
clazz.getModifiers();
clazz.getPackage();
```

---

# 6. Inspecting fields

Use:

```java
getFields()
```

or:

```java
getDeclaredFields()
```

Example:

```java
Field[] fields = User.class.getDeclaredFields();

for (Field field : fields) {
    System.out.println(field.getName());
}
```

Output:

```text
name
age
```

---

# 7. `getFields()` vs `getDeclaredFields()`

This distinction is extremely important.

### `getFields()`

Returns **public fields**, including inherited public fields.

```java
clazz.getFields();
```

### `getDeclaredFields()`

Returns fields **declared directly by that class**, regardless of visibility.

```java
clazz.getDeclaredFields();
```

So:

```text
getFields()
    ↓
public fields
    ↓
including inherited fields


getDeclaredFields()
    ↓
fields declared by this class
    ↓
private + protected + package-private + public
```

The same distinction exists for methods and constructors.

---

# 8. Reading a field

Suppose:

```java
User user = new User("Ali", 25);
```

You can find the field:

```java
Field field = User.class.getDeclaredField("name");
```

Then:

```java
Object value = field.get(user);
```

Result:

```text
Ali
```

Notice that `field.get()` receives the **object whose field you want to read**.

Conceptually:

```text
Field
 │
 ├── metadata: "name"
 │
 └── get(user)
       ↓
     "Ali"
```

---

# 9. Private fields

Reflection can inspect private members.

```java
Field field = User.class.getDeclaredField("name");
```

Modern Java strongly controls whether code is allowed to bypass normal access boundaries, especially across modules.

Historically you may see:

```java
field.setAccessible(true);
```

This asks Java to suppress ordinary Java language access checks.

Example:

```java
field.setAccessible(true);

Object value = field.get(user);
```

However, **`setAccessible(true)` is not a universal escape hatch**. The Java Platform Module System (JPMS) can prevent access to strongly encapsulated packages, resulting in exceptions such as `InaccessibleObjectException`.

For application/framework code, prefer supported APIs and explicit access whenever possible.

---

# 10. Writing a field

You can also modify a field:

```java
Field field = User.class.getDeclaredField("name");

field.setAccessible(true);
field.set(user, "John");
```

Then:

```java
System.out.println(user.getName());
```

prints:

```text
John
```

This is one reason reflection can be powerful—and dangerous.

---

# 11. Inspecting methods

Use:

```java
Method[] methods = User.class.getDeclaredMethods();

for (Method method : methods) {
    System.out.println(method.getName());
}
```

You might see:

```text
getName
sayHello
```

You can also inspect:

```java
method.getReturnType();
method.getParameterTypes();
method.getModifiers();
method.getAnnotations();
```

---

# 12. Finding a specific method

Suppose:

```java
public void sayHello() {
    System.out.println("Hello");
}
```

You can obtain it:

```java
Method method =
        User.class.getDeclaredMethod("sayHello");
```

---

# 13. Invoking a method

Now you can execute it dynamically:

```java
User user = new User("Ali", 25);

Method method =
        User.class.getDeclaredMethod("sayHello");

method.invoke(user);
```

Output:

```text
Hello
```

This is fundamentally different from:

```java
user.sayHello();
```

The normal version is resolved through ordinary Java language mechanisms.

The reflection version says:

> Find a method whose name and signature I provide at runtime, then invoke it.

---

# 14. Methods with parameters

Suppose:

```java
public void greet(String name) {
    System.out.println("Hello " + name);
}
```

Find it:

```java
Method method =
        User.class.getDeclaredMethod(
                "greet",
                String.class
        );
```

Invoke it:

```java
method.invoke(user, "John");
```

Output:

```text
Hello John
```

The parameter types are important:

```java
getDeclaredMethod(
    "greet",
    String.class
);
```

Without the correct signature, Java may not find the method.

---

# 15. Return values

Suppose:

```java
public String getName() {
    return name;
}
```

Reflection:

```java
Method method =
        User.class.getDeclaredMethod("getName");

Object result = method.invoke(user);
```

`result` contains:

```text
"Ali"
```

You can cast it:

```java
String name = (String) method.invoke(user);
```

---

# 16. Exceptions from `Method.invoke()`

Reflection introduces another layer of exception handling.

For example:

```java
method.invoke(user);
```

may throw:

```text
IllegalAccessException
IllegalArgumentException
InvocationTargetException
```

The particularly important one is:

### `InvocationTargetException`

If the invoked method itself throws an exception, reflection wraps it inside:

```java
InvocationTargetException
```

You can inspect the underlying cause:

```java
catch (InvocationTargetException e) {
    Throwable cause = e.getCause();
}
```

This distinction matters when debugging frameworks.

---

# 17. Constructors

Reflection can inspect constructors using:

```java
getDeclaredConstructors()
```

Example:

```java
Constructor<?>[] constructors =
        User.class.getDeclaredConstructors();
```

You can inspect:

```java
for (Constructor<?> constructor : constructors) {
    System.out.println(constructor);
}
```

---

# 18. Creating objects with reflection

Suppose:

```java
public User(String name, int age) {
    this.name = name;
    this.age = age;
}
```

Find the constructor:

```java
Constructor<User> constructor =
        User.class.getConstructor(
                String.class,
                int.class
        );
```

Create an object:

```java
User user =
        constructor.newInstance("Ali", 25);
```

Conceptually:

```text
Constructor
     │
     ▼
newInstance(...)
     │
     ▼
new User("Ali", 25)
```

---

# 19. `getConstructor()` vs `getDeclaredConstructor()`

Again, visibility matters.

```java
getConstructor(...)
```

finds a **public constructor**.

```java
getDeclaredConstructor(...)
```

finds a constructor **declared by that class**, regardless of Java visibility.

Example:

```java
Constructor<User> constructor =
        User.class.getDeclaredConstructor();
```

---

# 20. Inspecting modifiers

Java provides:

```java
Modifier
```

For example:

```java
int modifiers = clazz.getModifiers();
```

Then:

```java
Modifier.isPublic(modifiers);
Modifier.isFinal(modifiers);
Modifier.isAbstract(modifiers);
Modifier.isStatic(modifiers);
```

Example:

```java
if (Modifier.isFinal(clazz.getModifiers())) {
    System.out.println("Final class");
}
```

---

# 21. Inspecting inheritance

Reflection lets you inspect the superclass:

```java
Class<?> superclass =
        User.class.getSuperclass();
```

And interfaces:

```java
Class<?>[] interfaces =
        User.class.getInterfaces();
```

You can construct a hierarchy:

```text
Object
  ↑
Person
  ↑
User
```

Reflection allows you to walk that hierarchy programmatically.

---

# 22. `isAssignableFrom()`

One very useful reflection method is:

```java
SomeType.class.isAssignableFrom(otherType)
```

Example:

```java
Number.class.isAssignableFrom(Integer.class)
```

returns:

```text
true
```

Because:

```text
Integer → Number
```

Conceptually:

```text
Number
  ↑
Integer
```

This is useful for checking type compatibility dynamically.

---

# 23. Annotations and reflection

This is where reflection becomes extremely important for frameworks.

Suppose:

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface Component {
}
```

Then:

```java
@Component
public class UserService {
}
```

Reflection can inspect it:

```java
boolean isComponent =
        UserService.class.isAnnotationPresent(Component.class);
```

Result:

```text
true
```

You can retrieve the annotation:

```java
Component component =
        UserService.class.getAnnotation(Component.class);
```

---

# 24. Why runtime retention matters

Not every annotation is available through reflection.

For example:

```java
@Retention(RetentionPolicy.RUNTIME)
```

means:

> Keep this annotation available at runtime.

Without runtime retention, reflection generally cannot inspect it at runtime.

The three major retention policies are:

```text
SOURCE
   ↓
compiler only

CLASS
   ↓
stored in .class
but generally unavailable through runtime reflection

RUNTIME
   ↓
available through reflection
```

---

# 25. Reflection and frameworks

This is where you encounter reflection professionally.

Frameworks such as:

- Spring
    
- Hibernate
    
- JUnit
    
- Jackson
    

use reflection extensively, although modern frameworks may also combine it with bytecode generation, proxies, method handles, annotation processing, and other mechanisms.

For example, Spring sees:

```java
@Service
public class UserService {
}
```

and can inspect the class metadata to determine:

```text
Is this class a component?
What constructors does it have?
What dependencies does it require?
What annotations are present?
What methods/fields are relevant?
```

Then Spring builds its application context around that metadata.

---

# 26. Dependency Injection example

Imagine:

```java
@Service
public class UserService {

    private final UserRepository repository;

    public UserService(UserRepository repository) {
        this.repository = repository;
    }
}
```

A framework can inspect the constructor:

```java
Constructor<?>[] constructors =
        UserService.class.getDeclaredConstructors();
```

Then inspect:

```java
constructor.getParameterTypes();
```

and discover:

```text
UserService constructor requires:
    UserRepository
```

The framework can then resolve a `UserRepository` object and construct the service.

Conceptually:

```text
UserService
     │
     ▼
constructor
     │
     ▼
UserRepository required
     │
     ▼
Container finds dependency
     │
     ▼
constructor.newInstance(repository)
```

That's a simplified model of what dependency injection frameworks can do.

---

# 27. Reflection and JPA/Hibernate

Reflection is also historically important in ORM frameworks.

Suppose:

```java
@Entity
public class User {

    @Id
    private Long id;

    private String name;
}
```

A persistence framework can inspect:

```text
@Entity
@Id
fields
types
constructors
annotations
```

and build metadata describing how the Java class maps to database data.

Conceptually:

```text
Java class
     │
 Reflection / metadata
     │
     ▼
@Entity
@Id
fields
     │
     ▼
ORM metadata
     │
     ▼
Database mapping
```

Modern Hibernate does considerably more than simple reflection, but reflection is part of the broader runtime metadata model.

---

# 28. Reflection and serialization

A serializer can inspect:

```java
public record User(
    String name,
    int age
) {}
```

and discover:

```text
name → String
age  → int
```

It can then map:

```text
Java object
     ↓
JSON
```

For example:

```json
{
  "name": "Ali",
  "age": 25
}
```

Libraries such as Jackson use reflection and other runtime mechanisms to perform this kind of mapping.

---

# 29. Reflection and dependency injection are related but not identical

Don't think:

```text
Reflection = Dependency Injection
```

Instead:

```text
Reflection
    ↓
runtime inspection/access mechanism

Dependency Injection
    ↓
design pattern / framework mechanism
```

A DI framework **can use reflection** to implement part of its behavior.

---

# 30. Reflection vs normal Java code

Normal:

```java
User user = new User("Ali", 25);
String name = user.getName();
```

Everything is known statically.

Reflection:

```java
Class<?> clazz = Class.forName("com.example.User");

Constructor<?> constructor =
        clazz.getConstructor(String.class, int.class);

Object user =
        constructor.newInstance("Ali", 25);

Method method =
        clazz.getMethod("getName");

Object name =
        method.invoke(user);
```

The second approach discovers and interacts with the class **at runtime**.

---

# 31. Why reflection is powerful

Reflection enables programs to become highly dynamic.

For example, you can write:

```java
String className = configuration.get("implementation");

Class<?> clazz = Class.forName(className);

Object object = clazz.getDeclaredConstructor()
                     .newInstance();
```

The actual implementation doesn't need to be hard-coded:

```text
Configuration
      │
      ▼
class name
      │
      ▼
Class.forName()
      │
      ▼
Class object
      │
      ▼
Constructor
      │
      ▼
Object
```

This is useful for:

- Plugins
    
- Frameworks
    
- Dependency injection
    
- Serialization
    
- Testing
    
- ORM
    
- Dependency discovery
    
- Runtime configuration
    

---

# 32. The cost of reflection

Reflection has trade-offs.

### 1. Less compile-time safety

Normal:

```java
user.getName();
```

The compiler verifies that `getName()` exists.

Reflection:

```java
clazz.getMethod("getName");
```

The compiler doesn't know whether `"getName"` actually exists.

A typo becomes a runtime problem:

```java
clazz.getMethod("getNmae");
```

---

### 2. More complicated exceptions

Reflection introduces exceptions such as:

```text
ClassNotFoundException
NoSuchMethodException
NoSuchFieldException
IllegalAccessException
InvocationTargetException
InstantiationException
```

---

### 3. Can be harder to understand

This:

```java
user.getName();
```

is immediately understandable.

This:

```java
method.invoke(object);
```

requires understanding what `method` and `object` actually represent.

---

### 4. Performance overhead

Reflection can have additional overhead compared with ordinary direct invocation.

For ordinary application code, this usually isn't a reason to panic; frameworks can use caching and optimized mechanisms.

But if you are executing reflective operations in extremely hot loops, you should measure rather than assume.

---

### 5. Encapsulation concerns

Reflection can interact with private implementation details.

That creates tighter coupling to internal structure and can conflict with Java's module boundaries.

---

# 33. Reflection vs `MethodHandle`

Modern Java also provides:

```java
java.lang.invoke.MethodHandle
```

A `MethodHandle` can represent a dynamically invokable method/constructor/field operation.

Conceptually:

```text
Reflection API
     ↓
Method / Field / Constructor
```

versus:

```text
java.lang.invoke
     ↓
MethodHandle
```

`MethodHandle` is a lower-level, more strongly typed dynamic invocation mechanism and is important in JVM-level programming and language implementation.

You don't need to replace ordinary reflection with `MethodHandle` in normal Spring development, but understanding the distinction becomes useful at advanced Java/JVM level.

---

# 34. Reflection and generics

Reflection can also inspect generic metadata.

For example:

```java
class Repository<T> {
}
```

Methods and fields can expose generic information through APIs such as:

```java
getGenericType()
getGenericReturnType()
getGenericParameterTypes()
```

For example:

```java
Field field = SomeClass.class.getDeclaredField("users");

Type type = field.getGenericType();
```

The important point is that Java's runtime generic information is **not equivalent to the full compile-time generic type system**, because of **type erasure**.

---

# 35. Reflection and type erasure

Consider:

```java
List<String>
```

and:

```java
List<Integer>
```

At runtime, the JVM does not normally distinguish these as different runtime classes:

```text
List<String>
List<Integer>
      ↓
   List
```

This is **type erasure**.

Reflection can still expose some generic declaration metadata through `Type`, `ParameterizedType`, etc., but you cannot generally ask an ordinary runtime `Class` object:

> "Is this particular List object a `List<String>`?"

The runtime object is fundamentally a `List`.

---

# 36. Reflection and modules

Since Java 9, Java has the **Java Platform Module System (JPMS)**.

This matters for reflection because Java can distinguish between:

```text
accessible
```

and:

```text
strongly encapsulated
```

A reflective access attempt can fail with:

```java
InaccessibleObjectException
```

particularly when attempting to access non-opened packages across module boundaries.

This is why commands such as:

```text
--add-opens
```

sometimes appear when running older frameworks or libraries on newer JDKs.

---

# 37. Reflection and security

Reflection can be dangerous when used carelessly.

For example:

```java
field.setAccessible(true);
```

can bypass ordinary access restrictions where permitted.

Therefore, don't build security around:

> "The field is private, so nobody can access it."

Private access is primarily a **language-level encapsulation mechanism**, not a security boundary.

Security-sensitive systems need actual access-control mechanisms.

---

# 38. A complete reflection example

Consider:

```java
public class User {

    private String name;
    private int age;

    public User(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public String greet(String message) {
        return message + " " + name;
    }
}
```

Now dynamically inspect and invoke it:

```java
Class<User> clazz = User.class;

Constructor<User> constructor =
        clazz.getConstructor(String.class, int.class);

User user =
        constructor.newInstance("Ali", 25);

Method method =
        clazz.getMethod("greet", String.class);

Object result =
        method.invoke(user, "Hello");

System.out.println(result);
```

Output:

```text
Hello Ali
```

The entire process is:

```text
             User.class
                 │
                 ▼
              Class
                 │
       ┌─────────┼─────────┐
       ▼         ▼         ▼
 Constructor   Method    Fields
       │         │
       ▼         ▼
newInstance()  invoke()
       │         │
       ▼         ▼
     object    result
```

---

# 39. The reflection workflow

When working with reflection, think in this order:

```text
1. Obtain Class
       ↓
2. Inspect metadata
       ↓
3. Find member
       ↓
4. Check/access permissions
       ↓
5. Invoke/read/write/create
       ↓
6. Handle runtime exceptions
```

Example:

```java
Class<?> clazz = ...;

Method method =
        clazz.getDeclaredMethod("foo", String.class);

Object result =
        method.invoke(target, "hello");
```

---

# 40. The most important Reflection API

Keep this mental map:

|API|Purpose|
|---|---|
|`Class<?>`|Represents a runtime Java type|
|`Class.forName()`|Load/find a class by name|
|`getDeclaredFields()`|Get fields declared by a class|
|`getFields()`|Get public fields|
|`getDeclaredMethods()`|Get methods declared by a class|
|`getMethods()`|Get public methods, including inherited ones|
|`getDeclaredConstructors()`|Get declared constructors|
|`getConstructor()`|Find a public constructor|
|`getDeclaredConstructor()`|Find a declared constructor|
|`getDeclaredMethod()`|Find a declared method|
|`getMethod()`|Find a public method|
|`Field.get()`|Read a field|
|`Field.set()`|Write a field|
|`Method.invoke()`|Invoke a method|
|`Constructor.newInstance()`|Create an object|
|`getSuperclass()`|Get superclass|
|`getInterfaces()`|Get implemented interfaces|
|`getModifiers()`|Inspect modifiers|
|`isAnnotationPresent()`|Check annotation|
|`getAnnotation()`|Retrieve annotation|
|`isAssignableFrom()`|Check type compatibility|

---

# The big picture

Reflection is essentially **runtime introspection + dynamic access**.

```text
                   JAVA PROGRAM
                        │
                        ▼
                 Runtime metadata
                        │
                        ▼
                     Class
                        │
       ┌────────────────┼────────────────┐
       │                │                │
       ▼                ▼                ▼
     Fields           Methods       Constructors
       │                │                │
       ▼                ▼                ▼
    get/set           invoke()       newInstance()
       │                │                │
       └────────────────┼────────────────┘
                        ▼
                 Dynamic behavior
```

### The core distinction

Normal Java:

```java
user.getName();
```

means:

> **I know what I want at compile time.**

Reflection:

```java
method.invoke(user);
```

means:

> **I'll discover what I want at runtime.**

That is why reflection is fundamental to understanding how **Spring, Hibernate, Jackson, JUnit, dependency injection, annotations, proxies, and many Java frameworks** work internally.


[[Java]]