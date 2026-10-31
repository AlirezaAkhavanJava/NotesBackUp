


In Java, `**this**` **is a keyword that refers to the current object**, allowing us to access its instance fields and methods. It is especially useful when a constructor parameter or method parameter has the same name as an instance field. We also have `**this()**`, which is different: it invokes another constructor within the same class, allowing us to reuse initialization logic instead of repeating code. In simple terms, `this` means **"this current object"**, while `this()` means **"call another constructor of this class."**

## 1. Understanding `this`

Consider a simple class:

```
public class User {

    private String username;

    public User(String username) {
        this.username = username;
    }
}
```

Look at this line:

```
this.username = username;
```

We have two variables with the same name:

- `this.username` refers to the instance field belonging to the current object.
    
- `username` refers to the constructor parameter.
    

Without `this`, Java would interpret both names as the constructor parameter.

For example:

```
public User(String username) {
    username = username;
}
```

This compiles, but it doesn't initialize the instance field. It simply assigns the parameter to itself.

### Using `this` with methods

We can also use `this` to access methods belonging to the current object.

```
public class User {

    private String username;

    public User(String username) {
        this.username = username;
    }

    public void printUsername() {
        System.out.println(this.username);
    }

    public void introduce() {
        this.printUsername();
    }
}
```

When we execute:

```
User user = new User("Ali");
user.introduce();
```

Output:

```
Ali
```

Here, `this.printUsername()` invokes the method on the current `User` object.

In this example, writing `printUsername()` without `this` would also work.

---

## 2. Understanding `this()` — Constructor Chaining

`**this()**` **is used to invoke another constructor in the same class.**

This is called _constructor chaining_.

### The problem it solves

Imagine we have a class with multiple constructors:

```
public class User {

    private String username;
    private int age;

    public User() {
        this.username = "Guest";
        this.age = 0;
    }

    public User(String username) {
        this.username = username;
        this.age = 0;
    }

    public User(String username, int age) {
        this.username = username;
        this.age = age;
    }
}
```

This works, but notice how we're repeating initialization logic.

Instead, we can reuse one constructor.

### Using `this()`

```
public class User {

    private String username;
    private int age;

    public User() {
        this("Guest", 0);
    }

    public User(String username) {
        this(username, 0);
    }

    public User(String username, int age) {
        this.username = username;
        this.age = age;
    }
}
```

Now we can instantiate `User` in different ways:

```
User user1 = new User();
User user2 = new User("Ali");
User user3 = new User("Ali", 25);
```

### What Happens Internally?

When we execute:

```
User user = new User();
```

Java follows this constructor chain:

```
new User()
    |
    v
User()
    |
    | this("Guest", 0)
    v
User(String username, int age)
    |
    | Initialize username and age
    v
Object initialized
```

Notice that **Java doesn't create multiple objects**.

We create only one `User` object, but multiple constructors participate in initializing it.

---

## 3. Can We Use `this` to Pass the Current Object?

Yes! Since `this` refers to the current object, we can pass it as an argument to another method.

```
public class User {

    private String username;

    public User(String username) {
        this.username = username;
    }

    public void register() {
        UserService service = new UserService();
        service.save(this);
    }
}
```

```
public class UserService {

    public void save(User user) {
        System.out.println("User received");
    }
}
```

When we call:

```
User user = new User("Ali");
user.register();
```

The `register()` method passes a reference to the current `User` object into `save()`.

No new `User` object is created by passing `this`.

---

## 4. Rules of `this` and `this()`

|Rule|Explanation|
|---|---|
|`this`|Refers to the current object|
|`this.field`|Accesses an instance field|
|`this.method()`|Invokes an instance method on the current object|
|`this()`|Invokes another constructor in the same class|
|`this(arguments)`|Invokes a matching overloaded constructor|
|Constructor chaining|Allows constructors to reuse initialization logic|
|Static context|`this` cannot be used in a static method|
|Recursive constructor calls|Constructors cannot form a cycle by repeatedly calling `this()`|

**Java version note:** In older Java versions, `this()` had to be the first statement in a constructor. Java 25 allows certain statements before it, but the constructor invocation rules still apply.

---

## 5. The Whole Picture

|Feature|`this`|`this()`|
|---|---|---|
|Purpose|Refers to the current object|Calls another constructor in the same class|
|Type|Object reference expression|Explicit constructor invocation|
|Used for|Accessing fields, methods, passing the current object|Constructor chaining|
|Creates an object?|No|No|
|Example|`this.name = name;`|`this("Guest", 0);`|

### Final Mental Model

`**this**` **means "the object I'm currently working with," while** `**this()**` **means "use another constructor of my own class to initialize this object."** We use `this` when we need to explicitly refer to the current object's fields or methods, especially when local variables or parameters have the same names. We use `this()` when a class has multiple constructors and we want them to share initialization logic instead of duplicating code. Both operate on the same object and neither creates an additional object.



[[Java]]