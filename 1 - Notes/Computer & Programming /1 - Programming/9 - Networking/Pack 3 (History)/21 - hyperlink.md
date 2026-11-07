
## 1. What is a hyperlink?

A **hyperlink** is a reference inside one document that lets you jump to another resource or another location.

For example:

```html
<a href="https://example.com/about">About</a>
```

The important part is:

```text
About
  │
  └── hyperlink → https://example.com/about
```

When you click **About**, the browser follows the reference and retrieves that resource.

So:

> **A hyperlink is a navigable reference connecting one resource to another.**

---

## 2. What problem did hyperlinks solve?

Before hypertext, documents were mostly **isolated**.

Imagine you have:

```text
Document A
Document B
Document C
```

To get from A to B, you might need to know where B is and manually locate it.

Hyperlinks create:

```text
Document A ─────→ Document B
      │
      └──────────→ Document C
```

Now information can be **connected**, rather than existing as independent documents.

This solved a fundamental information-retrieval problem:

> **How do you navigate from one piece of related information directly to another?**

This is why the Web became a **network of documents**, not merely a collection of downloadable files.

---

# 3. Who invented the hyperlink?

This needs a historical distinction.

The **idea of hypertext predates the Web**.

### Vannevar Bush — 1945

Vannevar Bush described an idea called the **Memex** in his 1945 essay _As We May Think_.

He imagined information being connected through **associative trails**:

```text
Information A
      │
      └────→ related Information B
                    │
                    └────→ Information C
```

He did **not** invent the Web or the modern HTML hyperlink, but his ideas strongly influenced later hypertext systems.

### Ted Nelson — 1960s

Ted Nelson coined the term **hypertext** in the 1960s and developed the concept of interconnected documents.

### Douglas Engelbart — 1960s

Douglas Engelbart implemented working hypertext systems. His **NLS (oN-Line System)** demonstrated clickable links between information.

So the history is roughly:

```text
1945  Bush
      ↓
      associative information connections

1960s Nelson
      ↓
      "hypertext" concept

1960s Engelbart
      ↓
      working hypertext systems

1989  Tim Berners-Lee
      ↓
      hypertext + Internet + HTTP + HTML + URL

1990s Web
      ↓
      billions of hyperlinks
```

---

# 4. What did Tim Berners-Lee actually invent?

Tim Berners-Lee did **not invent the general idea of hyperlinks**.

He created a practical system for using hypertext **across a network**.

The Web combined several pieces:

```text
HTML
  ↓
describes documents

URL
  ↓
identifies/locates resources

HTTP
  ↓
transfers resources

Hyperlinks
  ↓
connect resources

Internet
  ↓
provides the network
```

This combination created the **World Wide Web**.

That was the major breakthrough.

---

# 5. What is a "link" then?

In the Web context, a **link** is usually shorthand for a hyperlink.

For example:

```html
<a href="https://google.com">Google</a>
```

The relationship is:

```text
"Google"
   │
   │ hyperlink
   ↓
https://google.com
```

Technically, there are different kinds of links in computing, but when discussing the history of the Web, **link ≈ hyperlink**.

---

# 6. Why did links become extremely important to Google?

This is where **PageRank** becomes interesting.

Once the Web became popular, you had something like:

```text
Page A ──→ Page B
   │
   ├──────→ Page C
   │
   └──────→ Page D

Page B ──→ Page C

Page C ──→ Page A
```

The Web had become a gigantic **directed graph**.

```text
Pages      = nodes
Hyperlinks = directed edges
```

This was an enormous source of information.

But there was a problem:

> **How do you determine which pages are important?**

---

# 7. PageRank's key insight

Before PageRank, a search engine could primarily ask:

> "Does this page contain the words the user searched for?"

But suppose you search:

```text
computer networking
```

There could be millions of pages containing those words.

Which one should appear first?

PageRank used the **link structure of the Web** as an additional signal.

The basic idea was:

> **A link from one page to another can be treated as a signal that the destination page is important.**

But there's an important refinement:

```text
Page A ─────→ X
Page B ─────→ X
Page C ─────→ X
```

Three links to X doesn't automatically mean X is important.

Consider:

```text
RandomPage1 ──→ X
RandomPage2 ──→ X
RandomPage3 ──→ X
```

versus:

```text
HighlyImportantPage ──→ X
```

The second link could carry much more weight.

So PageRank became recursive:

```text
Important pages
       │
       │ link to
       ↓
    Page X
       │
       ↓
Page X becomes more important
```

And therefore:

```text
A page's importance
        depends partly on
the importance of pages linking to it
```

---

# 8. The connection between hyperlinks and PageRank

This is the important mental model:

### Hyperlinks created the graph.

```text
A ──→ B ──→ C
│         ↗
└────→ D
```

### PageRank analyzed the graph.

It asked:

```text
Which nodes appear to be important
based on how the Web links to them?
```

So PageRank **didn't create hyperlinks**.

It exploited the structure that hyperlinks had already created.

---

## 9. The bigger historical chain

You can think of the evolution like this:

```text
Hypertext
   │
   │ connects pieces of information
   ↓
Hyperlinks
   │
   │ connect documents
   ↓
World Wide Web
   │
   │ millions → billions of connected pages
   ↓
Problem:
"How do we find the important/relevant pages?"
   │
   ↓
Search engines
   │
   ↓
PageRank
   │
   │ analyzes hyperlink structure
   ↓
Google Search
```

And this is the deeper idea:

> **The Web's hyperlinks weren't merely navigation mechanisms. They accidentally created a massive graph describing relationships between information. PageRank realized that this graph itself could be used as a ranking signal.**

That's one of the most important conceptual transitions in Web history.


[[Networking]]