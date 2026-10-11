

## The intuition

Spring only reads a profile file like `application-local.yaml` if the profile **`local` is active**. The file name is the link: `application-{profile}.yaml` loads when that profile is switched on. So "telling Spring to use it" just means **activating the `local` profile**.

There are two other ways to point Spring at a file directly. All three are below.

## Option 1: Activate the `local` profile

**In `application.yml`:**

```yaml
spring:
  profiles:
    active: local
```

**Or in `application.properties`:**

```properties
spring.profiles.active=local
```

Spring then loads `application.yml` first and layers `application-local.yml` on top, so the local values win.

The catch is that this line is committed, so every environment, including production, defaults to `local`. If production doesn't have that file, the password placeholders fail to resolve. It's better to activate the profile from **outside** the file, which is Option 2.

## Option 2: Activate it from outside (recommended)

Nothing is written in the config file, and you choose the profile per run:

```bash
# Maven
./mvnw spring-boot:run -Dspring-boot.run.profiles=local

# Running the jar
java -jar app.jar --spring.profiles.active=local

# Environment variable (set once in ~/.bashrc on Debian)
export SPRING_PROFILES_ACTIVE=local
```

**In IntelliJ:** Run → Edit Configurations → your Spring Boot app → "Active profiles" → type `local`.

This keeps `application.yml` neutral: `local` on your machine, `prod` on the server, same code.

## Option 3: Point directly at a secrets file

You can import any file explicitly:

```yaml
# application.yml
spring:
  config:
    import: optional:file:./secrets.yml
```

The `optional:` prefix matters. Without it, Spring crashes at startup if the file is missing (for example on a teammate's machine). With it, a missing file is skipped silently, and then your `${DB_PASSWORD}` placeholders will fail loudly instead, which is what you want.

`secrets.yml` sits in the **project root**, not in `src/main/resources`:

```yaml
spring:
  datasource:
    username: library_user
    password: secret123
```

Add `secrets.yml` to `.gitignore`.

## Why the file's location matters

Anything in `src/main/resources` is **packaged into the jar** when you build. A gitignored `application-local.yaml` there stays out of Git, but it still ends up inside `app.jar`, so anyone you give the jar to gets your password. Files outside `resources` (like `./secrets.yml`) are not packaged.

Spring also auto-loads config from a `config/` folder next to where you run the app:

```
myproject/
├── config/
│   └── application-local.yml   <- found automatically, not in the jar
├── src/main/resources/
│   └── application.yml
```

Both `./config/` and `./secrets.yml` (via import) stay out of the jar, so they're safer than `src/main/resources`.

## A mistake to avoid

You **cannot** put `spring.profiles.active` inside `application-local.yml` itself. Spring has to decide which profiles are active _before_ it loads profile files, so the setting is ignored there. It must come from `application.yml`, the command line, or an environment variable.

## Which should you pick?

For learning: use `./config/application-local.yml` (gitignored) plus activate the profile with the IDE setting or `SPRING_PROFILES_ACTIVE=local`. It's the least typing, never ends up in the jar, and nothing sensitive is committed.



[[Spring Framework]]