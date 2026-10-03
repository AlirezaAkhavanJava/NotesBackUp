
# CommandParser: turning raw words into structured meaning

## The mental model

Think of a restaurant. The customer says _"one burger, no onions, extra cheese"_. The **waiter** doesn't cook. They translate that speech into a structured order slip. The **kitchen** reads the slip and cooks.

- `args` is the raw speech: `String[]`
- **`CommandParser` is the waiter**: raw strings → a structured object
- The code that runs the command is the kitchen

Your current `main` does parsing and executing in one place. That works for 3 lines, but breaks down as the program grows. The principle is **separation of concerns**: each class has one job.

## Step 1: the data holder, a `record`

Before parsing, decide what the _result_ looks like. Given `gex add file.txt --force --name=abc`:

```java
package com.gex;

import java.util.List;
import java.util.Map;

public record Command(String name, List<String> arguments, Map<String, String> options) {}
```

A `record` (Java 16+) is a compact immutable data class. That one line gives you a constructor, getters (`command.name()`), `equals`, `hashCode`, and `toString` for free. Here the result is:

```
name      = "add"
arguments = ["file.txt"]                        (positional)
options   = {"force" -> "true", "name" -> "abc"}   (named)
```

## Step 2: the parser

```java
package com.gex;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class CommandParser {

    public Command parse(String[] args) {
        if (args.length == 0) {
            throw new IllegalArgumentException("No command given");
        }

        String name = args[0];
        List<String> positional = new ArrayList<>();
        Map<String, String> options = new HashMap<>();

        for (int i = 1; i < args.length; i++) {
            String arg = args[i];

            if (arg.startsWith("--")) {
                int eq = arg.indexOf('=');
                if (eq == -1) {
                    options.put(arg.substring(2), "true");          // flag: --force
                } else {
                    options.put(arg.substring(2, eq),               // --name=abc
                                arg.substring(eq + 1));
                }
            } else {
                positional.add(arg);
            }
        }

        return new Command(name, List.copyOf(positional), Map.copyOf(options));
    }
}
```

### Walking through `add file.txt --force --name=abc`

|`args[i]`|Branch|Effect|
|---|---|---|
|`add`|(index 0)|becomes `name`|
|`file.txt`|no `--` prefix|goes to `positional`|
|`--force`|`--`, no `=`|`options["force"]="true"`|
|`--name=abc`|`--`, has `=` at index 6|`substring(2,6)="name"`, `substring(7)="abc"`|

`indexOf` returns **-1** when the character is absent, which is the standard Java "not found" signal, so that check is how we distinguish a flag from a key=value option.

## Step 3: `main` becomes tiny

```java
public class GexApplication {

    public static void main(String[] args) {
        CommandParser parser = new CommandParser();

        try {
            Command command = parser.parse(args);
            System.out.println("Running: " + command);
        } catch (IllegalArgumentException e) {
            System.out.println("Gex");
        }
    }
}
```

Try it (compile everything with `javac -d out src/com/gex/*.java`):

```bash
java -cp out com.gex.GexApplication add file.txt --force --name=abc
# Running: Command[name=add, arguments=[file.txt], options={force=true, name=abc}]
```

That output format is free from the record's `toString`.

## Why this design is better

1. **Testable.** `parse` is a _pure function_: same input gives same output, with no printing and no side effects. You can test it without running the program.
2. **Replaceable.** If you later switch to a library, only `CommandParser` changes.
3. **Failure is explicit.** The parser _throws_ on bad input instead of deciding how to display errors. The caller decides what to do. Parsing shouldn't know about the user interface.

## Nuances and gotchas

1. **`List.copyOf` / `Map.copyOf` make immutable copies.** Without them, the record would expose mutable internals, and anyone could modify `command.arguments()` after creation. Immutable copies are a defensive habit. Note that `Map.copyOf` **loses ordering** and throws on `null`.
2. **`--name abc` (space-separated) is ambiguous.** Is `abc` the value of `name`, or a positional argument? Our parser treats it as positional. Real tools must know _in advance_ which options take values. This is the hardest part of CLI parsing.
3. **`--` conventionally means "stop parsing options."** So `gex add -- --weird-filename` treats `--weird-filename` as a file. Our parser doesn't handle that yet.
4. **`--=x` would produce an empty key.** Robust parsers validate that, and this is the kind of edge case that unit tests reveal.
5. **Exception choice.** `IllegalArgumentException` (unchecked) fits bad input. An alternative for "maybe absent" results is `Optional<Command>`, but throwing gives you an error message to show.
6. **Validation belongs in the record too.** A _compact constructor_ can enforce rules:

