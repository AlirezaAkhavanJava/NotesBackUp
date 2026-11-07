


**PageRank is an algorithm developed at Stanford in the late 1990s by Larry Page and Sergey Brin to rank Web pages based partly on the links pointing to them.**

It became one of the foundational ideas behind **Google Search**.

![Image](https://images.openai.com/static-rsc-4/tVOC2iAHpcv3lcx90et7gVfcIJm2VeFinH4gplW_G6dweFDirlSHj5j0OZVZIo2amEY1kr1cUTNyVhMekXDyQ2HE_EvZuMpf2LBhgJogRgTiF4B9qts1NLxoZeNja8UAmHkSSQgnBJxu3muKTS21hln7Iy1yUlQmQUHI_ll8oFdozYeI4MxT23AjehB2lKjr?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/UujckzQJ9_2tlWccDsJrtAcO4PEMIx4Xh95_1PbKm8LNVFuqHmixnMSQrYyfgMiHaSice5O-hjea_thPlLf67x72fwzebIhhP0Fa41-QHLRZNYaQeRxBhQlpSXbZCeYJwJ-wWtZ1t9P6A5zmYd035GUh8grmRVcMYpw432xBTg248fARpKnshiglnuz0t8-g?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/uzIWFMQzUDqJyi4rytGnjiuo8JAROPMJw2Jg7zyIV7QtY5KTO_kJmM55Fj1TS16qD-go4Mv09SphVD-sI4g40Vts9Iwt2oSTKpGLjjDHBsuItOXuSFwfpkYAaKKqmxy-U3e7kcQePN5xngOBGT6Z1GBi7j8qn7DB-CHsnQ-6nqL2DnIMgAPOCSNYIEHVNy_k?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/-VuSSGCWRbIwMK5I5ySQsOfzSge3Bapky94ZDd7XxGVIN5_rWdLk_H__KlpwwpGBAQ-YCymjms5s0qyhtObo3dzWvq-8KL_vj92yfwmy4xPeZJAlBu67wyBZTFVEPPvNMEk7Fuse_e37Q8jCmtIslEILzm8AQj3o67NoFngnNRFk0Dj_OKi9-LIPYJiNaHtZ?purpose=fullsize)

## 1. What problem did PageRank solve?

By the late 1990s, the Web was becoming enormous:

```text
1990
    a few Web pages
        ↓
1995
    thousands/millions
        ↓
1998
    enormous Web
```

Search engines could find pages containing your keywords.

But there was a problem:

> **How do you determine which matching page is actually important or trustworthy?**

Suppose you search:

```text
networking
```

and there are 100,000 pages containing the word.

A search engine needs to decide:

```text
Which result should be #1?
Which should be #2?
Which should be #3?
...
```

Early search engines relied heavily on **content and keyword matching**, which made them vulnerable to manipulation.

---

# 2. Google's key idea

Page and Brin realized that the **link structure of the Web contains information about importance**.

Suppose we have:

```text
A ───────→ B
```

A is linking to B.

That link can be interpreted as a kind of **vote or endorsement** for B.

Now:

```text
A ─────→ B
C ─────→ B
D ─────→ B
```

B has three incoming links.

It might therefore be more important than a page with only one incoming link.

But there's a deeper idea.

---

# 3. Not all links are equal

Consider:

```text
Page X
   │
   └──────→ B
```

versus:

```text
Very important Page A
   │
   └──────→ B
```

A link from an important page should arguably count **more**.

So PageRank became recursive:

> **A page is important when important pages link to it.**

That produces a feedback system:

```text
important page
      ↓
links to B
      ↓
B becomes more important
      ↓
links to C
      ↓
C becomes more important
```

---

# 4. The Web becomes a graph

This is the key computer-science perspective.

Treat the Web as a **directed graph**:

```text
        ┌───────┐
        │   A   │
        └───┬───┘
            │
            ▼
        ┌───────┐
        │   B   │──────→ C
        └───────┘        │
             ↑           │
             └───────────┘
```

Pages = **vertices/nodes**

Hyperlinks = **directed edges**

PageRank analyzes this graph.

This was a powerful insight because the Web isn't just a collection of documents.

It's a **network of relationships between documents**.

---

# 5. The basic mathematical idea

A simplified PageRank equation is:

PR(A)=1−dN+d∑i=1nPR(Ti)C(Ti)PR(A) = \frac{1-d}{N} + d\sum_{i=1}^{n} \frac{PR(T_i)}{C(T_i)}

Where:

- `PR(A)` = PageRank of page A
    
- `Tᵢ` = pages linking to A
    
- `PR(Tᵢ)` = PageRank of those pages
    
- `C(Tᵢ)` = number of outgoing links from those pages
    
- `N` = total number of pages
    
- `d` = damping factor, traditionally around **0.85**
    

Don't worry about memorizing the equation yet.

The important concept is:

```text
PageRank(A)
    =
importance coming from pages linking to A
    +
baseline probability
```

And the incoming importance is divided among the outgoing links.

---

# 6. Why the damping factor?

Imagine a user randomly browsing the Web.

They click links:

```text
A → B → C → D → ...
```

But eventually they might stop following links and jump somewhere else.

PageRank models this with a **random surfer**.

Roughly:

```text
85% → follow a link
15% → jump to another page
```

The exact model is more precise than that, but that's the intuition behind the damping factor.

This also prevents certain graph structures from trapping the calculation indefinitely.

---

# 7. Why was this better than simply counting links?

Consider:

```text
Page A
  │
  ├──→ B
  ├──→ C
  ├──→ D
  ├──→ E
  └──→ F
```

A links to five pages.

Each link gets only part of A's ranking contribution.

Meanwhile:

```text
Important Page X
      │
      └────→ B
```

If X has high PageRank and only a few outgoing links, B can receive a much stronger contribution.

So PageRank isn't simply:

> "More backlinks = higher ranking."

It's closer to:

> **"More high-quality/high-importance backlinks can increase a page's authority."**

---

# 8. Where Google comes in

Page and Brin were working at Stanford.

Their research project was initially called **BackRub**.

The idea evolved into Google.

The famous Google paper was:

**"The Anatomy of a Large-Scale Hypertextual Web Search Engine"**, published in 1998.

Google's early advantage came partly from combining:

```text
Page content
     +
Link structure
     +
PageRank
     +
efficient search infrastructure
```

This produced much better search results than many existing engines for many queries.

---

# 9. But PageRank wasn't the entire Google algorithm

This is an important correction.

It's common to hear:

> "Google ranks pages using PageRank."

That's incomplete.

PageRank was **one important component** of Google's early ranking system.

Modern Google Search uses many signals and sophisticated systems.

PageRank is historically important because it introduced a powerful principle:

> **The structure of the Web itself can be used to determine the relative importance of information.**

---

# 10. Why it was such a clever idea

Before PageRank, you could look at a page and ask:

```text
"What words are on this page?"
```

PageRank added:

```text
"Who links to this page?"
"How important are those pages?"
"How does the entire Web's link structure relate to this page?"
```

So instead of treating Web pages independently:

```text
A    B    C    D
│    │    │    │
independent documents
```

Google treated the Web as a **connected graph**:

```text
A ──→ B ──→ C
│     ↑     │
└─────┘     ↓
      ←──── D
```

That shift—from **document analysis** to **network analysis**—is the real conceptual breakthrough behind PageRank.

### And it fits perfectly into the history you've been following:

```text
Internet
   ↓
Web
   ↓
Millions of interconnected pages
   ↓
Problem: finding the important ones
   ↓
PageRank
   ↓
Google
   ↓
Search becomes dramatically more useful
```

The interesting next step is **how Google actually crawled the Web to discover those pages and links** — that's where **web crawlers/spiders, indexing, and the Googlebot** enter the story.


[[Networking]]