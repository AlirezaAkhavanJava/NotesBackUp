

## 1. Definition

A **regular expression (regex)** is a pattern used to describe and search for text.

Java provides regex through:

```java
java.util.regex.Pattern
java.util.regex.Matcher
```

The relationship is:

```text
Regex String
    ↓
Pattern.compile(...)
    ↓
Pattern
    ↓
pattern.matcher(input)
    ↓
Matcher
    ↓
matches / find / group / replace / ...
```

Example:

```java
Pattern pattern = Pattern.compile("\\d+");

Matcher matcher = pattern.matcher("Age: 25");

if (matcher.find()) {
    System.out.println(matcher.group());
}
```

Output:

```text
25
```

---

# 2. `Pattern`

`Pattern` represents a **compiled regular expression**.

```java
Pattern pattern = Pattern.compile("\\d+");
```

You normally compile once and reuse it.

```java
private static final Pattern EMAIL =
        Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$");
```

This is preferable to repeatedly compiling the same regex.

---

# 3. `Matcher`

`Matcher` applies a `Pattern` to a particular input.

```java
Pattern pattern = Pattern.compile("\\d+");

Matcher matcher = pattern.matcher("abc123xyz");
```

Now `matcher` represents:

```text
Pattern: \d+
Input:   abc123xyz
```

The matcher can search that input.

---

# 4. Java String Escaping Is Important

Regex has its own escaping rules, and Java strings have escaping rules.

For example, regex:

```text
\d+
```

means:

```text
one or more digits
```

But Java needs:

```java
"\\d+"
```

