
"Centralized configuration" is the thing you've already built — one Config Server, many clients pulling from it. "Refresh" is the harder half: once a client has started and cached its values, what actually makes it see a changed value without a restart, and more importantly, what _doesn't_. You've seen `@RefreshScope` and `/actuator/refresh` already; this goes into how that actually works, where it silently fails to do what people expect, and how it scales past one manual curl command.

## Two refresh behaviors, and they're not the same thing

There's a distinction that trips people up: `@ConfigurationProperties` beans are refresh-aware **automatically**, with no annotation needed. `@Value`-injected fields are **not** — they need `@RefreshScope` explicitly, which you already saw.

```java
// Automatically refreshed on /actuator/refresh — no @RefreshScope needed
@ConfigurationProperties(prefix = "discount")
public class DiscountProperties {
    private double rate;
    // getters/setters
}

// Needs @RefreshScope — plain @Value does NOT refresh on its own
@RefreshScope
@Component
public class PricingCalculator {
    @Value("${discount.rate}")
    private double rate;
}
```

The reason is structural, not arbitrary: `@ConfigurationProperties` beans are rebound to the `Environment` every time it changes, by design, as part of how that annotation works. `@Value` is evaluated once at bean construction and baked into the field — the only way to force that re-evaluation is to destroy and rebuild the bean itself, which is exactly what `@RefreshScope` exists to make possible.

## What @RefreshScope actually does under the hood

`@RefreshScope` doesn't make your bean magically reactive. It puts a **scoped proxy** in front of the real bean. Every method call goes through that proxy, which checks "has this scope been invalidated since I last built the target?" — if not, it reuses the cached instance; if the scope was refreshed, it discards the old instance and constructs a fresh one from current config, then delegates the call to that.

This matters because of the timing: calling `/actuator/refresh` doesn't rebuild your beans _immediately_ — it just clears the scope cache. The actual rebuild happens lazily, on the **next method call** that goes through the proxy. In practice this is invisible for a `@RestController` handling HTTP requests (every request is a fresh call anyway), but it explains confusing cases where a long-running background method that already grabbed a reference to the bean keeps using stale values even after a refresh fired — the refresh cleared the cache, but nothing called through the proxy to trigger the rebuild until the next request came in.

## Where refresh silently doesn't reach

A few patterns look like they should refresh and don't, and knowing them up front saves a debugging session:

```java
@Service
public class ReportScheduler {

    private final DiscountProperties discountProperties;

    public ReportScheduler(DiscountProperties discountProperties) {
        this.discountProperties = discountProperties;
    }

    @Scheduled(fixedRate = 60000)
    public void runReport() {
        double rate = discountProperties.getRate(); // fine — re-reads the field each call
    }
}
```

That example is actually safe, because it re-reads the field on every scheduled run. The trap is this variant:

```java
@Scheduled(fixedRateString = "${report.interval.ms}") // baked in at startup, NOT refreshable
public void runReport() { ... }
```

`fixedRateString` is resolved once, when the scheduled task is registered at startup — refreshing config afterward does not change an already-scheduled task's interval. Similarly, any value you copy out of a `@RefreshScope` bean into a local variable, a constant, or another non-refresh-scoped bean's field at construction time is frozen the moment that copy happens — refresh only helps the _next read through the proxy_, not values that have already escaped into something else.

## Scaling refresh past one instance: Spring Cloud Bus

Hitting `/actuator/refresh` works for one instance. With ten instances of `order-service` running, you'd need to curl all ten. This is exactly where **Spring Cloud Bus**, which you've already met at the ecosystem level, does its actual job: instead of `/actuator/refresh` on each instance, you hit `/actuator/busrefresh` on _any one_ instance.

```
POST http://any-instance:8080/actuator/busrefresh
```

That instance publishes a `RefreshRemoteApplicationEvent` onto a shared broker topic (`springCloudBus`, over RabbitMQ or Kafka — whichever Stream binder you've configured). Every other instance subscribed to that topic receives the event and runs its own local refresh in response. One HTTP call, every instance updates — you never need to know how many instances exist or where they are.

## Push instead of poll: webhook-triggered refresh

Everything so far still needs a human (or a script) to decide "config changed, go call the refresh endpoint." Config Server's `/monitor` endpoint closes that loop: your Git host (GitHub, GitLab) calls `/monitor` as a webhook on every push to the config repo, and Config Server translates that into the same bus-wide refresh event automatically.

```yaml
# on the Config Server
spring:
  cloud:
    bus:
      enabled: true
    config:
      server:
        git:
          uri: https://github.com/yourorg/config-repo
```

With this wired up, a GitHub webhook pointed at `https://config-server/monitor` means: a teammate merges a config change → GitHub fires the webhook → Config Server detects which applications' config paths changed from the commit payload → it publishes a bus refresh event scoped to just those applications → every affected instance updates itself, with no one touching `/actuator/busrefresh` by hand. This is the actual production pattern — manual `/actuator/refresh` is really a debugging/testing tool, not how refresh is meant to run day to day.

## A related concept worth knowing: this whole mechanism has a Kubernetes-native alternative

If you end up running on Kubernetes, there's a parallel to this entire refresh chain that doesn't involve Config Server, Bus, or `@RefreshScope` at all: Kubernetes ConfigMaps/Secrets mounted as files, watched by **Spring Cloud Kubernetes' Config Watcher**, which detects a ConfigMap change and triggers the same kind of refresh event locally in-pod. It's worth knowing this exists so that if a team says "we don't use Config Server, we use ConfigMaps," you recognize it as solving the identical problem (config changes without restarts) through the platform layer instead of the Spring Cloud layer — not a completely different idea.


[[Spring Framework]]
