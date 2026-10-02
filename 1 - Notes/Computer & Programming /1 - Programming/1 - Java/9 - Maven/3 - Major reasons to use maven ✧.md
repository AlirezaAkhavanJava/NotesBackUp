

### 1. Dependency version management

Instead of manually managing:

```text
lib/
├── spring-x.jar
├── jackson-y.jar
└── postgresql-z.jar
```

you declare versions in Maven:

```xml
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <version>...</version>
</dependency>
```

Maven then resolves and downloads the required dependency **and its transitive dependencies**.

This gives you a reproducible dependency graph.

---

### 2. Build output

Maven creates a standard output directory:

```text
target/
├── classes/
│   └── com/example/App.class
├── test-classes/
│   └── ...
└── my-app.jar
```

The important distinction:

```text
.java source
    ↓
javac
    ↓
.class bytecode
    ↓
package
    ↓
.jar artifact
```

So `target/classes/` contains your **compiled classes**, while the `.jar` is the **packaged artifact**.

---

### 3. The artifact

For example:

```bash
mvn package
```

can produce:

```text
target/
└── my-app-1.0.jar
```

That JAR is what you can distribute:

```bash
java -jar target/my-app-1.0.jar
```

For a Spring Boot application, the JAR can be an **executable/fat JAR** containing your application plus the required dependencies.

So your mental model is basically:

```text
                Maven
                  │
       ┌──────────┼──────────┐
       ↓          ↓          ↓
 Dependencies  Compile     Test
       │          │          │
       └──────────┼──────────┘
                  ↓
              Package
                  ↓
             target/app.jar
                  ↓
            Deploy / Run
```

And there's a third major thing worth adding: **Maven standardizes the entire build lifecycle** — `validate → compile → test → package → verify → install → deploy`. That's what makes Maven much more than just a dependency manager.


[[Maven]]