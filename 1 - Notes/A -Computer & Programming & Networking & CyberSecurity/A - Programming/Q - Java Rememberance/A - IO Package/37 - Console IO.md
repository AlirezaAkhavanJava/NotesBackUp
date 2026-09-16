# Basic Console I/O in Java

## Definition

**Console I/O** (Input/Output) is the mechanism by which a Java program reads data from, and writes data to, the terminal/console — the most basic form of the "inside ↔ outside" boundary crossing we've discussed throughout. "Basic" here means: no files, no networks, no GUIs — just a program talking directly to whoever is running it in a terminal window.

It has exactly two directions, and Java gives you a dedicated, pre-built stream for each:

```
        OUTPUT (program → screen)
Program ───────────────────────────► Console
Program ◄─────────────────────────── Console
        INPUT (keyboard → program)
```

---

## The two halves

### Output — writing to the console

```java
System.out.println("Hello, Alireza!");
```

- `System.out` is a ready-made `PrintStream` object (a field on the `System` class)
- `println()` / `print()` / `printf()` are its methods for writing text
- This is **output** because data is flowing **out** of the program to something "outside" (the terminal)

### Input — reading from the console

```java
Scanner scanner = new Scanner(System.in);
String name = scanner.nextLine();
```

- `System.in` is a ready-made `InputStream` object (raw bytes from the keyboard)
- `Scanner` (or `BufferedReader`) wraps it to turn raw bytes into usable typed values
- This is **input** because data is flowing **in** from "outside" (the keyboard) into the program

---

## A complete basic console I/O program

```java
import java.util.Scanner;

public class Greeting {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);   // set up input

        System.out.print("Enter your name: ");       // OUTPUT: prompt
        String name = scanner.nextLine();             // INPUT: read

        System.out.print("Enter your age: ");         // OUTPUT: prompt
        int age = Integer.parseInt(scanner.nextLine()); // INPUT: read + parse

        System.out.println("Hello " + name + "! In 10 years you'll be " + (age + 10)); // OUTPUT: result

        scanner.close();                               // release the resource
    }
}
```

**Run it:**

```
Enter your name: Alireza
Enter your age: 25
Hello Alireza! In 10 years you'll be 35
```

Every piece here is something we've already individually defined — this program is just the assembly of `System.out`, `System.in`, `Scanner`, `Integer.parseInt()`, and string concatenation into one working flow.

---

## The typical pattern for any console I/O program

1. **Set up an input source** — `new Scanner(System.in)` (once, usually near the top of `main`)
2. **Prompt** — `System.out.print("...")` so the user knows what to type
3. **Read** — `scanner.nextLine()` / `nextInt()` etc.
4. **Validate / parse / process** the input
5. **Output the result** — `System.out.println(...)`
6. **Repeat** (often in a loop) or **close** resources when done

```java
Scanner scanner = new Scanner(System.in);
boolean running = true;

while (running) {
    System.out.print("Enter a number (or 'exit'): ");
    String input = scanner.nextLine();

    if (input.equalsIgnoreCase("exit")) {
        running = false;
    } else {
        int num = Integer.parseInt(input);
        System.out.println("Square: " + (num * num));
    }
}
scanner.close();
```

---

## Why "basic" is the right word here

This is the _simplest possible_ form of I/O because:

- The source/destination is fixed and always available (no file paths, no network addresses, no permissions to worry about)
- No checked exceptions to handle in the common `Scanner` path (unlike `BufferedReader.readLine()`, which throws `IOException`, or file I/O, which can fail if a path doesn't exist)
- It's synchronous and linear — the program just pauses at `nextLine()` until the human types something and presses Enter

Everything more advanced we've covered — files, sockets, serialization, buffered streams — follows the _exact same input/output concept_, just with a different, less forgiving "outside" on the other end (a file that might not exist, a network connection that might drop). Console I/O is the training-wheels version where none of that unpredictability exists, which is why it's always the starting point.

[[Java]]