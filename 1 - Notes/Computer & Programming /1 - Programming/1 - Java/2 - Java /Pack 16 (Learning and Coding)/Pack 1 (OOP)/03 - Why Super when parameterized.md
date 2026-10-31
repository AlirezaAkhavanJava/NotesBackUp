

In Java, when a class extends another class, the superclass must be initialized before the subclass finishes its own initialization. This is why Java requires every subclass constructor to invoke a superclass constructor using `super()` or `super(arguments)`, either explicitly or implicitly. You cannot disable this requirement because it is a fundamental rule of Java's object initialization process. If you don't write `super()` or `this(...)`, Java automatically inserts `super()`, which requires an accessible no-argument constructor in the superclass.

However, `super()` does not create a separate superclass object in memory. When you instantiate a subclass using `new Son()`, Java allocates memory for one object containing both the inherited fields from `Father` and the fields declared in `Son`. The superclass constructor initializes the superclass portion of that object, and then the subclass constructor completes its own initialization. In simple terms, `super()` exists to ensure that inherited state is properly initialized, not to create another object or teach Java what the superclass contains.

---
In Java, calling a superclass constructor through `super()` or `super(arguments)` is mandatory because every subclass object contains inherited state that must be properly initialized before the subclass finishes its own initialization. Java enforces this rule to guarantee a predictable and consistent object initialization process, preventing subclasses from bypassing their superclass constructors and potentially leaving inherited fields in an invalid state. However, `super()` does not create a separate superclass object; it initializes the superclass portion of the same object. You don't always need to write `super()` explicitly because Java can insert it automatically, but you cannot skip superclass constructor execution.
## 1. The Problem It Solves

Imagine we have two concrete classes:

- `Father` — the superclass (parent).
    
- `Son` — the subclass (child).
    

Our `Son` extends `Father`, meaning it inherits accessible fields and methods from `Father`.

```
public class Father {

    private String name;

    public Father(String name) {
        this.name = name;
    }
}
```

```
public class Son extends Father {

}
```

But Java gives us this compilation error:

```
There is no no-arg constructor available in 'Father'
```

**Why?**

Because whenever we create an object of a subclass, Java must initialize its superclass first.

In other words:

> Before Java can finish constructing a `Son` object, it must initialize the `Father` part of that object.

This is where constructors and the `super()` keyword come into play.

---

## 2. How Constructors Work with Inheritance

Let's first understand an important rule:

**Constructors are not inherited in Java.**

When `Son` extends `Father`, it inherits accessible members, but it does not inherit `Father`'s constructors.

However, Java still requires a constructor of the superclass to be called during subclass construction.

Consider:

```
public class Father {

    private String name;

    public Father(String name) {
        this.name = name;
        System.out.println("Father constructor");
    }
}
```

```
public class Son extends Father {

    public Son(String name) {
        super(name);
        System.out.println("Son constructor");
    }
}
```

Now instantiate `Son`:

```
Son son = new Son("Ali");
```

Output:

```
Father constructor
Son constructor
```

### What Happened Internally?

1. We requested a new `Son` object.
    
2. Java allocated memory for the entire object.
    
3. The `Son` constructor started executing.
    
4. `super(name)` invoked the `Father` constructor.
    
5. `Father` initialized its `name` field.
    
6. Execution returned to the `Son` constructor.
    
7. The `Son` constructor completed.
    

**Important:** Java doesn't create two separate objects here. There is one `Son` object containing the inherited instance state defined by `Father`.

---

## 3. What Is `super()`?

`super()` is a special constructor invocation that allows a subclass constructor to call a constructor of its direct superclass.

It has two common forms:

|Syntax|Meaning|
|---|---|
|`super()`|Calls the superclass's no-argument constructor|
|`super(arguments)`|Calls a matching superclass constructor with arguments|

Example:

```
public class Father {

    public Father() {
        System.out.println("No-arg constructor");
    }

    public Father(String name) {
        System.out.println("Name: " + name);
    }
}
```

Now inside `Son`:

```
public Son() {
    super();
}
```

Calls:

```
Father()
```

But:

```
public Son(String name) {
    super(name);
}
```

