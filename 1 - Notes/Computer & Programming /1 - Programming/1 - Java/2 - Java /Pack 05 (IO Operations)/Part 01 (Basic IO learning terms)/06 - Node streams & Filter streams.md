
A **basic stream** is one that connects directly to a real data source or destination, and does nothing else. It's the bare pipe. `FileInputStream` is plugged straight into a file, `ByteArrayInputStream` straight into a byte array in memory, and `FileOutputStream` straight into a file you're writing. These are also called **node streams** (or "source streams"), because they sit at the end of the chain, right where the data actually lives. What they can do is limited: read or write raw bytes, one at a time or in small arrays.

---

A **wrapper stream** doesn't connect to a data source itself. Instead, you hand it _another stream_, and it sits around that stream, adding one extra ability. These are also called **filter streams** or "processing streams". `BufferedInputStream` adds buffering, `DataInputStream` lets you read ints and doubles instead of raw bytes, and `GZIPInputStream` decompresses on the fly. A wrapper can't work alone, because it has nothing to read from until you give it a pipe to wrap.

Here they are together:

```java
InputStream basic = new FileInputStream("data.txt");        // basic: talks to the file
InputStream wrapped = new BufferedInputStream(basic);       // wrapper: adds buffering

// usually written in one line, stacked up:
InputStream in = new BufferedInputStream(new FileInputStream("data.txt"));
```

You only ever read from the outermost one (`in`). When you call `in.read()`, the wrapper does its extra job and then asks the stream inside it for the data, which asks the file. Each layer passes the request inward, and the data flows back out through the layers.

The analogy is adapters snapped onto the end of a hose, each adding one feature. It breaks down in one spot: with a real hose you could connect the pieces in any order, but with streams the order matters. `new GZIPInputStream(new BufferedInputStream(new FileInputStream(...)))` is sensible, since you decompress what the buffer hands you, but a wrapper has to be given a stream that makes sense for it. A `DataInputStream` wrapped around a file that doesn't contain data written in its format will happily give you nonsense.


[[Java]]
[[IO]]