```java
public record Command(String name, List<String> arguments, Map<String, String> options) {
    public Command {
        if (name == null || name.isBlank())
            throw new IllegalArgumentException("Command name required");
    }
}
```

This guarantees no invalid `Command` can ever exist.

## Connection to Spring Boot

Spring Boot does this exact job. When you run `java -jar app.jar --server.port=9090 --debug`, `SpringApplication.run(..., args)` wraps the array in an `ApplicationArguments` object that separates **option arguments** (`--server.port=9090`, `--debug`) from **non-option arguments** (positional), which are the same two buckets you just built. Real CLI libraries like **picocli** and **Apache Commons CLI** are grown-up versions of this class.


---

## `CommandParser` in Java

Let's break down this small but meaningful class piece by piece.

## The Full Code

```java
package com.gex.cli;

public class CommandParser {

    public String parse(String[] args) {

        if (args.length == 0) {
            return null;
        }

        return args[0];
    }
}
```

---

## 1. The Package Declaration

```java
package com.gex.cli;
```

- **What it is:** Declares that this class belongs to the package `com.gex.cli`.
- **Why it matters:** Packages group related classes. This one is for **GEX** (probably your project name), the **CLI** (command-line interface) part.
- **File location rule:** The file must live at `com/gex/cli/CommandParser.java` on disk.
- **Naming convention:** Reverse domain style (`com.company.project.module`).

---

## 2. The Class Declaration

```java
public class CommandParser {
```

- `public` → visible to any other class in the project.
- `class` → blueprint for objects.
- `CommandParser` → by convention, class names use **PascalCase**.
- The name tells us its job: **parse** command-line arguments.

---

## 3. The Method

```java
public String parse(String[] args) {
```

| Piece | Meaning |
|---|---|
| `public` | Callable from outside the class |
| `String` | Return type — gives back a `String` (or `null`) |
| `parse` | Method name (verb, camelCase) |
| `String[] args` | Parameter — an array of Strings, typically from `main(String[] args)` |

So this method takes the command-line arguments and returns **the first one** (or `null` if there are none).

---

## 4. The Guard Clause

```java
if (args.length == 0) {
    return null;
}
```

- **`args.length`** → how many elements are in the array.
- **Guard clause** → an early return that handles the "bad" case first.
- If no arguments were passed, we return `null` instead of crashing on `args[0]`.

Why not just do `return args[0]` directly? Because if `args` is empty, `args[0]` would throw an **`ArrayIndexOutOfBoundsException`**. The guard prevents that.

---

## 5. The Return Statement

```java
return args[0];
```

- Arrays are **zero-indexed** in Java, so `args[0]` is the **first** argument.
- For example, running `java MyApp hello world` gives:
  - `args[0]` = `"hello"`
  - `args[1]` = `"world"`
- This method ignores anything after the first argument.

---

## How It Would Be Used

```java
public class Main {
    public static void main(String[] args) {
        CommandParser parser = new CommandParser();
        String command = parser.parse(args);

        if (command == null) {
            System.out.println("No command provided.");
        } else {
            System.out.println("Command: " + command);
        }
    }
}
```

**Run:** `java Main greet` → prints `Command: greet`  
**Run:** `java Main` → prints `No command provided.`

---

## Key Concepts You Just Learned

1. **Packages** organize code into namespaces.
2. **Method signatures** = access modifier + return type + name + parameters.
3. **Arrays** are fixed-size, zero-indexed, and have a `.length` field (not a method).
4. **Guard clauses** prevent exceptions by handling edge cases early.
5. **Returning `null`** is a common Java way to signal "no result" — though modern Java often prefers `Optional<String>`.

---

## Small Improvements to Consider

- **Use `Optional`** to avoid `null`:
  ```java
  public Optional<String> parse(String[] args) {
      return args.length == 0 ? Optional.empty() : Optional.of(args[0]);
  }
  ```
- **Validate the input array itself:** `args` could theoretically be `null`.
- **Rename for clarity:** `parse` returns a command *name*, so `parseCommand` or `firstArg` might be more descriptive.




[[Java]]