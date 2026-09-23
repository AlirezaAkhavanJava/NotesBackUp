# Ways to Get User Input in Java

## Why this needs multiple approaches

Getting input means crossing the same **inside/outside boundary** we discussed with I/O — the keyboard (or a file, or a network connection) is "outside," and your running program is "inside." Java has evolved several ways to cross that boundary, each solving a different problem: simplicity, performance, formatting control, or type-safety.

---

## 1. `Scanner` — the beginner-friendly, most common way

```java
import java.util.Scanner;

Scanner scanner = new Scanner(System.in);
System.out.print("Enter your name: ");
String name = scanner.nextLine();

System.out.print("Enter your age: ");
int age = scanner.nextInt();

System.out.println("Hello " + name + ", age " + age);
scanner.close();
```

**Problem it solves:** reading raw bytes from `System.in` (which is just an `InputStream` — same family we covered earlier) byte-by-byte and manually parsing them into an `int` or a line of text is tedious. `Scanner` wraps that and gives you typed reading methods directly.

**Key methods:**

|Method|Reads|
|---|---|
|`nextLine()`|a full line of text|
|`next()`|a single word (stops at whitespace)|
|`nextInt()` / `nextDouble()` / `nextBoolean()`|a typed value|

**Common gotcha — mixing `nextInt()` and `nextLine()`:**

```java
System.out.print("Age: ");
int age = scanner.nextInt();     // reads "25", leaves the trailing newline in the buffer
System.out.print("Name: ");
String name = scanner.nextLine(); // reads that leftover newline as an EMPTY string!
```

`nextInt()` doesn't consume the newline character after the number. **Fix:** add an extra `scanner.nextLine()` to consume it, or just use `nextLine()` everywhere and parse manually:

```java
int age = Integer.parseInt(scanner.nextLine().trim());
```

**When to use it:** simple console programs, learning exercises, quick scripts. It's the standard teaching tool — but it's not the fastest option (see `BufferedReader` below).

---

## 2. `BufferedReader` — faster, more control, but text-only

```java
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;

BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
System.out.print("Enter your name: ");
String name = reader.readLine();      // reads one line as a String
System.out.println("Hello " + name);
```

This connects directly to what we covered on Java I/O: `System.in` is a byte stream (`InputStream`); `InputStreamReader` converts it into a character stream (`Reader`, handling encoding); `BufferedReader` wraps that to add efficient line-based reading and buffering.

**Problem it solves:** `Scanner` does extra parsing work (tokenizing, regex-based number detection) that has real overhead in performance-sensitive code (e.g., competitive programming, reading huge input files). `BufferedReader` just reads raw lines fast — no parsing overhead — and you convert to numbers yourself when needed.

```java
int age = Integer.parseInt(reader.readLine().trim());
```

**`readLine()` throws a checked exception** (`IOException`) — this is exactly the checked-exception mechanism we covered: reading from "outside" can genuinely fail (stream closed, I/O error), so Java forces you to handle it:

```java
try {
    String line = reader.readLine();
} catch (IOException e) {
    System.out.println("Input error: " + e.getMessage());
}
```

**When to use it:** performance-critical input reading, or when you want raw lines without `Scanner`'s tokenizing behavior.

---

## 3. `Console` — for real terminal interaction (e.g., passwords)

```java
import java.io.Console;

Console console = System.console();
if (console != null) {
    String name = console.readLine("Enter your name: ");
    char[] password = console.readPassword("Enter your password: "); // hides input!
    System.out.println("Hello " + name);
}
```

**Problem it solves:** `Scanner`/`BufferedReader` echo everything you type — including passwords, visibly, on screen. `Console.readPassword()` reads input **without echoing it** to the terminal, which is the correct way to prompt for sensitive input from a command-line program.

**Important limitation:** `System.console()` returns `null` when there's no real interactive terminal attached (e.g., running inside an IDE, a redirected/piped input, or many automated environments) — always null-check before using it.

**When to use it:** command-line tools that need to prompt for credentials or sensitive data.

