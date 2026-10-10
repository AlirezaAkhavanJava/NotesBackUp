

**Binding** is the process of connecting a name in your code (a variable, a method call, a field access) to the actual piece of code or memory it refers to. When you write `speak()`, something has to decide _which_ `speak` method runs. That decision is binding.

In Java, the term most often means **method binding**, and it comes in two kinds: **early binding** and **late binding**. Spring Boot uses a different sense of the word, **data binding**, which you'll meet soon, so I'll cover that too.

## Why binding exists

Your program may have several methods with the same name, spread across a class hierarchy. The compiler and the JVM need a rule for choosing one. Without binding rules, `animal.speak()` would be ambiguous: the variable's type says `Animal`, but the object in memory might be a `Dog`.

Java's rules answer that question, and the answer depends on which kind of member you're accessing.

## Early binding (static binding)

Early binding means the choice is made **at compile time**, using the **declared type** of the reference, not the object it points to.

It applies to:

- **Static methods**
- **Fields** (instance and static)
- **Overloaded methods** (same name, different parameter types)
- **Private and final methods**, which cannot be overridden

Here is a complete example:

```java
class Animal {
    String sound = "...";

    String speak() {
        return "Generic animal sound";
    }

    static String kingdom() {
        return "Animalia";
    }
}

class Dog extends Animal {
    String sound = "Woof";  // hides the parent's field, does not override it

    @Override
    String speak() {        // overrides the parent's method
        return "Woof!";
    }

    static String kingdom() {  // hides the parent's static method
        return "Dog kingdom";
    }
}

public class BindingDemo {
    public static void main(String[] args) {
        Animal a = new Dog();    // declared type: Animal, actual object: Dog

        System.out.println(a.sound);      // prints "..."   (field: resolved by declared type Animal)
        System.out.println(a.speak());    // prints "Woof!" (method: resolved at runtime, see below)
        System.out.println(a.kingdom());  // prints "Animalia" (static: resolved by declared type Animal)
    }
}
```

What each line shows:

- `a.sound` prints `"..."` because fields are not polymorphic. Java picks the field from `Animal`, the declared type. The `Dog` field only hides it.
- `a.kingdom()` prints `"Animalia"` because static methods belong to the class, not to objects, so the declared type decides.
- `a.speak()` is the interesting one. It's an instance method, so Java uses late binding, covered next.

Overloading is also early binding. Consider this:

```java
class Printer {
    void print(Object o)  { System.out.println("Object version"); }
    void print(String s)  { System.out.println("String version"); }
}

Printer p = new Printer();
Object text = "hello";
p.print(text);  // prints "Object version"
```

Even though `text` holds a `String`, the compiler chose `print(Object)` because the declared type of `text` is `Object`. The choice was locked in at compile time.

## Late binding (dynamic binding)

Late binding means the choice is made **at runtime**, based on the **actual object's class**. This is what makes polymorphism work.

It applies to **overridden instance methods**. When you call `a.speak()`, the JVM doesn't look at `Animal` to decide what to run. It looks at the real object in memory, finds it is a `Dog`, and runs `Dog.speak()`.

Internally, the JVM does this with a method table per class. Each object carries a reference to its class, and the call looks up the overriding implementation in that class's table. You don't need to manage this yourself, but it explains why the behavior is determined at runtime.

This is the rule that matters most in practice:

|Member|Decided by|When|
|---|---|---|
|Overridden instance method|Actual object type|Runtime (late)|
|Field|Declared reference type|Compile time (early)|
|Static method|Declared reference type|Compile time (early)|
|Overloaded method|Declared argument types|Compile time (early)|

A practical consequence: if you want polymorphic behavior, put it in **methods**, not **fields**. Keep fields private and expose behavior through methods.

## Data binding in Spring Boot

Spring uses "binding" to mean something different: **copying values from an external source into Java objects by matching names**. The source might be a configuration file, an HTTP request body, or request parameters.

Here's a common case, binding configuration properties:

```java
// application.properties
// app.mail.host=smtp.example.com
// app.mail.port=587

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.mail")
public record MailProperties(String host, int port) {}
```

Spring reads every property starting with `app.mail`, matches `host` and `port` by name, converts `"587"` to the `int` `587`, and fills the record. You never write a parser yourself.

The same idea applies to HTTP requests. When a controller has this method:

```java
@PostMapping("/users")
public String create(@RequestBody UserDto user) { ... }
```

Spring binds the incoming JSON fields to the `UserDto` fields by name. Binding also handles type conversion, validation, and errors such as a field that can't be converted.

Both kinds of binding are part of your Spring Boot path, but they solve different problems: late binding gives you polymorphism in your own class design, while data binding moves external data into your objects.

## How you'll use this

Early and late binding will affect your design choices every day. When you override methods in a class hierarchy, you rely on late binding. When you write a field in a subclass with the same name as a parent field, you're triggering the surprising behavior above, which is usually a bug. When you add an overloaded method, the compiler chooses it using the static types of the arguments.

For Spring, you'll use data binding constantly: `@ConfigurationProperties`, `@Value`, `@RequestBody`, `@RequestParam`, and form binding all depend on it.




[[Java]]