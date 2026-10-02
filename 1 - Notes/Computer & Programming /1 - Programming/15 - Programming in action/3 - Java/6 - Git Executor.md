

```java
package com.gex.git;

import java.io.IOException;

public class GitExecutor {

    public void execute(String... arguments) throws IOException, InterruptedException {

        ProcessBuilder processBuilder = new ProcessBuilder();

        processBuilder.command("git");

        for (String argument : arguments) {
            processBuilder.command().add(argument);
        }

        Process process = processBuilder.inheritIO().start();

        int exitCode = process.waitFor();

        System.out.println("Git exited with code: " + exitCode);
    }
}
```

# `GitExecutor`: a wrapper around an external tool

You already know `ProcessBuilder`, `inheritIO()`, `start()` and `waitFor()`, so I'll focus on what's **new** in this class: the design idea, varargs, and the live list returned by `command()`.

## The mental model

`GitExecutor` is a **remote control**. Git is the TV. You don't rebuild the TV, you build a clean set of buttons around it:

```java
new GitExecutor().execute("status");
new GitExecutor().execute("commit", "-m", "hello");
```

The rest of Gex never touches `ProcessBuilder`. It only knows "ask GitExecutor to run git with these words." This is the **wrapper (adapter) pattern**: hide an awkward low-level mechanism behind a small, purpose-built class. It also explains the package name, since `com.gex.git` groups everything Git-related in one place.

## Piece 1: `String... arguments` (varargs)

```java
public void execute(String... arguments)
```

The `...` means "zero or more Strings." Inside the method, `arguments` is simply a **`String[]`**, the same type as `main`'s `args`.

```java
execute();                          // arguments = []  (empty array, never null)
execute("status");                  // arguments = ["status"]
execute("commit", "-m", "hi");      // arguments = ["commit", "-m", "hi"]
execute(new String[]{"log", "-1"}); // you can pass an array directly
```

That last form is the bridge to your `CommandParser`:

```java
executor.execute(command.arguments().toArray(new String[0]));
```

Rules worth knowing:

- Varargs must be the **last parameter**, and there can be only one per method.
- Calling `execute()` with nothing runs bare `git`, which just prints Git's help. That is legal, so decide whether you want it.

## Piece 2: the empty builder and `command()`

```java
ProcessBuilder processBuilder = new ProcessBuilder();
processBuilder.command("git");
```

Before, we passed the command to the constructor. Here the builder starts **empty**, and `command("git")` is a **setter** that replaces the whole command with `["git"]`. (`command(String...)` and `command(List<String>)` both exist.)

The important part is next:

```java
for (String argument : arguments) {
    processBuilder.command().add(argument);
}
```

Called with **no parameters**, `command()` is a **getter**, and it returns the builder's **actual internal list, not a copy**. So `.add(argument)` modifies the builder directly. It works, but it is a subtle API: the same method name does two different things depending on parameters, and it only works because the returned list happens to be mutable.

After `execute("commit", "-m", "hi")`, the internal list is:

```
["git", "commit", "-m", "hi"]
```

Since there is no shell, each element is passed as **one argument**, exactly as we discussed. A commit message like `"hello world"` stays a single argument with its space intact, with no quoting bugs.

## Piece 3: the rest of the flow

```java
Process process = processBuilder.inheritIO().start();
int exitCode = process.waitFor();
System.out.println("Git exited with code: " + exitCode);
```

Nothing new mechanically. Consequences of `inheritIO()` here:

- Git's output appears live in the terminal.
- Interactive Git works. If Git opens your editor for a commit message or asks for a password, it can read your keyboard.
- `git status` may even show colors, because Git sees it is attached to a real terminal.

## Piece 4: `throws IOException, InterruptedException`

This class **doesn't handle** the two checked exceptions, it **passes them up** to the caller:

|Exception|When|
|---|---|
|`IOException`|`start()` failed: `git` isn't installed or isn't on `PATH`|
|`InterruptedException`|your thread was interrupted during `waitFor()`|

Note that a Git _failure_ (like `git commit` with nothing staged) is **not** an exception. Git starts fine and exits with a non-zero code. Only "couldn't launch git at all" throws. Those are two different kinds of failure.

## Nuances and design critique

1. **The exit code is printed but lost.** `void` means the caller can't learn whether Git succeeded. Returning it is more useful:
    
    ```java
    public int execute(String... arguments) throws IOException, InterruptedException {
        // ...
        return process.waitFor();
    }
    ```
    
2. **The `println` pollutes output.** If someone runs `gex status | grep modified`, the extra line `Git exited with code: 0` gets mixed into the data. Classes like this should generally not print. Let the caller decide, and use `System.err` for diagnostics if you must.
    
3. **The loop can be simpler.** Build the full list up front:
    
    ```java
    List<String> command = new ArrayList<>();
    command.add("git");
    command.addAll(Arrays.asList(arguments));
    Process process = new ProcessBuilder(command).inheritIO().start();
    ```
    
    Then no reliance on the live list from `command()`.
    
4. **No timeout.** A bare `waitFor()` can hang forever, which is often fine for interactive Git but worth knowing.
    
5. **Not thread-safe or reusable concerns?** None here. The builder is local to each call, so the class holds no state and one instance can be reused freely. That is a good property.
    
6. **Testability.** Because this launches a real Git, testing it means needing Git installed. Later you'd hide it behind an interface so tests can substitute a fake.
    

## Connection to Spring Boot

In Spring, this class would typically become a **`@Component`** (a managed bean), injected wherever it's needed instead of created with `new`. Spring's idea of a "service that wraps an external system" (a database, an HTTP API, or here, Git) is exactly this wrapper pattern.

## Putting it together with what you know

```java
public static void main(String[] args) throws Exception {
    Command command = new CommandParser().parse(args);
    GitExecutor git = new GitExecutor();

    switch (command.name()) {
        case "status" -> git.execute("status");
        case "log"    -> git.execute("log", "--oneline", "-5");
        default       -> System.out.println("Unknown command: " + command.name());
    }
}
```




[[Java]]