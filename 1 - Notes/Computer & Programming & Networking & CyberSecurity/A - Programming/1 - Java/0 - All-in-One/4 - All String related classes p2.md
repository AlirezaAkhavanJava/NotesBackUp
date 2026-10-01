


## 1. `StringCharacterIterator` (java.text)

**Bi-directional iterator** over a `String`. Used by `Format`, `Collator`, and `BreakIterator`.

### Common methods

```java
StringCharacterIterator it = new StringCharacterIterator("Hello");

it.first();          // 'H'  (index 0)
it.last();           // 'o'  (index 4)
it.current();        // 'o'
it.next();           // returns DONE ('\uFFFF') after end
it.previous();       // 'o'
it.setIndex(1);      // 'e'
it.getIndex();       // int
it.getBeginIndex();  // 0
it.getEndIndex();    // 5
it.clone();          // StringCharacterIterator
```

### Forward iteration

```java
StringCharacterIterator it = new StringCharacterIterator("Hello");
for (char c = it.first(); c != CharacterIterator.DONE; c = it.next()) {
    System.out.print(c + " ");   // H e l l o
}
```

### Backward iteration

```java
for (char c = it.last(); c != CharacterIterator.DONE; c = it.previous()) {
    System.out.print(c + " ");   // o l l e H
}
```

### Chain

```java
char lastChar = new StringCharacterIterator("Hello World").last(); // 'd'
```

No further chaining—returns `char` or `StringCharacterIterator`.

---

## 2. `StringReader` (java.io)

A **character stream** whose source is a `String`. Useful for APIs that require a `Reader` but you have a `String`.

### Common methods

```java
StringReader reader = new StringReader("Hello World");

reader.read();              // int (72 = 'H')
reader.read(char[] buf);    // int (number of chars read)
reader.skip(6);             // long
reader.ready();             // boolean
reader.markSupported();     // boolean (always true)
reader.mark(0);             // void
reader.reset();             // void
reader.close();             // void
```

### Full example

```java
try (StringReader reader = new StringReader("Hello World")) {
    int ch;
    while ((ch = reader.read()) != -1) {
        System.out.print((char) ch);   // Hello World
    }
} catch (IOException e) {
    e.printStackTrace();
}
```

### Chain

```java
String content = new BufferedReader(new StringReader("line1\nline2"))
        .lines()
        .collect(Collectors.joining(" | "));
// "line1 | line2"
```

**Chainable:** `BufferedReader` wraps `StringReader`; then `.lines()`, `.readLine()`, etc.

---

## 3. `StringSelection` (java.awt.datatransfer)

A `Transferable` implementation that **transfers a `String`** as plain text. Used with the system clipboard.

### Common methods

```java
StringSelection sel = new StringSelection("Copy me");

sel.getTransferDataFlavors();          // DataFlavor[]
sel.isDataFlavorSupported(DataFlavor.stringFlavor); // boolean
sel.getTransferData(DataFlavor.stringFlavor);       // Object (the String)
sel.lostOwnership(Clipboard, Transferable);         // void (ClipboardOwner)
```

### Clipboard example

```java
StringSelection sel = new StringSelection("Hello Clipboard");
Toolkit.getDefaultToolkit().getSystemClipboard()
       .setContents(sel, sel);

// Paste back
Transferable t = Toolkit.getDefaultToolkit()
                        .getSystemClipboard().getContents(null);
String pasted = (String) t.getTransferData(DataFlavor.stringFlavor);
// "Hello Clipboard"
```

### Chain

```java
String pasted = (String) Toolkit.getDefaultToolkit()
        .getSystemClipboard()
        .getContents(null)
        .getTransferData(DataFlavor.stringFlavor);
```

**Chainable:** via `Transferable` methods; returns `Object`, so cast then chain.

---

## 4. `StringWriter` (java.io)

A **character stream** that collects output in a `StringBuffer`. Used when an API writes to a `Writer` but you want the result as a `String`.

### Common methods

```java
StringWriter writer = new StringWriter();

writer.write("Hello");          // void
writer.write(" World");         // void
writer.append("!");             // StringWriter (chainable)
writer.append('?');             // StringWriter
writer.flush();                 // void
writer.close();                 // void (does nothing)
writer.getBuffer();             // StringBuffer
writer.toString();              // String ← final
```

