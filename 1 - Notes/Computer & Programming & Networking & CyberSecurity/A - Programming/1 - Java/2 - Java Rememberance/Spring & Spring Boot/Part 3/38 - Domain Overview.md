

## 1. What a Domain Overview Is

A **Domain Overview** is a short, prose-based section — usually the _first_ thing you write in a requirements or design document — that describes:

- **What problem space the system operates in** (the business/subject-matter context)
- **The key concepts and vocabulary** used in that space (a shared "language")
- **The boundaries** of what's in-scope vs. out-of-scope
- **The core actors/roles** who interact with the domain

It's **not** the same as the Domain Model (the entities/attributes/relationships diagram we built last time). Think of it this way:

|Domain Overview|Domain Model|
|---|---|
|Prose, narrative|Diagram, structured (classes/attributes)|
|Establishes shared _vocabulary_|Establishes _structure_|
|Written for humans (stakeholders, new devs)|Written to be translated into code|
|Comes **first**|Comes **after**, built from the vocabulary|

In Domain-Driven Design (DDD) terms, the Domain Overview is where you establish the **Ubiquitous Language** — the exact words the team and the business agree to use consistently, in conversation _and_ in code. This matters more than it sounds: if the business says "member" but your code says "customer," every conversation and every code review carries translation overhead and bugs slip through the cracks.

---

## 2. Why It Matters (and why skipping it hurts later)

If you jump straight from raw notes to entity diagrams, you tend to:

- Mix up terms (is it a "loan" or a "borrowing" or a "checkout"?) — and end up with `Loan`, `Borrowing`, and `checkoutRecord` all in the same codebase
- Miss domain boundaries — e.g., accidentally modeling "payment processing" when your system was only ever supposed to _reference_ an external payment system
- Confuse two different meanings of the same real-world word

A Domain Overview forces you to nail down language and scope **before** anyone writes an `@Entity`.

---

## 3. What a Domain Overview Contains

A good Domain Overview has four parts. Let's build each one using our **Library Management System** example.

### a) Domain Purpose (1–2 sentences)

A plain statement of what business/problem area this system supports.

> _This system supports the day-to-day operation of a library: managing a catalog of books, tracking which members currently have which books, and enforcing library policies on borrowing._

### b) Glossary of Domain Terms

This is the heart of the Domain Overview. List every important noun from your requirements (remember, we extracted these in the "Analysis" step) and **define it precisely, in one sentence, using the exact term you'll use everywhere else** — in conversation, in docs, and later in code.

|Term|Definition|
|---|---|
|**Book**|A title held by the library; may have multiple physical **copies**|
|**Copy**|One physical instance of a Book; a Book can have 0 or more Copies|
|**Member**|A person registered with the library who is permitted to borrow Copies|
|**Librarian**|A staff user who manages the catalog and can view/administer Loans|
|**Loan**|A record of a Member borrowing a specific Copy, with a loan date and due date|
|**Overdue**|A Loan whose due date has passed without the Copy being returned|
|**Catalog**|The complete collection of Books the library holds, regardless of copy availability|

Notice `Book` vs `Copy` — that distinction didn't come up explicitly in our earlier FRs (we said "book" loosely), but a real library domain needs it: a title can exist even when every physical copy is checked out. **This is exactly the kind of thing a Domain Overview catches before it becomes a modeling mistake** — if you'd gone straight to a diagram, you might have given `Book` an `available: boolean` field, which breaks the moment there's more than one copy.

This is also why the glossary step often _feeds back_ and revises your earlier requirements:

> FR6 revised: _The system shall prevent borrowing when a Book has zero available Copies_ (previously said "book" ambiguously)

### c) Domain Boundaries (Scope)

State explicitly what's **inside** this system's responsibility and what's **outside** it (handled by another system, a human process, or simply not built).

|In Scope|Out of Scope|
|---|---|
|Tracking Books, Copies, Members, Loans|Payment/fine processing (assume a separate finance system)|
|Enforcing borrow limits and due dates|Physical security (RFID gates, alarms)|
|Flagging overdue Loans|Sending automated overdue emails (future phase)|

This prevents scope creep and clarifies integration points — e.g., "fine processing" being out of scope tells you your `Loan` entity doesn't need a `fineAmount` field yet, but it _might_ need a hook (like a domain event) for a future system to consume.

### d) Key Actors / Roles

List who (or what external system) interacts with the domain, and their relationship to it.

|Actor|Role in the Domain|
|---|---|
|**Member**|Browses catalog, borrows/returns Copies|
|**Librarian**|Manages Books/Copies, oversees Loans|
|**(future) Notification System**|External — will consume overdue events (out of scope for now)|

---

## 4. The Full Domain Overview — Assembled

Here's what it looks like as a real document section (this is what you'd actually write down, e.g. in a `docs/domain-overview.md` file):

```markdown
## Domain Overview — Library Management System

### Purpose
This system supports the day-to-day operation of a library: managing
a catalog of books, tracking which members currently hold which
copies, and enforcing library borrowing policies.

### Glossary
- **Book** — a title in the catalog; may have multiple physical copies.
- **Copy** — one physical instance of a Book.
- **Member** — a registered person permitted to borrow Copies.
- **Librarian** — staff who manage the catalog and oversee Loans.
- **Loan** — a record of a Member borrowing a Copy, with loan/due dates.
- **Overdue** — a Loan past its due date, not yet returned.
- **Catalog** — the full collection of Books.

### In Scope
- Catalog management (Books, Copies)
- Loan lifecycle (borrow, return, overdue detection)
- Borrow-limit enforcement

### Out of Scope
- Fine/payment processing
- Physical security systems
- Automated notifications (future phase)

### Actors
- Member — browses, borrows, returns
- Librarian — manages catalog, oversees loans
```

---

## 5. Where This Fits in the Pipeline

Updating the pipeline from last time — Domain Overview sits **between** requirements and the formal Domain Model:

```
Raw notes
   ↓
Functional + Non-Functional Requirements
   ↓
Use Cases / User Stories
   ↓
Domain Overview  ← (NEW — vocabulary + scope + actors, in prose)
   ↓
Domain Model     ← (entities, attributes, relationships — now using consistent terms)
   ↓
Spring Boot code (domain/, service/, repository/, controller/)
```

Notice the domain overview's glossary (`Book`, `Copy`, `Member`, `Loan`) maps **directly and unambiguously** into your `@Entity` class names later — because you already agreed on the vocabulary before drawing a single box on a diagram.

---

## 6. Quick Template You Can Reuse

For any new project:

1. **Purpose** — 1–2 sentences: what real-world process does this support?
2. **Glossary** — every important noun from your requirements, one precise definition each, using the term consistently everywhere after this point
3. **In Scope / Out of Scope** — a two-column table; be explicit about what you're _not_ building
4. **Actors** — who (or what external system) touches this domain




[[Java]]
[[0 - Spring Framework]]