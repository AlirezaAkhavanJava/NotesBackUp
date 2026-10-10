

A **custom annotation** is an annotation you declare yourself with `@interface`. It gives a name to a rule or piece of information and attaches it to code. The annotation itself contains **no logic**. Its only job is to hold data. Some other code, called the **reader**, finds the annotation and decides what to do.

So the answer to "where do we write its logic?" has two parts:

- **The annotation declaration** holds the name and the data, such as `priority = 2`.
- **The reader** holds the logic. It is ordinary Java code that uses reflection to find annotated elements and act on them.

If you remember one sentence from this lesson, make it this one: **an annotation is a label, and the logic is in whatever code reads the label.**

## Why annotations separate data from logic

Suppose you want every method marked `@Check` to run as a test. You could write a list of method names in a separate file, but then renaming a method would break the list silently. Or you could put `if (method.getName().equals("addition"))` inside the runner, which hardcodes the names.

An annotation solves this by putting the marker on the method itself. The runner does not need to know any method names. It asks each method, "do you carry `@Check`?" and works from the answers. Renaming or deleting a method carries its marker with it, so the marker cannot drift away from the code.

## Writing the annotation

Here is a complete custom annotation:

```java
@Retention(RetentionPolicy.RUNTIME)   // keep it in the class file and visible to reflection
@Target(ElementType.METHOD)           // may be placed only on methods
@interface Check {
    String name() default "";         // optional label
    int priority() default 5;         // lower runs first
}
```

Each piece has a specific purpose:

- **Elements** look like methods, but they are only declarations. They can have a `default`, and they cannot have a body. An element can be a `String`, a primitive, an enum, a `Class`, another annotation, or an array of those.
- **`@Retention(RUNTIME)`** is required for reflection to see the annotation. With the default `CLASS` retention, the annotation is in the `.class` file but reflection cannot read it. This is the most common mistake with custom annotations.
- **`@Target(METHOD)`** makes the compiler reject `@Check` on a field or class. The rule about correct placement lives in the declaration.
- **`value`** is a special element name. If an annotation has only a `value` element, users may write `@Property("app.name")` instead of `@Property(value = "app.name")`.

## Reflection: how a reader looks at code

**Reflection** is the ability for a running program to inspect and manipulate classes, fields, and methods as objects. It is the mechanism that connects an annotation to the code that reads it. The main entry points are:

|You want|Use|Returns|
|---|---|---|
|The class description|`obj.getClass()` or `Foo.class`|`Class<?>`|
|All methods declared in this class|`getDeclaredMethods()`|`Method[]`|
|All public methods, including inherited|`getMethods()`|`Method[]`|
|All fields declared in this class|`getDeclaredFields()`|`Field[]`|
|An annotation on an element|`getAnnotation(Foo.class)`|the annotation, or `null`|
|Whether an annotation is present|`isAnnotationPresent(Foo.class)`|`boolean`|
|Call a method|`method.invoke(target, args...)`|the return value|
|Read a field|`field.get(target)`|`Object`|
|Write a field|`field.set(target, value)`|nothing|

Three details matter in practice:

- **`getDeclaredX` versus `getX`.** `getDeclaredMethods` sees every method in the class, including `private` ones, but not inherited ones. `getMethods` sees only `public` methods, including inherited ones. Pick according to what your annotation should cover.
- **`setAccessible(true)`** lets reflection bypass `private`. It works for your own classes. On Java 9 and later it can fail for JDK internal classes with `InaccessibleObjectException`, but your own code is fine.
- **Exceptions from `invoke`** arrive wrapped in `InvocationTargetException`. The real exception is available through `getCause()`. Forgetting to unwrap it is a very common source of confusing errors.

## Example 1: a test runner driven by `@Check`

This program defines a runner that finds every `@Check` method, sorts them by priority, and invokes each one. Create a folder and save this as `AnnotationLab.java`:

