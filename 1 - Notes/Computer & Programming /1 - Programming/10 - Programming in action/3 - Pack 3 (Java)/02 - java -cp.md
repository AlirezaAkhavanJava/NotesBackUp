
# `java -cp`: telling the JVM where to look

## The mental model

The JVM is a **librarian** who loads classes on demand. When your code says "I need class `com.gex.GexApplication`", the librarian has to know which shelves to search. **The classpath is that list of shelves.** `-cp` is how you hand the librarian the list.

A shelf can be:
- a **directory** containing `.class` files (like your `out/` folder)
- a **JAR file** (a zip of `.class` files, which is how libraries are shipped)

## Core syntax

```bash
java -cp out com.gex.GexApplication hello
#    ^^^^^^^ ^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^
#    where   which class to start    args → main(String[] args)
#    to look
```

`-cp`, `-classpath`, and `--class-path` are all the same option. Everything **before** the class name is for the JVM, and everything **after** it goes to your `args`. Swapping them is a classic mistake.

## How the lookup works

The JVM turns the fully qualified name into a path and tries it under each classpath entry:

```
com.gex.GexApplication  →  com/gex/GexApplication.class
```

With `-cp out`, it looks for `out/com/gex/GexApplication.class`. This is why the package must match the folder structure: the package name **is** the path.

## Multiple entries

On Linux, separate entries with a **colon** (Windows uses `;`):

```bash
java -cp out:lib/gson-2.10.jar:. com.gex.GexApplication
```

Three shelves are searched **in order**, and the **first match wins**. If two JARs contain the same class, the earlier one shadows the later one. This is the cause of many "works on my machine" bugs.

## Wildcards

```bash
java -cp "out:lib/*" com.gex.GexApplication
```

`lib/*` means every `.jar` in `lib`. Two gotchas:
- **Quote it.** Otherwise the shell expands `*` into a list of files before Java sees it, and the command breaks.
- It matches only `.jar` files, and it is **not recursive**.

## The default classpath, and how `-cp` replaces it

With no `-cp` (and no `CLASSPATH` environment variable), the classpath defaults to `.`, the current directory. Once you pass `-cp`, it **replaces** the default entirely. So `-cp lib/x.jar` no longer searches the current directory unless you add `:.` yourself.

## A concrete experiment

Suppose you use Gson (a JSON library) in your code:

```bash
# compile: javac also needs the classpath, to check your imports
javac -cp lib/gson-2.10.jar -d out src/com/gex/GexApplication.java

# run: the JVM needs it again at runtime
java -cp out:lib/gson-2.10.jar com.gex.GexApplication
```

Two separate programs, `javac` and `java`, each need to be told where the libraries are. Forgetting it at runtime is the most common beginner error.

## Reading the errors

| Error | Meaning |
|---|---|
| `Error: Could not find or load main class com.gex.GexApplication` | The librarian couldn't find the *starting* class: wrong `-cp`, wrong package name, or you ran from the wrong directory. |
| `ClassNotFoundException` | Code asked for a class **by name at runtime** (e.g. `Class.forName`) and it wasn't on any shelf. |
| `NoClassDefFoundError` | The class existed at **compile time** but is missing at **runtime**. This usually means you forgot a JAR in `-cp`. |

## Nuances

1. **`-jar` ignores `-cp`.** With `java -jar app.jar`, the classpath comes from the JAR's own manifest (`Class-Path:` entry), and `-cp` is silently ignored.
2. **JDK classes aren't on your classpath.** `String`, `System`, and so on are loaded from the JDK's own modules, so you never list them.
3. **The `CLASSPATH` environment variable** does the same job, but it is global and invisible, which makes it fragile. Prefer explicit `-cp`.
4. **Java 9+ added a second mechanism**, the module path (`--module-path`), for the module system. The classpath is still what nearly all projects, Spring Boot included, use.

## Connection to Spring Boot

You will rarely type `-cp` yourself, because **Maven and Gradle build the classpath for you**. Spring Boot has 50+ dependency JARs, and hand-writing that list would be miserable. You can see what Maven builds:

```bash
mvn dependency:build-classpath
```

When you package a Boot app as a "fat JAR", the dependencies live *inside* it (`BOOT-INF/lib/`), and Spring's own launcher builds the classpath at startup. That is why `java -jar app.jar` works with no `-cp`.

Understanding `-cp` explains what every build tool is doing under the hood.

Say **next** when this is clear.


[[Java]]