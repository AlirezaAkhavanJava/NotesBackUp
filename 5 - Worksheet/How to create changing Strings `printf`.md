

This guide explains how to use Java's `printf` method for string formatting, with a focus on creating time displays like `HH:mm:ss` and updating output on the same line, as seen in the `InterruptedThreads` example.

## What is `printf`?

The `printf` method in Java (short for "print formatted") allows you to format strings by embedding placeholders for variables. It's part of `System.out` and uses a format string with specifiers to control how values are displayed.

### Basic Syntax

```java
System.out.printf(formatString, arg1, arg2, ...);
```

- `formatString`: A string containing text and format specifiers (e.g., `%d`, `%s`).
- `arg1, arg2, ...`: Values to insert into the placeholders.

## Key Format Specifiers

Here are common specifiers used in `printf`:

- `%d`: For integers (e.g., `5`).
- `%02d`: For integers, padded with zeros to at least 2 digits (e.g., `05`).
- `%s`: For strings.
- `%f`: For floating-point numbers.
- `%n`: Newline (platform-independent).

## Creating the `HH:mm:ss` Format

To display time in `HH:mm:ss` (e.g., `00:00:05`), you calculate hours, minutes, and seconds from a total seconds count and use `%02d` to ensure two-digit formatting.

### Example from `InterruptedThreads`

```java
int seconds = 5;
int hours = seconds / 3600;
int minutes = (seconds % 3600) / 60;
int secs = seconds % 60;
System.out.printf("Elapsed time: %02d:%02d:%02d", hours, minutes, secs);
```

- **Calculation**:
    - `seconds / 3600`: Divides total seconds by 3600 (seconds in an hour) to get hours.
    - `(seconds % 3600) / 60`: Takes the remainder after hours and divides by 60 to get minutes.
    - `seconds % 60`: Takes the remainder to get seconds.
- **Formatting**:
    - `%02d`: Ensures each number is at least two digits, padding with zeros (e.g., `5` becomes `05`).
- **Output**: `Elapsed time: 00:00:05`

## Updating the Same Line with `\r`

The `\r` (carriage return) moves the cursor to the start of the current line, allowing the next `printf` to overwrite the previous output. This is useful for updating a timer in place.

### Example

```java
System.out.printf("\rElapsed time: %02d:%02d:%02d", hours, minutes, secs);
System.out.flush();
```

- `\r`: Moves the cursor to the start of the line.
- `System.out.flush()`: Ensures the output is displayed immediately, as output may be buffered.

### In `InterruptedThreads`

The loop in your code updates the time every second:

```java
int seconds = 0;
while (!Thread.currentThread().isInterrupted()) {
    try {
        Thread.sleep(1000);
        int hours = seconds / 3600;
        int minutes = (seconds % 3600) / 60;
        int secs = seconds % 60;
        System.out.printf("\rElapsed time: %02d:%02d:%02d", hours, minutes, secs);
        System.out.flush();
        seconds++;
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
        System.out.println("\nThread is interrupted ...");
        break;
    }
}
```

- **Behavior**: Every second, the time is recalculated, formatted, and printed on the same line, creating a live-updating timer.
- **Output**: Shows `Elapsed time: 00:00:00`, then `00:00:01`, etc., on the same line until interrupted.

## Tips for Creating Formatted Strings

1. **Use `%02d` for Time**: Ensures consistent two-digit display for hours, minutes, and seconds.
2. **Combine Text and Specifiers**: Mix static text (e.g., `Elapsed time:`) with specifiers in the format string.
3. **Use `\r` for Overwrites**: When updating the same line, prepend `\r` to the format string.
4. **Flush Output**: Call `System.out.flush()` to ensure immediate display, especially in loops.
5. **Handle Edge Cases**: Ensure your calculations (like `seconds % 60`) are correct to avoid errors in time display.

## Additional Example

To format a timer that only shows minutes and seconds (`mm:ss`):

```java
int seconds = 125;
int minutes = seconds / 60;
int secs = seconds % 60;
System.out.printf("Time: %02d:%02d%n", minutes, secs);
// Output: Time: 02:05
```

## Resources

- [Java `printf` Documentation](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/Formatter.html): Official guide to format specifiers.
- [Java `Thread` Documentation](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/lang/Thread.html): For understanding thread interruption in your code.

This formatting technique is powerful for creating dynamic, readable console output in Java, especially for timers or progress indicators.

---
```java
package com.arcade.ObsidianNotes;  
  
public class Demons {  
    public static void operate() {  
  
        Thread demonThread = new Thread(() -> {  
            int seconds = 0;  
            while (Thread.currentThread().isAlive()) {  
                try {  
                    System.out.printf("\rThe Demon is running for : %d seconds", seconds);  
                    System.out.flush();  
                    seconds++;  
                    Thread.sleep(1000);  
  
  
                } catch (InterruptedException e) {  
                    System.out.println("Demon thread is interrupted ! ");  
                    Thread.currentThread().interrupt();  
                    break;  
                }  
            }  
        });  
  
  
  
  
  
  
        Thread printer = new Thread(() -> {  
            for (int i = 0; i < 10; i++) {  
                try {  
                    Thread.sleep(1000);  
                } catch (InterruptedException e) {  
                    throw new RuntimeException(e);  
                }  
            }  
            System.out.println("The Thread Two finished");  
        });  
  
        demonThread.setDaemon(true);  
        demonThread.start();  
        printer.start();  
    }  
}
```
---
###### *Tags : [[My mistakes in action]]