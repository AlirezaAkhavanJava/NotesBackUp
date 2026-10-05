

**Serialized bytes are a message, and a message is only useful to a reader who understands two things:**

1. **The format:** how the bytes are laid out (Java native, JSON, Protobuf).
2. **The meaning:** what the fields represent (a `Person` with name and age).

Everything below follows from this.

---

## Part 1: Storage. Why save it, and who reads it?

Storage is a message to the **future**. The reader is whoever runs later and needs that state.

Scenarios:

1. **The same program, after a restart.** A game saves your progress and loads it next launch. The reader is the same code.
2. **A newer version of the same program.** You update the app, and it reads data the old version wrote. The classes are similar but not identical, which is why `serialVersionUID` exists.
3. **A different Java program.** A reporting tool reads the `.ser` file your app wrote. It must have the `Person` class on its classpath, and it can't use the data without it.
4. **A Go (or Python) program.** It **cannot** read Java native serialization in any practical way. The bytes follow Java's private format, and Go has no `Person` class to rebuild. This is the main reason JSON or Protobuf is used when other languages are involved.
5. **A human or a tool.** With JSON you can open the file in an editor, search it, or load it into a database.

You can see the difference directly. Java native output is binary, starting with the magic bytes `AC ED 00 05` and containing the class name. JSON is plain readable text:

```
Java native:  AC ED 00 05 73 72 00 06 50 65 72 73 6F 6E ...   (binary, Java-only)
JSON:         {"name":"Alice","age":25}      (text, any language)
```

**Why not just keep the object in memory?** Because memory dies with the process. Storage is how state survives the program.

---

## Part 2: Network. What is actually sent?

**Not bytecode. Just the data bytes.** The `.class` file does not travel.

### What travels

For native Java serialization: the class name, the `serialVersionUID`, and the field values. For JSON: just the field values as text. Never the methods, never the code.

### "Is it in a file?"

No. A file is just one place bytes can live (on disk). On a network, the bytes live in **memory buffers** and are pushed through a connection. The same bytes can go either way, which is why Java's streams are designed like this:

```java
// To a file
var out1 = new ObjectOutputStream(new FileOutputStream("person.ser"));
out1.writeObject(person);

// To a network connection: identical code, different destination
var out2 = new ObjectOutputStream(socket.getOutputStream());
out2.writeObject(person);
```

`ObjectOutputStream` doesn't care where the bytes go. It wraps any `OutputStream`. So "file or network" is a choice of destination, not a different kind of data.

### What the receiver needs

1. **A program already running and listening.** The network doesn't start programs. Your bytes arrive at an IP address and port, and some process must already be waiting there (a Spring Boot app listening on port 8080, for example).
2. **Knowledge of the format and meaning.** That program already has its own code, with the `Person` class (Java native) or a schema or class that matches the JSON shape.

Numbered flow for one request:

1. Your program builds a `Person` object.
2. It serializes it to bytes (JSON, in this example).
3. Those bytes become the **body** of an HTTP request.
4. The operating system splits them into TCP packets and sends them.
5. The server's OS reassembles the packets and hands the bytes to the listening program.
6. The program deserializes them into its own `Person` object.

### What it looks like on the wire

HTTP is just text with a structure. This is a real request:

```
POST /person HTTP/1.1
Host: server.example.com
Content-Type: application/json
Content-Length: 25

{"name":"Alice","age":25}
```

The `Content-Type` header tells the receiver the **format**. That is the "format agreement" from the top of this answer, written down explicitly.

---

## The WWW case: where code does travel

This is probably the source of the confusion, because on the web **code does travel**, but it is a separate thing from serialized data.

|What travels|Example|Is it code or data?|
|---|---|---|
|HTML / CSS|A web page|Description of a page|
|**JavaScript source**|`<script src="app.js">`|**Code**. The browser downloads and runs it|
|JSON|The response to `fetch("/person")`|**Data**. The state of an object|
|Images, video||Data|

When you open a site:

1. The browser requests the page and receives **HTML and JavaScript (code)**.
2. That JavaScript runs in your browser.
3. It calls your Spring Boot server with `fetch("/api/person")` and receives **JSON (data)**.
4. It turns the JSON into a JavaScript object and shows it.

So the browser got the **program** from one request and the **state** from another. The program already existed on the receiving side before the data arrived, which is the same rule as before: the code comes first (or separately), and the data fills it in.

### When Java bytecode does travel

Bytecode is sent in specific, separate situations, never as part of serialization:

- **Deployment:** you copy a `.jar` to a server so it can run your app.
- **Downloading libraries:** Maven fetches JARs from a repository.
- **Old Java applets:** a browser downloaded and ran bytecode (this technology is dead).
- **RMI codebase:** an old mechanism for downloading classes remotely, now disabled by default.

Notice that all of these are about getting the **program** somewhere. Serialization is about getting the **state** somewhere. Two different jobs.

---

## Gotchas

- **"Looks sent" is not "was received."** The bytes might be lost, truncated, or arrive when no one is listening. Networks need acknowledgments and retries, which is where TCP and idempotency come in.
- **Sending a class name is a security risk.** Native Java serialization tells the receiver _which class to instantiate_, so an attacker chooses what gets built. JSON with Jackson targets a class **you** specified in your code (`PersonDto.class`), so the sender doesn't choose. This is another reason JSON is safer at trust boundaries.
- **Encoding matters.** "Bytes" must be agreed on too: JSON text is normally UTF-8. A mismatch garbles non-ASCII characters.
- **Same bytes, different lifetime.** A file in storage might be read a decade later. A network message is usually read within milliseconds. Version compatibility problems are much worse for the first.

---

## Mental model

```
CODE  (the class, the program)   ──▶ installed on each machine beforehand
STATE (the field values)         ──▶ serialized, travels or is stored

Reader needs:  [format knowledge] + [its own code that understands the meaning]
```

The sender and receiver never share objects or memory. They share a **message format** and each run their own code.






[[Serialization]]
[[Networking]]