Let's start from **zero** and build up exactly what happens when your Java program runs:

```java
ProcessBuilder javaVersion =
        new ProcessBuilder("java", "--version");

javaVersion.redirectErrorStream(true);

Process process = javaVersion.start();
```

and then reads the result and shows it in a popup.

---

# 1. What are we trying to do?

Normally, you might open a terminal and type:

```bash
java --version
```

The operating system runs the `java` program and prints something like:

```text
openjdk 21.0.5 2024-10-15
OpenJDK Runtime Environment ...
OpenJDK 64-Bit Server VM ...
```

We want our Java program to do the same thing:

```text
Java Program
     │
     │ "Please run this command"
     ▼
Operating System
     │
     │ runs: java --version
     ▼
New Process
     │
     │ produces text
     ▼
Our Java Program
     │
     │ reads the text
     ▼
JOptionPane
     │
     ▼
Popup window
```

---

# 2. What is a system command?

A command is usually a program that you ask the operating system to execute.

For example on Linux:

```bash
ls
```

asks the OS to run the `ls` program.

```bash
java --version
```

asks the OS to run the `java` program with the argument:

```text
--version
```

You can think of it like this:

```text
java
 │
 └── --version
     ↑
     argument
```

The command itself is:

```text
java
```

And:

```text
--version
```

is information passed to that command.

---

# 3. What is `ProcessBuilder`?

Java itself does not automatically execute terminal commands just because you write them as strings.

You need to tell Java:

> "I want to create and configure an operating system process."

That is what the `ProcessBuilder` class helps us do.

```java
ProcessBuilder javaVersion =
        new ProcessBuilder("java", "--version");
```

Let's break this apart.

## `ProcessBuilder`

This is a **class** provided by Java.

Its job is to help you prepare a process that will be started by the operating system.

Think of it as a blueprint or configuration object:

```text
ProcessBuilder
      │
      │ contains instructions
      ▼
"Run java with --version"
```

At this point, the command is **not running yet**.

You have only created an object that knows how to start it.

---

# 4. What does `new` mean?

You have seen things like:

```java
new int[5]
```

or:

```java
new String(...)
```

In this case:

```java
new ProcessBuilder(...)
```

means:

> Create an object of the `ProcessBuilder` class.

Conceptually:

```text
new ProcessBuilder("java", "--version")
        │
        ▼
ProcessBuilder object created in memory
```

That object stores information about the command you want to execute.

---

# 5. Why do we write `"java", "--version"` separately?

We write:

```java
new ProcessBuilder("java", "--version");
```

Instead of:

```java
new ProcessBuilder("java --version");
```

because `ProcessBuilder` expects the command and its arguments separately.

So conceptually:

```text
Argument 0 → java
Argument 1 → --version
```

You can imagine it as an array:

```text
["java", "--version"]
```

The first element is the executable program:

```text
java
```

The next elements are arguments:

```text
--version
```

---

# 6. What does this variable mean?

```java
ProcessBuilder javaVersion
```

This declares a variable.

```java
ProcessBuilder
       ↑
       data type
```

```java
javaVersion
       ↑
       variable name
```

The variable stores a **reference** to the `ProcessBuilder` object.

Conceptually:

```text
javaVersion
     │
     │ reference
     ▼
ProcessBuilder object
     │
     ├── Command: java
     │
     └── Argument: --version
```

So:

```java
ProcessBuilder javaVersion =
        new ProcessBuilder("java", "--version");
```

means:

> Create a `ProcessBuilder` object configured to run `java --version`, and store a reference to it in the variable `javaVersion`.

---

# 7. What is `redirectErrorStream(true)`?

When a program runs, it can usually produce output through different streams.

The important ones are:

```text
Standard Input
Standard Output
Standard Error
```

---

## Standard Input

Usually called:

```text
stdin
```

This is data going **into** the program.

For example:

```text
Keyboard
   │
   ▼
Program
```

---

## Standard Output

Usually called:

```text
stdout
```

This is normal output produced by a program.

For example:

```text
Program
   │
   ▼
"Hello World"
```

---

## Standard Error

Usually called:

```text
stderr
```

This is another output channel, traditionally used for errors and diagnostic messages.

For example:

```text
Program
   │
   ▼
"File not found"
```

---

# 8. Why is this important for `java --version`?

