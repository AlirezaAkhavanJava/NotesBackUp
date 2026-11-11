

Your sentence is almost right, with one fix: the pool doesn't hand requests _to_ threads. The threads in the pool are the ones that _handle_ requests. Each incoming HTTP request is picked up by one worker thread, which runs your whole controller → service → repository chain and writes the response. When the response is done, the thread goes back to the pool for the next request.

The number 200 is the default maximum size of that pool, both in Tomcat itself and in Spring Boot's embedded Tomcat. It means at most 200 requests can be _executing your code_ at the same moment. It does not mean only 200 users or connections can exist.

## How a request reaches a worker thread

Spring Boot's embedded Tomcat uses the NIO connector by default. Three kinds of threads are involved:

1. **Acceptor** (1 thread): accepts new TCP connections.
2. **Poller** (a small number of threads): watches open connections and notices when one has request data ready to read. Idle keep-alive connections cost almost nothing here, because they don't occupy a worker.
3. **Worker threads** (the pool of up to 200): take a ready request, run it through the servlet (`DispatcherServlet`), and send back the response.

You can see worker threads yourself:

```java
@GetMapping("/whoami")
String whoami() {
    return Thread.currentThread().getName();
}
```

Calling this returns names like `http-nio-8080-exec-1`, `exec-2`, and so on. `exec` marks the worker pool. Call it from several tabs at once and you'll see different numbers.

## The settings that control it

```properties
server.tomcat.threads.max=200
server.tomcat.threads.min-spare=10
server.tomcat.accept-count=100
server.tomcat.max-connections=8192
```

|Property|Default|Meaning|
|---|---|---|
|`threads.max`|200|Maximum worker threads, so the maximum requests running at once|
|`threads.min-spare`|10|Threads kept alive even when idle, so a sudden request doesn't wait for thread creation|
|`max-connections`|8192|Maximum open connections Tomcat accepts and manages (NIO)|
|`accept-count`|100|Length of the operating system's queue for new connections once `max-connections` is reached|

The pool starts small (`min-spare`) and grows one thread at a time as demand rises, up to `threads.max`. It does not create 200 threads at startup.

## What happens when all 200 are busy

Take request number 201 while all workers are still running:

- The connection is **accepted** (up to `max-connections`), but the request **waits** until a worker finishes. It isn't rejected.
- If you pass `max-connections` too, new connections wait in the OS queue (`accept-count`).
- If that queue is full as well, the client gets a connection refused or timeout.

So the failure mode under overload is usually _latency_ first (requests waiting), and errors only later. This is why a slow database can make a whole app look frozen: if each request holds a worker for 5 seconds on a slow query, 200 workers handle only about 40 requests per second.

## Sizing: why raising 200 is often the wrong fix

Each platform thread reserves stack memory (roughly 1 MB by default, outside the heap), and more threads mean more context switching on the same cores. Raising `threads.max` to 2000 usually moves the bottleneck instead of removing it, since a Hikari pool of 10 database connections still lets only 10 requests use the database at once. The rest sit blocked while holding a worker.

A useful rule: first measure how long requests actually spend waiting (database, remote calls). Only then adjust. For CPU-heavy work, more threads than cores won't help. For work that mostly waits on I/O, more threads help, but see the next section.

## Virtual threads

Since Spring Boot 3.2, with a modern JDK like yours, you can switch the worker pool to virtual threads:

```properties
spring.threads.virtual.enabled=true
```

Tomcat then runs each request on a cheap virtual thread instead of a pooled platform thread. The 200 limit no longer acts as a ceiling for blocking I/O, because a virtual thread that waits on the database is unmounted from its carrier thread and doesn't tie it up. Your connection pool (Hikari) then becomes the real limit, so size it deliberately. Virtual threads do not make CPU-bound work faster.

## Quick recap

- Worker threads **handle** requests; they are not handed requests by something else in the sense of "pool gives request to thread".
- 200 is the default max concurrent _executing_ requests, not max users.
- Extra requests queue rather than fail, up to the limits above.
- Tune `server.tomcat.threads.max` only after measuring, or switch to virtual threads when your work is mostly blocking I/O.



[[Threads]]
[[Spring Framework]]