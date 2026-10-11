


## The core idea

Your password becomes unsafe the moment it lands in a file that gets committed. Once it's in Git history, deleting it later doesn't help, because the old commit still contains it. So the goal is not "hide it in a file", it's **keep the secret out of anything Git tracks**, and let Spring read it from outside at runtime.

Spring's property precedence (which you saw earlier) is what makes this possible: environment variables and external files override what's inside your jar or repo.

## Your idea: `application-local.yaml`

Yes, that works, but only if you do one extra thing: **add it to `.gitignore`**. A file named `application-local.yaml` is not secret by itself. It's only safe because Git never sees it.

```
src/main/resources/
├── application.yaml          # committed: no secrets
├── application-local.yaml    # NOT committed: holds your password
```

`.gitignore`:

```
application-local.yaml
application-local.properties
.env
```

`application.yaml` (committed, safe):

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/library
    username: ${DB_USER}
    password: ${DB_PASSWORD}
```

`application-local.yaml` (ignored, your real values):

```yaml
spring:
  datasource:
    username: library_user
    password: secret123
```

Activate it:

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

Spring layers `application-local.yaml` over `application.yaml`, so the real password only exists on your machine.

**Gotcha:** if you already committed a file with the password, adding it to `.gitignore` does nothing, since Git keeps tracking files it already knows. You'd need `git rm --cached <file>`, and you should **change the password**, because it's already in history.

## The better habit: environment variables

Spring maps `SPRING_DATASOURCE_PASSWORD` to `spring.datasource.password` automatically, so you can leave the password out of every file:

```bash
export SPRING_DATASOURCE_PASSWORD='secret123'
./mvnw spring-boot:run
```

On Debian you can make this persistent for your user in `~/.bashrc`, or better, keep it in a `.env`-style file outside the project. This is also exactly how Docker, Kubernetes and cloud platforms inject secrets in production, so the habit transfers.

## Which to use

|Approach|Good for|Weakness|
|---|---|---|
|`application-local.yaml` (gitignored)|Local development, convenient in the IDE|Easy to forget the `.gitignore`; plain text on disk|
|Environment variables|Dev and production|Visible to processes of the same user; can leak into logs or crash dumps|
|Secret managers (Vault, AWS Secrets Manager, Kubernetes Secrets)|Production, teams|Extra setup and infrastructure|

For learning: use the gitignored local file, and commit a template so others know what to create:

```yaml
# application-local.yaml.example  (committed, fake values)
spring:
  datasource:
    username: your_user
    password: your_password
```

## Other things that matter

- **Lock down the file permissions** on Debian: `chmod 600 application-local.yaml` so other users on the machine can't read it.
- **Never put real passwords in `application.yaml` on GitHub**, even "just for now". Bots scan public repos for credentials within minutes.
- **Use a dedicated database user** with only the permissions your app needs, not the `postgres` superuser. If the password leaks, the damage is limited.
- **Don't log it.** `spring.jpa.show-sql` is fine, but never print your datasource properties.
- Note that none of this encrypts the password. These techniques only keep it out of version control; anyone with access to your machine or server can still read it.





[[Git & Github]]
[[Spring Framework]]