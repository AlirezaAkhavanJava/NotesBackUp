Date : 2025-09-04


Regular expressions (regex) in Java are used to match, search, and manipulate text patterns. The `java.util.regex` package provides the `Pattern` and `Matcher` classes for regex operations. This guide covers regex from beginner to advanced levels, with examples and features up to Java 25 (September 2025).

---

## Phase 1: Basics of Regular Expressions

### What are Regular Expressions?

Regular expressions are patterns that describe sets of strings, used for searching, validating, and replacing text. In Java, regex is handled by the `Pattern` and `Matcher` classes.

### Key Concepts

- **Pattern**: A compiled regex pattern.
- **Matcher**: Applies the pattern to a string for matching or manipulation.
- **Metacharacters**: Special characters like `.` (any character), `*` (zero or more), `+` (one or more), `?` (zero or one).
- **Character Classes**: `[abc]` (match a, b, or c), `[a-z]` (range), `[^a-z]` (negation).
- **Anchors**: `^` (start of string), `$` (end of string).
- **Groups**: `(...)` for capturing parts of a match.

**Example: Basic Regex Matching**

```java
import java.util.regex.Pattern;
import java.util.regex.Matcher;

public class Main {
    public static void main(String[] args) {
        String text = "Hello123";
        Pattern pattern = Pattern.compile("[a-zA-Z]+\\d+"); // Letters followed by digits
        Matcher matcher = pattern.matcher(text);
        
        if (matcher.matches()) {
            System.out.println("Match found: " + text);
        } else {
            System.out.println("No match");
        }
    }
}
```

**Output**:

```
Match found: Hello123
```

**Key Points**:

- Use `Pattern.compile()` to create a regex pattern.
- `Matcher.matches()` checks if the entire string matches the pattern.
- Use `try-with-resources` for I/O operations involving regex (e.g., reading files).

---

## Phase 2: Common Regex Operations

### Searching, Finding, and Replacing

- **Find**: Locate substrings matching the pattern.
- **Replace**: Substitute matched text with new text.
- **Split**: Divide a string based on a pattern.

**Example: Finding and Replacing**

```java
import java.util.regex.Pattern;
import java.util.regex.Matcher;

public class Main {
    public static void main(String[] args) {
        String text = "Contact: alice@example.com, bob@test.com";
        Pattern pattern = Pattern.compile("\\w+@\\w+\\.com"); // Email pattern
        Matcher matcher = pattern.matcher(text);
        
        while (matcher.find()) {
            System.out.println("Found email: " + matcher.group());
        }
        
        String replaced = matcher.replaceAll("****@****.com");
        System.out.println("Replaced: " + replaced);
    }
}
```

**Output**:

```
Found email: alice@example.com
Found email: bob@test.com
Replaced: Contact: ****@****.com, ****@****.com
```

**Example: Splitting a String**

```java
public class Main {
    public static void main(String[] args) {
        String text = "apple,banana,orange";
        String[] fruits = text.split(",");
        System.out.println(Arrays.toString(fruits)); // [apple, banana, orange]
    }
}
```

**Key Points**:

- `Matcher.find()` iterates over matches.
- `matcher.group()` retrieves matched text.
- `String.split()` uses regex to split strings.

---

## Phase 3: Advanced Regex Features

### Capturing Groups

Groups `(...)` capture parts of a match for reuse.

**Example: Extracting Phone Number Parts**

```java
import java.util.regex.Pattern;
import java.util.regex.Matcher;

public class Main {
    public static void main(String[] args) {
        String text = "Phone: 123-456-7890";
        Pattern pattern = Pattern.compile("(\\d{3})-(\\d{3})-(\\d{4})"); // Area code, prefix, line
        Matcher matcher = pattern.matcher(text);
        
        if (matcher.find()) {
            System.out.println("Area code: " + matcher.group(1));
            System.out.println("Prefix: " + matcher.group(2));
            System.out.println("Line: " + matcher.group(3));
        }
    }
}
```

**Output**:

```
Area code: 123
Prefix: 456
Line: 7890
```

