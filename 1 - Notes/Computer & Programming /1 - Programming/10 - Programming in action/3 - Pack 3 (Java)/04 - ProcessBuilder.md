
# `ProcessBuilder`: launching other programs from Java

## The mental model

Your Java program is a manager, and the operating system is a hiring agency. `ProcessBuilder` is the **job request form** where you fill in:

- what program to run and with what arguments
- which folder it works in
- what environment variables it sees
- where its input and output go

`start()` **submits the form**, and the OS creates a real, separate process. `Process` is the **handle** you get back, like a walkie-talkie to that worker.

It is the same idea as typing a command in your Debian terminal, but done from code. This is how a tool like your Gex could run `git`, an editor, or a build script.

## The full line, taken apart

```java
Process process = processBuilder.inheritIO().start();
```

Read it inside-out as a chain:

1. `processBuilder`: a configured, not-yet-running request.
2. `.inheritIO()`: modifies the request and **returns the same builder**, which is why chaining works.
3. `.start()`: launches the OS process and returns a `Process`.

Here is a full context:

```java
import java.io.IOException;

public class Runner {
    public static void main(String[] args) throws IOException, InterruptedException {
        ProcessBuilder processBuilder = new ProcessBuilder("ls", "-la", "/tmp");

        Process process = processBuilder.inheritIO().start();

        int exitCode = process.waitFor();   // block until the child finishes
        System.out.println("Exit code: " + exitCode);
    }
}
```

The `ls` output appears directly in your terminal, exactly as if you had typed the command.

## Part 1: constructing the builder

```java
new ProcessBuilder("git", "commit", "-m", "hello world");
// or
new ProcessBuilder(List.of("git", "commit", "-m", "hello world"));
```

Each string is **one argument**, already separated. Compare this with your `CommandParser`: it is the same array-of-words idea as `args`.

**This is not a shell.** There is no shell involved, so:

|You write|What happens|
|---|---|
|`new ProcessBuilder("ls *.txt")`|Fails: it looks for a program literally named `ls *.txt`|
|`new ProcessBuilder("ls", "*.txt")`|`ls` receives a literal `*.txt`. No glob expansion, because the shell does that, not `ls`|
|`new ProcessBuilder("echo", "a", "|", "wc")`|

If you truly need shell features (pipes, globbing, redirection), ask a shell explicitly:

```java
new ProcessBuilder("sh", "-c", "ls *.txt | wc -l");
```

The upside of no shell is safety: no quoting bugs and no shell-injection when arguments contain spaces or `;`. Only use `sh -c` with input you fully control.

## Part 2: the three streams and what `inheritIO()` does

Every process has three standard streams:

|Stream|Number|Direction|
|---|---|---|
|**stdin**|0|input into the process|
|**stdout**|1|normal output|
|**stderr**|2|error output|

By default, `ProcessBuilder` connects each of them to a **pipe** whose other end is _your Java program_. The child's output does not appear on screen. You must read it yourself.

`inheritIO()` is a shortcut for:

```java
processBuilder.redirectInput(ProcessBuilder.Redirect.INHERIT);
processBuilder.redirectOutput(ProcessBuilder.Redirect.INHERIT);
processBuilder.redirectError(ProcessBuilder.Redirect.INHERIT);
```

**INHERIT** means "use the same stdin/stdout/stderr as the parent (my Java process)." The child is wired straight to your terminal, with Java **not in the middle**.

This gives you these consequences:

- The child's output shows up live, immediately.
- **Interactive programs work.** `vim`, `nano`, `python`, or a password prompt can read your keyboard, because stdin is inherited.
- Java never sees the data, so you **cannot capture it**.

### Without `inheritIO()`: capturing output

```java
ProcessBuilder pb = new ProcessBuilder("ls", "-la");
Process p = pb.start();

try (var reader = new java.io.BufferedReader(
        new java.io.InputStreamReader(p.getInputStream()))) {   // child's stdout
    reader.lines().forEach(line -> System.out.println("GOT: " + line));
}
p.waitFor();
```

The naming is confusing at first: `p.getInputStream()` is the stream **you read from**, which is the child's _output_. It is "input" from Java's point of view. Likewise `p.getOutputStream()` is where **you write** to the child's stdin.

Choose based on your goal:

|Goal|Approach|
|---|---|
|Show the child's output to the user, or run something interactive|`inheritIO()`|
|Process the output in Java code|pipes plus reading `getInputStream()`|
|Save output to a file|`redirectOutput(new File("out.txt"))`|

