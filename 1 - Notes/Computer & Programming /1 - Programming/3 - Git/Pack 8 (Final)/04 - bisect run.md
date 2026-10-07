
 This is the next important step after manually using `git bisect`: **automating the test with a shell script**.

The goal is to go from:

```text
Git checks commit
        ↓
you manually run commands
        ↓
you decide "good" / "bad"
```

to:

```text
Git checks commit
        ↓
shell script runs automatically
        ↓
script exits 0 → GOOD
script exits non-zero → BAD
        ↓
Git continues the binary search
```

Let's build the concept from the ground up.

---

# 1. What is a shell script?

A **shell script** is simply a text file containing shell commands that the shell executes in sequence.

For example:

```sh
#!/bin/sh

echo "Hello"
pwd
git status
```

Save it as:

```text
test.sh
```

Then:

```bash
chmod +x test.sh
./test.sh
```

The shell executes:

```text
echo "Hello"
    ↓
pwd
    ↓
git status
```

So don't think of `.sh` as some special complicated programming language.

At its simplest:

> **A shell script is a saved sequence of commands, with the ability to add logic.**

---

# 2. Why does `git bisect` need a shell script?

You just used bisect manually:

```bash
git bisect good
git bisect bad
```

You were doing something like:

```bash
wc -l scripts/scan.sh
```

Then looking at the result:

```text
1  → good
10 → bad
```

But imagine your repository has **10,000 commits**.

You don't want to sit there doing:

```bash
git bisect
wc -l ...
look
think
git bisect good/bad
```

Instead, Git can execute your test automatically.

You give Git:

```bash
git bisect run ./test.sh
```

Git effectively does:

```text
checkout commit X
        ↓
./test.sh
        ↓
exit code?
        ↓
0 → good
1+ → bad
        ↓
checkout next commit
        ↓
repeat
```

That's the whole idea.

---

# 3. The most important concept: exit status

This is the part you **really need to understand**.

Every Unix/Linux command finishes with an **exit status**.

You can see it with:

```bash
echo $?
```

For example:

```bash
true
echo $?
```

Output:

```text
0
```

And:

```bash
false
echo $?
```

Output:

```text
1
```

The convention is:

```text
0       = success
non-zero = failure/error
```

This is incredibly important in Linux.

---

# 4. Why does `git bisect` care about exit codes?

Because Git needs a machine-readable answer.

You could tell Git:

```text
"Hey, this commit is bad."
```

But a shell script can't literally communicate that sentence to Git.

Instead:

```text
exit 0
```

means:

```text
GOOD
```

and:

```text
exit 1
```

means:

```text
BAD
```

So:

```text
Shell script
     │
     ├── exit 0 ──────→ Git: GOOD
     │
     └── exit 1+ ─────→ Git: BAD
```

That's the bridge between shell scripting and `git bisect`.

---

# 5. Your first bisect script

Let's recreate your previous test.

You were checking:

```bash
wc -l scripts/scan.sh
```

Suppose our definition is:

```text
1 line  → good
10 lines → bad
```

We could write:

```sh
#!/bin/sh

lines=$(wc -l < scripts/scan.sh)

if [ "$lines" -eq 1 ]; then
    exit 0
else
    exit 1
fi
```

Let's understand **every line**.

---

# 6. `#!/bin/sh`

```sh
#!/bin/sh
```

This is called a **shebang**.

It tells Linux:

> Execute this script using `/bin/sh`.

For example:

```sh
#!/bin/bash
```

means:

> Use Bash.

Whereas:

```sh
#!/bin/sh
```

means:

> Use the system's POSIX shell at `/bin/sh`.

For portable scripts, `/bin/sh` is often preferred.

---

# 7. Command substitution

This line:

```sh
lines=$(wc -l < scripts/scan.sh)
```

is extremely important shell syntax.

The:

```sh
$(...)
```

means:

> Execute this command and substitute its output here.

For example:

```bash
name=$(whoami)
```

If:

```bash
whoami
```

