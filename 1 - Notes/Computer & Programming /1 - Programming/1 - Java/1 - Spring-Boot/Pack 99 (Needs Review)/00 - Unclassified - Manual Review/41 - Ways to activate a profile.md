

A profile does nothing until you tell Spring which one is active. The property that does this is `spring.profiles.active`, and Spring Boot lets you set it in six different places: a file, the command line, an environment variable, a JVM flag, your IDE, or Java code.

All six set the same property, so they all end in the same result. The real question is which one fits where you're running the app. On your laptop you want convenience. In production you want the choice to come from _outside_ the JAR, so the same build can run anywhere.

---

## Pick by situation

|Where you are|Best way|
|---|---|
|Local development in the terminal|Maven flag (`-Dspring-boot.run.profiles=dev`)|
|Local development in an IDE|Run configuration|
|Running a JAR by hand|`--spring.profiles.active=prod`|
|Docker, Kubernetes, CI/CD, servers|Environment variable|
|Tests|`@ActiveProfiles("test")`|
|Almost never|A file or Java code|

---

## 1. In `application.properties` or YAML

```properties
spring.profiles.active=local
```

```yaml
spring:
  profiles:
    active: local
```

It is the simplest option, and it's fine as a default for your own machine. But it is hard-coded inside the JAR, so don't rely on it for production.

One rule: you can't set `spring.profiles.active` inside a profile-specific file such as `application-local.properties`. Boot rejects it, because the active profile has to be known _before_ it can choose which profile file to load.

---

## 2. On the command line

```bash
java -jar app.jar --spring.profiles.active=prod
```

Put it **after** the JAR name. It's a Spring argument, so it needs no changes to any file.

With Maven during development, use the plugin's own property:

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

Note that a plain `--spring.profiles.active=dev` after `spring-boot:run` is not passed through. If you prefer that style, use `-Dspring-boot.run.arguments=--spring.profiles.active=dev`.

---

## 3. As an environment variable

Spring maps `spring.profiles.active` to `SPRING_PROFILES_ACTIVE` (uppercase, dots become underscores).

```bash
# Linux (your Debian)
export SPRING_PROFILES_ACTIVE=prod
java -jar app.jar

# or for a single command
SPRING_PROFILES_ACTIVE=prod java -jar app.jar
```

On Windows the syntax differs:

```bat
:: Command Prompt
set SPRING_PROFILES_ACTIVE=prod
java -jar app.jar
```

```powershell
# PowerShell
$env:SPRING_PROFILES_ACTIVE="prod"
java -jar app.jar
```

This is the standard choice for Docker, Kubernetes and CI/CD, because platforms already configure apps through environment variables.

---

## 4. As a JVM system property

```bash
java -Dspring.profiles.active=prod -jar app.jar
```

`-D` goes **before** `-jar`. It is a Java setting, not a Spring argument, so compare the two:

```bash
java -Dspring.profiles.active=prod -jar app.jar     # JVM property, before -jar
java -jar app.jar --spring.profiles.active=prod     # Spring argument, after the jar
```

Both work.

---

## 5. In your IDE

In IntelliJ, open the Run Configuration and use one of:

- **Active profiles** field: `local`
- **Environment variables**: `SPRING_PROFILES_ACTIVE=local`
- **VM options**: `-Dspring.profiles.active=local`

The first one is the least error-prone.

---

## 6. In Java code

```java
SpringApplication app = new SpringApplication(MyApplication.class);
app.setAdditionalProfiles("local");
app.run(args);
```

Line by line: `setAdditionalProfiles` _adds_ a profile on top of whatever is already active from the other methods. It doesn't replace them.

Avoid this for choosing the environment. It ties "which environment" to your compiled code, which is exactly what profiles are meant to avoid. It's useful only for a profile that must always be on.

---

## What each profile file contains

After you activate `local`, Spring loads the base file and then layers the profile file on top:

```text
src/main/resources/
├── application.properties          ← always
├── application-local.properties    ← when "local" is active
└── application-prod.properties     ← when "prod" is active
```

```properties
# application.properties
spring.application.name=DoItLater

# application-local.properties
spring.datasource.url=jdbc:postgresql://localhost:5432/doitlater

# application-prod.properties
spring.datasource.url=${DB_URL}
```

The profile file wins on any key it shares with the base file. The `${DB_URL}` in the prod file points at an environment variable, so no real credentials live in your repo.

---

## When two methods disagree

The closer a setting is to the running process, the more it wins. From strongest to weakest:

```text
1. Command-line argument   (--spring.profiles.active=prod)
2. JVM system property     (-Dspring.profiles.active=prod)
3. Environment variable    (SPRING_PROFILES_ACTIVE=prod)
4. application.properties  (spring.profiles.active=local)
```

So a profile in `application.properties` is a safe local default that any launch method overrides. That's why production can decide the profile externally, without touching the JAR.

---

## Several profiles, and a default

```bash
SPRING_PROFILES_ACTIVE=prod,eu-region     # comma-separated, both active
```

```properties
spring.profiles.default=local             # used only when nothing else is active
```

Without that last line, an unset profile means Spring's built-in `default` profile.

---

## Checking which profile is active

Look at the first lines of the startup log:

```text
The following 1 profile is active: "prod"
```

Or, in code, `environment.getActiveProfiles()`. If you see `No active profile set, falling back to 1 default profile: "default"`, your launch method didn't take effect.

---

## Related concept in short

**`spring.profiles.include`** adds profiles _always_, on top of whatever else is active, and it can be set in a file. Use it to say "whenever `prod` is on, also turn on `metrics`." For the same idea with a friendlier name, see profile groups (`spring.profiles.group.production=prod,metrics`).

---

## Test yourself

1. `application.properties` has `spring.profiles.active=local`, and you launch with `SPRING_PROFILES_ACTIVE=prod`. Which profile is active, and why?
2. What is the difference between `--spring.profiles.active=prod` and `-Dspring.profiles.active=prod`, and where does each go on the command line?
3. Why can't you set `spring.profiles.active` inside `application-prod.properties`?




[[Spring Framework]]