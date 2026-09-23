

Before you touch Spring Boot, you need a clear picture of _what_ you're building and _why_. This is the step most self-taught devs skip — and it's exactly why apps end up with tangled logic and constant rewrites. Let's do it properly, using a small **Library Management System** as our running example (simple enough to grasp, complex enough to be realistic).

---

## 1. What Requirements Engineering Actually Is

It's the process of figuring out, before coding:

- **What** the system must do (functional requirements)
- **How well** it must do it (non-functional requirements)
- **What concepts/entities** exist in the problem domain (domain model)

Four phases, in order:

```
Elicitation → Analysis → Specification → Modeling
   (gather)     (refine)    (document)    (diagram)
```

We'll walk through each one.

---

## 2. Elicitation — Gathering Requirements

This is where you figure out what the stakeholders actually need. In a real job, this means interviews, surveys, watching users work. When you're the one building a personal/learning project, you do this by **writing down user goals in plain language**.

**Example — Library Management System, raw notes:**

- Members should be able to search for books
- Members can borrow up to 3 books at a time
- A librarian manages the book catalog (add/remove/update books)
- The system tracks who has which book and when it's due
- Overdue books should be flagged
- Members shouldn't be able to borrow a book that's already checked out

Nothing formal yet — just capturing intent.

---

## 3. Analysis — Turning Notes into Requirements

Now we classify and refine. This is where ambiguity gets squeezed out.

### a) Functional Requirements (FR)

What the system **does**. Write them as clear, testable statements, usually numbered:

|ID|Requirement|
|---|---|
|FR1|The system shall allow a member to search books by title, author, or ISBN|
|FR2|The system shall allow a member to borrow a book if it is available and their active loan count is below 3|
|FR3|The system shall allow a librarian to add, update, or remove a book from the catalog|
|FR4|The system shall record the due date when a book is borrowed (14 days from loan date)|
|FR5|The system shall mark a loan as "overdue" if the current date exceeds the due date|
|FR6|The system shall prevent borrowing a book with zero available copies|

Notice the pattern: **"The system shall [do X] when [condition]."** This phrasing forces you to be precise — vague requirements produce vague code.

### b) Non-Functional Requirements (NFR)

**How well** the system behaves — quality attributes, not features.

|Category|Example|
|---|---|
|Performance|Search results should return in under 500ms for a catalog of 100k books|
|Security|Only authenticated librarians can modify the catalog|
|Usability|Error messages must clearly state why a borrow request failed|
|Scalability|System should support 10,000 concurrent members (aspirational, but good to state)|
|Maintainability|Business rules (e.g., "3 book limit") must be configurable, not hardcoded|

NFRs matter because they influence _architecture decisions_ — e.g., "must be configurable" tells you to use `application.properties` instead of a magic number in code.

---

## 4. Specification — Use Cases & User Stories

Now we describe **how** functional requirements play out as interactions. Two common formats:

### a) User Stories (lightweight, Agile-style)

```
As a [role], I want to [action], so that [benefit].
```

- As a **member**, I want to **search for a book by title**, so that **I can find it quickly without browsing the whole catalog**.
- As a **member**, I want to **borrow an available book**, so that **I can read it**.
- As a **librarian**, I want to **see all overdue loans**, so that **I can follow up with members**.

Good for backlogs and sprints. Light on detail.

### b) Use Cases (heavier, more formal — better for learning system design)

A full use case documents the **flow of interaction**, including what goes wrong.

**Use Case: Borrow Book**

|Field|Detail|
|---|---|
|**Actor**|Member|
|**Precondition**|Member is logged in; book exists in catalog|
|**Main flow**|1. Member searches for a book.<br>2. System shows availability.<br>3. Member selects "Borrow."<br>4. System checks member's active loan count < 3.<br>5. System checks book has available copies.<br>6. System creates a Loan record with due date = today + 14 days.<br>7. System decrements available copy count.|
|**Alternate flow**|4a. If loan count ≥ 3 → system rejects with message "Borrow limit reached."<br>5a. If no copies available → system rejects with message "Book unavailable."|
|**Postcondition**|Loan is recorded; copy count is updated|

This table maps _almost directly_ to your service method later:

```java
public Loan borrowBook(Long memberId, Long bookId) {
    // step 4: check loan count
    // step 5: check availability
    // step 6-7: create loan, decrement copies
}
```

That's the whole point of doing this first — **the use case becomes your method's logic outline**, before you've written any Spring code.

---

## 5. Modeling — The Domain Model

This is where we go back to your earlier question about "domain." Now we identify the **nouns** from our requirements and turn them into a domain model — the entities, their attributes, and relationships.

### Step 1 — Extract candidate entities (nouns) from requirements

Scan FR1–FR6 above: _member, book, catalog, loan, librarian, due date, copy..._

### Step 2 — Decide which are real entities vs. attributes

- `Book` → entity (has identity, lifecycle)
- `Member` → entity
- `Loan` → entity (a _relationship_ between Member and Book, but important enough to have its own identity — due dates, status)
- `dueDate` → just an attribute of `Loan`, not its own entity

### Step 3 — Define attributes and relationships per entity

**Book**

- id, title, author, isbn, totalCopies, availableCopies

**Member**

- id, name, email, activeLoanCount (or derive it)

**Loan**

- id, book (→ Book), member (→ Member), loanDate, dueDate, returnDate, status (ACTIVE / RETURNED / OVERDUE)

### Step 4 — Draw the relationships (UML class diagram, simplified)

```
 Member (1) ────────── (0..*) Loan (*) ────────── (1) Book
        "borrows"                        "is borrowed as"
```

- One Member can have many Loans
- One Book can appear in many Loans (over time)
- Loan is the **association class** connecting them — this is exactly why it becomes its own entity, not just a join table with no meaning

This diagram is the direct blueprint for your `@Entity` classes and their `@OneToMany` / `@ManyToOne` annotations later.

---

## 6. Putting It All Together — The Full Pipeline

Here's how each artifact you produce leads into the next:

```
Raw notes
   ↓
Functional + Non-Functional Requirements  →  guide WHAT features to build
   ↓
Use Cases / User Stories                  →  guide HOW each feature flows,
   ↓                                          becomes your service method logic
Domain Model (entities + relationships)   →  becomes your @Entity classes
   ↓
(Next step, not covered yet) API design   →  becomes your @RestController endpoints
```

Notice this matches the clean architecture from the last tutorial:

- **Domain model** → `domain/` package (`Book`, `Member`, `Loan`)
- **Use case steps** → `service/` package logic
- **FR/NFR constraints** (e.g., "max 3 loans", "14-day due date") → constants or config, not hardcoded magic numbers scattered in code

---

## 7. A Template You Can Reuse for Any Project

When you start a new app, work through these in order:

1. **Brain-dump** — write 5–10 plain-English sentences about what the app should do
2. **Split into FR / NFR** — number them
3. **Pick 3–5 core use cases** — write main flow + at least one alternate/error flow for each
4. **Extract nouns → candidate entities** — decide entity vs. attribute
5. **Draw relationships** — even a rough box-and-arrow sketch is enough
6. **Only then** — open your IDE

---




[[Java]]
[[0 - Spring Framework]]