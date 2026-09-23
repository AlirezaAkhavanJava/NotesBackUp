

We've mentioned the Spring Boot Maven Plugin, Surefire, and a few others throughout previous tutorials without formally explaining what a **plugin** actually is in Maven's architecture. Let's fix that — plugins are, in a real sense, _all Maven actually does_. Understanding them demystifies a lot of what feels like "magic" in your builds.

---

## 1. The Core Idea — Maven Itself Does Almost Nothing

This might be surprising: **Maven's core has no built-in ability to compile Java, run tests, or package a jar.** All of that functionality comes from **plugins**. Maven core is really just:

1. A dependency resolution engine
2. A lifecycle/phase runner
3. A plugin execution framework

Every actual unit of work — compiling, testing, packaging — is a **goal**, provided by a **plugin**, bound to a **phase**. We touched this relationship in the Maven lifecycle tutorial; now let's look at plugins as first-class citizens.

```
Phase: compile
   └── bound to goal: compiler:compile
         └── provided by: maven-compiler-plugin

Phase: test
   └── bound to goal: surefire:test
         └── provided by: maven-surefire-plugin

Phase: package
   └── bound to goal: jar:jar (or spring-boot:repackage)
         └── provided by: maven-jar-plugin (or spring-boot-maven-plugin)
```

Every one of these plugins is downloaded from Maven Central just like a regular dependency — they just serve a different purpose (build-time tooling, not runtime code your app calls).

---

## 2. Two Categories of Plugins

|Category|Purpose|Where declared|
|---|---|---|
|**Build plugins**|Run during the build itself (compiling, testing, packaging)|`<build><plugins>`|
|**Reporting plugins**|Generate documentation/reports (rarely used day-to-day)|`<reporting><plugins>`|

You'll almost exclusively work with **build plugins** — that's the focus here.

---

## 3. Plugins You're Already Using Implicitly

Even a bare-minimum `pom.xml` uses several **default-bound** plugins you never explicitly declared — they're wired into the `default` lifecycle by Maven itself. Worth naming them so you know what's actually running:

|Plugin|Bound to phase|What it does|
|---|---|---|
|`maven-compiler-plugin`|`compile`, `test-compile`|Compiles your `.java` files|
|`maven-resources-plugin`|`process-resources`|Copies `src/main/resources` → `target/classes`|
|`maven-surefire-plugin`|`test`|Runs your unit tests (JUnit)|
|`maven-jar-plugin`|`package`|Bundles compiled classes into a plain `.jar`|
|`maven-install-plugin`|`install`|Copies the jar into your local `~/.m2` repository|

You never see these in your `pom.xml` because they're implicitly bound — but running `./mvnw compile` is really Maven invoking `maven-compiler-plugin:compile` behind the scenes.

---

## 4. Explicitly Declared Plugins — What You Actually Write

You override or add plugins in the `<build><plugins>` section when the default behavior isn't enough — this is where Spring Boot projects always add at least one plugin.

### a) `spring-boot-maven-plugin` — the one every Spring Boot project needs

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
    </plugins>
</build>
```

This plugin does two critical things, both tied to the `package` phase:

**1. Repackages your jar into an executable "fat jar."** Without this, `mvn package` (via the default `maven-jar-plugin`) produces a jar containing _only your own compiled classes_ — running `java -jar app.jar` would immediately throw `ClassNotFoundException`, because Spring, Tomcat, Jackson, etc. wouldn't be inside it. The Spring Boot plugin's `repackage` goal bundles every dependency into one self-contained, runnable jar.

**2. Enables `./mvnw spring-boot:run`** — direct goal invocation (bypassing the full package lifecycle) for fast local development, running your app straight from compiled classes without producing a jar at all.

```bash
./mvnw spring-boot:run    # dev loop — fast, no jar produced
./mvnw package             # produces the deployable fat jar
```

---

## 5. Configuring a Plugin — The `<configuration>` Block

Plugins have sensible defaults, but you can override specific behavior via `<configuration>`. Two common, practical examples:

### Setting the Java version explicitly (compiler plugin)

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <configuration>
        <source>21</source>
        <target>21</target>
    </configuration>
</plugin>
```

In a Spring Boot project with the `<parent>` set, you usually don't need this — the `<properties><java.version>21</java.version></properties>` block from our earlier Maven tutorial is read by the parent's own plugin configuration automatically. You'd only add this explicit block if you're _not_ using the Spring Boot parent, or need to override its default.

### Skipping tests during certain builds (Surefire plugin)

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-surefire-plugin</artifactId>
    <configuration>
        <skipTests>${skip.tests}</skipTests>
    </configuration>
