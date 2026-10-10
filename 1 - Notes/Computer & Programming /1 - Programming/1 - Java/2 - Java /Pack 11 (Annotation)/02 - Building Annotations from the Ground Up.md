

This lesson covers how an annotation is built, how its two most important settings (`@Retention` and `@Target`) control where it can be used and who can see it, and which Java classes you need to read it back. Each concept follows the same order: definition, the problem it solves, how it works, and how you will use it.

## 1. What `@interface` really creates

**Definition.** `@interface` declares an **annotation type**. Its elements look like methods, and it can carry default values and meta-annotations.

**The problem it solves.** You need a way to attach structured data to code that tools and frameworks can read. A plain comment cannot be read by a program, and a method cannot be attached to a field or class.

**How it works.** The compiler does not treat `@interface` as a new kind of type. It compiles it into an **interface** that extends `java.lang.annotation.Annotation` automatically. You can check this yourself. Save this as `Command.java`:

```java
import java.lang.annotation.*;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
@interface Command {
    String name();
    String[] aliases() default {};
}
```

Compile it and inspect the result:

```bash
javac Command.java
javap Command.class
```

The output looks like this:

```
public interface Command extends java.lang.annotation.Annotation {
  public abstract java.lang.String name();
  public abstract java.lang.String[] aliases();
}
```

The `extends Annotation` is added by the compiler. Each element becomes an abstract method. When you later call `m.getAnnotation(Command.class)`, the JVM returns an object that implements this interface. That object is generated at runtime with a dynamic proxy, the same mechanism from the previous lesson, so the annotation values you read are served by a proxy.

**How you will use this.** You can predict what is legal in an annotation because you know it is an interface. Elements are methods, and their return types are restricted (see the next section). Annotation types cannot extend other types, and they cannot implement interfaces.

## 2. Element rules: what an annotation may hold

**Definition.** An **element** is a value inside an annotation, declared as a method with an optional `default`.

**The problem it solves.** An annotation has to be stored in the `.class` file and set by the compiler, so its values must be known before the program runs. Java restricts element types to make that possible.

**How it works.** The allowed element types are:

- primitives (`int`, `boolean`, `long`, and the rest)
- `String`
- `Class<?>` or `Class<? extends X>`
- an enum type
- another annotation type
- an array of any of the above

Two more rules apply. Values must be **compile-time constants**, so `@Command(name = someVariable)` is illegal unless the variable is a `static final` constant with a constant value. Elements cannot be `null`, which is why an "absent" value is modeled as an empty string or an empty array, not `null`.

Here is an annotation that uses every kind of element:

```java
enum Level { DEBUG, INFO, WARN }

@Retention(RetentionPolicy.RUNTIME)
@interface Job {
    String name();                       // required: no default
    int retries() default 3;             // primitive with default
    Level level() default Level.INFO;    // enum
    String[] tags() default {};          // array
    Class<?> handler() default Object.class;   // class literal
    Schedule schedule() default @Schedule(every = 60);  // nested annotation
}

@Retention(RetentionPolicy.RUNTIME)
@interface Schedule {
    int every();
}
```

The `schedule` element holds another annotation as its value. The default for it must also be a constant annotation written with `@Schedule(...)`.

**Important rule.** An element without a `default` is required everywhere the annotation is used. Adding a new required element to an annotation that is already in use breaks every existing usage, which is why library authors give new elements defaults.

**How you will use this.** Keep elements few and make them obvious. Use `default` for any value that most users do not need to change. Pick the element type to match the data, so an enum for a fixed set of choices rather than a string that can be misspelled.

## 3. `@Retention` and `RetentionPolicy`

**Definition.** `@Retention` is a meta-annotation that says how long an annotation survives. Its value is one constant of the `RetentionPolicy` enum.

**The problem it solves.** Some annotations are only for the compiler, such as `@Override`. Storing them in every `.class` file wastes space. Other annotations, such as Spring's `@Controller`, must be readable while the program runs. Retention is the setting that makes the difference.

**How it works.** The three constants of `RetentionPolicy` are:

- `SOURCE`: the annotation exists only in the `.java` file. The compiler or an annotation processor can read it, and then it is discarded. It does not appear in the `.class` file.
- `CLASS`: the annotation is written to the `.class` file, but is not visible to reflection at runtime. It is stored in the `RuntimeInvisibleAnnotations` attribute.
- `RUNTIME`: the annotation is written to the `.class` file and is visible to reflection, stored in the `RuntimeVisibleAnnotations` attribute.

