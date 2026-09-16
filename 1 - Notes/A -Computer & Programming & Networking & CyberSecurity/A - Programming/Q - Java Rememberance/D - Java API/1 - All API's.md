
# Complete Java API Reference — Organized by Category

A "complete" list of every Java API would run into thousands of classes — so this is organized as a **comprehensive reference of every major package/API area** you're likely to encounter, with a definition for each. This connects to nearly everything covered in this conversation.

---

## 1. Core Language (`java.lang`) — auto-imported, always available

|API|Definition|
|---|---|
|`Object`|root class of every Java class; provides `toString()`, `equals()`, `hashCode()`|
|`String`|immutable sequence of characters|
|`StringBuilder` / `StringBuffer`|mutable, efficient text building (`StringBuffer` is thread-safe, `StringBuilder` isn't)|
|`Integer`, `Double`, `Boolean`, etc. (wrapper classes)|object wrappers around primitives, with utility methods like `parseInt()`|
|`Math`|static utility methods for math operations (`sqrt`, `pow`, `random`, etc.)|
|`System`|gateway to system facilities — `System.out`, `System.in`, `currentTimeMillis()`, `exit()`|
|`Thread`|represents a single path of execution within a process|
|`Runnable`|functional interface — a task with no input/output, run by a `Thread`|
|`Class`|runtime representation of a class/type — used for reflection|
|`Comparable<T>`|interface for defining a natural ordering (`compareTo()`)|
|`Iterable<T>`|interface enabling the for-each loop; root of `Collection`|
|`AutoCloseable` / `Closeable`|interfaces enabling try-with-resources|
|`Throwable`, `Exception`, `Error`, `RuntimeException`|the exception class hierarchy|
|`Enum`|base class for all enum types|
|`Record` (concept, Java 16+)|compact syntax for immutable data-carrier classes|

---

## 2. Collections & Data Structures (`java.util`)

|API|Definition|
|---|---|
|`Collection<E>`|root interface for groups of objects (`List`, `Set`, `Queue`)|
|`Collections`|static utility class — `sort()`, `reverse()`, `unmodifiableList()`, etc.|
|`List<E>`|ordered collection, allows duplicates, index-based access|
|`ArrayList`|resizable array-backed `List` implementation|
|`LinkedList`|doubly-linked-list-backed `List`/`Deque` implementation|
|`Set<E>`|collection with no duplicate elements|
|`HashSet`|unordered `Set`, backed by a hash table|
|`TreeSet`|sorted `Set`, backed by a red-black tree|
|`LinkedHashSet`|`Set` that preserves insertion order|
|`Map<K,V>`|key-value pair storage (not a `Collection`)|
|`HashMap`|unordered key-value map, backed by a hash table|
|`TreeMap`|sorted map by key|
|`LinkedHashMap`|map preserving insertion (or access) order|
|`Queue<E>`|FIFO-style collection interface|
|`Deque<E>`|double-ended queue — add/remove from both ends|
|`ArrayDeque`|resizable array-backed `Deque` implementation|
|`PriorityQueue`|queue ordered by priority, not insertion order|
|`Iterator<E>` / `ListIterator<E>`|interfaces for traversing a collection|
|`Optional<T>`|container object that may or may not hold a non-null value|
|`Arrays`|static utility class for array operations (`sort`, `asList`, `fill`)|
|`Objects`|static utility class — null-safe `equals()`, `hashCode()`, `requireNonNull()`|
|`Comparator<T>`|interface for defining custom orderings (separate from `Comparable`)|
|`Scanner`|parses/reads typed input from a source (console, file, string)|
|`Random`|pseudo-random number generator|
|`UUID`|universally unique identifier generation|
|`Properties`|key-value string map, typically for config files|
|`StringTokenizer`|legacy string-splitting utility (largely replaced by `String.split()`)|
|`BitSet`|a vector of bits, growable|

---

## 3. Streams & Functional Programming

|API|Definition|
|---|---|
|`Stream<T>` (`java.util.stream`)|a pipeline for processing sequences of elements (filter/map/reduce)|
|`IntStream`, `LongStream`, `DoubleStream`|primitive-specialized streams, avoiding boxing overhead|
|`Collectors`|static utility class for terminal stream operations (`toList()`, `groupingBy()`, `joining()`)|
|`Function<T,R>` (`java.util.function`)|takes 1 input, returns 1 output|
|`Consumer<T>`|takes 1 input, returns nothing|
|`Supplier<T>`|takes nothing, returns 1 output|
|`Predicate<T>`|takes 1 input, returns boolean|
|`BiFunction`, `BiConsumer`, `BiPredicate`|two-argument versions of the above|
|`UnaryOperator<T>` / `BinaryOperator<T>`|`Function`/`BiFunction` where input/output types match|
|`Optional<T>`|(also here) supports functional-style `map()`/`filter()`/`orElse()` chains|

---

## 4. I/O (`java.io`)

|API|Definition|
|---|---|
|`InputStream` / `OutputStream`|abstract base classes for byte streams (raw binary data)|
|`FileInputStream` / `FileOutputStream`|byte streams connected to files|
|`BufferedInputStream` / `BufferedOutputStream`|adds buffering to byte streams|
|`ObjectInputStream` / `ObjectOutputStream`|serialization — object ↔ byte stream|
|`Reader` / `Writer`|abstract base classes for character streams (text, encoding-aware)|
|`FileReader` / `FileWriter`|character streams connected to files|
|`BufferedReader` / `BufferedWriter`|adds buffering + line-based reading/writing|
|`InputStreamReader` / `OutputStreamWriter`|bridges between byte streams and character streams|
|`PrintStream` / `PrintWriter`|adds `print`/`println`/`printf` convenience methods|
|`File`|represents a filesystem path (metadata only, not content)|
|`Serializable`|marker interface — opts a class into serialization|
|`IOException`|checked exception — base for I/O failures|
|`Console`|for real terminal interaction (e.g., password input)|

---

## 5. Modern File I/O (`java.nio.file`) — "NIO.2"

|API|Definition|
|---|---|
|`Path`|represents a filesystem path — the modern replacement for `File`|
|`Files`|static utility class — read/write/copy/move/delete/list files|
|`FileSystem` / `FileSystems`|abstraction over a filesystem (including ZIPs)|
|`WatchService`|watches a directory for file change events|
|`PathMatcher`|glob/regex-based filename matching|
|`StandardOpenOption`|controls how a file is opened (`CREATE`, `APPEND`, etc.)|
|`StandardCopyOption`|controls copy/move behavior (`REPLACE_EXISTING`, `ATOMIC_MOVE`)|
|`BasicFileAttributes` / `PosixFileAttributes`|file metadata (timestamps, permissions)|
|`FileVisitor` / `SimpleFileVisitor`|callback-based recursive directory traversal|

---

## 6. Low-Level NIO — Buffers/Channels/Selectors (`java.nio`)

|API|Definition|
|---|---|
|`ByteBuffer`, `CharBuffer`, etc.|fixed-size containers for direct buffer manipulation|
|`Channel`|bidirectional, buffer-based I/O connection (alternative to streams)|
|`FileChannel`|channel for file access, supports memory-mapping and locking|
|`MappedByteBuffer`|a file region mapped directly into memory|
|`Selector`|monitors multiple channels for readiness, enabling non-blocking I/O|
|`SocketChannel` / `ServerSocketChannel`|non-blocking network channels|
|`AsynchronousFileChannel` / `AsynchronousSocketChannel`|callback/future-based async I/O|

---

## 7. Concurrency (`java.util.concurrent` and subpackages)

|API|Definition|
|---|---|
|`ExecutorService`|manages a pool of reusable threads for running tasks|
|`Executors`|static factory methods for creating thread pools|
|`Future<V>`|represents the result of an asynchronous computation|
|`Callable<V>`|like `Runnable`, but returns a value and can throw checked exceptions|
|`CompletableFuture<T>`|declarative async programming with chained callbacks|
|`ScheduledExecutorService`|runs tasks after a delay or on a repeating schedule|
|`ForkJoinPool`|thread pool optimized for divide-and-conquer parallel tasks|
|`ThreadPoolExecutor`|fully configurable thread pool implementation|
|`AtomicInteger`, `AtomicLong`, `AtomicReference` (`java.util.concurrent.atomic`)|thread-safe primitives without needing `synchronized`|
|`ConcurrentHashMap`|thread-safe, high-performance `Map` implementation|
|`CopyOnWriteArrayList`|thread-safe `List`, optimized for many reads/few writes|
|`BlockingQueue` / `LinkedBlockingQueue`|thread-safe queue that blocks on full/empty conditions|
|`ReentrantLock` (`java.util.concurrent.locks`)|explicit, flexible locking mechanism (alternative to `synchronized`)|
|`CountDownLatch`|lets threads wait until a set number of events occur|
|`CyclicBarrier`|lets a fixed number of threads wait for each other at a barrier point|
|`Semaphore`|controls access to a limited number of resources|

---

## 8. Networking (`java.net`, `java.net.http`)

|API|Definition|
|---|---|
|`URL` / `URI`|represents a web address / resource identifier|
|`Socket` / `ServerSocket`|blocking TCP client/server connections|
|`HttpClient` (`java.net.http`, Java 11+)|modern HTTP client, supports sync/async requests|
|`HttpRequest` / `HttpResponse`|request/response objects for `HttpClient`|
|`InetAddress`|represents an IP address|

---

## 9. Date & Time (`java.time`, Java 8+)

|API|Definition|
|---|---|
|`LocalDate`|a date without time or timezone (year, month, day)|
|`LocalTime`|a time without date or timezone|
|`LocalDateTime`|combined date and time, no timezone|
|`ZonedDateTime`|date and time with a specific timezone|
|`Instant`|a single point on the timeline (machine-readable, UTC-based)|
|`Duration`|a time-based amount (hours, minutes, seconds)|
|`Period`|a date-based amount (years, months, days)|
|`DateTimeFormatter`|formats/parses date-time objects to/from strings|
|`ZoneId` / `ZoneOffset`|represents a timezone or a fixed UTC offset|

---

## 10. Serialization & Data Formats

|API|Definition|
|---|---|
|`Serializable`|marker interface for native Java serialization|
|`Externalizable`|interface for fully custom serialization logic|
|`ObjectInputFilter` (Java 9+)|restricts which classes can be deserialized (security)|
|_(Jackson `ObjectMapper`)_|not JDK-native, but the de facto standard for JSON — used heavily in Spring Boot|

---

## 11. Reflection (`java.lang.reflect`)

|API|Definition|
|---|---|
|`Class<T>`|runtime metadata representation of a type|
|`Method`|represents a method, allows dynamic invocation|
|`Field`|represents a field, allows dynamic get/set|
|`Constructor<T>`|represents a constructor, allows dynamic instantiation|
|`Proxy`|creates dynamic proxy implementations of interfaces at runtime|

---

## 12. Annotations (`java.lang.annotation`)

|API|Definition|
|---|---|
|`@Override`, `@Deprecated`, `@SuppressWarnings`|built-in standard annotations|
|`@FunctionalInterface`|marks an interface as having exactly one abstract method|
|`Retention`, `Target`|meta-annotations for defining custom annotations|

---

## 13. Regular Expressions (`java.util.regex`)

|API|Definition|
|---|---|
|`Pattern`|a compiled regular expression|
|`Matcher`|applies a `Pattern` against input text, finds/extracts matches|

---

## 14. Security (`java.security`, `javax.crypto`)

|API|Definition|
|---|---|
|`MessageDigest`|computes hashes (SHA-256, MD5, etc.)|
|`KeyPairGenerator` / `KeyPair`|generates public/private key pairs|
|`Cipher` (`javax.crypto`)|performs encryption/decryption|
|`SecureRandom`|cryptographically strong random number generator|

---

## 15. Exceptions (`java.lang`, cross-cutting)

|API|Definition|
|---|---|
|`Exception`|base class for recoverable, checked exceptions|
|`RuntimeException`|base class for unchecked exceptions|
|`Error`|base class for serious, typically unrecoverable JVM problems|
|`NullPointerException`, `ArrayIndexOutOfBoundsException`, `ArithmeticException`|common unchecked exceptions|
|`IOException`, `FileNotFoundException`, `SQLException`|common checked exceptions|

---

## 16. Database Access (`java.sql`, `javax.sql`)

|API|Definition|
|---|---|
|`Connection`|represents a connection to a database|
|`Statement` / `PreparedStatement`|executes SQL queries/updates|
|`ResultSet`|represents the result rows of a query|
|`DriverManager`|manages JDBC driver connections|
|`DataSource` (`javax.sql`)|factory for database connections, typically pooled|

---

## 17. Text Formatting (`java.text`)

|API|Definition|
|---|---|
|`NumberFormat` / `DecimalFormat`|formats numbers (currency, percentages, decimals)|
|`SimpleDateFormat`|legacy date formatting (mostly replaced by `java.time.format`)|
|`MessageFormat`|formats strings with placeholders/parameters|

---

## Quick summary — package-to-purpose map

|Package|Purpose|
|---|---|
|`java.lang`|core language types, always imported|
|`java.util`|collections, utilities, `Scanner`, `Optional`|
|`java.util.stream`|Stream API — functional-style data processing|
|`java.util.function`|functional interfaces for lambdas|
|`java.util.concurrent`|thread pools, futures, thread-safe collections|
|`java.util.concurrent.atomic`|lock-free thread-safe primitives|
|`java.util.concurrent.locks`|explicit locking mechanisms|
|`java.util.regex`|regular expressions|
|`java.io`|classic stream-based I/O|
|`java.nio`|buffers, channels, selectors|
|`java.nio.file`|modern file-system API (`Path`/`Files`)|
|`java.net`|sockets, URLs|
|`java.net.http`|modern HTTP client|
|`java.time`|modern date/time API|
|`java.lang.reflect`|reflection|
|`java.lang.annotation`|custom annotation support|
|`java.security`|cryptographic hashing, keys|
|`javax.crypto`|encryption/decryption|
|`java.sql`|database access (JDBC)|
|`java.text`|legacy text/number/date formatting|

This table covers essentially every API area a working Java/Spring Boot developer encounters regularly — everything we've built up across this entire conversation (I/O, streams, concurrency, threads, collections) fits into this map, and it gives you the vocabulary to recognize what package something belongs to and roughly what it's for, even before you've used it directly.


[[Java]]