Some programs send their information to the normal output stream:

```text
stdout
```

Others may send information or diagnostics to:

```text
stderr
```

If your Java program only reads:

```java
process.getInputStream()
```

you are reading the process's normal output.

But if the information appears on the error stream, you might not see it.

So we use:

```java
javaVersion.redirectErrorStream(true);
```

This tells the `ProcessBuilder`:

> Combine the error output with the normal output.

Conceptually:

### Without it

```text
Running Program
      │
      ├──────────────► stdout
      │                  │
      │                  ▼
      │              getInputStream()
      │
      └──────────────► stderr
                         │
                         ▼
                    not being read
```

### With it

```text
Running Program
      │
      ├── stdout ──┐
      │            │
      └── stderr ──┘
                   │
                   ▼
              One combined stream
                   │
                   ▼
             getInputStream()
```

The:

```java
true
```

means that you want this behavior enabled.

---

# 9. What does `start()` do?

This is the point where the command actually starts.

```java
Process process = javaVersion.start();
```

Before this line:

```text
ProcessBuilder exists

But:

java --version

has NOT started yet.
```

After:

```java
javaVersion.start();
```

Java asks the operating system to create and run a new process.

Conceptually:

```text
Your Java Program
       │
       │ start()
       ▼
Operating System
       │
       ▼
Creates new process
       │
       ▼
Runs:

java --version
```

---

# 10. What is a `Process`?

A **process** is a running instance of a program.

For example, when you run:

```bash
java --version
```

the operating system creates a process.

Your Java program gets an object representing that running process:

```java
Process process
```

So:

```java
Process process = javaVersion.start();
```

means:

> Start the command and give me a `Process` object that lets me communicate with and monitor that running program.

Conceptually:

```text
process
   │
   ▼
┌───────────────────────┐
│ Operating System      │
│                       │
│ Process               │
│                       │
│ java --version        │
│                       │
└───────────────────────┘
```

The `Process` object gives us access to things like:

```java
process.getInputStream()
process.getErrorStream()
process.getOutputStream()
process.waitFor()
process.exitValue()
```

---

# 11. Why is it called `getInputStream()`?

This part can be confusing.

We write:

```java
process.getInputStream()
```

You might think:

> "But I want the output of the command. Why am I getting an InputStream?"

The answer is: **the direction is from the perspective of your Java program.**

The other process produces output:

```text
Other Process
     │
     │ output
     ▼
Your Java Program
```

Your Java program receives that data as **input**.

So:

```java
process.getInputStream()
```

means:

> Give me a stream that my Java program can use to read the normal output coming from this process.

---

# 12. What is a stream?

A stream is basically a flow of data.

Imagine water flowing through a pipe:

```text
Water ───────────────►
```

A data stream is similar:

```text
Data ────────────────►
```

For our command:

```text
java --version
       │
       │ text data
       ▼
InputStream
```

The data might arrive like this:

```text
o
p
e
n
j
d
k
...
```

or internally as bytes.

Java's `InputStream` lets us receive those bytes.

---

# 13. What is `InputStream`?

`InputStream` is a Java class hierarchy used for reading raw bytes.

For example:

```text
01001000 01100101 01101100 ...
```

Internally, text is represented as bytes.

So:

```java
InputStream input = process.getInputStream();
```

would give us access to the raw data coming from the process.

However, we don't usually want to manually work with individual bytes when reading text.

So we use another class.

---

# 14. What is `InputStreamReader`?

We write:

```java
new InputStreamReader(process.getInputStream())
```

Its job is to convert:

```text
Bytes
  ↓
Characters
```

Conceptually:

```text
Process Output

Raw bytes
   │
   ▼
InputStream
   │
   ▼
InputStreamReader
   │
   ▼
Characters
```

For example, it helps turn encoded data into readable Java characters such as:

```text
J
a
v
a
```

---

# 15. What is `BufferedReader`?

Now we have characters, but we want a convenient way to read text.

So we use:

```java
BufferedReader
```

We create it like this:

```java
BufferedReader reader =
        new BufferedReader(
                new InputStreamReader(
                        process.getInputStream()
                )
        );
```

Let's look at the layers:

