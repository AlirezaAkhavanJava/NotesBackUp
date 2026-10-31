


Polymorphism means "many forms." In Java, it lets you write code against one general type and have it behave differently depending on the actual object it receives. You write `animal.speak()` once, and a dog barks, a cat meows, and a cow moos, without your code ever checking which one it is.
Polymorphism needs a "family": classes connected by `extends` or `implements`. You hold the object through a variable of the parent or interface type, and Java runs the child's version of the method. Let's make that precise, and then answer your question about reference types.

---

## 1. First, your question: "Is Java a reference type?"

Not quite. Java is a language, and it has two kinds of types:

|Kind|Examples|What the variable holds|
|---|---|---|
|Primitive types|`int`, `double`, `boolean`, `char`, `long` ...|The actual value|
|Reference types|classes, interfaces, arrays, enums, `String`|An address (reference) pointing to an object|

Polymorphism only works with **reference types**. A variable of reference type doesn't contain the object. It points to it, like a remote control pointing to a TV. That's why one variable type can point to many different objects.

```java
int x = 5;               // x holds the number 5 itself
Animal a = new Dog();    // a holds a reference to a Dog object
```

You can't do polymorphism with an `int`, because there's no object behind it to be "different."

---

## 2. The two types every reference variable has

This is the most important idea in the whole topic. Every reference variable has two types:

||Static type (compile-time)|Runtime type (actual object)|
|---|---|---|
|What is it?|The type written on the left|The class after `new`|
|Who decides?|You, in the source code|The object that was really created|
|Who uses it?|The compiler|The JVM, when the program runs|

```java
Animal a = new Dog();
//  ^          ^
//  static     runtime
//  type       type
```

The rule that makes polymorphism work:

- **The compiler** checks that the method exists in the _static_ type.
- **The JVM** picks which version to run based on the _runtime_ type.

---

## 3. A full example with inheritance

```java
public class Animal {
    public void speak() {
        System.out.println("Some sound");
    }
}

public class Dog extends Animal {
    @Override
    public void speak() {
        System.out.println("Woof");
    }
}

public class Cat extends Animal {
    @Override
    public void speak() {
        System.out.println("Meow");
    }
}
```

Now use them:

```java
Animal a1 = new Dog();
Animal a2 = new Cat();
Animal a3 = new Animal();

a1.speak();   // Woof
a2.speak();   // Meow
a3.speak();   // Some sound
```

Line by line:

- `Animal a1 = new Dog();` is allowed because a `Dog` _is an_ `Animal`. The variable type is `Animal`, the object is a `Dog`.
- `a1.speak()`: the compiler asks, "Does `Animal` have `speak()`?" Yes, so it compiles.
- At runtime, the JVM looks at the real object, finds a `Dog`, and runs `Dog`'s `speak()`.
- Same call, same variable type, three different results. That's polymorphism.

---

## 4. Polymorphism with an interface

Same idea, but the "family" is built with `implements`:

```java
public interface Notifier {
    void send(String message);
}

public class EmailNotifier implements Notifier {
    public void send(String message) { System.out.println("Email: " + message); }
}

public class SmsNotifier implements Notifier {
    public void send(String message) { System.out.println("SMS: " + message); }
}
```

```java
Notifier n = new EmailNotifier();
n.send("Hello");   // Email: Hello

n = new SmsNotifier();
n.send("Hello");   // SMS: Hello
```

Walkthrough:

- `Notifier n` is the reference type. You can't write `new Notifier()`, but `n` can point to _any_ class that implements it.
- The same variable `n` points to an email notifier first, then an SMS notifier.
- The line `n.send("Hello")` is identical both times. Only the object changed.

This is also why polymorphism is so useful in practice:

```java
void alertUser(Notifier notifier) {
    notifier.send("Your order shipped");
}
```

`alertUser` works with every current and future `Notifier`. You never have to edit it when you add a `PushNotifier`.

---

## 5. Polymorphism with collections

A very common real-world use is one list holding many kinds of objects:

```java
List<Animal> zoo = List.of(new Dog(), new Cat(), new Animal());

for (Animal animal : zoo) {
    animal.speak();
}
```

Output:

```
Woof
Meow
Some sound
```

The loop has no `if (animal is Dog)` checks. Each object knows how to speak for itself.

---

## 6. What polymorphism does NOT cover

Beginners often get surprised here. Only **instance methods that are overridden** are polymorphic.

|Thing|Polymorphic?|Which version runs?|
|---|---|---|
|Overridden instance method|Yes|Runtime type's version|
|Fields (variables)|No|Static type's field|
|`static` methods|No|Static type's method (called _hiding_)|
|`private` methods|No|Not inherited, so nothing to override|
|`final` methods|No|Can't be overridden|

Here's the field trap:

```java
class Animal { String type = "animal"; }
class Dog extends Animal { String type = "dog"; }

Animal a = new Dog();
System.out.println(a.type);   // animal  (not "dog")
```

Fields are looked up using the _static_ type (`Animal`), not the real object. That's one more reason to keep fields `private` and use methods.

---

## 7. The "family" limit: you only see the static type's members

```java
Animal a = new Dog();
a.speak();      // fine
a.fetch();      // compile error, if fetch() exists only in Dog
```

The compiler only knows `a` is an `Animal`. To use `Dog`-only methods, you cast:

```java
if (a instanceof Dog) {
    Dog d = (Dog) a;
    d.fetch();
}
```

Or with modern Java pattern matching:

```java
if (a instanceof Dog d) {
    d.fetch();
}
```

Walkthrough:

- `instanceof Dog` checks the runtime type.
- If it's true, you get a `Dog`-typed variable `d`, and now `fetch()` is visible.
- If you cast without checking and the object isn't a `Dog`, you get a `ClassCastException`.

---

## 8. Two kinds of polymorphism in Java

What we've covered so far is **runtime polymorphism** (also called dynamic dispatch or overriding). Java has a second kind:

||Compile-time polymorphism|Runtime polymorphism|
|---|---|---|
|Also called|Overloading|Overriding|
|Same method name, different...|Parameters|Class (same signature)|
|Decided by|Compiler|JVM at runtime|
|Needs inheritance?|No|Yes (or interface)|

```java
class Printer {
    void print(int x)    { System.out.println("int: " + x); }
    void print(String s) { System.out.println("String: " + s); }
}
```

`print(5)` and `print("hi")` pick different methods, and the compiler decides which one, based on the argument types. This is what you described when you said "family relation," so the runtime kind is the one you were focusing on, and it's the one people usually mean when they say "polymorphism."

---

## 9. Rules for overriding (so polymorphism works)

- Same method name and same parameter list.
- Return type must be the same, or a subtype (a "covariant" return).
- Access can't be _more restrictive_ (`public` can't become `private`).
- Can't override `final`, `static`, or `private` methods.
- Use `@Override` so the compiler catches typos.

---

## Related concept: Dynamic dispatch (short summary)

Dynamic dispatch is the _mechanism_ behind runtime polymorphism. When you call `a.speak()`, the JVM looks at the real object's class at runtime and finds the right `speak()` to run. Polymorphism is what you _get_. Dynamic dispatch is _how_ Java delivers it.

---

## Quick recap

- Polymorphism = one reference type, many possible behaviors.
- It needs reference types (objects), a family (`extends` / `implements`), and overridden instance methods.
- The compiler checks the static type. The JVM runs the runtime type's method.
- Fields, `static`, `private`, and `final` methods are not polymorphic.
- Java isn't "a reference type." It has primitive types and reference types, and polymorphism lives in the reference ones.




[[Java]]