because Java interprets `\` as an escape character.

So:

|Regex|Java string|
|---|---|
|`\d`|`"\\d"`|
|`\s`|`"\\s"`|
|`\w`|`"\\w"`|
|`\.`|`"\\."`|
|`\(`|`"\\("`|

This is one of the most common regex mistakes in Java.

---

# 5. Basic Regex Syntax

## Literal characters

```regex
hello
```

Matches:

```text
hello
```

---

## Character classes

```regex
[abc]
```

Matches one character:

```text
a
b
c
```

```regex
[0-9]
```

Matches one digit.

```regex
[a-z]
```

Matches lowercase letters.

```regex
[A-Z]
```

Matches uppercase letters.

---

# 6. Negated Character Classes

```regex
[^0-9]
```

Means:

> any character that is not a digit.

Example:

```java
Pattern.compile("[^0-9]+");
```

---

# 7. Shorthand Character Classes

|Regex|Meaning|
|---|---|
|`\d`|digit|
|`\D`|non-digit|
|`\s`|whitespace|
|`\S`|non-whitespace|
|`\w`|word character|
|`\W`|non-word character|

Example:

```java
Pattern digit = Pattern.compile("\\d");
```

---

# 8. Quantifiers

Quantifiers determine **how many times something may occur**.

|Regex|Meaning|
|---|---|
|`a*`|0 or more|
|`a+`|1 or more|
|`a?`|0 or 1|
|`a{3}`|exactly 3|
|`a{3,}`|3 or more|
|`a{3,5}`|3–5|

Example:

```regex
\d+
```

Matches:

```text
123
42
99999
```

but not:

```text
abc
```

---

# 9. Anchors

Anchors don't consume characters.

|Regex|Meaning|
|---|---|
|`^`|beginning|
|`$`|end|
|`\A`|absolute beginning|
|`\z`|absolute end|
|`\b`|word boundary|

Example:

```regex
^\d+$
```

means:

> The **entire input** must consist only of digits.

This is extremely useful for validation.

```java
Pattern number = Pattern.compile("^\\d+$");

System.out.println(number.matcher("12345").matches());
```

Output:

```text
true
```

---

# 10. Alternation

Use:

```regex
cat|dog
```

Meaning:

```text
cat OR dog
```

Example:

```java
Pattern pattern =
        Pattern.compile("cat|dog");

Matcher matcher =
        pattern.matcher("The dog is here");

System.out.println(matcher.find());
```

---

# 11. Groups

Parentheses create a **capturing group**.

```regex
(\\d+)-(\\d+)
```

For:

```text
123-456
```

you have:

```text
Group 0 = 123-456
Group 1 = 123
Group 2 = 456
```

Java:

```java
Pattern pattern =
        Pattern.compile("(\\d+)-(\\d+)");

Matcher matcher =
        pattern.matcher("123-456");

if (matcher.find()) {
    System.out.println(matcher.group(0));
    System.out.println(matcher.group(1));
    System.out.println(matcher.group(2));
}
```

Output:

```text
123-456
123
456
```

---

# 12. Named Groups

Java supports named capturing groups:

```regex
(?<area>\d{3})-(?<number>\d{4})
```

Java:

```java
Pattern pattern =
        Pattern.compile(
            "(?<area>\\d{3})-(?<number>\\d{4})"
        );

Matcher matcher =
        pattern.matcher("123-4567");

if (matcher.matches()) {
    System.out.println(matcher.group("area"));
    System.out.println(matcher.group("number"));
}
```

Named groups become very useful when a regex becomes complicated.

---

# 13. `Matcher.matches()`

This is one of the most important methods.

```java
matcher.matches()
```

asks:

> Does the **entire input** match the pattern?

Example:

```java
Pattern pattern =
        Pattern.compile("\\d+");

System.out.println(
    pattern.matcher("12345").matches()
);
```

```text
true
```

But:

```java
System.out.println(
    pattern.matcher("abc123").matches()
);
```

```text
false
```

Because the entire string isn't digits.

Conceptually:

```text
Pattern: \d+

12345
█████    → match

abc123
────███  → not a full match
```

---

# 14. `Matcher.find()`

`find()` asks:

> Can I find a matching substring anywhere in the input?

```java
Pattern pattern =
        Pattern.compile("\\d+");

Matcher matcher =
        pattern.matcher("abc123xyz");

System.out.println(matcher.find());
```

Output:

```text
true
```

Because `123` was found.

This is different from `matches()`.

```text
matches()
→ entire input

find()
→ any matching region
```

---

# 15. `Matcher.lookingAt()`

`lookingAt()` asks:

> Does the pattern match starting at the beginning of the input?

```java
Pattern pattern = Pattern.compile("\\d+");

Matcher matcher =
        pattern.matcher("123abc");

System.out.println(matcher.lookingAt());
```

```text
true
```

But:

```java
matcher =
        pattern.matcher("abc123");

System.out.println(matcher.lookingAt());
```

```text
false
```

Comparison:

|Method|Behavior|
|---|---|
|`matches()`|entire input|
|`lookingAt()`|beginning of input|
|`find()`|anywhere|

---

# 16. Finding Multiple Matches

This is one of the most important uses of `Matcher`.

```java
Pattern pattern =
        Pattern.compile("\\d+");

Matcher matcher =
        pattern.matcher("Order 123, item 456, box 789");

while (matcher.find()) {
    System.out.println(matcher.group());
}
```

Output:

```text
123
456
789
```

The matcher moves through the input:

```text
Order 123, item 456, box 789
      ↑
     find()

              ↑
             find()

                         ↑
                        find()
```

---

# 17. Match Positions

You can determine where a match occurred.

### `start()`

```java
matcher.start()
```

Returns the starting index.

### `end()`

```java
matcher.end()
```

Returns the index **after** the match.

Example:

```java
Pattern pattern = Pattern.compile("\\d+");

Matcher matcher =
        pattern.matcher("abc123xyz");

if (matcher.find()) {
    System.out.println(matcher.group());
    System.out.println(matcher.start());
    System.out.println(matcher.end());
}
```

Output:

```text
123
3
6
```

Because:

```text
abc123xyz
012345678
   ^  ^
   3  6
```

---

# 18. `group()`

Returns the last successful match.

```java
matcher.group()
```

Equivalent to:

```java
matcher.group(0)
```

Example:

```java
while (matcher.find()) {
    String match = matcher.group();
    System.out.println(match);
}
```

---

# 19. `group(int)`

Returns a specific capturing group.

```java
matcher.group(1)
```

Example:

```java
Pattern pattern =
        Pattern.compile("(\\w+)@(\\w+\\.\\w+)");

Matcher matcher =
        pattern.matcher("alice@example.com");

if (matcher.matches()) {
    System.out.println(matcher.group(1));
    System.out.println(matcher.group(2));
}
```

Output:

```text
alice
example.com
```

---

# 20. `groupCount()`

Returns the number of capturing groups.

```java
int count = matcher.groupCount();
```

For:

```regex
(\d+)-([A-Z]+)-(.*)
```

there are:

```text
3
```

capturing groups.

---

# 21. Input Filtering

Regex is extremely useful for **checking whether input has an allowed format**.

For example, suppose a username may contain:

```text
letters
digits
underscore
3–20 characters
```

Regex:

```regex
^[A-Za-z0-9_]{3,20}$
```

Java:

```java
private static final Pattern USERNAME =
        Pattern.compile("^[A-Za-z0-9_]{3,20}$");
```

Validate:

```java
String username = "alireza_123";

if (USERNAME.matcher(username).matches()) {
    System.out.println("Valid");
} else {
    System.out.println("Invalid");
}
```

---

# 22. Filtering Input From a List

Suppose:

```java
List<String> usernames = List.of(
    "alice123",
    "bob!",
    "admin_01",
    "hello world",
    "john"
);
```

Filter using regex:

```java
Pattern pattern =
        Pattern.compile("^[A-Za-z0-9_]{3,20}$");

List<String> valid =
        usernames.stream()
                 .filter(s -> pattern.matcher(s).matches())
                 .toList();
```

Result:

```text
alice123
admin_01
john
```

This is a very practical combination of:

```text
Regex
+
Matcher
+
Stream API
```

---

# 23. Input Filtering ≠ Input Sanitization

This distinction is extremely important.

Regex validation can answer:

> "Does this input have the format I allow?"

It does **not automatically make the input safe**.

For example:

```java
Pattern.compile("^[A-Za-z0-9_]+$")
```

can validate a username format.

But regex is not the correct defense for SQL injection.

Don't do:

```java
String sql =
    "SELECT * FROM users WHERE name = '" + input + "'";
```

Instead use parameterized SQL:

```java
PreparedStatement statement =
    connection.prepareStatement(
        "SELECT * FROM users WHERE name = ?"
    );

statement.setString(1, input);
```

Regex and security controls solve different problems.

---

# 24. Filtering Dangerous Characters

Suppose you only permit a limited character set:

```java
Pattern allowed =
        Pattern.compile("^[A-Za-z0-9 .,!?'-]+$");
```

Then:

```java
boolean valid =
    allowed.matcher(input).matches();
```

This is useful when your application has a defined input grammar.

But don't assume:

```text
"remove suspicious characters"
```

is a universal security strategy.

For each context, use the appropriate defense:

```text
SQL       → PreparedStatement
HTML      → output encoding
Shell     → avoid shell execution / proper argument APIs
Path      → Path APIs + authorization
JSON      → JSON parser
Regex     → regex itself
```

---

# 25. `Pattern` Matching With Case Insensitivity

You can compile with flags.

```java
Pattern pattern =
        Pattern.compile("java", Pattern.CASE_INSENSITIVE);
```

Then:

```java
pattern.matcher("JAVA").find();
```

returns:

```text
true
```

Useful flags include:

|Flag|Meaning|
|---|---|
|`CASE_INSENSITIVE`|case-insensitive matching|
|`MULTILINE`|changes `^` and `$` behavior|
|`DOTALL`|`.` also matches line terminators|
|`COMMENTS`|allows whitespace/comments in regex|
|`UNICODE_CASE`|Unicode-aware case behavior|
|`UNIX_LINES`|Unix line semantics|

You can combine flags:

```java
Pattern.compile(
    regex,
    Pattern.CASE_INSENSITIVE |
    Pattern.MULTILINE
);
```

---

# 26. `.` — Any Character

The dot:

```regex
.
```

generally means:

> any character except line terminators.

Example:

```regex
c.t
```

matches:

```text
cat
cot
cut
c9t
```

With `Pattern.DOTALL`, dot can also match line terminators.

---

# 27. Greedy Quantifiers

By default, quantifiers are **greedy**.

Example:

```regex
<.*>
```

Input:

```text
<a> hello <b>
```

A greedy match can consume:

```text
<a> hello <b>
```

rather than only:

```text
<a>
```

---

# 28. Reluctant Quantifiers

Add `?`:

```regex
<.*?>
```

Now the quantifier is reluctant/non-greedy.

It tends to consume the smallest amount necessary.

```text
<a>
```

This distinction becomes important when parsing structured text.

---

# 29. Atomic / Possessive Quantifiers

Java also supports possessive quantifiers:

```regex
*+
++
?+
{n,m}+
```

For example:

```regex
\d++
```

A possessive quantifier does not backtrack once it has consumed characters.

This can matter when controlling regex backtracking and performance.

---

# 30. `Pattern.split()`

`Pattern` can also split text.

```java
Pattern comma =
        Pattern.compile(",");

String[] parts =
        comma.split("a,b,c");
```

Result:

```text
a
b
c
```

You can also use:

```java
String[] parts =
    Pattern.compile("\\s*,\\s*")
           .split("a, b,  c");
```

Result:

```text
a
b
c
```

---

# 31. `Matcher.replaceAll()`

Replace every match:

```java
Pattern pattern =
        Pattern.compile("\\d+");

String result =
        pattern.matcher("abc123xyz456")
               .replaceAll("#");
```

Result:

```text
abc#xyz#
```

---

# 32. `Matcher.replaceFirst()`

Only the first matching occurrence:

```java
String result =
    pattern.matcher("123 abc 456")
           .replaceFirst("#");
```

Result:

```text
# abc 456
```

---

# 33. Replacement With Groups

Input:

```text
John Smith
```

Regex:

```java
Pattern pattern =
        Pattern.compile("(\\w+) (\\w+)");
```

Replace:

```java
String result =
    pattern.matcher("John Smith")
           .replaceAll("$2, $1");
```

Result:

```text
Smith, John
```

`$1`, `$2`, etc. refer to capturing groups.

---

# 34. `Pattern.matches()`

There is also a convenience method:

```java
Pattern.matches(regex, input)
```

Example:

```java
boolean valid =
    Pattern.matches("\\d+", "12345");
```

This is essentially a convenient way of doing a full match.

For repeated use, prefer:

```java
Pattern pattern = Pattern.compile("\\d+");

pattern.matcher(input).matches();
```

because you can reuse the compiled pattern.

---

# 35. `String.matches()`

Java also provides:

```java
String.matches(regex)
```

Example:

```java
"12345".matches("\\d+");
```

returns:

```text
true
```

But remember:

```java
"abc123".matches("\\d+");
```

is:

```text
false
```

because `String.matches()` tests the **whole string**.

It does not mean "does this string contain digits?"

For that:

```java
"abc123".matches(".*\\d+.*")
```

or, preferably for searching, use `Matcher.find()`.

---

# 36. A Useful Validation Pattern

Suppose we want:

```text
Java username
3–20 characters
letters, numbers, underscore
```

```java
private static final Pattern USERNAME =
        Pattern.compile("[A-Za-z0-9_]{3,20}");
```

Then:

```java
public static boolean isValidUsername(String input) {
    return input != null &&
           USERNAME.matcher(input).matches();
}
```

Notice that we don't actually need `^` and `$` when using `matches()`, because `matches()` already requires the entire region to match.

So:

```java
"^[A-Za-z0-9_]{3,20}$"
```

and:

```java
"[A-Za-z0-9_]{3,20}"
```

can serve the same purpose when used with `matches()`.

---

# 37. Extracting Information

Regex isn't only for validation.

Suppose:

```text
User: Alireza, Age: 25
```

We can extract fields:

```java
Pattern pattern =
        Pattern.compile(
            "User: (\\w+), Age: (\\d+)"
        );

Matcher matcher =
        pattern.matcher("User: Alireza, Age: 25");

if (matcher.matches()) {

    String name = matcher.group(1);
    int age = Integer.parseInt(matcher.group(2));

    System.out.println(name);
    System.out.println(age);
}
```

Output:

```text
Alireza
25
```

This demonstrates the three major regex jobs:

```text
Validation
Extraction
Searching
```

---

# 38. `Matcher` State

A `Matcher` maintains state as it searches.

```java
Matcher matcher = pattern.matcher(input);

matcher.find();
matcher.find();
matcher.find();
```

Each `find()` searches for the **next match**.

You can restart with:

```java
matcher.reset();
```

Or reset with a new input:

```java
matcher.reset("new input");
```

---

# 39. `region()`

You can restrict matching to part of the input.

```java
matcher.region(5, 10);
```

Now the matcher operates on:

```text
input[5..10)
```

This is useful for advanced parsing.

---

# 40. Useful `Matcher` Methods

|Method|Purpose|
|---|---|
|`matches()`|Entire region must match|
|`find()`|Find next occurrence|
|`lookingAt()`|Match from beginning|
|`group()`|Current full match|
|`group(int)`|Captured group|
|`group(String)`|Named group|
|`groupCount()`|Number of capture groups|
|`start()`|Start index|
|`start(int)`|Group start|
|`end()`|End index|
|`end(int)`|Group end|
|`reset()`|Reset matcher|
|`reset(CharSequence)`|Change input|
|`region()`|Get/set matching region|
|`replaceAll()`|Replace all matches|
|`replaceFirst()`|Replace first match|
|`find(int)`|Start searching at index|
|`hitEnd()`|Whether matching reached input end|
|`requireEnd()`|Whether more input could affect the result|

Some of the last methods are mainly useful for advanced parsing and incremental input processing.

---

# 41. Useful `Pattern` Methods

|Method|Purpose|
|---|---|
|`compile(String)`|Compile regex|
|`compile(String, int)`|Compile with flags|
|`matcher(input)`|Create `Matcher`|
|`matches(regex, input)`|Convenience full-match operation|
|`split(input)`|Split string|
|`split(input, limit)`|Split with limit|
|`quote(String)`|Treat text literally|
|`pattern()`|Get original regex|
|`flags()`|Get compilation flags|

`Pattern.quote()` is particularly useful when you have **user-provided text that should be treated literally**, rather than interpreted as regex syntax.

```java
String userText = "a.b";

String regex = Pattern.quote(userText);

Pattern pattern = Pattern.compile(regex);
```

Now the `.` means an actual dot rather than "any character".

---

# 42. Practical Input-Filtering Workflow

For an application accepting user input, a good workflow is:

```text
Input
  ↓
Null / empty check
  ↓
Define allowed format
  ↓
Pattern.compile(...)
  ↓
matcher(input)
  ↓
matches()
  ↓
Accept / reject
```

Example:

```java
private static final Pattern USERNAME =
        Pattern.compile("[A-Za-z0-9_]{3,20}");

public static boolean validUsername(String input) {

    if (input == null) {
        return false;
    }

    return USERNAME.matcher(input).matches();
}
```

Then:

```java
if (!validUsername(username)) {
    throw new IllegalArgumentException(
        "Invalid username"
    );
}
```

---

# 43. Validation vs Searching vs Extraction

This is the most important distinction to internalize:

```text
                 REGEX
                   │
       ┌───────────┼───────────┐
       │           │           │
   Validation   Searching   Extraction
       │           │           │
   matches()      find()    group()
```

### Validation

```java
pattern.matcher(input).matches();
```

Question:

> "Does the entire input conform to this format?"

### Searching

```java
matcher.find();
```

Question:

> "Does this pattern occur anywhere?"

### Extraction

```java
while (matcher.find()) {
    System.out.println(matcher.group());
}
```

Question:

> "What values occur in the input?"

---

# 44. Example: Email Extraction

```java
Pattern pattern =
        Pattern.compile(
            "[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+"
        );

Matcher matcher =
        pattern.matcher(
            "Contact alice@example.com or bob@test.org"
        );

while (matcher.find()) {
    System.out.println(matcher.group());
}
```

Output:

```text
alice@example.com
bob@test.org
```

Notice we're using `find()`, because we're **extracting occurrences from a larger string**, not validating the whole string.

---

# 45. One Complete Example

```java
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class RegexDemo {

    private static final Pattern PHONE =
            Pattern.compile("(\\d{3})-(\\d{4})");

    public static void main(String[] args) {

        String input = "Call 123-4567 or 555-1234";

        Matcher matcher = PHONE.matcher(input);

        while (matcher.find()) {

            String full = matcher.group();
            String area = matcher.group(1);
            String number = matcher.group(2);

            System.out.println("Full: " + full);
            System.out.println("Area: " + area);
            System.out.println("Number: " + number);
            System.out.println(
                "Start: " + matcher.start()
            );
        }
    }
}
```

Conceptually:

```text
Pattern
  │
  │ "(\\d{3})-(\\d{4})"
  ▼
Matcher
  │
  ├── find()
  │     ↓
  │   "123-4567"
  │
  ├── group(1)
  │     ↓
  │   "123"
  │
  ├── group(2)
  │     ↓
  │   "4567"
  │
  └── start()
        ↓
      position
```

---

# 46. The Mental Model You Should Keep

```text
Pattern
    =
compiled regex definition

Matcher
    =
regex + input + current search state
```

And:

```java
Pattern pattern = Pattern.compile(regex);
Matcher matcher = pattern.matcher(input);
```

Then choose the operation based on what you're doing:

```java
matcher.matches();   // validate whole input
matcher.find();      // search input
matcher.lookingAt(); // search at beginning
matcher.group();     // get match
matcher.group(1);    // get captured data
matcher.start();     // where match begins
matcher.end();       // where match ends
```

For **input filtering**, the central pattern is usually:

```java
private static final Pattern RULE =
        Pattern.compile("your-rule");

boolean accepted =
        RULE.matcher(input).matches();
```

That gives you the core of Java's regex system: **define a grammar with `Pattern`, apply it with `Matcher`, then validate, search, extract, or replace depending on which operation you need.**


[[Java]]