If you omit `@Retention`, the default is `CLASS`. That default surprises many people, because the annotation looks present in the file but code using reflection cannot find it.

Here is a program that shows the three behaviors. Save it as `RetentionDemo.java`:

```java
import java.lang.annotation.*;
import java.util.Arrays;

@Retention(RetentionPolicy.SOURCE)
@interface SourceOnly { }

@Retention(RetentionPolicy.CLASS)
@interface ClassOnly { }

@Retention(RetentionPolicy.RUNTIME)
@interface RuntimeKept { }

@SourceOnly
@ClassOnly
@RuntimeKept
class Sample { }

public class RetentionDemo {
    public static void main(String[] args) {
        System.out.println("Visible at runtime: " + Arrays.toString(Sample.class.getAnnotations()));
        System.out.println("ClassOnly present? " + Sample.class.isAnnotationPresent(ClassOnly.class));
        System.out.println("RuntimeKept present? " + Sample.class.isAnnotationPresent(RuntimeKept.class));
    }
}
```

Compile and run:

```bash
javac RetentionDemo.java
java RetentionDemo
```

The output shows that `RuntimeKept` is the only annotation reflection can see. `ClassOnly` is reported as not present, even though it was compiled into the class file.

Now look at the class file to confirm where each annotation went:

```bash
javap -v -p Sample.class | grep -E "Annotations|Runtime"
```

You should see `RuntimeVisibleAnnotations` mentioning `RuntimeKept`, and `RuntimeInvisibleAnnotations` mentioning `ClassOnly`. The `SourceOnly` annotation appears nowhere in the class file.

**How you will use this.** Use `RUNTIME` for anything a framework or your own reader must see while the program runs. Use `SOURCE` for annotations consumed by an annotation processor during compilation, such as code generators. Use `CLASS` only when a bytecode tool needs the information and runtime code does not. When a reader finds nothing, check the retention first. It is the most common cause of silent failure.

## 4. `@Target` and `ElementType`

**Definition.** `@Target` is a meta-annotation that limits where an annotation may be placed. Its value is an `ElementType` constant or an array of them.

**The problem it solves.** An annotation designed for methods should not be placed on a field, where a reader would misinterpret it. `@Target` lets the compiler reject misuse before the program runs.

**How it works.** `ElementType` is an enum with these constants:

- `TYPE`: classes, interfaces, enums, records, and annotation types
- `FIELD`: fields, including enum constants
- `METHOD`: methods
- `PARAMETER`: method and constructor parameters
- `CONSTRUCTOR`: constructors
- `LOCAL_VARIABLE`: local variables
- `ANNOTATION_TYPE`: annotation declarations themselves
- `PACKAGE`: package declarations
- `TYPE_PARAMETER`: type parameters such as `T` in `class Box<T>`
- `TYPE_USE`: any place a type is written, such as `List<@NonNull String>` or `new @Tag Foo()`
- `MODULE`: module declarations
- `RECORD_COMPONENT`: components of a record

If you omit `@Target`, the annotation may be used in any declaration context. A single constant is written directly, and several are written in braces:

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
@interface Endpoint {
    String path();
}

@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.FIELD, ElementType.PARAMETER})
@interface Sensitive { }
```

Now test misuse. Add this to a class:

```java
class Misuse {
    @Endpoint(path = "/count")   // compile error: not applicable to a field
    int count;
}
```

`javac` rejects it with an error stating that the annotation is not applicable to this kind of declaration. The rule is enforced by the compiler, not by your reader.

**TYPE_USE** is worth one extra explanation. An annotation with `TYPE_USE` attaches to the type expression, not to the declaration. In `@NonNull String name;`, the annotation applies to the type `String`. In `List<@NonNull String> names;`, it applies to the element type. Frameworks use this for null-safety checks. If an annotation has `TYPE_USE` and also `FIELD`, it can be used in both positions, and then the placement is ambiguous in some cases, so choose targets deliberately.

**How you will use this.** Always declare `@Target`, even when you think one is enough. It documents intent, prevents misuse, and makes a reader's assumptions safe. Pick the narrowest set that matches what your reader handles.

## 5. Other meta-annotations you should know

These four appear in the standard library and in senior-level code. Each one changes how an annotation behaves.

**`@Documented`** makes an annotation appear in generated Javadoc. Without it, users of your API cannot see the annotation in documentation. Use it on public annotations that change behavior.

**`@Inherited`** affects only class-level annotations. When a superclass has the annotation, `isAnnotationPresent` returns `true` on subclasses too. Interfaces are not covered, and neither are methods or fields. This example shows the behavior:

```java
import java.lang.annotation.*;

