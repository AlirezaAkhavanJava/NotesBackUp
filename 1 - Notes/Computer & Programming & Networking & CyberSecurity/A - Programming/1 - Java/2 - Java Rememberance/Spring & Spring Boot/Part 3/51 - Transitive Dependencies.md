

We touched on this briefly in the Maven tutorial. It deserves its own deep dive because it's one of those concepts that seems simple ("dependencies of dependencies") but causes real, confusing bugs once your project grows — and understanding it properly will save you hours of debugging later.

---

## 1. The Core Idea

A **transitive dependency** is a dependency of your dependency — a library you never explicitly declared in your `pom.xml`, but that gets pulled onto your classpath anyway because something you _did_ declare needs it.

```
Your project
  └── declares: spring-boot-starter-web
        └── which needs: spring-webmvc
              └── which needs: spring-core
                    └── which needs: ...
```

You wrote **one line** in your `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

But Maven silently resolves and downloads dozens of jars underneath it — Tomcat, Jackson, Spring MVC, Spring Core, and more — none of which you wrote yourself. **This is transitive dependency resolution**, and it's the entire reason Spring Boot "starter" dependencies work the way they do.

---

## 2. Why This Design Exists

Without transitive resolution, every `pom.xml` would need to manually list _every single library in the entire dependency chain_ — which would be unmanageable and would break constantly (imagine having to know that Spring MVC needs exactly Jackson 2.17.1, and updating that by hand every time Spring changes it).

Transitive dependencies let library authors bundle what their library needs, and consumers (you) just declare the top-level thing they actually care about. This is precisely why `spring-boot-starter-web` is called a "starter" — it's not really a library with its own code; it's mostly a curated list of transitive dependencies bundled under one convenient name.

---

## 3. Seeing the Full Tree

You don't have to guess what's being pulled in — Maven can show you the entire resolved tree:

```bash
./mvnw dependency:tree
```

Example output (abbreviated):

```
com.example:library-app:jar:1.0.0
├── org.springframework.boot:spring-boot-starter-web:jar:3.3.0
│   ├── org.springframework.boot:spring-boot-starter:jar:3.3.0
│   │   ├── org.springframework.boot:spring-boot:jar:3.3.0
│   │   └── org.springframework:spring-core:jar:6.1.8
│   ├── org.springframework.boot:spring-boot-starter-tomcat:jar:3.3.0
│   │   └── org.apache.tomcat.embed:tomcat-embed-core:jar:10.1.24
│   └── com.fasterxml.jackson.core:jackson-databind:jar:2.17.1
├── org.springframework.boot:spring-boot-starter-data-jpa:jar:3.3.0
│   ├── org.hibernate.orm:hibernate-core:jar:6.5.2.Final
│   └── ...
```

Every indented entry is a **transitive** dependency — pulled in automatically, declared by no one in your own `pom.xml`. Running this command on a real project is genuinely eye-opening the first time; a simple Spring Boot web app easily resolves 60-100+ jars total, from maybe 5-8 lines you actually wrote.

---

## 4. The Real Problem: Version Conflicts (Diamond Dependency)

Here's where transitive dependencies stop being free convenience and start requiring your attention.

Imagine two of your direct dependencies both transitively depend on the same library, but at **different versions**:

```
Your project
  ├── LibraryA → needs jackson-databind 2.15.0
  └── LibraryB → needs jackson-databind 2.17.1
```

This is called the **diamond dependency problem** — two paths converge on the same artifact with conflicting versions. Maven can only put **one** version of `jackson-databind` on the classpath. Which one wins?

### Maven's resolution rule: "nearest wins"

Maven picks whichever version is **closest to your project** in the dependency tree (fewest hops away). If both are equally close, the one declared **first** in your `pom.xml` wins.

```
Your project
  ├── LibraryA (direct, distance 1) → jackson-databind 2.15.0   ← wins (closer)
  └── LibraryB (direct, distance 1)
        └── LibraryC (transitive, distance 2) → jackson-databind 2.17.1
