
The story of computers and programming is a story of people trying to stop doing repetitive work by hand, so I'll build it as a timeline with the key ideas first.

**Analogy:** Think of a music box versus a piano. A music box plays one fixed tune built into its mechanism. A piano plays anything, as long as someone feeds it instructions (the notes). The history of computing is the journey from music boxes to pianos: from machines hardwired for one task to machines you can _instruct_ to do anything.

## Timeline

**Before electronics (1800s)**

- **1801, Jacquard loom:** punched cards controlled which threads the loom wove. This was the first time a machine's behavior was changed by swapping a card instead of rebuilding the machine. That is the seed of "programming."
- **1830s-40s, Charles Babbage and Ada Lovelace:** Babbage designed the _Analytical Engine_, a mechanical general-purpose computer (never fully built). Ada Lovelace wrote an algorithm for it to compute Bernoulli numbers, and is widely credited as the **first programmer**.

**Theory (1930s)**

- **1936, Alan Turing:** described the _Turing machine_, a mathematical model proving that one machine, given the right instructions, can compute anything computable. This is the theoretical foundation of every modern computer.

**First electronic computers (1940s)**

- **1945, ENIAC:** a room-sized electronic computer. "Programming" meant physically rewiring cables and flipping switches, which took days.
- **1945-49, stored-program concept (von Neumann, EDSAC and others):** the breakthrough that the _program itself_ is stored in memory as data, next to the data it works on. Now changing the program meant loading new data, not rewiring. This is the architecture your Debian machine still uses.

**Programming languages (1950s onward)**

- Early on you wrote **machine code** (raw 0s and 1s), then **assembly** (human-readable abbreviations like `ADD`, `MOV`).
- **1957, FORTRAN:** one of the first high-level languages, so you could write math-like formulas and a **compiler** translated them to machine code.
- **1959, COBOL** (business) and **LISP** (AI research).
- **1970, C** (Dennis Ritchie): fast, close to hardware. Unix and Linux, which Debian is built on, are written in it.

**Personal and networked era**

- **1970s-80s:** personal computers (Apple II, IBM PC).
- **1969-83:** ARPANET becomes the Internet (TCP/IP standardized in 1983), which connects directly to your networking lesson.
- **1991:** Linus Torvalds starts Linux. **1993:** Debian begins.
- **1989-91:** the World Wide Web (HTTP), the basis of REST APIs.

**Java and your world**

- **1995, Java** (James Gosling at Sun): "write once, run anywhere," because Java compiles to _bytecode_ that runs on the JVM on any OS.
- **2004, Maven** and **2002-2014, Spring** (Spring Boot arrived in 2014), built to reduce Java boilerplate.
- **1970s, SQL** and relational databases (Codd's model); **2000, SQLite**.

## The pattern behind it all

Each step added a **layer of abstraction**: hardware, then machine code, then assembly, then high-level languages, then libraries, then frameworks like Spring Boot. Each layer hides the one below, so you can do more with less effort. This is the same idea you saw with APIs.

```
Spring Boot  ->  Java  ->  Bytecode  ->  JVM  ->  OS (Debian)  ->  Hardware
```

## Gotchas

- **"First computer" is disputed:** it depends on whether you mean mechanical (Babbage), electronic (ENIAC, the Colossus machines in Britain), or stored-program (the Manchester Baby, 1948).
- **"Computer" originally meant a person** who did calculations by hand; the machines took over the name.
- **Dates for languages** vary slightly by source (design date vs. first release), so treat them as approximate.



[[Java]]