@Retention(RetentionPolicy.RUNTIME)
@Inherited
@interface Audited { }

@Audited
class Base { }

class Child extends Base { }

public class InheritedDemo {
    public static void main(String[] args) {
        System.out.println(Child.class.isAnnotationPresent(Audited.class));  // true
    }
}
```

**`@Repeatable`** allows the same annotation to appear more than once on one element. The compiler stores the repeated values inside a **container annotation** that you must declare. The container's `value` element must be an array of the repeatable type:

```java
import java.lang.annotation.*;

@Retention(RetentionPolicy.RUNTIME)
@Repeatable(Tags.class)
@interface Tag {
    String value();
}

@Retention(RetentionPolicy.RUNTIME)
@interface Tags {
    Tag[] value();
}

@Tag("admin")
@Tag("beta")
class Account { }
```

Reading the repeated annotation requires a specific method. `getAnnotation(Tag.class)` returns `null`, because the compiler stored the values inside `Tags`. Use `getAnnotationsByType(Tag.class)` instead, which returns both values. This is a common senior-level trap.

**`@Retention` and `@Target`** are the two you must always write, as shown in earlier sections.

**How you will use this.** Add `@Documented` to public annotations, `@Inherited` only when subclasses should share the behavior, and `@Repeatable` only when a single annotation naturally needs several values on one element.

## 6. The reflection classes you need

Reflection is the set of classes that let a running program inspect code. Every custom annotation reader uses some of these classes, so it helps to know what each one represents. The table below groups them by role.

|Class or interface|Package|Role|
|---|---|---|
|`Annotation`|`java.lang.annotation`|Parent interface of every annotation instance|
|`RetentionPolicy`|`java.lang.annotation`|Enum with `SOURCE`, `CLASS`, `RUNTIME`|
|`ElementType`|`java.lang.annotation`|Enum of places an annotation may go|
|`Retention`, `Target`, `Documented`, `Inherited`, `Repeatable`|`java.lang.annotation`|Meta-annotations used on your declarations|
|`AnnotatedElement`|`java.lang.reflect`|Interface for anything that can carry annotations|
|`Class`|`java.lang`|Describes a type; implements `AnnotatedElement`|
|`Method`|`java.lang.reflect`|Describes a method; implements `AnnotatedElement`|
|`Field`|`java.lang.reflect`|Describes a field; implements `AnnotatedElement`|
|`Constructor`|`java.lang.reflect`|Describes a constructor; implements `AnnotatedElement`|
|`Parameter`|`java.lang.reflect`|Describes one method parameter; implements `AnnotatedElement`|
|`RecordComponent`|`java.lang.reflect`|Describes a record component; implements `AnnotatedElement`|
|`Modifier`|`java.lang.reflect`|Utility for reading `public`, `static`, `private` flags|

The key idea is `AnnotatedElement`. Because `Class`, `Method`, `Field`, `Constructor`, and `Parameter` all implement it, they share the same annotation methods, which are the ones you use every day:

- `getAnnotation(Class<A>)` returns the annotation of that type, or `null`
- `isAnnotationPresent(Class<A>)` returns `true` or `false`
- `getAnnotations()` returns all annotations, including inherited ones
- `getDeclaredAnnotations()` returns only annotations written directly on the element
- `getAnnotationsByType(Class<A>)` returns all annotations of that type, including repeated ones

### The Method class in detail

`Method` is the class you will use most, so it is worth knowing its main operations.

**Getting a method.** You can list methods with `getDeclaredMethods()` (all methods in this class, including private ones) or `getMethods()` (public methods, including inherited ones). To find one by name, use `getDeclaredMethod(name, parameterTypes...)`:

```java
Method m = Shell.class.getDeclaredMethod("greet", String.class, String.class);
```

It throws `NoSuchMethodException` if the signature does not match. The parameter types must match exactly, including primitive versus wrapper types.

**Describing a method.** These methods answer questions about the signature:

- `getName()` returns the method name
- `getReturnType()` returns the return type as a `Class`
- `getParameterCount()` returns the number of parameters
- `getParameterTypes()` returns their types
- `getParameters()` returns `Parameter` objects, which carry annotations
- `getModifiers()` returns an `int` of flags, which `Modifier.isStatic(...)` and `Modifier.isPublic(...)` decode
- `getDeclaringClass()` returns the class that declares the method

**Calling a method.** `invoke(target, args...)` calls the method. For an instance method, the first argument is the object. For a static method, pass `null`. Three rules matter here:

- Call `setAccessible(true)` first if the method is private, and only for code you control.
- The arguments are checked at runtime, so a wrong type throws `IllegalArgumentException`.
- Exceptions thrown inside the method arrive wrapped in `InvocationTargetException`. Call `getCause()` to see the original exception.

**Reading parameter names.** `Parameter.getName()` returns `arg0`, `arg1`, and so on, unless the code was compiled with the `-parameters` flag. Compile with it when your reader depends on names:

```bash
javac -parameters Shell.java
```

### Field, Constructor, and Parameter

`Field` offers `get(obj)`, `set(obj, value)`, and typed versions such as `getInt` and `setInt`. Use `getType()` to decide how to convert values.

`Constructor` offers `newInstance(args...)`. It is useful when a reader creates objects, such as a dependency injector.

`Parameter` is the class that makes parameter annotations possible. You read `Parameter[] params = method.getParameters()`, then call `params[i].getAnnotation(...)` on each one. The example in section 8 uses this.

## 7. How to create an annotation: a step-by-step recipe

Follow these steps every time you design one. They match what experienced library authors do.

1. **State the rule in one sentence.** For example: "a method marked as a command is invoked when the user types its name." If you cannot state the rule, the annotation is not ready.
2. **Choose the elements.** Each element should hold one piece of data the reader needs. Remove any element the reader does not use.
3. **Give every optional element a default.** Make the required elements as few as possible.
4. **Choose the retention.** Use `RUNTIME` unless only a compiler or processor needs it.
5. **Choose the targets.** Name the narrowest set of `ElementType` constants the reader can handle.
6. **Add `@Documented` if it is part of a public API.** Add `@Inherited` or `@Repeatable` only if the rule needs them.
7. **Write the reader separately.** The annotation holds data. A reader class holds the logic, and it should validate the annotated code, failing with a clear message when the rule is broken.
8. **Test a positive case and a negative case.** Test that the reader acts when the annotation is present, and that it reports a clear error when the annotated code breaks the rule.

## 8. A complete example: a command dispatcher

This program uses everything from the lesson. It defines annotations with enum and array elements, puts a parameter annotation on method parameters, and reads them with `Method`, `Parameter`, and `invoke`. Create a folder and save this as `CommandDemo.java`:

```java
import java.lang.annotation.*;
import java.lang.reflect.*;
import java.util.*;

