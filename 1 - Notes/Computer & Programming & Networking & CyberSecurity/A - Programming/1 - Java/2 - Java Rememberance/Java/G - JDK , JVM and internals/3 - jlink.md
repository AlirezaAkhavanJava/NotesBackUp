


## The problem jlink solves

Before Java 9, if you wanted to run a Java app on a server, you needed the **entire JDK or JRE** installed on that machine — even if your app only used 5% of it. A "Hello World" console app and a huge Swing GUI app both required the same full-sized runtime sitting on disk (100s of MB), because the JDK was monolithic — you couldn't ask for "just the parts I need."

`jlink` exists because Java 9's **module system (JPMS)** finally made the JDK itself modular. Once the JDK was split into pieces (`java.base`, `java.sql`, `java.desktop`, etc. — the modules you saw in `--list-modules`), it became _possible_ to ask: "give me a runtime containing only these modules." `jlink` is the tool that answers that request.

## The mental model: think of it as a custom JRE factory

```lua
Your app's dependencies  +  jlink  →  a brand-new, minimal java runtime folder
   (which modules?)                    (its own bin/java, its own lib/)
```

The output isn't a jar file or a script — it's a **complete, independent JRE directory**, with its own `bin/java` executable. You could delete every trace of Java from a machine, copy this folder over, and `./output/bin/java` would still run. That's the core idea: **the runtime becomes part of your deliverable**, tailored to exactly what your app uses.

## Why this matters, tied to what you already know

Remember the loader hierarchy:

- **Bootstrap loader** → loads `java.base` (native code, non-negotiable, the JVM literally cannot start without it)
- **Platform loader** → loads everything else the JDK ships (`java.sql`, `java.desktop`, `java.xml`...) — these are _modules_, loaded on demand

`jlink` operates exactly along this same seam. It says: "`java.base` always comes along — but for every other module (the ones the Platform loader would normally handle), _you_ tell me whether to include it." That's why understanding the loader split wasn't just trivia — it's literally the boundary `jlink` operates on.

## The three steps, conceptually (not commands yet)

**Step 1 — Figure out what your app actually touches.**  
You can't manually guess which of the ~60 JDK modules your app needs. So there's a companion tool, `jdeps`, whose entire job is to _scan your compiled code_ and report: "this app touches these modules, and only these." Think of `jdeps` as a dependency X-ray for module usage — the same way `imports` at the top of a Java file tell you what packages a class touches, `jdeps` tells you what _modules_ a whole app touches.

**Step 2 — Ask jlink to assemble a runtime from exactly that list.**  
`jlink` takes that module list and copies over only the class data, native libraries, and resources for those modules — nothing else. No modules you don't use ever make it into the output.

**Step 3 — The output is runnable, standalone, and small.**  
Because it's a real JRE folder (not a jar, not a script), you don't need `java` installed on the target machine at all. This is the same category of idea as a statically-linked binary in C — you're not shipping "code that needs a runtime," you're shipping "code + exactly the runtime slice it needs" as one unit.

## Why this wasn't possible before Java 9

Pre-modules, the JDK's classes lived in one giant undifferentiated `rt.jar`. There was no clean boundary saying "these 200 classes are the `java.sql` module and nothing depends on them unless you use JDBC." Everything was just... in there, together. You couldn't slice it because there were no slices — only the module system created the seams that `jlink` cuts along.

## A concrete mental example

Say you write a simple command-line app that just prints to `System.out` and does some math with `java.util.ArrayList`. That's 100% `java.base`.

- `jdeps` scans it, reports back: `java.base` only.
- `jlink` builds a runtime containing _just_ `java.base` — no SQL support, no GUI toolkit, no XML parser.
- The resulting folder might be ~40MB instead of the ~300MB+ full JDK, because you've excluded dozens of modules your app never touches.

If instead your app used `java.sql.Connection` somewhere (like a Spring Boot app talking to Postgres), `jdeps` would report `java.base` **and** `java.sql`, and `jlink` would include both.

## Where this fits with Spring Boot, since that's your context

In practice, most people don't hand-roll `jlink` runtimes for Spring Boot apps — Spring Boot's build plugins (Maven/Gradle) can integrate with `jlink`/`jpackage` to produce a custom runtime image or even a native installer automatically, doing the `jdeps` scan under the hood. But understanding what's happening underneath — "only java.base is mandatory, everything else is a module I can opt in or out of" — is exactly the loader-hierarchy knowledge you built up earlier in this conversation. `jlink` isn't a separate topic; it's that same architecture, made practical.




[[Java]]