### Lookaheads and Lookbehinds

- **Positive Lookahead**: `(?=...)` ensures a pattern follows.
- **Negative Lookahead**: `(?!...)` ensures a pattern does not follow.
- **Positive Lookbehind**: `(?<=...)` ensures a pattern precedes.
- **Negative Lookbehind**: `(?<!...)` ensures a pattern does not precede.

**Example: Password Validation with Lookahead**

```java
import java.util.regex.Pattern;

public class Main {
    public static void main(String[] args) {
        String password = "Pass123!";
        Pattern pattern = Pattern.compile("^(?=.*[A-Z])(?=.*\\d)(?=.*[!@#])[A-Za-z\\d!@#]{8,}$");
        // At least one uppercase, one digit, one special char, min 8 chars
        if (pattern.matcher(password).matches()) {
            System.out.println("Valid password");
        } else {
            System.out.println("Invalid password");
        }
    }
}
```

**Output**:

```
Valid password
```

---

## Phase 4: Regex in Real-World Applications

### Validating Input

Regex is commonly used to validate emails, phone numbers, or URLs.

**Example: Email Validation**

```java
import java.util.regex.Pattern;

public class Main {
    public static void main(String[] args) {
        String email = "user@domain.com";
        Pattern pattern = Pattern.compile("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$");
        if (pattern.matcher(email).matches()) {
            System.out.println("Valid email");
        } else {
            System.out.println("Invalid email");
        }
    }
}
```

### Processing Files

Regex can process text files for pattern matching or data extraction.

**Example: Extract Dates from File**

```java
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

public class Main {
    public static void main(String[] args) throws Exception {
        String content = Files.readString(Paths.get("data.txt"));
        Pattern pattern = Pattern.compile("\\d{2}/\\d{2}/\\d{4}");
        Matcher matcher = pattern.matcher(content);
        
        while (matcher.find()) {
            System.out.println("Found date: " + matcher.group());
        }
    }
}
```

**Note**: Assumes `data.txt` contains text like "Meeting on 04/09/2025".

---

## Phase 5: Concurrent Regex Processing

For large datasets, use virtual threads (Java 21+) to process regex operations concurrently.

**Example: Concurrent Pattern Matching**

```java
import java.util.List;
import java.util.concurrent.Executors;
import java.util.regex.Pattern;

public class Main {
    public static void main(String[] args) {
        List<String> texts = List.of("test1@example.com", "test2@domain.com", "invalid");
        Pattern pattern = Pattern.compile("\\w+@\\w+\\.com");
        
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            for (String text : texts) {
                executor.submit(() -> {
                    if (pattern.matcher(text).matches()) {
                        System.out.println("Valid email: " + text);
                    }
                });
            }
        }
    }
}
```

**Output**:

```
Valid email: test1@example.com
Valid email: test2@domain.com
```

**Key Points**:

- Virtual threads scale regex processing for large datasets.
- `Pattern` is thread-safe; `Matcher` is not (create a new `Matcher` per thread).

---

## Java Features Up to Java 25 for Regular Expressions

- **Java 8 (2014)**:
    
    - **Streams API**: Process regex matches efficiently.
        
        ```java
        import java.util.regex.Pattern;
        import java.util.List;
        
        public class Main {
            public static void main(String[] args) {
                List<String> texts = List.of("apple123", "banana456", "xyz");
                Pattern pattern = Pattern.compile("[a-z]+\\d+");
                texts.stream()
                     .filter(text -> pattern.matcher(text).matches())
                     .forEach(System.out::println); // apple123, banana456
            }
        }
        ```
        
    - **Lambda Expressions**: Simplify regex operations.
        
        ```java
        texts.forEach(text -> pattern.matcher(text).matches() ? System.out.println(text) : null);
        ```
        
- **Java 9 (2017)**:
    
    - **Pattern.asMatchPredicate()**: Converts regex to `Predicate`.
        
        ```java
        import java.util.regex.Pattern;
        
        public class Main {
            public static void main(String[] args) {
                Pattern pattern = Pattern.compile("\\d+");
                var predicate = pattern.asMatchPredicate();
                System.out.println(predicate.test("123")); // true
            }
        }
        ```
        