</plugin>
```

(Though for occasional skipping, the command-line flag `-DskipTests` we saw in the Maven tutorial is simpler than baking it into the pom.)

---

## 6. Binding a Plugin Goal to a Different Phase

Sometimes you want a plugin's goal to run at a phase it's _not_ bound to by default. You do this with an `<executions>` block:

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-checkstyle-plugin</artifactId>
    <executions>
        <execution>
            <id>check-style</id>
            <phase>verify</phase>
            <goals>
                <goal>check</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

This says: _during the `verify` phase, run Checkstyle's `check` goal._ Now `./mvnw verify` (or anything that triggers `verify`, like `install`) automatically enforces your code style rules as part of the normal build — fail the build if style violations exist, rather than requiring a separate manual step.

---

## 7. Practical Plugins Worth Knowing (Beyond Spring Boot's Own)

These connect to things we've already discussed across earlier tutorials — now you can see them as the actual plugin mechanism making them work.

### Lombok annotation processing (via the compiler plugin)

We've used `@RequiredArgsConstructor`, `@Getter`, etc. throughout — these work because `maven-compiler-plugin` runs Lombok as an **annotation processor** during compilation, generating boilerplate code before your `.class` files are produced. Usually this "just works" once Lombok is declared as a dependency; no extra plugin config needed in modern Maven/Lombok versions.

### `spotless` — the formatter we mentioned in the Coding Style tutorial

```xml
<plugin>
    <groupId>com.diffplug.spotless</groupId>
    <artifactId>spotless-maven-plugin</artifactId>
    <version>2.43.0</version>
    <configuration>
        <java>
            <googleJavaFormat/>
        </java>
    </configuration>
</plugin>
```

```bash
./mvnw spotless:apply    # auto-formats your code
./mvnw spotless:check    # fails the build if code isn't formatted correctly
```

### `springdoc-openapi` — actually a dependency, not a plugin

Worth clarifying since we mentioned it in the REST API tutorial: `springdoc-openapi-starter-webmvc-ui` is a regular runtime **dependency** (it runs _inside_ your app, generating docs at runtime when you hit `/swagger-ui.html`), not a build-time plugin. Easy to conflate the two — the distinction is: plugins do work _during the build_; dependencies are code your _running app_ uses.

### `jacoco` — test coverage reporting

```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.12</version>
    <executions>
        <execution>
            <goals><goal>prepare-agent</goal></goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals><goal>report</goal></goals>
        </execution>
    </executions>
</plugin>
```

Generates an HTML report (`target/site/jacoco/index.html`) showing exactly which lines of your code your tests actually exercise — genuinely useful once you start writing real test suites for `BookService`, `LoanService`, etc.

---

## 8. Finding Plugin Coordinates and Goals

Same approach as finding dependency coordinates (mentioned in the Maven tutorial) — [mvnrepository.com](https://mvnrepository.com/) lists plugin versions too. Additionally, you can inspect a plugin's available goals directly from the command line:

```bash
./mvnw help:describe -Dplugin=org.springframework.boot:spring-boot-maven-plugin -Dgoal=repackage
```

This prints the goal's full description, parameters, and defaults — useful when a plugin's documentation is thin or you want to confirm exact behavior before adding `<configuration>`.

---

## 9. Full Example — A Realistic `<build>` Section for the Library App

Pulling together everything from this and earlier tutorials into one realistic block:

```xml
<build>
    <plugins>
        <!-- Makes the jar runnable, enables spring-boot:run -->
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>

        <!-- Auto-formatting, enforced at build time -->
        <plugin>
            <groupId>com.diffplug.spotless</groupId>
            <artifactId>spotless-maven-plugin</artifactId>
            <version>2.43.0</version>
            <configuration>
                <java>
                    <googleJavaFormat/>
                </java>
            </configuration>
            <executions>
                <execution>
                    <phase>verify</phase>
                    <goals><goal>check</goal></goals>
                </execution>
            </executions>
        </plugin>

        <!-- Test coverage reporting -->
        <plugin>
            <groupId>org.jacoco</groupId>
            <artifactId>jacoco-maven-plugin</artifactId>
            <version>0.8.12</version>
            <executions>
                <execution>
                    <goals><goal>prepare-agent</goal></goals>
                </execution>
                <execution>
                    <id>report</id>
                    <phase>test</phase>
                    <goals><goal>report</goal></goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

Now `./mvnw clean verify` — compiles, tests, checks formatting, generates a coverage report, and packages — a fully automated, self-checking build pipeline, driven entirely by plugins bound to phases.

---

## 10. Quick Reference Table

|Plugin|Purpose|Typically bound to|
|---|---|---|
|`maven-compiler-plugin`|Compiles Java source|`compile` (implicit)|
|`maven-surefire-plugin`|Runs unit tests|`test` (implicit)|
|`maven-jar-plugin`|Packages a plain jar|`package` (implicit)|
|`spring-boot-maven-plugin`|Repackages into executable fat jar; enables `spring-boot:run`|`package`|
|`spotless-maven-plugin`|Enforces code formatting|usually `verify` (manual binding)|
|`jacoco-maven-plugin`|Test coverage reports|`test` (manual binding)|
|`maven-checkstyle-plugin`|Enforces code style rules|usually `verify` (manual binding)|

---

## Quick Summary

1. Maven's core does almost nothing on its own — **plugins provide every real capability** (compiling, testing, packaging)
2. A **goal** is one unit of work a plugin performs; goals get **bound** to lifecycle phases, by default or explicitly via `<executions>`
3. `spring-boot-maven-plugin` is the one plugin every Spring Boot project needs — it's what makes `java -jar app.jar` actually work, by bundling all dependencies into one executable jar
4. Use `<configuration>` to override a plugin's default behavior; use `<executions>` to bind a goal to a phase it isn't bound to by default
5. Plugins run _during the build_; dependencies run _inside your app_ — don't confuse the two (e.g., `springdoc-openapi` is a dependency, not a plugin)

---




[[1 - Maven 👻]]
[[Java]]
[[0 - Spring Framework]]