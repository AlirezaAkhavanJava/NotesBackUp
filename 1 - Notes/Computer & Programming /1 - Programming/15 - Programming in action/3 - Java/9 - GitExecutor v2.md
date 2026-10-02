
```java
package com.gex.git;
import java.io.IOException;

public class GitExecutor {

    public GitResult execute(String... arguments)
            throws IOException, InterruptedException {
        ProcessBuilder processBuilder = new ProcessBuilder();
        processBuilder.command("git");
        for (String argument : arguments) {
            processBuilder.command().add(argument);
        }
        Process process = processBuilder
                .inheritIO()
                .start();
        int exitCode = process.waitFor();
        return new GitResult(exitCode);
    }
}
```


# `GitExecutor` v2: from "doing and announcing" to "doing and reporting"

This is your exercise from before, done correctly. The focus is on what changed, why it matters, and what it enables.

## The mental model

Before, the executor was a **worker who shouted results out loud** (`println`). Now it is a **worker who hands a report to the manager** (`GitResult`) and stays quiet. The manager, the caller, decides whether to print, retry, log, or exit.

```
Before:  execute() → runs git → prints "Git exited with code: 0" → returns nothing
Now:     execute() → runs git → returns GitResult(0)
```

## What changed, and why each change matters

|Change|Consequence|
|---|---|
|`void` → `GitResult`|The caller finally _learns_ the outcome. Information is no longer lost.|
|`println` removed|The class has no side effects except running git, so `gex status \| grep modified` isn't polluted.|
|`return new GitResult(exitCode)`|The raw `int` gets wrapped, so callers use `result.isSuccess()` instead of remembering "0 = success".|

A method that **computes and returns** instead of computing and printing is far easier to reuse, and it can be tested by asserting on the returned value.

## The data flow, end to end

```
main → CommandParser.parse(args) → Command
     → GitExecutor.execute(...)  → spawns OS process → git runs, inheriting your terminal
     → process.waitFor()         → int
     → new GitResult(int)        → returned to main
     → System.exit(...)          → your shell sees the same code
```

Here is a usable `main` that closes the loop:

```java
public static void main(String[] args) throws Exception {
    Command command = new CommandParser().parse(args);
    GitExecutor git = new GitExecutor();
    GitResult result = git.execute(command.name());
    if (!result.isSuccess()) {
        System.err.println("gex: git failed with code " + result.getExitCode());
    }
    System.exit(result.getExitCode());
}
```

Two habits here: diagnostics go to **`System.err`** (stderr), not stdout, and the process **exits with git's code**, so scripts like `gex commit && echo done` behave correctly.

## Two kinds of failure, now visible in the signature

```java
public GitResult execute(String... arguments) throws IOException, InterruptedException
```

The signature separates two failure types:

1. **Git ran and said "no"** → you get a `GitResult` with `exitCode != 0`. This is normal data, not an exception.
2. **Git couldn't run at all** (not installed, not on `PATH`) → `IOException` is thrown, and no `GitResult` exists.

The caller must handle both, and they mean different things. Try it: temporarily change `"git"` to `"gitt"` and watch `IOException` appear (`Cannot run program "gitt": error=2, No such file or directory`).

## What's still improvable (edge cases and gotchas)

1. **The `command()` loop is the same live-list trick** from before. It works, but this is the cleaner equivalent:
    
    ```java
    List<String> command = new ArrayList<>();
    command.add("git");
    command.addAll(Arrays.asList(arguments));
    Process process = new ProcessBuilder(command).inheritIO().start();
    ```
    
    Or with `Stream.concat` / `List.of` tricks later. Not a bug, only a readability choice.
    
2. **`arguments` could contain `null`.** `execute("status", null)` would make `start()` throw a `NullPointerException`. Whether to guard is a design choice (`Objects.requireNonNull`).
    
3. **Interrupted state.** If `waitFor()` throws `InterruptedException`, the git process **keeps running** as an orphan. A robust version would catch it, call `process.destroy()`, and then `Thread.currentThread().interrupt()` to restore the flag.
    
4. **`GitResult` has no output.** Because of `inheritIO()`, git's text goes straight to the terminal and Java never sees it. This is the limit of this design: you can _show_ output but not _use_ it (parse branch names, detect "nothing to commit"). To use output, you switch from `inheritIO()` to pipes.
    
5. **Working directory.** git runs in your JVM's current directory. To run in a specific repo, add `processBuilder.directory(new File(path))`. Right now `gex` only works on the repo you launched it from.
    
6. **Repeated `new ProcessBuilder()` per call is correct**, since each call gets its own builder and the class stays stateless and reusable.
    

## Where this is heading

The natural evolution captures output, which `GitResult` is already shaped for:

```java
public record GitResult(int exitCode, String output) {
    public boolean isSuccess() { return exitCode == 0; }
}
```

```java
Process process = new ProcessBuilder(command).redirectErrorStream(true).start();
String output = new String(process.getInputStream().readAllBytes());  // read BEFORE waitFor
int code = process.waitFor();
return new GitResult(code, output);
```

Note the order: read the output first, then wait. Doing it the other way risks the pipe deadlock from earlier. You could then implement things like "is this a git repo?" by running `git rev-parse --is-inside-work-tree` and checking `isSuccess()`.

## Connection to Spring Boot

This class is nearly a **Spring service** already. You would add `@Component` on top, and Spring would create one instance and inject it where needed:

```java
@Component
public class GitExecutor { ... }

@Service
public class GitService {
    private final GitExecutor executor;
    public GitService(GitExecutor executor) { this.executor = executor; }   // constructor injection
}
```

Stateless, single-purpose, returning value objects: this is the shape Spring wants.




[[Java]]