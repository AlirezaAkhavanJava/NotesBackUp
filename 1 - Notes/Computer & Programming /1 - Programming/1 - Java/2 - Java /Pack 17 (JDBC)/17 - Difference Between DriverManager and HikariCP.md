

The confusion makes sense — both lines of code look identical:

```java
Connection conn1 = DriverManager.getConnection(url, user, password);
Connection conn2 = dataSource.getConnection(); // HikariCP
```

Both return something typed `Connection`. But what happens underneath those two calls, and what `close()` means afterward, are completely different. The difference isn't in the _interface_ — it's in what object actually sits behind it and what work gets done on each call.

## What `DriverManager.getConnection()` Actually Does

Every single time you call this, real work happens, right then:

1. The driver opens a brand new **TCP socket** to the database server.
2. It performs the database's **authentication handshake** (sending credentials, negotiating protocol version).
3. The database server allocates memory and a backend process/thread for this new session.
4. Only after all that completes does the method return a `Connection` object to you.

This takes real time — typically tens of milliseconds, sometimes more depending on network distance and server load. And when you call `conn.close()`, it is gone for real: the socket closes, the database server tears down the session's resources. If you need another connection a moment later, you pay that entire setup cost again from zero.

```java
Connection conn = DriverManager.getConnection(url, user, password); // full handshake happens HERE
// ... use it ...
conn.close(); // socket actually closes HERE, session is gone for good
```

There's no reuse, no memory of the fact that you just had a perfectly good connection open a second ago.

## What HikariCP Actually Does

HikariCP does the expensive part — the TCP handshake and authentication — **once per physical connection**, up front, when the pool is created (or when it needs to grow). After that, `getConnection()` and `close()` don't touch the network at all; they just move an already-open connection in and out of an internal collection.

```java
HikariDataSource dataSource = new HikariDataSource(config);
// at this point, Hikari has ALREADY opened `minimumIdle` real connections,
// done their TCP handshakes and authentication, up front

Connection conn = dataSource.getConnection(); // no handshake here — just hands you an already-open one
// ... use it ...
conn.close(); // no socket closes — connection just goes back into the idle set
```

The physical connection HikariCP opened at startup might get borrowed and returned hundreds of times over the life of your application, without ever being closed and reopened, as long as it stays within `maxLifetime`.

## The Key Mechanism: Proxying

Here's the part that actually explains _how_ `close()` can mean something different depending on where the `Connection` came from, even though both are typed `java.sql.Connection`.

When you call `DriverManager.getConnection()`, you get back the JDBC driver's own real `Connection` implementation (e.g., PostgreSQL's `PgConnection`) — calling `close()` on it calls the driver's real close logic, which shuts the socket.

When you call `dataSource.getConnection()` on a Hikari pool, you do **not** get the raw driver connection directly. You get a **proxy object** (`HikariProxyConnection`) that wraps a real, already-open driver connection internally. This proxy implements the exact same `Connection` interface, so your code can't tell the difference and doesn't need to — but its `close()` method is intercepted:

```java
// Simplified idea of what Hikari's proxy does internally
public void close() {
    // does NOT call the real connection's close()
    pool.returnConnectionToPool(this.realConnection);
}
```

Everything else you call on the proxy — `prepareStatement()`, `setAutoCommit()`, `commit()` — gets forwarded straight through to the real underlying connection, unchanged. Only `close()` is rewritten to mean "give this back to the pool" instead of "destroy this."

This is exactly why the JDBC code you write looks identical either way — `try (Connection conn = ...)` behaves correctly whether `conn` is a raw driver connection or a Hikari proxy, because `Connection` is just an interface and Java doesn't care which implementation sits behind it.

## Side-by-Side Summary

||`DriverManager`|HikariCP|
|---|---|---|
|When is the TCP handshake done?|Every single `getConnection()` call|Once, up front, per physical connection|
|What does `getConnection()` return?|The driver's real `Connection`|A proxy wrapping an already-open real connection|
|What does `close()` actually do?|Closes the socket for real|Returns the connection to the pool, unchanged|
|Cost of getting a connection|Full handshake cost, every time|Essentially free — just a hand-off|
|Reuse across requests?|None — every connection is one-shot|Same physical connections reused indefinitely (up to `maxLifetime`)|

So the pool isn't "just creating a connection" in the sense you'd expect from the name — it's front-loading the expensive part exactly once, then handing out and reclaiming the same already-paid-for connections, intercepting `close()` so that your code never has to know it's not actually destroying anything.



[[Java]]