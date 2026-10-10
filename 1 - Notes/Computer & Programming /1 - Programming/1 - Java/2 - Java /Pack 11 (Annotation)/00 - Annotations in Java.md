

An **annotation** is metadata attached to a declaration: a class, method, field, parameter, or other element. It is a label that says something _about_ that declaration. An annotation does not run by itself and does not change the code's behavior. Something else has to read the label and act on it.

Consider `@Override`. Writing it does not make the method override anything. It asks the compiler to check that a method with the same signature exists in a superclass, and to report an error if none does. The annotation changes nothing in the program. It gives the compiler a rule to enforce.

That separation is the key idea of the whole lesson: **annotations describe, and readers act.**

## Why annotations exist

Before annotations, frameworks needed configuration somewhere else. A web framework might require an XML file that mapped each URL to a class and method, so the code and its configuration lived in two places that could drift apart. Developers had to edit both files and keep them in sync.

Annotations move that information next to the code it describes. The mapping from a URL to a method is written on the method itself:

```java
@GetMapping("/users/{id}")
public User findUser(@PathVariable long id) { ... }
```

Now the method and its routing rule are one unit. When the method is renamed or deleted, the rule goes with it. The same idea applies to validation rules on fields, transaction boundaries on service methods, and dependency injection points. You have seen all of these in Spring code.

## Anatomy: how an annotation is declared

An annotation type is declared with `@interface`. Its elements look like methods with optional defaults:

```java
@interface Timeout {
    int seconds() default 30;
    String reason() default "";
}
```

Usage:

```java
@Timeout(seconds = 5, reason = "slow API")   // both elements set
void fetch() { }

@Timeout                                       // both use their defaults
void save() { }
```

Two rules are worth knowing. Elements can only be constants, enums, classes, other annotations, or arrays of those. If an annotation has a single element named `value`, you may write its name without `value =`, so `@MaxLength(10)` is shorthand for `@MaxLength(value = 10)`.

## The meta-annotations: controlling your annotation

An annotation type is itself annotated with **meta-annotations** that define how it behaves. The important ones are:

|Meta-annotation|Controls|Common values|
|---|---|---|
|`@Retention`|How long the annotation survives|`SOURCE`, `CLASS` (default), `RUNTIME`|
|`@Target`|Where it may be placed|`TYPE`, `METHOD`, `FIELD`, `PARAMETER`, and others|
|`@Inherited`|Whether subclasses inherit it from a superclass|(marker only)|
|`@Documented`|Whether it appears in generated Javadoc|(marker only)|
|`@Repeatable`|Whether it may appear more than once on one element|used with a container annotation|

`@Retention` is the setting that matters most. It decides who can see the annotation:

- **`SOURCE`**: kept only in the `.java` file. Read by the compiler itself, such as `@Override`, then discarded.
- **`CLASS`**: written into the `.class` file, but not visible to code running on the JVM. Read by bytecode tools.
- **`RUNTIME`**: written into the `.class` file and visible through reflection while the program runs. This is what frameworks like Spring use.

## Who reads annotations

Each retention level has a matching reader, which gives three ways an annotation can have an effect.

**1. The compiler** reads built-in annotations such as `@Override`, `@FunctionalInterface`, and `@Deprecated`. It warns or fails the build. This happens during `javac`.

**2. Annotation processors** are plugins that run inside `javac`. They read annotations and generate new source files or check rules. MapStruct generates mapping classes this way, and Lombok generates getters and setters. The generated code is then compiled like anything you wrote. This also happens at compile time, before the program runs.

**3. Reflection** is code that inspects classes at runtime. It asks questions such as "does this field have an annotation?" and reads the values of its elements. Spring uses this to find beans, route requests, and wire dependencies when your application starts.

Reflection is the one that makes an annotation behave like a live feature, so it is the reader the next example uses.

## Example: a validator that reads annotations at runtime

This program defines two annotations, marks the fields of a class with them, and then uses reflection to check the values. It is a small version of what Bean Validation does in Spring Boot. Save it as `ValidationDemo.java` in a new folder:

