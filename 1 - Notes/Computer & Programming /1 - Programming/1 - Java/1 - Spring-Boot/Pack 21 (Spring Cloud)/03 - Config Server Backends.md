
Backend is the actual place Config Server reads property values _from_ — Git was the one you saw as the default, but it's one of several, and production systems often combine more than one. The server's HTTP contract to clients (`/{application}/{profile}/{label}`) stays identical no matter which backend sits behind it, which is exactly the point — clients never know or care which one you picked.

## Git — the default, and the parts worth knowing beyond the basics

You've seen the simple case (`spring.cloud.config.server.git.uri` pointing at one repo). Three things make it production-ready rather than toy-ready:

**Authentication.** A private repo needs credentials:

```yaml
spring:
  cloud:
    config:
      server:
        git:
          uri: https://github.com/yourorg/config-repo
          username: svc-config-reader
          password: ${GIT_TOKEN}          # a token, never a real password
```

For SSH instead of HTTPS, you point at an SSH URL and supply a private key path (`spring.cloud.config.server.git.private-key` / `ignore-local-ssh-settings`) instead of username/password.

**Multiple repositories, matched by pattern.** One Git repo per application name doesn't scale once you have dozens of services. `spring.cloud.config.server.git.repos` lets different applications resolve to different repos based on a pattern match against `{application}`:

```yaml
spring:
  cloud:
    config:
      server:
        git:
          uri: https://github.com/yourorg/default-config    # fallback
          repos:
            payments:
              pattern: payments-*                             # matches payments-service, payments-worker, etc.
              uri: https://github.com/yourorg/payments-config
            legacy-monolith:
              pattern: legacy-*
              uri: https://github.com/yourorg/legacy-config
```

A request for `payments-service` gets routed to the `payments-config` repo; anything not matching falls back to the top-level `uri`. This is how large orgs give each team ownership of their own config repo without the Config Server itself needing to know about every team upfront.

**Where in the repo it looks.** By default the server reads from the repo root, but `search-paths` lets you point it at subfolders — useful when one monorepo holds config for many apps in separate directories rather than one repo per app:

```yaml
spring:
  cloud:
    config:
      server:
        git:
          uri: https://github.com/yourorg/config-repo
          search-paths: 'configs/{application}'
```

**Refresh timing.** `clone-on-start: true` clones immediately at server boot (so the first client request doesn't pay that latency); otherwise the first clone happens lazily on first request. The server pulls fresh commits on every incoming request by default, which is simple but means every request pays a Git fetch — `force-pull` and webhook-triggered refresh (pairing Config Server with a `/monitor` webhook endpoint that Git calls on push) are the two ways production setups avoid polling Git on every single config request.

## Native — plain local files, no Git at all

The `native` profile serves config straight from the filesystem, with the exact same `application-profile-label` file-naming convention you already know, just with no version control underneath:

```yaml
spring:
  profiles:
    active: native
  cloud:
    config:
      server:
        native:
          search-locations: file:///opt/config-repo/,classpath:/shared-config/
```

This is the right choice for local development (no need to stand up or mock a Git repo just to test Config Server locally) and for cases where config genuinely doesn't need version history. It's rarely the right choice for production, precisely because you lose the audit trail and rollback-via-git-revert that make the Git backend worth using in the first place.

## JDBC — config rows in a database

Instead of files, config lives as rows in a relational table your Config Server reads from:

```yaml
spring:
  profiles:
    active: jdbc
  datasource:
    url: jdbc:postgresql://localhost:5432/configdb
    username: config_reader
    password: ${DB_PASSWORD}
  cloud:
    config:
      server:
        jdbc:
          sql: SELECT "key", "value" FROM properties WHERE application=? AND profile=? AND label=?
```

This fits teams that already have config-management tooling built around a database — an internal admin UI for editing config rows, say — but it's a minority choice; most teams that want queryable/editable config reach for a dedicated config UI on top of the Git backend instead, since Git still gives you history and review (pull requests) on every change, which a raw table doesn't.

## Vault — for secrets specifically, not general config

You already know Config Server can decrypt `{cipher}`-prefixed values from a Git-backed config file. The Vault backend is a step further: instead of encrypted values sitting in Git, the actual secret values live in HashiCorp Vault, and Config Server fetches them live at request time:

```yaml
spring:
  cloud:
    config:
      server:
        vault:
          host: vault.internal
          port: 8200
          scheme: https
```

Clients authenticate to Config Server with a Vault token (`spring.cloud.config.token` on the client side), and Config Server uses that to read from Vault's own `secret/{application}/{profile}` path convention. The distinction worth holding onto: Git+encryption is "secrets travel through version control as ciphertext"; Vault is "secrets never touch version control at all, Git only ever holds non-secret config." Teams with strict security requirements tend to end up splitting config this way rather than picking one backend for everything.

## Composite backends — using more than one at once

`spring.cloud.config.server.composite` lets one Config Server pull from several backends and merge the results, each with a priority order:

```yaml
spring:
  profiles:
    active: composite
  cloud:
    config:
      server:
        composite:
          - type: git
            uri: https://github.com/yourorg/config-repo
          - type: vault
            host: vault.internal
            port: 8200
```

This is exactly the Git-for-non-secrets, Vault-for-secrets split above, expressed as one server instead of running two separate Config Server instances. Order matters — earlier entries in the list take priority when the same key exists in more than one backend.

## Picking one, for a real app

For most teams: **Git** as the primary backend (you get history, PR review, and rollback for free), **encrypted values or a Vault composite** for anything secret, and **native** reserved for local development only. JDBC is a narrower fit — reach for it only if there's already a database-backed config workflow it needs to plug into, not as a default choice.

[[Spring Framework]]
