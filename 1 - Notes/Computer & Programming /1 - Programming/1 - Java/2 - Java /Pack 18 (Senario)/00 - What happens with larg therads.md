
In an interview, or at 2am when production is on fire, nobody asks you to recite "race conditions happen when state is shared." They hand you a system and ask "what breaks, and why." So here's a system. We'll push it until it breaks in each of the three ways, in the order they'd actually surface.

**The scenario: TicketRush**

You're building the backend for a concert ticket flash sale. At exactly 8:00 PM, 50,000 people hit `POST /buy-seat` within a 30-second window. Each request does four things:

1. Read `seatsRemaining` for that concert (currently `2000`)
2. Call an external payment gateway over HTTPS (this takes 300ms–2s — it's network I/O, your thread just sits there waiting)
3. If payment succeeds, decrement `seatsRemaining`
4. Send a confirmation email (another network call, another 200ms–1s wait)

Someone on the team says: _"Just give the ExecutorService 100,000 threads so nothing ever has to queue."_ You're asked to evaluate that. Let's actually run it, mentally, step by step.

---

**Step 1 — the JVM tries to honor "100,000 threads"**

```java
ExecutorService pool = Executors.newFixedThreadPool(100_000);
```

Each of those is a **platform thread** — one real OS thread, with its own OS-allocated stack (default ~1MB on a 64-bit JVM, tunable via `-Xss`). The moment the pool tries to actually spin up anywhere near 100,000 of these, two things are racing against each other, and the OS loses first:

- **Native thread ceiling**: Linux enforces a max process/thread count (`ulimit -u`, often in the low thousands by default on a normal box). You don't gracefully run out of RAM — you hit this ceiling first and get:

```
java.lang.OutOfMemoryError: unable to create new native thread
```

- **If** you raised that ceiling and somehow got all 100K created: `100,000 × ~1MB stack ≈ 100GB`, just for stack space, before any of your actual request data exists.

So "give it 100K threads" doesn't fail the way people picture — a slow memory leak. It fails fast and loud, usually before the sale even starts.

---

**Step 2 — say you dodge that (smaller pool, say 500 threads) and the sale goes live**

Now 500 threads are genuinely running concurrently, all reading and writing `seatsRemaining`. Here's the part that matters: **this risk has nothing to do with how many threads you have — it exists at 2 threads just as much as 500.** More threads just mean the bad interleaving gets hit more often. Watch:

```java
int available = seatsRemaining;       // Thread A reads 2000
// -- OS suspends Thread A here, schedules Thread B --
int available2 = seatsRemaining;      // Thread B also reads 2000
seatsRemaining = available2 - 1;       // B writes 1999
seatsRemaining = available - 1;        // A writes 1999 (A's write clobbers B's)
```

Two seats sold, two payments charged, but `seatsRemaining` only dropped by one. You've oversold a seat, and there's no exception, no log line — the code runs "successfully." That's what makes races dangerous: they don't crash, they corrupt. The fix isn't "fewer threads," it's making the read-decrement-write one indivisible step:

```java
AtomicInteger seatsRemaining = new AtomicInteger(2000);
// ...
if (seatsRemaining.getAndDecrement() <= 0) {
    seatsRemaining.incrementAndGet(); // back out, sold out
    throw new SeatUnavailableException();
}
```

`getAndDecrement()` is atomic at the hardware level — no thread can see a half-finished update. Thread count is irrelevant to whether you need this; it only changes how quickly the bug gets found (the hard way, in prod, during your biggest sale).

---

**Step 3 — suppose the box has 16 CPU cores, and you did get 500 threads running**

500 runnable threads, 16 cores. The OS scheduler can only actually _execute_ 16 of them at any given instant — everyone else is parked, waiting for a turn. The scheduler keeps yanking threads on and off the cores, saving one thread's register state and loading the next's, over and over. That bookkeeping isn't free — it's pure overhead, zero business logic.

Past a certain thread count, you hit a point where the CPU spends more cycles context-switching than doing your actual work. Throughput doesn't just plateau — it can go _down_ as you add threads, because you're adding more switching overhead without adding more cores to run on. This is sometimes called thread thrashing. Notice this is a completely different failure from Step 1: Step 1 was "the OS won't even let you create the threads." This is "the threads exist and run, but CPU time is going to overhead instead of your code."

---

**Step 4 — now contrast this with a real "thread exhaustion," because it's easy to confuse with Step 3**

Say instead you'd gone _too_ small — a bounded pool of 20 threads for a service that calls the payment gateway, and the gateway is having a slow day (each call now takes 10 seconds instead of 300ms). All 20 threads are now sitting blocked, mid-call, not doing CPU work, not switching — just stuck waiting on the network. The 21st incoming request has nowhere to go:

```java
ExecutorService pool = Executors.newFixedThreadPool(20);
// all 20 are blocked on gateway.charge(...)
pool.submit(task); // queues, then eventually: RejectedExecutionException
```

This is pool exhaustion — every thread is alive and fine, just unavailable, because they're all blocked on I/O. It's a _pool-sizing-vs-blocking-time_ problem. Step 3's thrashing is a _CPU-count-vs-runnable-thread-count_ problem. They look similar from the outside ("stuff is slow") but you fix them in opposite directions — thrashing wants _fewer_ threads competing for cores; exhaustion wants _more_ threads (or shorter blocking calls) so I/O waits don't queue everything behind them.

---

**So what actually fixes TicketRush?**

The deciding question is: _what are these 500 (or 100,000) threads doing while they exist?_ Look back at the four steps in a request — step 1 and 3 are tiny CPU work (a read, a decrement). Steps 2 and 4 are almost entirely _waiting on the network_. That's the signature of I/O-bound work, and it's exactly the case virtual threads were built for:

```java
ExecutorService pool = Executors.newVirtualThreadPerTaskExecutor();

pool.submit(() -> {
    int remaining = seatsRemaining.getAndDecrement(); // still needs atomic — see Step 2
    PaymentResult result = gateway.charge(request);    // blocks — but cheaply now
    emailService.sendConfirmation(user);                // blocks again
});
```

A virtual thread isn't a real OS thread with its own 1MB stack — thousands of them get multiplexed onto a small handful of real "carrier" threads by the JVM. When a virtual thread blocks on I/O (the gateway call), the JVM parks it and frees the carrier thread to run someone else's virtual thread in the meantime. So you genuinely can spin up 50,000 of these for your flash sale without hitting the OS thread ceiling from Step 1 or the stack-memory wall, _because most of them are parked, not scheduled, most of the time._

What virtual threads do **not** fix: the `seatsRemaining` race from Step 2 (you still need the `AtomicInteger`, or a lock, or a database-level constraint — virtual threads change the concurrency model, not whether shared mutable state needs protecting), and they don't help at all if your work were CPU-bound instead of I/O-bound — if steps 2 and 4 were heavy computation instead of network waits, you'd be back to being limited by your 16 real cores no matter how many virtual threads you spin up, because there's no I/O wait for the JVM to multiplex around.



[[Java]]