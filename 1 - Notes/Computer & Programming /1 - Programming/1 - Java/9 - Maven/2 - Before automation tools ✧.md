


Imagine you had a Java project in the early days:

```text
MyApp/
├── src/
│   └── com/example/App.java
└── lib/
    ├── junit.jar
    ├── mysql-driver.jar
    └── logging.jar
```

You might manually have to:

**1. Download libraries**

```text
Go to website
→ download JAR
→ put JAR in lib/
```

**2. Construct the classpath**

Something like:

```bash
javac -cp "lib/*" src/com/example/*.java
```

As the project grew, this became painful.

**3. Compile everything**

```bash
javac ...
```

You had to know exactly which source files and options needed compiling.

**4. Run tests**

You had to configure the test framework and invoke it yourself.

**5. Package the application**

You might manually create a JAR:

```bash
jar cf MyApp.jar ...
```

and make sure the correct files were included.

**6. Make sure everyone had the same dependencies**

This was a major problem.

Developer A:

```text
logging.jar 1.2
```

Developer B:

```text
logging.jar 1.3
```

Developer C:

```text
logging.jar 1.1
```

Now you get:

> "Works on my machine."

---

# The bigger problem: reproducibility

This is probably the most important concept.

Suppose your project needs:

```text
Spring 6.x
Jackson 2.x
PostgreSQL driver
JUnit
```

You don't want every developer to remember:

```text
Download this
Copy that
Use this version
Compile with these flags
Run these tests
Package these files
```

Instead, you describe the project:

```text
This project needs:

Spring = version X
Jackson = version Y
PostgreSQL driver = version Z
Java = version N
```

Then Maven/Gradle performs the procedure.

```text
                 pom.xml
                    │
                    ▼
             Maven interprets it
                    │
       ┌────────────┼────────────┐
       ▼            ▼            ▼
 dependencies    compile       tests
       │            │            │
       └────────────┼────────────┘
                    ▼
                  JAR
```

Now another developer can clone the repository and do:

```bash
mvn package
```

instead of learning your entire manual build procedure.

---

# And this existed before Maven too

Build automation itself isn't new.

Unix developers were already doing this with tools such as **Make**.

For example:

```bash
make
```

could understand:

```text
source.c
   ↓
compiler
   ↓
object file
   ↓
linker
   ↓
program
```

And only rebuild things that changed.

That's the fundamental idea behind build automation:

> **Describe how the software should be built, then let a machine execute that procedure consistently.**

Maven later brought this philosophy into the Java ecosystem with standardized project structure, dependency management, lifecycle phases, plugins, etc.

---

### So the evolution is roughly:

```text
Manual commands
      ↓
Make / shell scripts
      ↓
Java build tools
(Ant)
      ↓
Maven
      ↓
Gradle
```

The problem wasn't simply **"developers were lazy and wanted dependency downloads automated."**

The real problem was:

> **As software projects became larger, manually coordinating compilation, dependencies, tests, packaging, and releases became error-prone, inconsistent, and difficult to reproduce.**

That's why build tools became important.


[[1 - Maven ✧]]