### Full example

```java
StringWriter writer = new StringWriter();
writer.append("User: ").append("alice")
      .append(", Role: ").append("admin");
String result = writer.toString();
// "User: alice, Role: admin"
```

### Chain

```java
String xml = new StringWriter() {{
    append("<user>").append("alice").append("</user>");
}}.toString();
// "<user>alice</user>"
```

**Chainable:** `append()` returns `StringWriter`; `write()` returns `void`.

---

## 5. `StringContent` (javax.swing.text)

An implementation of `AbstractDocument.Content` that stores text in a **`StringBuffer`**. "Brute-force" implementation suitable for small documents and debugging.

### Common methods

```java
StringContent content = new StringContent();

content.insertString(0, "Hello");        // void
content.insertString(5, " World");       // void
content.getString(0, 11);               // String → "Hello World"
content.length();                        // int
content.remove(0, 5);                    // void
content.getChars(0, 5, Segment);         // void
content.createPosition(6);               // Position
content.getPositionsInRange(Vector, 0, 5); // void
```

### Full example

```java
StringContent content = new StringContent();
content.insertString(0, "Hello");
content.insertString(5, " World");
String text = content.getString(0, content.length());
// "Hello World"

content.remove(0, 6);
String remaining = content.getString(0, content.length());
// "World"
```

### Chain

No chainable methods—all return `void`, `int`, or `String`.

---

## 6. `StringMonitor` (javax.management.monitor)

A **monitor MBean** that observes `String` attributes and sends notifications when the value **matches** or **differs** from a configured string.

### Common methods

```java
StringMonitor monitor = new StringMonitor();

monitor.setObservedAttribute("Status");       // void
monitor.setStringToCompare("OK");             // void
monitor.setNotifyMatch(true);                 // void
monitor.setNotifyDiffer(true);                // void
monitor.setGranularityPeriod(1000);           // void
monitor.start();                              // void
monitor.stop();                               // void
monitor.getStringToCompare();                 // String
monitor.isNotifyMatch();                      // boolean
monitor.isNotifyDiffer();                     // boolean
```

### Full example

```java
StringMonitor monitor = new StringMonitor();
monitor.setObservedAttribute("State");
monitor.setStringToCompare("RUNNING");
monitor.setNotifyMatch(true);
monitor.setNotifyDiffer(true);
monitor.addObservedObject(new ObjectName("com.example:type=Service"));
monitor.setGranularityPeriod(5000);
monitor.start();
```

### Chain

No chainable methods—all setters return `void`.

---

## 7. `StringMonitorMBean` (javax.management.monitor)

**Interface** implemented by `StringMonitor`. Defines the management interface for string monitors.

### Common methods (from the interface)

```java
String getStringToCompare();
void setStringToCompare(String value);
boolean getNotifyMatch();
void setNotifyMatch(boolean value);
boolean getNotifyDiffer();
void setNotifyDiffer(boolean value);
String getDerivedGauge(ObjectName object);
long getDerivedGaugeTimeStamp();
```

### Proxy example

```java
StringMonitorMBean proxy = JMX.newMBeanProxy(
    mbeanServer, monitorName, StringMonitorMBean.class);

proxy.setStringToCompare("OK");
proxy.setNotifyMatch(true);
boolean matching = proxy.getNotifyMatch(); // true
```

### Chain

No chaining—it's an interface for JMX proxies.

---

## 8. `StringRefAddr` (javax.naming)

Represents a **string-form address** of a communications end-point (e.g., a host name or URL). Used in JNDI `Reference` objects.

### Common methods

```java
StringRefAddr addr = new StringRefAddr("URL", "ldap://host:389");

addr.getType();      // String → "URL"
addr.getContent();   // Object → "ldap://host:389"
addr.toString();     // String representation
```

### JNDI Reference example

```java
Reference ref = new Reference(
    "com.example.Widget",
    new StringRefAddr("URL", "rmi://server/Widget"),
    "com.example.WidgetFactory",
    null
);

RefAddr addr = ref.get("URL");
String url = (String) addr.getContent();
// "rmi://server/Widget"
```

### Chain