Calls:

```
Father(String name)
```

Java determines which constructor to invoke using constructor overload resolution.

### `super()` vs. `super`

Don't confuse these:

- `super()` invokes a superclass constructor.
    
- `super.methodName()` calls an accessible superclass method implementation.
    
- `super.fieldName` accesses an accessible superclass field, subject to Java's access rules.
    

---

## 4. Why Does Java Automatically Call `super()`?

Consider:

```
public class Father {

    private String name;

    public Father(String name) {
        this.name = name;
    }
}
```

```
public class Son extends Father {

}
```

We didn't create a constructor in `Son`.

But Java automatically provides a default constructor when a class declares no constructors.

Conceptually, Java treats `Son` as though we had written:

```
public class Son extends Father {

    public Son() {
        super();
    }
}
```

Notice this line:

```
super();
```

Java attempts to invoke:

```
Father()
```

But our superclass only has:

```
Father(String name)
```

**There is no matching no-argument constructor.**

That is exactly why we receive:

```
There is no no-arg constructor available in 'Father'
```

### Important Rule

When you explicitly declare at least one constructor in a class, Java does not generate a default constructor for that class.

For example:

```
public class Father {

    public Father(String name) {

    }
}
```

Java will not automatically create:

```
public Father() {

}
```

However, a subclass still needs to invoke an accessible superclass constructor.

---

## 5. How to Fix the Problem

### Solution 1 — Explicitly Call the Superclass Constructor

```
public class Father {

    private String name;

    public Father(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }
}
```

```
public class Son extends Father {

    public Son(String name) {
        super(name);
    }
}
```

Usage:

```
Son son = new Son("Ali");

System.out.println(son.getName());
```

Output:

```
Ali
```

This works because `Son` passes the required argument to `Father`, allowing it to initialize its private field.

Notice that `name` is private.

Even though `Son` inherits the underlying state, it cannot directly access `Father`'s private field. Calling `super(name)` lets `Father` initialize its own state.

### Solution 2 — Add a No-Argument Constructor to the Superclass

```
public class Father {

    private String name;

    public Father() {
        this.name = "Unknown";
    }

    public Father(String name) {
        this.name = name;
    }
}
```

Now we can write:

```
public class Son extends Father {

}
```

This works because the automatically generated `Son()` constructor can call `Father()`.

But remember: adding a no-argument constructor is not always the best design.

If a `Father` object must have a valid name, requiring the name in its constructor may be preferable.

---

## 6. What If the Subclass Has Its Own Fields?

This is where inheritance becomes more interesting.

Suppose the superclass has a `name`, and the subclass has an `age`.

```
public class Father {

    private String name;

    public Father(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }
}
```

```
public class Son extends Father {

    private int age;

    public Son(String name, int age) {
        super(name);
        this.age = age;
    }

    public int getAge() {
        return age;
    }
}
```

Usage:

```
Son son = new Son("Ali", 25);

System.out.println(son.getName());
System.out.println(son.getAge());
```

Output:

```
Ali
25
```

### Understand the Responsibilities

```
super(name);
```

Delegates the initialization of superclass state to `Father`.

```
this.age = age;
```

Initializes state declared in `Son`.

This is an important object-oriented design principle:

> Each class should be responsible for initializing and maintaining its own state.

Also notice that the superclass constructor doesn't need to know anything about the additional fields in the subclass.

---

## 7. What If We Have Multiple Levels of Inheritance?

Suppose we have:

```
GrandFather
    |
    v
  Father
    |
    v
   Son
```

Each level must invoke a constructor of its direct superclass.

```
class GrandFather {

    public GrandFather() {
        System.out.println("GrandFather");
    }
}
```

```
class Father extends GrandFather {

    public Father() {
        super();
        System.out.println("Father");
    }
}
```

```
class Son extends Father {

    public Son() {
        super();
        System.out.println("Son");
    }
}
```

Now execute:

```
new Son();
```

Output:

```
GrandFather
Father
Son
```

Why?

The superclass initialization happens before the subclass finishes initializing.

The constructor chain is:

```
Son()
  |
  +-- Father()
        |
        +-- GrandFather()
              |
              +-- Object()
```

`Object` is the root superclass of ordinary Java classes.

Constructor bodies complete from the highest superclass down toward the most specific subclass.

### A Detail About Initialization Order

The simplified constructor chain is useful, but Java also runs instance field initializers and instance initialization blocks.

For each class, those initializers run after its superclass constructor completes and before the remaining body of that class's constructor.

This explains why superclass initialization occurs before subclass-specific field initialization.

---

## 8. The Difference Between `this()` and `super()`

Java has two special constructor invocations.

|Keyword|Purpose|
|---|---|
|`this()`|Invokes another constructor in the same class|
|`super()`|Invokes a constructor in the direct superclass|

For example:

```
public class Father {

    private String name;

    public Father() {
        this("Unknown");
    }

    public Father(String name) {
        this.name = name;
    }
}
```

Here:

```
this("Unknown");
```

Calls another constructor inside `Father`.

Now consider:

```
public class Son extends Father {

    public Son() {
        super("Ali");
    }
}
```

Here:

```
super("Ali");
```

Calls a constructor of `Father`.

One important restriction: a constructor cannot directly invoke both `this(...)` and `super(...)` as its constructor invocation. It can delegate to another constructor with `this(...)`, which eventually invokes the superclass constructor.

**Java version note:** Traditionally, explicit constructor invocations had to be the first statement in a constructor. Java 25 supports limited statements before `super(...)` or `this(...)`, but superclass initialization is still required.

---

## 9. Common Mistakes

|Mistake|Why it's wrong|Solution|
|---|---|---|
|Assuming constructors are inherited|Java does not inherit constructors|Declare the constructor needed in the subclass|
|Not calling a superclass constructor|Java implicitly attempts `super()`|Explicitly call `super(arguments)` when necessary|
|Assuming `super()` always exists|The superclass may have no accessible no-arg constructor|Check the available superclass constructors|
|Trying to initialize private superclass fields directly|Private fields are inaccessible from the subclass|Use the superclass constructor or accessible methods|
|Adding a no-arg constructor only to hide the error|It may allow invalid object state|Prefer passing required constructor arguments|

---

## 10. Try It Yourself

Consider the following code:

```
class Animal {

    private String species;

    public Animal(String species) {
        this.species = species;
        System.out.println("Animal created");
    }
}
```

```
class Dog extends Animal {

    private String breed;

    public Dog(String breed) {
        this.breed = breed;
        System.out.println("Dog created");
    }
}
```

### Questions

1. Why does `Dog` fail to compile?
    
2. What constructor is Java trying to call automatically?
    
3. How can you modify `Dog` without changing `Animal`?
    
4. What will be printed when you create a `Dog` instance?
    

### One Possible Solution

```
class Dog extends Animal {

    private String breed;

    public Dog(String species, String breed) {
        super(species);
        this.breed = breed;
        System.out.println("Dog created");
    }
}
```

Now:

```
Dog dog = new Dog("Canine", "Husky");
```

Output:

```
Animal created
Dog created
```

---

## 11. The Whole Picture

|Concept|Explanation|
|---|---|
|Inheritance|A subclass extends a superclass and inherits its accessible functionality|
|Constructor|Initializes an object when it is instantiated|
|Constructor inheritance|Constructors are not inherited|
|Default constructor|Compiler-generated no-argument constructor when no constructors are declared|
|`super()`|Invokes an accessible no-argument superclass constructor|
|`super(arguments)`|Invokes a matching accessible superclass constructor|
|`this(arguments)`|Delegates to another constructor in the same class|
|Initialization chain|Superclass initialization happens before subclass initialization completes|
|Main reason for the error|Java cannot find an accessible superclass constructor matching the implicit `super()` call|

### Final Mental Model

Whenever you see:

```
class Son extends Father
```

Think:

**"To construct a** `**Son**`**, Java must also initialize everything that belongs to its** `**Father**` **superclass."**

So if `Father` requires information to initialize its state, `Son` must provide that information through a superclass constructor.

That is the fundamental reason behind `super()` and constructor chaining in Java.





[[Java]]