```java
import java.lang.annotation.*;
import java.lang.reflect.*;
import java.util.*;

// ---------- The annotation: data only ----------
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
@interface Check {
    String name() default "";
    int priority() default 5;
}

// ---------- The reader: the logic lives here ----------
class CheckRunner {

    // Helper used for sorting: reads the annotation, falls back if it is missing
    static int priorityOf(Method m) {
        Check c = m.getAnnotation(Check.class);
        return c == null ? Integer.MAX_VALUE : c.priority();
    }

    static void run(Object target) {
        Method[] methods = target.getClass().getDeclaredMethods();  // order is not guaranteed
        Arrays.sort(methods, Comparator.comparingInt(CheckRunner::priorityOf));

        for (Method m : methods) {
            Check c = m.getAnnotation(Check.class);
            if (c == null) continue;                         // not one of ours

            String label = c.name().isEmpty() ? m.getName() : c.name();

            if (m.getParameterCount() != 0 || m.getReturnType() != void.class) {
                System.out.println("SKIP " + label + ": must be void with no parameters");
                continue;
            }

            try {
                m.setAccessible(true);                       // allow private methods
                m.invoke(target);                            // call it on the object
                System.out.println("PASS " + label);
            } catch (InvocationTargetException e) {
                // The method itself threw; the real cause is wrapped inside
                System.out.println("FAIL " + label + ": " + e.getCause());
            } catch (IllegalAccessException e) {
                System.out.println("ERROR " + label + ": " + e);
            }
        }
    }
}

// ---------- The annotated class: data, no runner code ----------
class MathChecks {

    @Check(name = "addition", priority = 1)
    void addition() {
        if (1 + 1 != 2) throw new AssertionError("1 + 1 should be 2");
    }

    @Check(name = "division by zero", priority = 2)
    void divideByZero() {
        int x = 1 / 0;                                       // throws ArithmeticException
    }

    @Check(name = "subtraction", priority = 3)
    void subtraction() {
        if (5 - 3 != 2) throw new AssertionError("5 - 3 should be 2");
    }

    void helper() {                                          // not annotated: ignored
        System.out.println("never run by the runner");
    }
}

// ---------- Main ----------
public class AnnotationLab {
    public static void main(String[] args) {
        CheckRunner.run(new MathChecks());
    }
}
```

Compile and run on Debian 13 with a Java 21 JDK (`sudo apt install openjdk-21-jdk` if you need one):

```bash
mkdir -p ~/java-lessons/annotations && cd ~/java-lessons/annotations
nano AnnotationLab.java        # paste the code, save, exit
javac AnnotationLab.java
java AnnotationLab
```

Output:

```
PASS addition
FAIL division by zero: java.lang.ArithmeticException: / by zero
PASS subtraction
```

What each piece does:

- `Check` holds data only. It has no idea what a runner does with it.
- `CheckRunner.run` is where the logic lives. It works for any class, not just `MathChecks`, because it looks up the annotation at runtime.
- `getDeclaredMethods()` returns methods in no guaranteed order, so the runner sorts them by `priority`. The `Comparator` uses a method reference to a helper that reads the annotation.
- `helper()` has no annotation, so the runner skips it. The message never prints.
- The runner unwraps the `InvocationTargetException` to show that `divideByZero` threw `ArithmeticException`. Without the unwrapping, the output would say only "InvocationTargetException."

Try an experiment: change `@Retention(RetentionPolicy.RUNTIME)` to nothing. The runner will print nothing at all, because reflection can no longer see the annotation. Restore it and move on.

## Example 2: a reader that writes values into fields

Annotations on fields are often used for injection, which is how Spring's `@Value` works. The reader reads the annotation on each field and sets the field's value. Add this to the same file, then include the new classes in `main`:

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
@interface Property {
    String value();                       // the key to look up
}

class AppSettings {
    @Property("app.name")
    String appName;

    @Property("app.port")
    int port;

    @Override
    public String toString() {
        return "AppSettings[name=" + appName + ", port=" + port + "]";
    }
}

class PropertyInjector {
    static void inject(Object target, Map<String, String> props) throws IllegalAccessException {
        for (Field f : target.getClass().getDeclaredFields()) {
            Property p = f.getAnnotation(Property.class);
            if (p == null) continue;

            String raw = props.get(p.value());
            if (raw == null) {
                throw new IllegalStateException("missing property: " + p.value());
            }

            f.setAccessible(true);
            if (f.getType() == int.class) {
                f.setInt(target, Integer.parseInt(raw));  // convert text to the field's type
            } else if (f.getType() == String.class) {
                f.set(target, raw);
            } else {
                throw new IllegalArgumentException("unsupported type: " + f.getType());
            }
        }
    }
}
```

Use it in `main`:

```java
Map<String, String> props = Map.of("app.name", "FamilyInbox", "app.port", "8080");
AppSettings settings = new AppSettings();
try {
    PropertyInjector.inject(settings, props);
} catch (IllegalAccessException e) {
    throw new RuntimeException(e);
}
System.out.println(settings);   // AppSettings[name=FamilyInbox, port=8080]
```

What this shows:

- The reader uses `f.getType()` to decide how to convert the text. The annotation says _which_ key, and the reflection API says _what type_ the field is.
- `f.set` and `f.setInt` write to the object's fields. This is the reflective counterpart of assigning `this.appName = ...`.
- The missing-property check fails fast with a clear message. Spring does the same when a required property is absent at startup.

## Example 3: wrapping behavior around a method

Example 1 calls methods. Real frameworks also need to run code _before and after_ a method, such as for logging, timing, or transactions. You cannot do that by reading the annotation inside the method, because the method body is your code and you do not want to edit it. The usual technique is a **dynamic proxy**: an object that implements the same interface and forwards each call, adding behavior along the way.

Dynamic proxies work only through **interfaces**, and the annotation must be placed on the interface method, because the proxy's handler receives the interface's `Method` object.

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
@interface Logged { }

interface Greeter {
    @Logged
    String greet(String name);

    String plain(String name);       // not annotated
}

class GreeterImpl implements Greeter {
    public String greet(String name) { return "Hello, " + name; }
    public String plain(String name) { return "Hi " + name; }
}
```