- **Java 10 (2018)**:
    
    - **var**: Cleaner code for regex objects.
        
        ```java
        var pattern = Pattern.compile("\\w+");
        ```
        
- **Java 14 (2020)**:
    
    - **Records**: Store regex configurations.
        
        ```java
        record RegexConfig(String pattern, boolean caseInsensitive) {}
        RegexConfig config = new RegexConfig("\\w+", true);
        ```
        
- **Java 17 (2021)**:
    
    - **Pattern Matching for `instanceof`**:
        
        ```java
        if (obj instanceof String s && Pattern.compile("\\d+").matcher(s).matches()) {
            System.out.println("Numeric string: " + s);
        }
        ```
        
- **Java 21 (2023)**:
    
    - **Virtual Threads**: Concurrent regex processing (shown above).
    - **Structured Concurrency (Preview)**: Manage multiple regex tasks.
        
        ```java
        import java.util.concurrent.StructuredTaskScope;
        import java.util.regex.Pattern;
        
        public class Main {
            public static void main(String[] args) throws Exception {
                Pattern pattern = Pattern.compile("\\w+@\\w+\\.com");
                try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
                    var future1 = scope.fork(() -> pattern.matcher("a@b.com").matches());
                    var future2 = scope.fork(() -> pattern.matcher("x@y.com").matches());
                    scope.join().throwIfFailed();
                    System.out.println("Matches: " + future1.get() + ", " + future2.get());
                }
            }
        }
        ```
        
- **Java 25 (2025)**:
    
    - **Implicit Classes**: Simplify regex utility methods.
        
        ```java
        implicit class RegexUtils {
            static boolean isEmail(String text) {
                return Pattern.compile("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$").matcher(text).matches();
            }
        }
        ```
        
    - **Flexible Constructor Bodies**: Validate regex patterns.
        
        ```java
        class Validator {
            private Pattern pattern;
            Validator(String regex) {
                this.pattern = Pattern.compile(regex);
                if (regex.isEmpty()) throw new IllegalArgumentException("Regex cannot be empty");
            }
        }
        ```
        

---

## Best Practices

1. **Precompile Patterns**: Use `Pattern.compile()` for reusable patterns to improve performance.
2. **Use Specific Patterns**: Avoid overly broad regex (e.g., `.*`) for efficiency.
3. **Handle Exceptions**: Catch `PatternSyntaxException` for invalid regex.
4. **Test Thoroughly**: Use JUnit to test regex patterns.
    
    ```xml
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter</artifactId>
        <version>5.11.0</version>
        <scope>test</scope>
    </dependency>
    ```
    
5. **Thread Safety**: Reuse `Pattern` (thread-safe) but create new `Matcher` instances per thread.

**Related Library: Apache Commons Lang**  
For additional string utilities that complement regex:

```xml
<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-lang3</artifactId>
    <version>3.17.0</version> <!-- Check latest -->
</dependency>
```

**Example with Apache Commons Lang**:

```java
import org.apache.commons.lang3.StringUtils;
import java.util.regex.Pattern;

public class Main {
    public static void main(String[] args) {
        String text = "  user@domain.com  ";
        if (StringUtils.isNotBlank(text) && Pattern.compile("\\w+@\\w+\\.com").matcher(text.trim()).matches()) {
            System.out.println("Valid email");
        }
    }
}
```

---

## Real-World Applications

- **Input Validation**: Validate emails, phone numbers, or URLs.
- **Log Parsing**: Extract data from logs (e.g., timestamps, IPs).
- **Text Processing**: Search and replace in documents or files.
- **Data Extraction**: Parse structured data like CSV or JSON.

---

## Conclusion

Java’s `java.util.regex` package provides powerful tools for pattern matching and text manipulation. Start with basic patterns, use groups and lookaheads for complex tasks, and leverage virtual threads for concurrent processing. Java 25 features like implicit classes and structured concurrency enhance regex usability and performance.



##### *Tags : [[Java]]