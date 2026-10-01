
```java

public class Application {

    public static void main(String[] args) {

        if (args.length == 0) {
            System.out.println("Gex");
            return;
        }

        String command = args[0];

        System.out.println("Command: " + command);
    }
}
```


## The mental model

Think of a Java program as a building with many rooms (classes). When you start it, the JVM (Java Virtual Machine) needs to know **which door to walk through first**. That door is the `main` method. Everything else is reached from there.

Your program says: _"If the user gave me no extra words, print `Gex`. Otherwise, take the first word as a command and print it back."_ It is a tiny version of how tools like `git` work: `git commit`, `git push`, where `commit` and `push` are commands passed as arguments.

## Line by line

### `package com.gex;`

A package is a **folder-like namespace**. It prevents name clashes (two libraries might both have a class called `Utils`). By convention it is a reversed domain name (`com.gex` ← `gex.com`). It must match the folder structure:

```
src/
└── com/
    └── gex/
        └── GexApplication.java
```

### `public class GexApplication`

Everything in Java lives inside a class. `public` means visible from anywhere. A `public` class **must** be in a file with the same name (`GexApplication.java`), or the compiler refuses.

### `public static void main(String[] args)`

This exact signature is what the JVM looks for. Each word has a reason:

|Word|Why|
|---|---|
|`public`|The JVM is outside your class, so it needs access.|
|`static`|It belongs to the class itself, not to an object. At startup no object exists yet, so the JVM couldn't call an instance method. (Chicken-and-egg problem.)|
|`void`|Returns nothing. To signal an exit code, use `System.exit(1)`.|
|`main`|The agreed-upon name.|
|`String[] args`|An array of the words typed after the class name.|

### `if (args.length == 0)`

`args` is an array, and `.length` (no parentheses, unlike `String.length()`) gives its size. If the user typed nothing, `args` is an **empty array**, never `null`. That guarantee is why this check is safe.

### `return;`

In a `void` method, `return;` means "stop here, leave the method." Since this is `main`, the program ends. It is an **early exit** (a "guard clause"), which avoids nesting the rest in an `else`.

### `String command = args[0];`

Arrays are **zero-indexed**, so `args[0]` is the first argument. Without the guard above, running with no arguments would throw `ArrayIndexOutOfBoundsException`. That is the real reason the check exists: it protects this line.

### `System.out.println("Command: " + command);`

`System` is a class, `out` is a static field of type `PrintStream`, and `println` is a method that prints and adds a newline. The `+` between Strings **concatenates** them.

## Running it on Debian

```bash
sudo apt install default-jdk        # once

# from the project root
javac -d out src/com/gex/GexApplication.java
java -cp out com.gex.GexApplication              # prints: Gex
java -cp out com.gex.GexApplication hello        # prints: Command: hello
```

Notes:

- `-d out` puts compiled `.class` files in `out/com/gex/`, mirroring the package.
- You run the **fully qualified name** (`com.gex.GexApplication`), not the file name, because the package is part of the class's identity.

## Nuances and gotchas

1. **Arguments are always Strings.** `java ... 42` gives you `"42"`, not a number. You'd convert with `Integer.parseInt(args[0])`.
2. **The shell splits on spaces.** `hello world` gives 2 args (`args.length == 2`), but `"hello world"` in quotes gives 1. Your program only reads `args[0]`, so extra arguments are silently ignored.
3. **Comparing strings:** if you later write `command == "help"`, that is a bug. Use `command.equals("help")`, since `==` compares object identity, not content.
4. **Modern Java:** recent versions (Java 25) allow simplified entry points without `public static`, but the classic form above is still what you'll see everywhere, including Spring Boot.

## Connection to Spring Boot

Every Spring Boot app starts with this same `main`:

```java
public static void main(String[] args) {
    SpringApplication.run(GexApplication.class, args);
}
```

Same signature, same `args`. Spring takes those arguments and interprets things like `--server.port=9090` as configuration. So what you just learned is the seed of every Spring Boot application.

Your code is also a natural start for a **command dispatcher**. Try replacing the print with a `switch`:

```java
switch (command) {
    case "help" -> System.out.println("Available: help, version");
    case "version" -> System.out.println("Gex 1.0");
    default -> System.out.println("Unknown command: " + command);
}
```

Say **next** when this feels solid.



[[Java]]