

In Spring Security, a "leak" almost always refers to the **security context leaking across threads or requests** — authentication data escaping the request it belongs to and showing up somewhere it shouldn't. It's not a memory leak in the GC sense; it's a correctness and security bug caused by how Spring stores the current user's identity.

**Where the leak comes from**

`SecurityContextHolder` is the static class that holds the current `SecurityContext` (which wraps the `Authentication` object). By default, it stores that context in a `ThreadLocal`:

```java
public class SecurityContextHolder {
    private static final ThreadLocalSecurityContextHolderStrategy strategy =
        new ThreadLocalSecurityContextHolderStrategy();
}
```

A `ThreadLocal` means the value is tied to the _thread_, not to the request. Spring normally handles this for you: for every incoming HTTP request, a filter (`SecurityContextHolderFilter`, formerly `SecurityContextPersistenceFilter`) sets the context at the start of the request and clears it at the end, in a `finally` block. As long as that filter runs and you don't bypass it, you're safe.

The leak happens when a thread is **reused** and nobody clears the context in between. Two common cases:

1. **Thread pools (Tomcat worker threads, `ExecutorService`, `@Async`)** — the servlet container reuses a fixed pool of worker threads across many requests. If a background task running on a pooled thread sets the `SecurityContext` manually (or inherits one via `MODE_INHERITABLETHREADLOCAL`) and nothing clears it, the _next_ task that happens to land on that same thread can see the previous user's authentication.
    
2. **Manually spawned threads** — if you do `new Thread(() -> doSomething()).start()` inside a request handler, that new thread does **not** automatically get the current `SecurityContext` (ThreadLocal doesn't propagate to child threads by default), so code inside it sees an empty context. That's the opposite problem — a "loss" rather than a leak — but it's taught alongside leaks because it comes from the same root cause: ThreadLocal boundaries not matching logical request boundaries.
    

**Showing the leak**

```java
ExecutorService pool = Executors.newFixedThreadPool(2);

// Request A, authenticated as "alice"
SecurityContextHolder.getContext().setAuthentication(aliceAuth);
pool.submit(() -> {
    System.out.println(SecurityContextHolder.getContext().getAuthentication()); // alice
    // forgot to clear here
});

// Later, Request B, authenticated as "bob", happens to get the same pooled thread
pool.submit(() -> {
    System.out.println(SecurityContextHolder.getContext().getAuthentication());
    // could still print "alice" if the thread was reused and never cleared
});
```

Only `setAuthentication` and `getAuthentication` are new here — both are just the standard read/write accessors on `SecurityContextHolder.getContext()`.

**The fix**

- Always clear the context when you're done with it manually: `SecurityContextHolder.clearContext();` in a `finally` block.
- For propagating the context _into_ a new thread safely (instead of losing it), Spring provides `DelegatingSecurityContextRunnable` and `DelegatingSecurityContextExecutorService`, which copy the current context into the task and clear it afterward — so you get propagation without leakage into unrelated tasks.
- `SecurityContextHolder` also supports `MODE_INHERITABLETHREADLOCAL` (child threads inherit the parent's context) and `MODE_GLOBAL` (one context for the whole JVM — almost never appropriate in a web app, since every user would share it). The default `MODE_THREADLOCAL` is the safest baseline precisely because it doesn't leak to children or siblings on its own — leaks happen when _you_ introduce thread reuse or inheritance without cleanup.

**A related concept worth knowing**: "leak" in security is also used for **information leaks** — not a ThreadLocal bug, but a design flaw where your app's responses reveal more than they should, e.g. a login endpoint returning "user not found" vs "wrong password" tells an attacker whether a username exists. That's usually fixed by returning the same generic error for both cases. Different mechanism, same word.


[[Spring Security]]