```text
Process
   │
   ▼
InputStream
   │
   │ raw bytes
   ▼
InputStreamReader
   │
   │ characters
   ▼
BufferedReader
   │
   │ convenient text reading
   ▼
Your Java code
```

`BufferedReader` is useful because it has methods such as:

```java
readLine()
```

which lets us read one line at a time.

---

# 16. What does `readLine()` do?

Suppose the command outputs:

```text
openjdk 21
Runtime Environment
64-Bit Server VM
```

Each line can be read separately.

```java
reader.readLine();
```

First time:

```text
openjdk 21
```

Second time:

```text
Runtime Environment
```

Third time:

```text
64-Bit Server VM
```

Eventually, there is nothing left to read.

Then:

```java
readLine()
```

returns:

```java
null
```

`null` means:

> There is no object/value available here.

---

# 17. What is `StringBuilder`?

We want to collect all the lines into one big string.

We could repeatedly do this:

```java
output = output + line;
```

But `StringBuilder` is designed for efficiently building text.

We create one:

```java
StringBuilder output = new StringBuilder();
```

Initially:

```text
output
  │
  ▼

(empty)
```

Then we can append text:

```java
output.append(line);
```

For example:

```text
Before:

""

After append:

"openjdk 21"
```

Then:

```java
output.append("\n");
```

adds a new line.

Then we add another line:

```text
"openjdk 21\nRuntime Environment\n"
```

---

# 18. What does `append()` do?

This:

```java
output.append(line);
```

means:

> Add `line` to the end of the `StringBuilder`.

Example:

```java
StringBuilder output = new StringBuilder();

output.append("Hello");
```

Now:

```text
Hello
```

Then:

```java
output.append(" World");
```

Now:

```text
Hello World
```

---

# 19. What does this loop do?

```java
String line;

while ((line = reader.readLine()) != null) {
    output.append(line).append("\n");
}
```

This is probably the most important part.

Let's break it down.

First:

```java
String line;
```

creates a variable that can hold a `String`.

Then:

```java
reader.readLine()
```

reads one line.

This:

```java
line = reader.readLine()
```

assigns that line to the variable:

```text
line
```

For example:

```text
line = "openjdk 21"
```

Then:

```java
(line = reader.readLine()) != null
```

checks:

> Did we actually receive a line?

If yes:

```text
true
```

the loop continues.

If there are no more lines:

```java
readLine()
```

returns:

```text
null
```

Then:

```java
null != null
```

is:

```text
false
```

and the loop stops.

---

# 20. Step-by-step example of the loop

Imagine the command produces:

```text
Line 1
Line 2
Line 3
```

### First iteration

```java
line = reader.readLine();
```

Result:

```text
line = "Line 1"
```

Then:

```java
output.append(line).append("\n");
```

Output becomes:

```text
Line 1
```

---

### Second iteration

```text
line = "Line 2"
```

Output becomes:

```text
Line 1
Line 2
```

---

### Third iteration

```text
line = "Line 3"
```

Output becomes:

```text
Line 1
Line 2
Line 3
```

---

### Fourth iteration

There are no more lines.

```java
reader.readLine()
```

returns:

```java
null
```

The loop stops.

---

# 21. What is `JOptionPane`?

`JOptionPane` is a class from Java's Swing GUI library.

It allows you to create simple popup dialogs.

For example:

```java
JOptionPane.showMessageDialog(
    null,
    "Hello!"
);
```

This creates a popup window.

The full version we used is:

```java
JOptionPane.showMessageDialog(
    null,
    output.toString(),
    "Java Version",
    JOptionPane.INFORMATION_MESSAGE
);
```

Let's break down every argument.

---

# 22. First argument: `null`

```java
null
```

represents the parent component.

A dialog can belong to another window.

For example:

```text
Main Window
     │
     └── Popup Dialog
```

If you don't have a parent window, you can use:

```java
null
```

which essentially means there is no specific parent component.

---

# 23. Second argument: `output.toString()`

Our variable:

```java
StringBuilder output
```

is a `StringBuilder`, not a `String`.

But `JOptionPane` needs text to display.

So:

```java
output.toString()
```

converts the built text into a regular `String`.

Example:

```text
StringBuilder

Hello
World
   │
   │ toString()
   ▼

String

"Hello\nWorld"
```

---

# 24. Third argument: `"Java Version"`

```java
"Java Version"
```

is the title of the popup.

