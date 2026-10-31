

The Java Collections Framework (JCF) is an excellent real-world example of how interfaces, abstract classes, and concrete classes work together. It uses interfaces to define contracts, abstract classes to provide reusable implementations, and concrete classes to implement actual data structures.

The important design principle is code reuse without sacrificing flexibility. Instead of forcing every collection class to implement dozens of methods from scratch, Java provides abstract classes containing common implementations. Concrete classes can inherit that code and focus on their own storage mechanisms and specialized behavior.

## 1. The problem Java needed to solve

Imagine Java has three different collection classes:

- `ArrayList` — stores elements in a resizable array.
    
- `LinkedList` — stores elements in linked nodes.
    
- `Vector` — stores elements in a resizable array with synchronized methods.
    

All three need methods such as `add()`, `get()`, `size()`, and `contains()`.

Although their internal storage differs, some operations can share the same general implementation.

So Java's designers used three layers.

## 2. Understanding the three layers

Interface — `List<E>`

Defines what list implementations must support

get() · add() · remove() · size()

implements

Abstract class — `AbstractList<E>`

Provides common implementations

iterator() · indexOf() · equals()

extends

Concrete class — `ArrayList<E>`

Provides array-backed storage and specialized implementations

This diagram simplifies the real inheritance hierarchy. In Java, `AbstractList` also extends `AbstractCollection`, which supplies even more reusable methods.

