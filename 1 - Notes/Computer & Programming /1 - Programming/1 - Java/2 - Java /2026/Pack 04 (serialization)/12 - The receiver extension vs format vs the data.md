


## 1. Short answer

It depends on **neither the extension nor the object's data**. It depends on the **format** you chose when serializing.

1. **Format** (Java native, JSON, Protobuf...) decides what the bytes look like and which reader can open them.
2. **The object's data** (fields and values) only fills in the content. A `Person` and an `Order` can both be saved as JSON.
3. **The file extension** is just a label for humans and tools. Java ignores it completely.

## 2. Mental model: shipping labels

A sealed box can have any label on it ("books", "misc", "fragile"). The label doesn't change what is inside, and the person opening it still needs to know how it was packed. The extension is the label, and the format is the packing method.

## 3. Extensions are conventions

|Format|Conventional extension|Content you'd see|
|---|---|---|
|Java native|`.ser` (or `.bin`, `.dat`)|Binary, begins with `AC ED 00 05`|
|JSON|`.json`|Readable text|
|Protobuf|`.pb` or `.bin`|Binary, no class names|
|XML|`.xml`|Readable text|
|Plain text|`.txt`|Readable text|
|Markdown|`.md`|Text meant for documents|

You can save native serialization as `person.txt` and it still works, because `ObjectInputStream` reads the bytes and never looks at the name. But the name would lie:

- Opening it in an editor shows garbage characters.
- Other people and tools will assume it is readable text.

**`.md` is wrong for data.** Markdown is a document format for humans. Don't use it to hold serialized objects, except maybe to _show_ a JSON example inside documentation.

## 4. Proof on your Debian machine

The first bytes identify the real format, whatever the extension says:

```bash
xxd -l 16 person.ser
# 0000: aced 0005 7372 0006 5065 7273 6f6e  ....sr..Person

file person.ser
# Java serialization data, version 5

head -c 40 person.json
# {"name":"Alice","age":25}
```

`AC ED 00 05` is the Java serialization magic number. `file` can recognise it by content, not by the name.

## 5. What the receiver looks like

The receiver is **code**, not a file. It must use the reader that matches the format.

Native Java:

```java
try (var in = new ObjectInputStream(new FileInputStream("person.ser"))) {
    Person p = (Person) in.readObject();
}
```

JSON:

```java
Person p = mapper.readValue(new File("person.json"), Person.class);
```

Names are irrelevant here, but **the pairing is strict**:

|Written with|Must be read with|
|---|---|
|`ObjectOutputStream`|`ObjectInputStream`|
|Jackson (JSON)|Jackson, or any JSON parser|
|Protobuf|The Protobuf parser for the same `.proto` schema|

## 6. Gotchas

- **Wrong reader, wrong format.** Reading a JSON file with `ObjectInputStream` throws:
    
    ```
    StreamCorruptedException: invalid stream header: 7B226E61
    ```
    
    Those four bytes are the ASCII for `{"na`, so the reader found text where it expected `AC ED`. This error message is a good clue that the format is mismatched.
- **Binary in text mode gets corrupted.** Reading a binary file with a `Reader`, or transferring it in an ASCII mode (old FTP, some copy tools), changes bytes and breaks it. Treat binary data as bytes only.
- **Over a network there is no file name at all.** The receiver learns the format from a header, as with HTTP `Content-Type: application/json`. Java native has a type for this too (`application/x-java-serialized-object`), and `application/octet-stream` is the generic "unknown binary".
- **Same format, different class.** A native `.ser` file is meaningless without the matching `Person` class (name and `serialVersionUID`). A JSON file only needs the _shape_ to match.
- **Extensions help tools.** IDEs, file managers, and `grep` workflows behave better when `.json` means JSON, so use the conventional names even though Java doesn't need them.

## 7. Summary

```
Object data   ──▶ decides the CONTENT (the values)
Format choice ──▶ decides the BYTES and the matching reader
Extension     ──▶ only a human label
```

Use `.ser` for native Java, `.json` for JSON, and make the receiver's code match the format that was written.




[[Serialization]]