Create the proxy in `main`:

```java
Greeter real = new GreeterImpl();

Greeter proxied = (Greeter) Proxy.newProxyInstance(
        Greeter.class.getClassLoader(),
        new Class<?>[] { Greeter.class },
        (proxy, method, args) -> {               // this runs for every call
            boolean logged = method.isAnnotationPresent(Logged.class);
            if (logged) System.out.println("-> calling " + method.getName());

            Object result = method.invoke(real, args);   // forward to the real object

            if (logged) System.out.println("<- " + method.getName() + " returned " + result);
            return result;
        });

System.out.println(proxied.greet("Alireza"));
System.out.println(proxied.plain("Alireza"));
```

Output:

```
-> calling greet
<- greet returned Hello, Alireza
Hello, Alireza
Hi Alireza
```

What each part does:

- `Proxy.newProxyInstance` creates an object at runtime that implements `Greeter`. You never write a class for it.
- The lambda is the `InvocationHandler`. It is the logic that runs on every call to the proxy. Here it checks for `@Logged` and prints around the forwarded call.
- `method.invoke(real, args)` forwards the call to the real object. Without this, nothing would happen.
- `plain` passes through the proxy unchanged, because it has no annotation.

This is the mechanism behind Spring's `@Transactional`, `@Cacheable`, and `@Async`. The annotation is the label, the proxy is the wrapper, and the handler is the logic that reads the label and acts. Spring uses CGLIB subclassing when there is no interface, but the idea is the same.

## Where the logic goes: a summary

|Piece|Holds|Runs when|
|---|---|---|
|Annotation declaration (`@interface`)|Name, elements, defaults, retention, target|Never runs; it is data|
|Reader code (reflection)|The rule: what to do when the annotation is found|At runtime, when your program asks|
|Annotation processor (advanced)|Code that generates or checks source files|During `javac`, before the program runs|
|Proxy or framework aspect|Behavior wrapped around annotated methods|Each time the wrapped method is called|

## Compile-time readers (brief)

Readers do not have to wait until runtime. An **annotation processor** runs inside `javac`. It extends `AbstractProcessor`, declares which annotations it handles with `@SupportedAnnotationTypes`, and can write new `.java` files that are compiled with the rest of your code. Lombok and MapStruct work this way. The processor is registered in `META-INF/services/javax.annotation.processing.Processor`. Processors are powerful but more involved than reflection, so start with runtime readers and reach for processors when you need to generate code.

## Pitfalls to remember

- **An annotation does nothing by itself.** If nothing reads it, it is decorative. This is the most common surprise for beginners.
- **Forgetting `RUNTIME` retention** makes reflection silently return `null`. Check the retention first when a reader finds nothing.
- **Annotations on the implementation do not reach a proxy** when the proxy is created from an interface. Put them on the interface method.
- **Self-invocation bypasses proxies.** If a method calls another annotated method on `this`, the call never goes through the proxy, so the annotation is ignored. In Spring, this is why a `@Transactional` method called from the same class may run without a transaction.
- **Reflection is slower than a direct call** and reads annotations every time. Cache the results (for example, collect the annotated methods once at startup) when the reader runs often.
- **`getAnnotation` returns `null`** when the annotation is absent. Always check before using the result.

## How you'll use this

In Spring Boot, you will mostly write annotations and aspects rather than raw readers. A common real case is a custom `@Timed` annotation on service methods, with a Spring aspect (`@Aspect`, `@Around`) that measures the time of each annotated call. That is the same pattern as Example 3, managed by the framework. For Family Inbox, a `@AuditedAction` annotation on message-sending methods, read by an aspect that writes a log entry, would keep auditing out of your business logic.



[[Java]]