Note that with `inheritIO()`, `p.getInputStream()` returns an empty stream that hits end-of-file immediately, since there is no pipe.

## Part 3: `start()`

`start()` is where the request becomes real.

- It **creates the OS process** and returns immediately. It does not wait for the program to finish.
- It **throws `IOException`** if the process cannot even be launched: program not found in `PATH`, no execute permission, or the working directory doesn't exist. This is different from the program starting and then failing.
- You can call `start()` **several times** on the same builder to launch several independent processes from the same template.

## Part 4: the `Process` handle

```java
int code = process.waitFor();                          // block until done, returns exit code
boolean done = process.waitFor(5, TimeUnit.SECONDS);   // wait with timeout
process.isAlive();                                     // still running?
process.exitValue();                                   // throws IllegalThreadStateException if still running
process.pid();                                         // OS process id (Java 9+)
process.destroy();                                     // polite kill (SIGTERM on Linux)
process.destroyForcibly();                             // hard kill (SIGKILL)
process.onExit().thenAccept(p -> ...);                 // async callback (Java 9+)
```

**Exit codes:** by universal Unix convention, `0` means success and anything else means failure. A good CLI passes the child's code upward:

```java
System.exit(process.waitFor());
```

**Timeouts matter.** A bare `waitFor()` waits forever if the child hangs. For anything non-trivial:

```java
if (!process.waitFor(10, TimeUnit.SECONDS)) {
    process.destroyForcibly();
}
```

## Part 5: other configuration you'll use

```java
ProcessBuilder pb = new ProcessBuilder("git", "status");

pb.directory(new File("/home/alireza/project"));   // working directory (default: your JVM's)
pb.environment().put("GIT_PAGER", "cat");          // add/change env variables
pb.redirectErrorStream(true);                      // merge stderr into stdout
pb.redirectOutput(new File("log.txt"));            // stdout to a file
pb.redirectOutput(ProcessBuilder.Redirect.appendTo(new File("log.txt")));
```

`pb.environment()` starts as a **copy of your JVM's environment**, so the child inherits `PATH` and friends. Changing it affects only children, not your own program.

You can also mix and match: inherit only some streams instead of all three.

```java
pb.redirectInput(ProcessBuilder.Redirect.INHERIT);   // keyboard works
pb.redirectErrorStream(true);                        // but I capture stdout+stderr myself
```

## Nuances and gotchas

1. **The pipe deadlock (the classic bug).** With the default pipes, if the child writes more output than the OS pipe buffer holds (about 64 KB on Linux) and you never read it, the child **blocks** and `waitFor()` never returns. Fixes: read the output, redirect it to a file, or use `inheritIO()`, which has no pipe at all. This is a major reason `inheritIO()` is popular for simple "just run it" cases.
2. **Output ordering.** Your Java `System.out` and the child write to the same terminal but through different buffers. Lines may interleave in surprising orders. Print before `start()` and it usually looks right, but there is no hard guarantee.
3. **`InterruptedException`** from `waitFor()` is checked. It means your thread was interrupted while waiting. Don't swallow it silently.
4. **Killing the parent doesn't necessarily kill the child.** If your JVM is killed, the child may become an orphan. Use `process.toHandle().descendants()` and `destroy()` for cleanup.
5. **Portability.** `"ls"` doesn't exist on Windows and `"cmd"` doesn't exist on Debian. Anything calling external programs is OS-dependent, which is a real trade-off compared with pure Java.
6. **Security.** Never build a command by concatenating user input into one string for `sh -c`. Passing arguments as separate list items is what protects you.
7. **`Runtime.getRuntime().exec(...)`** is the older API doing the same thing. `ProcessBuilder` is the modern replacement, with better control over streams, directory, and environment.

## Connecting it to what you've learned

Here is a Gex-style dispatcher tying together `main`, `CommandParser`, and `ProcessBuilder`:

```java
public static void main(String[] args) throws Exception {
    Command command = new CommandParser().parse(args);

    if (command.name().equals("run")) {
        ProcessBuilder pb = new ProcessBuilder(command.arguments());  // reuse parsed args!
        Process process = pb.inheritIO().start();
        System.exit(process.waitFor());
    }
}
```

```bash
java -cp out com.gex.GexApplication run ls -la
```

Notice how `command.arguments()` is already a `List<String>`, which is exactly what `ProcessBuilder` accepts. The parser and the launcher fit together naturally.

**Bonus for later:** Spring Boot's dev tools, Maven's `exec` plugin, and Gradle's `Exec` task are all built on this same mechanism.



[[Java]]