```java
String url = (String) new Reference(
        "com.example.Widget",
        new StringRefAddr("URL", "rmi://server/Widget"),
        "com.example.WidgetFactory", null)
        .get("URL")
        .getContent();
```

**Chainable:** via `get()` returns `RefAddr`, then `getContent()`.

---

## 9. `StringValueExp` (javax.management)

Represents a **string argument** to a JMX relational constraint. Used with `Query` to build queries like `"Name = 'Alice'"`.

### Common methods

```java
StringValueExp exp = new StringValueExp("Alice");

exp.getValue();          // String → "Alice"
exp.apply(ObjectName);   // ValueExp (applies on MBean)
exp.setMBeanServer(MBeanServer); // void
exp.toString();          // String representation
```

### Query example

```java
QueryExp query = Query.eq(
    Query.attr("Name"),
    new StringValueExp("Alice")
);
Set<ObjectName> results = mbeanServer.queryNames(null, query);
// all MBeans where Name = "Alice"
```

### Chain

No chainable methods—`apply` returns `ValueExp`, which can be used further in query building.

---

## 10. `StringArgument` (com.sun.jdi.connect.Connector)

**Interface** for a `Connector.Argument` whose value is a `String`. Used in the Java Debug Interface (JDI) to specify connector arguments.

### Common methods

```java
Connector.StringArgument arg = ...;

arg.name();          // String
arg.label();         // String
arg.description();   // String
arg.value();         // String
arg.setValue(String); // void
arg.isValid(String);  // boolean
arg.mustSpecify();    // boolean
```

### JDI example

```java
VirtualMachineManager vmm = Bootstrap.virtualMachineManager();
LaunchingConnector connector = vmm.defaultConnector();

Map<String, Connector.Argument> args = connector.defaultArguments();
Connector.StringArgument mainClass = (Connector.StringArgument) args.get("main");
mainClass.setValue("com.example.Main");

VirtualMachine vm = connector.launch(args);
```

### Chain

No chaining—getters return `String` or `boolean`.

---

## 11. `StringReference` (com.sun.jdi)

A **JDI mirror** of a `String` object in the target VM. Represents a string in the debuggee.

### Common methods

```java
StringReference ref = vm.mirrorOf("Hello");

ref.value();          // String → "Hello"
ref.type();           // StringReferenceType
ref.uniqueID();       // long
ref.isCollected();    // boolean
ref.referenceType();  // ReferenceType
ref.invokeMethod(ThreadReference, Method, List, int); // Value
```

### Debugger example

```java
VirtualMachine vm = ...;
StringReference hello = vm.mirrorOf("Hello");
String value = hello.value();   // "Hello"

// Invoke a method on the string
Method lengthMethod = hello.referenceType()
    .methodsByName("length").get(0);
IntegerValue len = (IntegerValue) hello.invokeMethod(
    vm.allThreads().get(0), lengthMethod,
    Collections.emptyList(), 0);
int length = len.value();       // 5
```

### Chain

```java
int length = ((IntegerValue) vm.mirrorOf("Hello")
        .invokeMethod(thread, method, List.of(), 0))
        .value();
```

**Chainable:** via `invokeMethod` returns `Value`, then cast and call `value()`.

---

## Summary table

| Class | Package | Chainable methods | Primary use |
|-------|---------|-------------------|-------------|
| `StringCharacterIterator` | `java.text` | `clone()` | Bi-directional char iteration |
| `StringReader` | `java.io` | Wrap in `BufferedReader` | String → Reader |
| `StringSelection` | `java.awt.datatransfer` | `getTransferData()` | Clipboard transfer |
| `StringWriter` | `java.io` | `append()` | Writer → String |
| `StringContent` | `javax.swing.text` | None | Document content storage |
| `StringMonitor` | `javax.management.monitor` | None | JMX string attribute monitoring |
| `StringMonitorMBean` | `javax.management.monitor` | None | MBean interface |
| `StringRefAddr` | `javax.naming` | `getContent()` via `get()` | JNDI address |
| `StringValueExp` | `javax.management` | `apply()` | JMX query building |
| `StringArgument` | `com.sun.jdi.connect` | None | JDI connector argument |
| `StringReference` | `com.sun.jdi` | `invokeMethod()` → `value()` | Debugger string mirror |




[[Java]]