enum Level { DEBUG, INFO }

// Annotation for methods: declares a command and its name and aliases
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
@interface Command {
    String name();
    String[] aliases() default {};
    Level level() default Level.INFO;
}

// Annotation for parameters: names the argument and marks it optional
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.PARAMETER)
@interface Arg {
    String value();
    boolean optional() default false;
}

// The annotated class: declares data only, contains no dispatch code
class Shell {

    @Command(name = "greet", aliases = {"hi", "hello"}, level = Level.DEBUG)
    void greet(@Arg("who") String who,
               @Arg(value = "times", optional = true) String times) {
        int n = (times == null) ? 1 : Integer.parseInt(times);
        for (int i = 0; i < n; i++) {
            System.out.println("Hello, " + who);
        }
    }

    @Command(name = "quit")
    void quit() {
        System.out.println("bye");
    }
}

// The reader: all the logic lives here
class Dispatcher {

    static void dispatch(Object target, String line) throws Exception {
        String[] tokens = line.trim().split("\\s+");
        String word = tokens[0];

        for (Method m : target.getClass().getDeclaredMethods()) {
            Command cmd = m.getAnnotation(Command.class);
            if (cmd == null) continue;                                   // not a command

            boolean matches = cmd.name().equals(word)
                    || Arrays.asList(cmd.aliases()).contains(word);
            if (!matches) continue;

            if (cmd.level() == Level.DEBUG) {
                System.out.println("[debug] matched " + m.getName());
            }

            Parameter[] params = m.getParameters();
            Object[] values = new Object[params.length];

            for (int i = 0; i < params.length; i++) {
                Arg arg = params[i].getAnnotation(Arg.class);            // parameter annotation
                String label = (arg != null) ? arg.value() : params[i].getName();
                boolean optional = (arg != null) && arg.optional();

                if (i + 1 >= tokens.length) {                            // no token for this argument
                    if (optional) {
                        values[i] = null;
                        continue;
                    }
                    throw new IllegalArgumentException("missing argument: " + label);
                }
                values[i] = tokens[i + 1];                               // this lesson handles only String
            }

            m.setAccessible(true);
            m.invoke(target, values);
            return;
        }
        System.out.println("unknown command: " + word);
    }
}

