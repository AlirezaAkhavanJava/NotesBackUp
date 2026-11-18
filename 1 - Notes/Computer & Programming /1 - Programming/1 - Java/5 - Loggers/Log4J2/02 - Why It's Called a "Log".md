

This one's genuinely from nautical history, not a metaphor someone invented later. Sailors used to measure a ship's speed by throwing a wooden board — literally a log — tied to a rope with knots at regular intervals over the side of the ship. They'd count how many knots paid out over a fixed time (measured with a sandglass) to calculate speed — which is also where "knots" as a unit of speed comes from.

The results — speed, heading, weather, position — were written down at regular intervals in a book called the **logbook**, named after the wooden log used to generate the readings. Over time, "log" came to mean any chronological record of events, and "logbook" shortened in common usage to just "log." That's the sense software borrowed: a log is a running, time-ordered record of what happened, written down as it happens — the ship's log just happened to be the original one.

## What a Log Actually Is (in Software)

A log, in computing, is a sequential, append-only record of discrete events, each one typically stamped with when it happened and what it concerns. "Append-only" is the key property carried over from the ship's logbook: you don't go back and edit yesterday's entry, you add a new entry for what's happening now. Each line is a fact about a moment in the program's life — a request came in, a payment failed, a cache was cleared — not a mutable record you update.

A raw log entry usually looks something like this:

```json
2026-11-18 14:32:07.112  INFO 8421 --- [nio-8080-exec-3] com.me.orders.OrderService : Processing order: 48213
2026-11-18 14:32:07.340 ERROR 8421 --- [nio-8080-exec-3] com.me.orders.PaymentService : Payment failed for order 48213
```

Each line carries: a timestamp (when), a severity level (how important), a process/thread id (what part of the running system), the originating class (where in the code), and a message (what happened). That's the whole anatomy of a log entry — software just formalized the ship captain's "14:32, position X, speed Y, all well" into something a machine writes automatically on every event worth recording.

## What Logging Is

**Logging** is the practice — and the code — of producing those entries as your program runs. It's the act of writing to the log, the same way "sailing" is the act of operating the ship, not the ship itself. Every time your code calls `logger.info(...)` or `logger.error(...)`, it's adding one new entry to that running record.

The reason this matters as a practice, not just a technical detail, is what the log _is for_: it's the history of a running system that you can go back and read after the fact. A server handling thousands of requests a minute can't be watched live — the log is how you reconstruct, hours or days later, exactly what sequence of events led to a bug, a crash, or a slow request. That's the whole point of keeping one: not to see things as they happen, but to have an honest, ordered record you can inspect afterward.


[[Logger]]