---

## 4. Command-line arguments — input provided at launch, not during execution

```java
public class Main {
    public static void main(String[] args) {
        if (args.length > 0) {
            System.out.println("Hello, " + args[0]);
        }
    }
}
```

```
java Main Alireza
// prints: Hello, Alireza
```

**Problem it solves:** sometimes you don't want _interactive_ input at all — you want the program to receive its configuration/data upfront, when it's launched (common for scripts, batch jobs, CLI tools meant to be automated rather than manually operated).

**Where this matters in Spring Boot:** Spring Boot applications actually read `args` in `main()` too —

```java
public static void main(String[] args) {
    SpringApplication.run(MyApplication.class, args);
}
```

— and Spring Boot supports passing configuration overrides as command-line arguments (e.g., `--server.port=8081`), which is this exact mechanism under the hood.

---

## 5. GUI input — `JOptionPane` (Swing, older desktop apps)

```java
import javax.swing.JOptionPane;

String name = JOptionPane.showInputDialog("Enter your name:");
System.out.println("Hello " + name);
```

**Problem it solves:** for desktop GUI applications, you don't have a terminal at all — `JOptionPane` pops up a dialog box to collect input instead. This is legacy/less common today (Swing is old), but you'll still encounter it in older codebases or simple desktop tutorials.

---

## 6. Reading from files instead of a live human (a related but distinct "input" source)

Since we already covered this in depth: input doesn't have to come from a person typing — a file is also "outside," and reading it is conceptually the same act of crossing the inside/outside boundary.

```java
try (BufferedReader reader = new BufferedReader(new FileReader("input.txt"))) {
    String line;
    while ((line = reader.readLine()) != null) {
        process(line);
    }
} catch (IOException e) {
    System.out.println("Failed to read file: " + e.getMessage());
}
```

**When relevant:** batch-processing tools, tests that feed in fixed sample data, config loading.

---

## 7. In Spring Boot specifically — "user input" usually means HTTP, not console

This is worth calling out because it's a real mental shift from console programs: **Spring Boot web apps almost never read from `System.in`.** Instead, "input" arrives as HTTP request data, and Spring converts it into Java objects for you automatically:

```java
@RestController
public class UserController {

    @PostMapping("/users")
    public String createUser(@RequestBody User user) {   // JSON body → Java object automatically
        return "Created user: " + user.getName();
    }

    @GetMapping("/greet")
    public String greet(@RequestParam String name) {      // ?name=Alireza in the URL
        return "Hello, " + name;
    }
}
```

Under the hood, Spring is reading the raw HTTP request body — which is, again, ultimately a byte stream — and using Jackson (mentioned earlier) to deserialize it into your `User` object. Same underlying concept (crossing from "outside" to "inside"), completely different mechanism than console input.

---

## Summary table

|Method|Reads from|Best for|Key trait|
|---|---|---|---|
|`Scanner`|console (`System.in`)|learning, simple programs|easy typed parsing, but slower|
|`BufferedReader`|console or file|performance-sensitive reading|fast, text-only, manual parsing|
|`Console`|console|passwords/sensitive input|hides input from screen|
|Command-line `args`|program launch|scripts, automated/CLI tools|input provided upfront, not interactively|
|`JOptionPane`|GUI dialog|old Swing desktop apps|popup dialog, no terminal needed|
|File reading|files|batch data, configs, tests|not "live" input, but same I/O mechanism|
|`@RequestBody` / `@RequestParam`|HTTP requests|Spring Boot web apps|Spring handles the byte stream + deserialization for you|

## Which one should you actually practice right now?

Since you're learning core Java before diving deeper into Spring Boot: **`Scanner` first** (to get comfortable with the API), then **`BufferedReader`** once you understand why performance/parsing control matters — both will make the eventual jump to Spring's `@RequestBody`/`@RequestParam` model click faster, because you'll already understand what's happening underneath ("input has to be read from an external source and converted into a usable Java type").

[[Java]]