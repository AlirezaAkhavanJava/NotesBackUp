
## The Core Truth: Nothing Is Kept Forever By Default

Every logging mechanism you've seen so far — stdout, the console, journald, Docker's log driver — has some limit on how long it holds data, because storing every log line forever would eventually fill any disk. Whether a given log message survives for an hour, a month, or indefinitely is entirely a matter of configuration at each layer of the pipeline, not something that happens automatically. If nobody configures retention explicitly, the defaults at each layer will eventually discard old entries — sometimes sooner than you'd expect.

The question "what gets kept" really breaks down into: at which layer does this log line get captured, and what's the retention policy configured at that layer?

## Layer 1: Your App's Own Log Files (if you write to one)

If Logback is configured with only a `ConsoleAppender`, nothing is saved to disk by your app at all — it's purely transient output waiting to be captured by whatever's running it (journald, Docker, etc.). To actually persist logs yourself, you add a `RollingFileAppender`, and _you_ decide the retention explicitly:

```xml
<appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <file>logs/app.log</file>
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
        <fileNamePattern>logs/app.%d{yyyy-MM-dd}.log.gz</fileNamePattern>
        <maxHistory>30</maxHistory>
        <totalSizeCap>3GB</totalSizeCap>
    </rollingPolicy>
</appender>
```

`maxHistory=30` means: keep 30 days of daily files, then delete the oldest automatically as new ones are created. `totalSizeCap` is a second, harder limit — even inside the 30-day window, if total log size exceeds 3GB, the oldest files get deleted early to stay under it. Without an appender like this, your app simply never writes logs anywhere durable — only wherever the platform underneath happens to catch stdout.

## Layer 2: What the Platform Keeps (journald / Docker / Kubernetes)

This is the layer most people forget is also time- or size-limited.

**journald** has its own storage caps, configured in `/etc/systemd/journald.conf`:

```ini
SystemMaxUse=500M
MaxRetentionSec=1month
```

Once total journal size hits `SystemMaxUse`, or an entry is older than `MaxRetentionSec`, journald deletes old entries — oldest first — regardless of whether anyone ever looked at them.

**Docker's default `json-file` driver** will grow a container's log file _without limit_ unless you configure rotation:

```bash
docker run --log-opt max-size=10m --log-opt max-file=3 myapp
```

This caps it at 3 files of 10MB each (30MB total) before old entries are overwritten. Critically: if a container is deleted, its logs are deleted with it, by default — Docker doesn't preserve logs beyond the container's own lifetime unless something ships them out first.

**Kubernetes is the most unforgiving of the three.** A pod's logs live only as long as that pod's container does. If a pod crashes, gets rescheduled, or a node is replaced, the logs captured by `kubectl logs` can vanish permanently the moment the pod is gone — there's no built-in long-term retention at all. This is precisely why nobody relies on `kubectl logs` for anything beyond quick live debugging.

## Layer 3: Centralized Aggregation — Where Real Retention Lives

Because the platform layer is fundamentally short-lived and ephemeral, any log that actually needs to survive long-term has to be **shipped off the machine** before that machine's local copy gets rotated away. This is the real job of the shipping agents mentioned earlier (Filebeat, Promtail, the CloudWatch agent) — they tail the local log files or stdout stream and forward each line to a central store _before_ local rotation deletes it.

Once in the central store, retention is a deliberate, often compliance-driven setting, not an accident of disk space:

```yaml
# Elasticsearch Index Lifecycle Management (ILM) policy example
policy:
  phases:
    hot:
      min_age: "0ms"
    delete:
      min_age: "90d"
      actions:
        delete: {}
```

This says: keep logs actively searchable for 90 days, then permanently delete the index. Grafana Loki, CloudWatch Logs, and Datadog all have equivalent retention settings (CloudWatch Logs even lets you set retention per log group, from 1 day to "never expire"). Organizations with regulatory requirements (finance, healthcare) often set these to a year or more for specific log categories; most everyday application logs are kept weeks to a few months, because keeping everything forever gets expensive fast at scale and most of it is never queried again anyway.

## Putting the Whole Lifetime Together

```
App writes to stdout
      |
      v
Local capture (journald/Docker) — short retention, hours to weeks, size-capped
      |
      v  (shipping agent must grab it BEFORE local rotation deletes it)
      v
Central aggregator (Elasticsearch/Loki/CloudWatch) — the real retention window,
                                                       days to months (or longer
                                                       if required by compliance)
      |
      v
Eventually deleted per the aggregator's own retention policy
```

So the honest answer to "do we even save them": only the ones that get shipped off the originating machine before local rotation catches up to them, and only for as long as whoever owns the central log store decided to pay to keep them. A log line that's never shipped anywhere — say, a container that crashes and gets deleted before an agent reads its output — can be gone permanently within minutes, which is exactly why log shipping is treated as part of the deployment setup itself, not an afterthought.


[[Logger]]