returns:

```text
ethan
```

then:

```text
name
```

contains:

```text
ethan
```

So:

```sh
lines=$(wc -l < scripts/scan.sh)
```

means:

```text
run wc -l
      ↓
capture its output
      ↓
store it in variable "lines"
```

---

# 8. Why `< scripts/scan.sh`?

You could write:

```bash
wc -l scripts/scan.sh
```

and get:

```text
10 scripts/scan.sh
```

But:

```bash
wc -l < scripts/scan.sh
```

gives only:

```text
10
```

That's useful because we want:

```sh
lines=10
```

rather than:

```sh
lines="10 scripts/scan.sh"
```

---

# 9. Variables in shell

We create a variable:

```sh
lines=10
```

Important:

```sh
lines=10
```

NOT:

```sh
lines = 10
```

Shell syntax does not allow spaces around `=`.

To read the variable:

```sh
echo "$lines"
```

The `$` means:

> Give me the value stored in this variable.

---

# 10. `if`

Our script:

```sh
if [ "$lines" -eq 1 ]; then
    exit 0
else
    exit 1
fi
```

This means:

```text
IF lines equals 1
    return GOOD
ELSE
    return BAD
```

The shell syntax is:

```sh
if [ condition ]; then
    commands
else
    commands
fi
```

Notice:

```sh
fi
```

is simply `if` backwards.

---

# 11. What is `[ ... ]`?

This:

```sh
[ "$lines" -eq 1 ]
```

is shell test syntax.

It asks:

> Is `$lines` numerically equal to `1`?

`-eq` means:

```text
equal
```

Some important operators:

```text
-eq    equal
-ne    not equal
-lt    less than
-le    less than or equal
-gt    greater than
-ge    greater than or equal
```

Example:

```sh
[ "$lines" -gt 5 ]
```

means:

```text
lines > 5
```

---

# 12. Now connect this to Git Bisect

Our complete script:

```sh
#!/bin/sh

lines=$(wc -l < scripts/scan.sh)

if [ "$lines" -eq 1 ]; then
    exit 0
else
    exit 1
fi
```

Make it executable:

```bash
chmod +x test.sh
```

Test it manually:

```bash
./test.sh
echo $?
```

If the current commit has one line:

```text
0
```

Git interprets:

```text
0 → GOOD
```

If the current commit has ten lines:

```text
1
```

Git interprets:

```text
1 → BAD
```

---

# 13. Now use it with `git bisect`

Start:

```bash
git bisect start
```

Tell Git your known bad commit:

```bash
git bisect bad b6c5f1b
```

Tell Git your known good commit:

```bash
git bisect good 0d16f95
```

Then:

```bash
git bisect run ./test.sh
```

Now **you don't manually classify anything**.

Git does:

```text
                 Git bisect
                     │
                     ▼
              choose midpoint
                     │
                     ▼
              checkout commit
                     │
                     ▼
                 ./test.sh
                     │
              ┌──────┴──────┐
              │             │
           exit 0         exit != 0
              │             │
            GOOD           BAD
              │             │
              └──────┬──────┘
                     ▼
              choose next midpoint
                     │
                     ▼
                   repeat
```

Eventually:

```text
<commit> is the first bad commit
```

---

# 14. The script does NOT need to print "good" or "bad"

This is a common misunderstanding.

This is **not necessary**:

```sh
echo "GOOD"
```

or:

```sh
echo "BAD"
```

Git primarily cares about:

```text
exit status
```

You can print information for yourself:

```sh
echo "Lines: $lines"
```

but the important part is:

```sh
exit 0
```

or:

```sh
exit 1
```

---

# 15. A much more realistic example

Your line-count test is useful for learning, but in real software development you normally don't test:

```text
"Does this file have 10 lines?"
```

You test the **actual bug**.

For example, suppose your Java application should successfully execute:

```bash
./gradlew test
```

You could make:

```sh
#!/bin/sh

./gradlew test
```

That's already potentially enough.

Why?

