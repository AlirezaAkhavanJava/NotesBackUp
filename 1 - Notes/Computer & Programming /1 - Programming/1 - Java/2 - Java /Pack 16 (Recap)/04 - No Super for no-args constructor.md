

## 1. The Problem It Solves

In Java, whenever we create an object of a subclass, the superclass must also be initialized. Java guarantees this by requiring every subclass constructor to invoke a superclass constructor.

However, **we don't always need to write** `**super()**` **ourselves because Java can insert it automatically.**

## 2. When the Superclass Has a No-Argument Constructor

Consider two classes:

```java
public class Father {

    private String name;

    public Father() {
        this.name = "Unknown";
    }
}
```

```java
public class Son extends Father {

    public Son() {
        System.out.println("Son created");
    }
}
```

Notice that we didn't write `super()` inside `Son`.

But Java implicitly treats the `Son` constructor as:

```java
public Son() {
    super();
    System.out.println("Son created");
}
```

This works because `Father` has an accessible no-argument constructor:

```java
public Father() {
    this.name = "Unknown";
}
```

**The important point:** Java doesn't skip the superclass constructor. It simply invokes it automatically.

## 3. What If Father Has Only a Parameterized Constructor?

Now imagine we change `Father`:

```java
public class Father {

    private String name;

    public Father(String name) {
        this.name = name;
    }
}
```

And keep `Son` unchanged:

```java
public class Son extends Father {

    public Son() {
        System.out.println("Son created");
    }
}
```

Now Java reports a compilation error.

Why?

Because Java still tries to insert:

```java
super();
```

But `Father` doesn't have a `Father()` constructor. It only has `Father(String name)`.

So we must explicitly specify which constructor to invoke and provide its required argument:

```java
public class Son extends Father {

    public Son(String name) {
        super(name);
        System.out.println("Son created");
    }
}
```

Now Java knows how to initialize the superclass state.

## 4. What If We Don't Declare Any Constructor?

If a class doesn't declare any constructors, Java automatically generates a default no-argument constructor.

For example:

```java
public class Father {
}
```

Conceptually, Java provides:

```java
public Father() {
    super();
}
```

The `super()` here invokes the constructor of `Object`, Java's root superclass.

Similarly:

```java
public class Son extends Father {
}
```

Java automatically provides a constructor equivalent to:

```java
public Son() {
    super();
}
```

Therefore, both classes can be instantiated without explicitly declaring constructors:

```java
Father father = new Father();
Son son = new Son();
```

Remember that if you explicitly declare any constructor, Java stops generating the default constructor for that class.

## 5. The Whole Picture

|Situation|What Java Does|
|---|---|
|`Father` has an accessible `Father()`|Java can invoke `super()` implicitly|
|`Father` only has `Father(String name)`|You must explicitly invoke a matching superclass constructor|
|`Father` declares no constructors|Java generates a default no-argument constructor|
|`Son` declares no constructors|Java generates a default constructor that invokes `super()`|
|`Son` invokes `this(...)`|Java delegates to another `Son` constructor, which must eventually invoke a superclass constructor|

## Final Mental Model

**Java always requires superclass constructor execution during subclass initialization, but it doesn't always require us to write** `**super()**` **explicitly.** When the superclass has an accessible no-argument constructor, Java automatically inserts `super()` if the subclass constructor doesn't explicitly invoke `super(...)` or `this(...)`. However, when the superclass requires arguments, we must explicitly call a matching constructor using `super(arguments)`. In simple terms, Java handles the superclass constructor call automatically when it can; otherwise, we must tell Java which constructor to use and what arguments to pass.




[[Java]]