```java
import java.lang.annotation.*;
import java.lang.reflect.*;

// Rule: the field must not be null or blank
@Retention(RetentionPolicy.RUNTIME)   // keep it visible at runtime
@Target(ElementType.FIELD)            // allowed only on fields
@interface NotBlank {
    String message() default "must not be blank";
}

// Rule: the text must not be longer than value characters
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.FIELD)
@interface MaxLength {
    int value();
    String message() default "is too long";
}

class UserForm {
    @NotBlank
    String username;

    @NotBlank(message = "email is required")
    String email;

    @MaxLength(value = 10, message = "must be 10 characters or fewer")
    String bio;

    UserForm(String username, String email, String bio) {
        this.username = username;
        this.email = email;
        this.bio = bio;
    }
}

public class ValidationDemo {

    static void validate(Object target) throws IllegalAccessException {
        // Reflection: list every field the class declares
        for (Field field : target.getClass().getDeclaredFields()) {
            field.setAccessible(true);                 // allow reading private fields
            Object value = field.get(target);
            String text = (value == null) ? null : value.toString();

            if (field.isAnnotationPresent(NotBlank.class)) {
                NotBlank rule = field.getAnnotation(NotBlank.class);
                if (text == null || text.isBlank()) {
                    System.out.println(field.getName() + " " + rule.message());
                }
            }

            if (field.isAnnotationPresent(MaxLength.class)) {
                MaxLength rule = field.getAnnotation(MaxLength.class);
                if (text != null && text.length() > rule.value()) {
                    System.out.println(field.getName() + " " + rule.message());
                }
            }
        }
    }

    public static void main(String[] args) throws IllegalAccessException {
        UserForm form = new UserForm("", "", "a very long biography");
        validate(form);
    }
}
```

Compile and run:

```bash
javac ValidationDemo.java
java ValidationDemo
```

The output is three lines, one for each broken rule. The order may differ, because `getDeclaredFields()` does not guarantee an order.

What each part does:

- `@Retention(RUNTIME)` on both annotations is what makes them visible to `getAnnotation`. Without it, the validator sees nothing.
- `@Target(FIELD)` makes the compiler reject `@NotBlank` if someone puts it on a method. The annotation's own declaration enforces correct use.
- `@NotBlank(message = "email is required")` overrides the default message, while `username` uses the default. This is how element defaults work in practice.
- `validate` never mentions `UserForm`. It works on any class whose fields carry these annotations. That separation, where the rule lives on the data and the logic lives in a generic reader, is the reason annotations are so widely used.

Now try an experiment. Remove `@Retention(RetentionPolicy.RUNTIME)` from `NotBlank` and run again. The `username` and `email` messages will disappear, because the annotation is now discarded in the class file and reflection cannot find it. This single line is the difference between a label and a live feature.

## What happens in the class file

Annotations with `CLASS` or `RUNTIME` retention are stored as attributes in the compiled `.class` file. You can see them with:

```bash
javap -v -p UserForm.class | grep -A3 NotBlank
```

The output lists the annotation type and its element values, such as the `message` string for `email`. The JVM does not execute annotations. It just keeps them in the class's metadata until some code asks for them.

## How Spring uses annotations

Spring Boot works in the same way the validator does, but at larger scale:

- `@Component`, `@Service`, and `@Repository` mark classes. At startup, Spring scans the classpath, reads these annotations, and creates beans.
- `@Autowired` or constructor parameters mark where a dependency should be injected. Spring reads these markers and supplies the matching bean.
- `@GetMapping("/users/{id}")` tells Spring which method handles a request. Spring builds its routing table from these labels when the application starts.
- `@Transactional` is handled differently. Spring reads it and wraps the bean in a proxy that opens and commits a transaction around the method. The annotation alone does nothing; the proxy does the work.

This is why a `@Transactional` method called from inside the same class sometimes runs without a transaction. The call bypasses the proxy, so no reader ever acts on the annotation. Knowing that annotations are read by something, not executed by themselves, is what lets you debug this.

## How you'll use this

When you write Spring code, you will mostly use annotations that already exist. When you write your own, follow the same steps as the example: choose `RUNTIME` retention if something must read it while the program runs, restrict it with `@Target`, give elements sensible defaults, and write the reader separately from the annotated classes.

For Family Inbox, a message-validation rule such as "a school notice needs a title" could be a custom annotation read by a validator, while Spring provides `@NotBlank` from Bean Validation for the same job. Most of the time you will reach for the library annotation, but the mechanism is the one you just built.




[[Java]]