```

Here `2.15.0` wins because it's one level closer to your project than `2.17.1`, which is two levels deep.

**Why this matters practically:** "nearest wins" doesn't mean "best version wins" or "newest version wins" — it's purely about tree distance. This can silently give you an _older_ version of a library than you'd want, with no error or warning — the build succeeds, but you might hit a bug that was already fixed in the newer version, or a method that doesn't exist yet in the older one.

---

## 5. Diagnosing Version Conflicts

When something behaves strangely — a `NoSuchMethodError` or `ClassNotFoundException` at _runtime_ despite compiling fine — a version conflict from transitive dependencies is one of the most common causes. `NoSuchMethodError` specifically is a strong signal: code compiled against one version of a class, but a _different_ version ended up on the runtime classpath.

### Step 1 — see every version of a specific artifact in your tree

```bash
./mvnw dependency:tree -Dincludes=com.fasterxml.jackson.core:jackson-databind
```

This filters the full tree down to just the paths that bring in `jackson-databind`, showing you every version being requested and by what.

### Step 2 — see _why_ a specific dependency was pulled in

```bash
./mvnw dependency:tree -Dverbose
```

The `-Dverbose` flag shows **conflicting versions that were excluded**, marked distinctly — so you can see exactly which version "lost" and why.

---

## 6. Controlling Transitive Dependencies — Three Tools

### a) Explicitly declare the version you want

The simplest fix: if you need a specific version of a transitive dependency, just declare it directly in your own `pom.xml`. A **direct** declaration always wins over anything transitive, regardless of "nearest wins" tree distance:

```xml
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.17.1</version>
</dependency>
```

Now every transitive path resolves to `2.17.1`, because your explicit declaration overrides whatever any transitive chain would have picked.

### b) Dependency Management (the Spring Boot approach — the better solution)

Rather than fixing versions one at a time, you can centralize version control for an entire family of dependencies using `<dependencyManagement>`. This is exactly what `spring-boot-starter-parent` does for you already:

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.3.0</version>
</parent>
```

This parent pom contains a giant `<dependencyManagement>` block (hundreds of entries) pinning compatible versions for the entire Spring ecosystem — Jackson, Hibernate, Tomcat, etc. This is _why_ you never write `<version>` for Spring-related dependencies in your own `pom.xml` — the parent already solved the diamond-dependency problem for you, tested and guaranteed compatible.

If you were managing your own multi-module project, you'd write your own such block:

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
            <version>2.17.1</version>
        </dependency>
    </dependencies>
</dependencyManagement>
```

Note: `<dependencyManagement>` **doesn't add** the dependency to your project — it only sets the version _if and when_ something (directly or transitively) requests that artifact. This is the key difference from a plain `<dependencies>` block.

### c) Exclusions — remove an unwanted transitive dependency entirely

Sometimes you don't want to just override the version — you want to **block** a transitive dependency from being pulled in at all (e.g., a library brings in a logging framework you don't use, and you want your own instead):

```xml
<dependency>
    <groupId>com.example</groupId>
    <artifactId>some-library</artifactId>
    <exclusions>
        <exclusion>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-core</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

A real-world example you'll encounter almost immediately in Spring Boot: excluding the default logging implementation to swap in a different one, or excluding Tomcat if you want to use Jetty instead:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <exclusions>
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-tomcat</artifactId>
        </exclusion>
    </exclusions>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jetty</artifactId>
</dependency>
```

---

## 7. Optional Transitive Dependencies

One more nuance worth knowing: a dependency can mark _its own_ dependencies as `<optional>true</optional>` — meaning **that dependency does not propagate transitively** to consumers of your library, even though it's used internally.

```xml
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
</dependency>
```

This is exactly why Lombok is marked `optional` in the Maven tutorial's example — Lombok is a compile-time-only annotation processor; it has no business being forced onto anyone who depends on _your_ project later. `optional` stops it from leaking downstream.

---

## 8. Practical Debugging Workflow — Putting It Together

When you hit a mysterious runtime error that smells like a version conflict:

```bash
# 1. See the full tree, spot anything suspicious
./mvnw dependency:tree

# 2. Narrow to the specific artifact you suspect
./mvnw dependency:tree -Dincludes=groupId:artifactId

# 3. See what got excluded/conflicted
./mvnw dependency:tree -Dverbose

# 4. Fix it — either:
#    a) declare the version explicitly in your pom.xml, or
#    b) add a <dependencyManagement> entry, or
#    c) exclude the offending transitive dependency and bring in the right version directly
```

---

## Quick Summary

1. **Transitive dependency** = a dependency of your dependency, pulled in automatically — this is _why_ Spring Boot "starters" work with one line in your `pom.xml`
2. Run `./mvnw dependency:tree` to see the entire resolved tree — genuinely useful, use it often
3. **Diamond dependency problem**: two paths pull in different versions of the same library; Maven resolves via **"nearest wins"** (tree distance), not "newest wins"
4. Fix conflicts by: declaring the version **directly** (always wins), using **`<dependencyManagement>`** to centralize versions (what `spring-boot-starter-parent` does for you), or **excluding** an unwanted transitive dependency entirely
5. `<optional>true</optional>` stops a dependency from propagating transitively to anyone who depends on your project





[[Java]]
[[1 - Maven 👻]]
[[0 - Spring Framework]]