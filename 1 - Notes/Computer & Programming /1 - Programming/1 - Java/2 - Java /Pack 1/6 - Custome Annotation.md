If your goal is to **create custom annotations and understand how to make them actually do something**, you don't need to learn hundreds of Java classes.

I'd learn them in this order:

### 1. `java.lang.annotation.Annotation`

This is the fundamental annotation interface.

You normally **don't implement it yourself**, but understanding it helps you understand what annotations actually are.

```java
public @interface LogMethod {
}
```

is an annotation type, and annotation instances conceptually implement `Annotation`.

---

### 2. `java.lang.annotation.Retention`

Controls **how long your annotation exists**.

```java
@Retention(RetentionPolicy.RUNTIME)
public @interface LogMethod {
}
```

Know these:

```text
SOURCE   → compiler sees it, then it's discarded
CLASS    → stored in .class, generally unavailable through runtime reflection
RUNTIME  → available while your program is running
```

For your logging example, you want:

```java
RetentionPolicy.RUNTIME
```

---

### 3. `java.lang.annotation.RetentionPolicy`

This is the enum used by `@Retention`.

You should know:

```java
RetentionPolicy.SOURCE
RetentionPolicy.CLASS
RetentionPolicy.RUNTIME
```

---

### 4. `java.lang.annotation.Target`

Controls **where your annotation is allowed**.

```java
@Target(ElementType.METHOD)
public @interface LogMethod {
}
```

---

### 5. `java.lang.annotation.ElementType`

This tells `@Target` what kind of Java element you're targeting.

Learn the important ones:

```java
ElementType.TYPE
ElementType.METHOD
ElementType.FIELD
ElementType.PARAMETER
ElementType.CONSTRUCTOR
ElementType.LOCAL_VARIABLE
```

For your logging annotation:

```java
@Target(ElementType.METHOD)
```

---

# Then comes the really important part: Reflection

If you want your own annotation to actually **do something**, this is where you need to go deeper.

### 6. `java.lang.reflect.Method`

This is extremely important for your example.

You can inspect methods:

```java
Method[] methods = MyClass.class.getDeclaredMethods();
```

Then:

```java
for (Method method : methods) {
    System.out.println(method.getName());
}
```

You can also ask:

```java
method.isAnnotationPresent(LogMethod.class)
```

and retrieve it:

```java
LogMethod annotation =
        method.getAnnotation(LogMethod.class);
```

---

### 7. `java.lang.reflect.Field`

Same concept, but for fields.

```java
Field[] fields = MyClass.class.getDeclaredFields();
```

You'll need this when creating annotations that inspect things like:

```java
@Column(...)
private String username;
```

---

### 8. `java.lang.reflect.Constructor`

For annotations placed on constructors:

```java
Constructor<?>[] constructors =
        MyClass.class.getDeclaredConstructors();
```

---

### 9. `java.lang.Class`

**Very important.**

Reflection basically starts from `Class`.

For example:

```java
Class<User> clazz = User.class;
```

Then:

```java
clazz.getDeclaredMethods();
clazz.getDeclaredFields();
clazz.getDeclaredConstructors();
```

This is the gateway into runtime reflection.

---

# For your specific `@LogMethod` project

You can think of your learning path as:

```text
                Custom Annotation
                       │
                       ▼
              java.lang.annotation
                 │          │
                 ▼          ▼
             @Target    @Retention
                 │          │
                 ▼          ▼
          ElementType   RetentionPolicy
                            │
                            ▼
                         RUNTIME
                            │
                            ▼
                       Reflection
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
          Class          Method         Field
              │             │
              └─────────────┘
                     │
                     ▼
          isAnnotationPresent()
                     │
                     ▼
              getAnnotation()
```

## But there's one more level

If your actual goal is:

```java
@LogMethod
public void login() {
}
```

and you want:

```text
LOG: login
```

**automatically every time `login()` is called**, Reflection alone isn't enough.

You'll eventually want to learn:

### 10. `java.lang.reflect.Proxy`

Dynamic proxies can intercept method calls.

And after that, for serious Java/Spring development:

```text
Reflection
   ↓
Dynamic Proxy
   ↓
AOP
   ↓
Bytecode / instrumentation
```

This is where you'll understand how frameworks can make something like:

```java
@Transactional
public void transferMoney() {
}
```

cause behavior that you never explicitly wrote inside `transferMoney()`.

---

# The minimum Java API you should learn

If you're specifically studying custom annotations, I'd make this your checklist:

|API|Importance|Why|
|---|--:|---|
|`Annotation`|★★★|Foundation of annotations|
|`Retention`|★★★★★|Controls annotation lifetime|
|`RetentionPolicy`|★★★★★|`SOURCE`, `CLASS`, `RUNTIME`|
|`Target`|★★★★★|Controls where annotation can be used|
|`ElementType`|★★★★★|Method, field, class, etc.|
|`Class`|★★★★★|Entry point to reflection|
|`Method`|★★★★★|Inspect/interact with methods|
|`Field`|★★★★|Inspect fields|
|`Constructor`|★★★|Inspect constructors|
|`Proxy`|★★★★|Intercept method calls|

### And one thing you should **not** misunderstand

There isn't a magical Java class you extend that says:

```java
public class LogMethod extends Something {
    // Java automatically logs methods
}
```

No.

You create:

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface LogMethod {
}
```

Then **you build the mechanism that interprets it**.

That's the fundamental architecture:

```text
ANNOTATION
    ↓
metadata

PROCESSOR / REFLECTION / AOP
    ↓
interpret metadata

ACTUAL BEHAVIOR
    ↓
log method name
```

If you're learning this to become strong in Java rather than just memorizing annotations, I'd recommend learning **Reflection immediately after annotations**. It will make Spring's "annotation magic" considerably less magical.

[[Java]]