public class CommandDemo {
    public static void main(String[] args) throws Exception {
        Shell shell = new Shell();

        Dispatcher.dispatch(shell, "greet Alireza");
        Dispatcher.dispatch(shell, "hi Alireza 2");
        Dispatcher.dispatch(shell, "quit");
        Dispatcher.dispatch(shell, "jump");

        try {
            Dispatcher.dispatch(shell, "greet");
        } catch (IllegalArgumentException e) {
            System.out.println("error: " + e.getMessage());
        }
    }
}
```

Compile with the parameter-name flag and run:

```bash
javac -parameters CommandDemo.java
java CommandDemo
```

The expected output is:

```
[debug] matched greet
Hello, Alireza
[debug] matched greet
Hello, Alireza
Hello, Alireza
bye
unknown command: jump
error: missing argument: who
```

What each part does:

- `Command` uses an enum element (`level`) and an array element (`aliases`), with defaults for both, so `quit` needs only a name.
- `Arg` is on parameters. The reader gets each `Parameter` from `getParameters()` and reads its annotation, which is how a parameter can carry its own rule.
- `Shell` contains no dispatch code. Renaming `greet` or adding a command requires no change to `Dispatcher`.
- `Dispatcher` finds the command with `getDeclaredMethods()`, checks the name and aliases, and builds the argument array. It then calls `invoke`.
- The `DEBUG` level changes the reader's behavior, showing that an annotation's data can control logic without the annotated code knowing.
- `greet` with no argument throws inside the reader, so the caller catches a clear error rather than a confusing reflection exception.
- The `javac -parameters` flag matters because it keeps real parameter names in the class file. Without it, `label` falls back to `arg0` for any unannotated parameter.

Try three experiments. Remove `@Retention(RetentionPolicy.RUNTIME)` from `Command` and see the dispatcher find nothing. Put `@Command` on a field and see the compiler reject it. Remove `-parameters` from the compile command and use an unannotated parameter to see `arg0` appear.

## 9. Senior-level rules and pitfalls

These points separate working annotation code from code that works only in simple cases.

**Retention and target are part of the public contract.** Once users depend on an annotation, changing its retention or targets can break them. Decide them before publishing.

**Adding a required element breaks every usage.** Always give new elements defaults. This is binary compatibility: code compiled against the old annotation must still run.

**`getAnnotation` costs time.** It reflects over the class each time. Collect the annotated methods once, at startup, and cache them. Spring does this when it scans beans.

**Annotation instances are proxies.** The object returned by `getAnnotation` is created by the JDK at runtime. Its `equals`, `hashCode`, and `toString` are defined by the annotation contract, so two identical annotations on different elements compare equal. Do not use them as identity keys without thinking about that.

**Record components propagate annotations.** An annotation placed on a record component can end up on the field, the accessor method, the constructor parameter, or the record component itself, depending on the `@Target` values. If you annotate a record and a reader finds nothing, check which target the annotation's `@Target` allows.

**Validate in the reader.** The compiler cannot check everything. A reader should check that annotated code follows the rule, for example that a `@Command` method is `void` with the right parameter types, and report a clear error when it does not. This is what `CheckRunner` did in the previous lesson.

**Self-invocation bypasses proxies.** This was mentioned earlier. A dynamic proxy only sees calls that come through it, so a method calling an annotated method on `this` runs without the annotation's behavior.

**Use `SOURCE` retention for processor-only annotations.** If an annotation is consumed only during compilation, `SOURCE` keeps your class files smaller and avoids leaking implementation details.

## 10. How you will use this

In Spring Boot, you will mostly use annotations that others declared, such as `@Target`-restricted `@GetMapping`, `@Service`, and `@Transactional`. Reading their source code, which you can do in the Spring repository, will show you the same `@Retention(RUNTIME)` and `@Target` settings you have just learned. When you write your own, the recipe in section 7 applies directly. For Family Inbox, an annotation such as `@Audited` on message-sending methods, with `@Target(METHOD)` and `@Retention(RUNTIME)`, and an aspect that reads it, would keep logging separate from business logic.




[[Java]]