![](https://www.google.com/s2/favicons?domain=https://docs.oracle.com&sz=32)

Oracle Docs

+1

## 3. First layer: The interface

Let's build our own simplified collection framework to understand Java's design.

```
public interface MyList {

    void add(String value);

    String get(int index);

    int size();

    boolean contains(String value);
}
```

This interface establishes a contract.

Any concrete class implementing `MyList` must have working implementations of those four methods, whether written directly or inherited.

However, the interface doesn't specify how elements must be stored.

One implementation might use an array. Another might use linked nodes.

That's the flexibility interfaces give us.

## 4. Second layer: The abstract class

Now imagine every implementation can use the same algorithm for `contains()`.

Why should every class rewrite it?

```
public abstract class AbstractMyList implements MyList {

    @Override
    public boolean contains(String value) {

        for (int i = 0; i < size(); i++) {

            if (java.util.Objects.equals(get(i), value)) {
                return true;
            }
        }

        return false;
    }
}
```

Look carefully at what we did.

We implemented only `contains()`.

We didn't implement `add()`, `get()`, or `size()`.

That's completely legal because our class is abstract.

Even more interesting: `contains()` calls `get()` and `size()` despite not implementing them!

At runtime, Java uses the implementations supplied by the concrete subclass.

This is polymorphism in action.

## 5. Third layer: The concrete class

Now we create a working implementation backed by an array.

```
import java.util.Arrays;

public class MyArrayList extends AbstractMyList {

    private String[] elements = new String[10];
    private int count = 0;

    @Override
    public void add(String value) {

        if (count == elements.length) {
            elements = Arrays.copyOf(elements, elements.length * 2);
        }

        elements[count++] = value;
    }

    @Override
    public String get(int index) {

        if (index < 0 || index >= count) {
            throw new IndexOutOfBoundsException();
        }

        return elements[index];
    }

    @Override
    public int size() {
        return count;
    }
}
```

Notice: We never implemented `contains()` in `MyArrayList`!

We inherited it from `AbstractMyList`.

Let's test everything.

```
public class Main {

    public static void main(String[] args) {

        MyList names = new MyArrayList();

        names.add("Ali");
        names.add("Sara");

        System.out.println(names.size());          // 2
        System.out.println(names.get(0));           // Ali
        System.out.println(names.contains("Sara")); // true
    }
}
```

### What happens internally?

When Java executes:

```
names.contains("Sara");
```

The following process happens:

1. `MyArrayList` instance

Receives the contains("Sara") call

2. `AbstractMyList.contains()`

Inherited implementation executes the loop

3. `MyArrayList.get()` and `size()`

Concrete methods supply the actual elements and length

4. Returns `true`

The element was found

That's the power of the design: a reusable algorithm in the superclass works with different concrete implementations.

## 6. How the real Java Collections Framework does this

Java takes the same idea further.

```
public interface List<E> extends Collection<E> {
    // List contract
}
```

```
public abstract class AbstractList<E>
        extends AbstractCollection<E>
        implements List<E> {
    // Shared implementations
}
```

```
public class ArrayList<E>
        extends AbstractList<E>
        implements List<E>, RandomAccess,
                   Cloneable, java.io.Serializable {
    // Array-backed implementation
}
```

These are simplified declarations of the real types.

For instance, `AbstractCollection` implements `isEmpty()` using `size()` and implements `contains()` using an iterator. That allows subclasses to reuse these methods when suitable.

![](https://www.google.com/s2/favicons?domain=https://docs.oracle.com&sz=32)

Oracle Docs

+1

One detail worth correcting from our earlier discussion: `ArrayList` actually overrides `indexOf()` with its own implementation rather than simply inheriting `AbstractList.indexOf()`. Abstract classes provide reusable defaults, but concrete classes are free to override them for optimization.

![](https://www.google.com/s2/favicons?domain=https://docs.oracle.com&sz=32)

Oracle Docs

+1

## 7. Let's extend Java's actual AbstractList

This time, instead of creating our own interface and abstract class, let's use the real Java API.

```
import java.util.AbstractList;
import java.util.List;

public class MyReadOnlyList extends AbstractList<String> {

    private final List<String> data =
            List.of("Ali", "Sara", "Reza");

    @Override
    public String get(int index) {
        return data.get(index);
    }

    @Override
    public int size() {
        return data.size();
    }
}
```

We only implemented two methods: `get()` and `size()`.

Now:

```
public class Main {

    public static void main(String[] args) {

        MyReadOnlyList names = new MyReadOnlyList();

        System.out.println(names.get(0));          // Ali
        System.out.println(names.size());          // 3
        System.out.println(names.contains("Sara")); // true
        System.out.println(names.indexOf("Reza"));  // 2
        System.out.println(names.isEmpty());        // false
        System.out.println(names);                  // [Ali, Sara, Reza]
    }
}
```

We received all those other operations through inherited implementations.

But if you call:

```
names.add("New user");
```

You'll get `UnsupportedOperationException`.

Why? Because `AbstractList` does not automatically know how to modify our storage. It provides implementations that reject unsupported modification operations until a subclass supplies the required behavior.

This demonstrates something important: An interface contract can include optional operations. In the Collections Framework, implementations can reject certain modifications while still satisfying the documented collection contract.

## 8. When to use each in your own projects

|Situation|Choose|
|---|---|
|Different classes need to follow the same contract|Interface|
|Related classes have reusable code|Abstract class|
|Related classes have common state or constructors|Abstract class|
|You need an instantiable implementation|Concrete class|
|You want loose coupling between services|Interface|
|A class needs to support multiple unrelated capabilities|Multiple interfaces|

Also remember: interfaces can have `default` methods with implementations. You don't automatically need an abstract class just to share one small method.

## 9. The whole picture

The pattern used here is often called the skeletal implementation pattern: an abstract class implements part of an interface so subclasses need to supply less code.

The important insight is:

- Interface: Defines the behavior expected from implementations.
    
- Abstract class: Implements common behavior using methods subclasses will provide.
    
- Concrete class: Supplies storage, concrete behavior, and any specialized optimizations.
    

And most importantly, you don't need all three layers for every design. Create an abstract class when there is meaningful implementation or state to share.

Once you understand this pattern, the inheritance structure of `Collection`, `List`, `AbstractCollection`, `AbstractList`, and `ArrayList` becomes much easier to read and reason about.



[[Java]]