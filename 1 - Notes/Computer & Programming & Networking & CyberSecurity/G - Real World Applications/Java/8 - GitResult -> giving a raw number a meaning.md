


You already know `record`, `final`/immutability from `Command`, and `execute` returning an exit code from the last exercise. So the focus here is **why** this class exists and what each piece of its structure means.

## The mental model

A doctor's lab test returns `7.2`. By itself that number is meaningless. A **lab report** says _"7.2: normal"_ and hides the range-checking from you.

`GitResult` is that lab report. Instead of returning a bare `int` (where every caller must remember "0 means success"), you return an object that **knows what the number means**:

```java
// before: every caller must know the convention
int code = git.execute("status");
if (code == 0) { ... }

// after: the meaning lives in one place
GitResult result = git.execute("status");
if (result.isSuccess()) { ... }
```

This idea is called a **value object**: a small, immutable object that represents a value and carries the logic that belongs to it.

## Piece by piece

### `private final int exitCode;`

- `private`: nobody outside the class can touch it. This is **encapsulation**. If you later change how the result is stored, callers don't break.
- `final`: it can be assigned exactly once, and only in the constructor. After construction it can never change. So a `GitResult` is **immutable**: safe to pass around and share between threads, and nobody can secretly flip a failure into a success.

### The constructor

```java
public GitResult(int exitCode) {
    this.exitCode = exitCode;
}
```

`this.exitCode` is the field, and `exitCode` alone is the parameter. They have the same name, so `this.` disambiguates. The constructor is the only place a `final` field may be set, and the compiler enforces that every `final` field is set exactly once.

### `getExitCode()`

A **getter**: read-only access to a private field. There is no setter, on purpose, because immutability means no way to change it. The `getX` naming is the **JavaBeans convention**, which matters a lot in Spring (see below).

### `isSuccess()`: the interesting one

```java
public boolean isSuccess() {
    return exitCode == 0;
}
```

Notice there is **no `success` field**. This is a **derived property**: computed from existing data on demand. Benefits:

- **Single source of truth.** If you stored a separate `boolean success`, the two fields could disagree (`exitCode=1, success=true`). A computed value can never be inconsistent.
- The convention "0 = success" (universal Unix convention, as we saw earlier) is written **once**, not scattered across your codebase.
- Boolean getters use `is` instead of `get` by convention.

## How it plugs into what you've built

The natural next step is your exercise from `GitExecutor`, upgraded:

```java
public GitResult execute(String... arguments) throws IOException, InterruptedException {
    List<String> command = new ArrayList<>();
    command.add("git");
    command.addAll(Arrays.asList(arguments));

    Process process = new ProcessBuilder(command).inheritIO().start();
    return new GitResult(process.waitFor());
}
```

And in `main`:

```java
GitResult result = new GitExecutor().execute("status");
System.exit(result.getExitCode());
```

Now the executor doesn't print anything. It reports, and the caller decides.

## The modern equivalent: a `record`

Since you learned records, here is the same class in one line:

```java
public record GitResult(int exitCode) {
    public boolean isSuccess() {
        return exitCode == 0;
    }
}
```

What the record generates for free: the `private final` field, the constructor, an accessor named `exitCode()` (no `get` prefix), plus `equals`, `hashCode`, and `toString`. You still write `isSuccess()` yourself.

So why does the class version exist? It is the classic pre-Java-16 style, and you'll see it in a huge amount of real code. Understanding it is what lets you understand what the record automates.

## Nuances and gotchas

1. **No `toString`, `equals`, or `hashCode`.** Printing a `GitResult` gives something like `com.gex.git.GitResult@1b6d3586`, and two results with the same code are **not equal** (`==` and the default `equals` compare identity). A record fixes both automatically.
2. **`final` is shallow.** It guarantees the _reference_ can't change, not that the object it points to is unmodifiable. That's harmless for an `int`, but if you later add `private final List<String> output`, callers could still modify the list unless you copy it (`List.copyOf`, as in `Command`).
3. **Exit codes are richer than success/failure.** Git uses `1` for many ordinary "no" answers (e.g. `git diff --exit-code` when differences exist) and `128` for fatal errors. Any code above 128 on Linux usually means the process was killed by a signal (`128 + signal number`, so `137` is SIGKILL). `isSuccess()` deliberately collapses all that, and you can add more precise methods later.
4. **Validation.** Exit codes on Linux are 0 to 255. The constructor could reject values outside that range, but only if you decide invalid input should be impossible.
5. **Why not just return `boolean`?** Because you'd throw away information. A result object is **extensible**: you can add fields without changing any method signature.

## Growing it (this is where the class earns its keep)

Once you capture output instead of inheriting IO (recall the pipe discussion), the same class expands naturally:

```java
public record GitResult(int exitCode, String output, String error) {
    public boolean isSuccess() { return exitCode == 0; }
}
```

Every existing `result.isSuccess()` call keeps working. That is the payoff of wrapping a raw `int`.

## Connection to Spring Boot

- **JavaBeans naming (`getX`/`isX`) is not just style.** Spring and its JSON library (Jackson) discover properties by these names. If you returned a `GitResult` from a REST controller, Jackson would call `getExitCode()` and `isSuccess()` and produce `{"exitCode":0,"success":true}`. Note that `success` appears in the JSON even though no field has that name, because it is derived from the getter.
- Immutable value objects like this (often written as records or DTOs) are the standard way Spring apps pass data between layers: controller, service, and repository all exchange small objects like this instead of raw primitives.




[[Java]]