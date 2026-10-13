



```
                              Reader
                                |
        ┌───────────────────────┼───────────────────────┐
        |                       |                       |
  CharArrayReader        InputStreamReader        FilterReader
        |                       |                       |
        |              ┌────────┴────────┐     ┌────────┼────────┐
        |              |                 |     |        |        |
        |       FileReader         (bridge) PushbackReader       |
        |                                  BufferedReader        |
        |                                                        |
        |                                                 LineNumberReader
        |
   PipedReader
        |
   StringReader

                               Writer
                                |
        ┌───────────────────────┼───────────────────────┐
        |                       |                       |
  CharArrayWriter        OutputStreamWriter       FilterWriter
        |                       |                       |
        |              ┌────────┴────────┐     ┌────────┼────────┐
        |              |                 |     |        |        |
        |       FileWriter         (bridge) BufferedWriter       |
        |                                  PrintWriter           |
        |                                                        |
        |                                                    (see below)
        |
   PipedWriter
        |
   StringWriter
```

**Note on placement:**
- `FileReader` / `FileWriter` are technically subclasses of `InputStreamReader` / `OutputStreamWriter` (they're convenience bridges that assume default charset).
- `PrintWriter` actually extends `Writer` directly (not `FilterWriter`), but functionally acts as a filtering writer.

---

```
                    ┌────────────────────────────────────────────┐
                    │  HELPER CLASSES FOR CHARACTER STREAMS      │
                    └────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                      File System Helpers                             │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   File           - Abstract pathname representation                  │
│   Files          - Static utilities (readAllLines, newBufferedReader)│
│   Path / Paths   - NIO.2 path handling                               │
│   FileDescriptor - Underlying file handle                            │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                    Byte ↔ Char Bridge Helpers                        │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│   InputStreamReader    - InputStream  → Reader  (bytes → chars)       │
│   OutputStreamWriter   - OutputStream → Writer  (chars → bytes)       │
│   FileReader           - Convenience: FileInputStream + default charset│
│   FileWriter           - Convenience: FileOutputStream + default charset│
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                       Encoding / Charset Helpers                      │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│   Charset           - Named character encoding (UTF-8, etc.)          │
│   CharsetDecoder    - Bytes → Characters                              │
│   CharsetEncoder    - Characters → Bytes                              │
│   StandardCharsets  - Predefined charset constants                    │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                    Parsing / Formatting Helpers                       │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│   Scanner           - Parse primitives & strings from a Reader        │
│   PrintWriter       - Formatted text output (printf, println)         │
│   Formatter         - Low-level formatting engine (used by printf)    │
│   String.format     - Static formatting utility                       │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                    Exception / Error Helpers                          │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│   IOException           - Base checked I/O exception                  │
│   FileNotFoundException - File missing / can't open                   │
│   UncheckedIOException  - Wraps IOException (for lambdas)             │
│   MalformedInputException   - Byte sequence invalid for charset       │
│   UnmappableCharacterException - Char can't encode in charset         │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                      Utility / Convenience Helpers                    │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│   System.in / System.out / System.err  - Predefined streams           │
│   Files.newBufferedReader / newBufferedWriter                          │
│   Files.readAllLines / write                                     │
│   IOUtils (Apache Commons)   - readLines, write, copy helpers         │
│   CharStreams (Guava)        - Static character stream utilities      │
│   Stream / Collectors        - lines() → Stream<String>               │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                    Third-Party / Legacy Helpers                       │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│   StringTokenizer    - Legacy tokenizer (prefer String.split/Scanner)│
│   StreamTokenizer    - Tokenize a Reader into tokens                  │
│   LineNumberReader   - BufferedReader with line tracking              │
│   PushbackReader     - Reader that can "unread" characters            │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

[[Java]]
[[IO]]