Because Gradle returns an exit code.

If tests pass:

```text
exit 0
```

If tests fail:

```text
exit non-zero
```

Therefore:

```bash
git bisect run ./test.sh
```

can automatically find the commit that introduced the failing test.

This is much closer to how bisect is used professionally.

---

# 16. Even simpler

You don't necessarily need a separate script.

For example:

```bash
git bisect run ./gradlew test
```

Git can execute the command directly.

Or:

```bash
git bisect run sh -c 'test -f scripts/scan.sh'
```

But scripts become much more useful when your test requires multiple operations.

---

# 17. Example: test an HTTP endpoint

Imagine your Spring Boot application should return:

```text
200 OK
```

You could write:

```sh
#!/bin/sh

curl --fail http://localhost:8080/api/tasks
```

`curl --fail` returns a non-zero status when the HTTP request fails.

So:

```text
HTTP 200
   ↓
curl exit 0
   ↓
GOOD
```

versus:

```text
HTTP 500
   ↓
curl non-zero
   ↓
BAD
```

Then:

```bash
git bisect run ./test-api.sh
```

Now Git is finding:

> Which commit first caused this endpoint to fail?

That's a genuinely useful application of bisect.

---

# 18. Shell scripting mental model

You should start thinking about shell scripts as **programs whose primary job is often orchestrating other programs**.

For example:

```sh
#!/bin/sh

./gradlew test

if [ $? -eq 0 ]; then
    echo "Tests passed"
    exit 0
else
    echo "Tests failed"
    exit 1
fi
```

The shell is coordinating:

```text
Shell
 │
 ├── starts Gradle
 │
 ├── receives Gradle's exit code
 │
 ├── makes a decision
 │
 └── returns its own exit code
```

This is why exit codes are fundamental to Linux automation.

---

# 19. One important improvement

You will often see:

```sh
./gradlew test

if [ $? -eq 0 ]; then
```

But you don't always need to inspect `$?` manually.

You can simply do:

```sh
if ./gradlew test; then
    exit 0
else
    exit 1
fi
```

The `if` directly evaluates the command's exit status.

This is cleaner.

---

# 20. Professional version

For your Java project:

```sh
#!/bin/sh

./gradlew test
```

That's potentially all your bisect script needs.

Then:

```bash
chmod +x bisect-test.sh
```

and:

```bash
git bisect start
git bisect bad HEAD
git bisect good <known-good-commit>
git bisect run ./bisect-test.sh
```

At the end:

```bash
git bisect reset
```

---

# 21. The deeper connection

You should see that **Git Bisect itself isn't really doing the testing**.

Git Bisect is only doing the **search**.

Your script is doing the **verification**.

```text
                  GIT BISECT
                      │
             "Which commit?"
                      │
                      ▼
              checkout commit
                      │
                      ▼
              YOUR TEST SCRIPT
                      │
                "Does bug exist?"
                      │
              ┌───────┴───────┐
              │               │
            exit 0          exit != 0
              │               │
             GOOD             BAD
              │               │
              └───────┬───────┘
                      ▼
              Git narrows search
```

So the division of responsibility is:

```text
Git       → binary search
Shell     → execute test
Your test → determine behavior
Exit code → communicate result
```

That is the core concept.

---

## What you should learn next

Before writing complicated bisect scripts, master these shell fundamentals:

1. **Commands and exit codes**
    
2. **Variables**
    
3. **Command substitution `$(...)`**
    
4. **`if / else / fi`**
    
5. **`[ ... ]` tests**
    
6. **`&&` and `||`**
    
7. **Arguments: `$1`, `$2`, `$@`**
    
8. **`for` / `while` loops**
    
9. **Functions**
    
10. **`grep`, `sed`, `awk`, `find`**
    
11. **Pipes `|` and redirection `>`, `<`, `>>`**
    
12. **Writing reliable `git bisect run` scripts**
    

Once those are clear, you can turn almost any reproducible regression test into an automated `git bisect` test.


[[Git & Github]]