For example:

```text
┌─────────────────────────┐
│ Java Version            │ ← Title
├─────────────────────────┤
│                         │
│ openjdk 21...           │
│                         │
│          [ OK ]         │
└─────────────────────────┘
```

---

# 25. Fourth argument: `JOptionPane.INFORMATION_MESSAGE`

This controls the type of message.

```java
JOptionPane.INFORMATION_MESSAGE
```

tells Swing:

> This is informational output.

It may display an information icon.

Other examples include:

```java
JOptionPane.ERROR_MESSAGE
```

for errors.

```java
JOptionPane.WARNING_MESSAGE
```

for warnings.

```java
JOptionPane.QUESTION_MESSAGE
```

for questions.

---

# 26. What does `throws IOException` mean?

Your method starts with:

```java
public static void check() throws IOException
```

The important part here is:

```java
throws IOException
```

Starting an external process can fail.

For example:

- Java executable cannot be found.
    
- The operating system refuses to start it.
    
- An I/O problem occurs.
    

`IOException` means **Input/Output Exception**.

Java considers this a checked exception.

So you must handle or declare it.

You have two choices.

### Option 1: Declare it

```java
public static void check() throws IOException
```

This means:

> This method might throw an `IOException`, and the method that calls me must deal with it.

---

### Option 2: Handle it yourself

```java
try {
    // Code that might throw IOException
} catch (IOException e) {
    // Handle the problem
}
```

---

# 27. The complete code

Here is everything together:

```java
import javax.swing.JOptionPane;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class JavaVersionChecker {

    public static void check() throws IOException {

        // 1. Prepare the command
        ProcessBuilder javaVersion =
                new ProcessBuilder("java", "--version");

        // 2. Combine normal output and error output
        javaVersion.redirectErrorStream(true);

        // 3. Actually start the command
        Process process = javaVersion.start();

        // 4. Get the command's output and prepare to read text
        BufferedReader reader =
                new BufferedReader(
                        new InputStreamReader(
                                process.getInputStream()
                        )
                );

        // 5. Store all output
        StringBuilder output = new StringBuilder();

        String line;

        // 6. Read the output one line at a time
        while ((line = reader.readLine()) != null) {
            output.append(line).append("\n");
        }

        // 7. Show the result in a popup
        JOptionPane.showMessageDialog(
                null,
                output.toString(),
                "Java Version",
                JOptionPane.INFORMATION_MESSAGE
        );
    }
}
```

---

# 28. The entire process visualized

When you call:

```java
JavaVersionChecker.check();
```

this happens:

```text
┌─────────────────────────────┐
│ Your Java Program           │
└──────────────┬──────────────┘
               │
               ▼
     new ProcessBuilder(
         "java",
         "--version"
     )
               │
               │ Command is prepared
               ▼
      redirectErrorStream(true)
               │
               │ stdout + stderr combined
               ▼
          start()
               │
               ▼
┌─────────────────────────────┐
│ Operating System            │
│                             │
│ Starts a new process:       │
│                             │
│ java --version              │
└──────────────┬──────────────┘
               │
               │ Produces text
               ▼
          InputStream
               │
               │ Raw bytes
               ▼
       InputStreamReader
               │
               │ Characters
               ▼
        BufferedReader
               │
               │ readLine()
               ▼
         StringBuilder
               │
               │ Stores all lines
               ▼
           toString()
               │
               ▼
          JOptionPane
               │
               ▼
         ┌───────────────┐
         │ Java Version  │
         ├───────────────┤
         │ openjdk ...   │
         │               │
         │     [ OK ]    │
         └───────────────┘
```

## The key idea

The three most important classes to understand are:

|Class|Purpose|
|---|---|
|`ProcessBuilder`|Prepares an OS command to run|
|`Process`|Represents the running command|
|`BufferedReader`|Reads the command's text output|
|`StringBuilder`|Collects all the output into one piece of text|
|`JOptionPane`|Displays that text in a popup|

The most important distinction is:

```text
ProcessBuilder = prepares how to start a program

Process = represents the program after it has been started
```

So this:

```java
ProcessBuilder builder = new ProcessBuilder("java", "--version");
```

does **not** run the command yet.

But this:

```java
Process process = builder.start();
```

actually asks the operating system to run it.


[[Java]]