MongoDB is a **NoSQL document-oriented database** that stores data in a flexible, JSON-like format called **BSON** (Binary JSON). Unlike relational databases (which use tables, rows, and strict schemas), MongoDB's structure is hierarchical and schema-flexible, allowing documents in the same collection to have varying fields and data types.


![[Pasted image 20251217143532.png]]


### Hierarchical Structure
MongoDB organizes data in the following levels:

- **Database**: The top-level container. A single MongoDB instance or cluster can host multiple databases (e.g., `myAppDB`). Each database is isolated and can contain multiple collections.

- **Collection**: A grouping of related documents, analogous to a table in relational databases. Collections do not enforce a rigid schema—documents within one can have different structures. Created automatically when data is inserted (e.g., `users`, `products`).

- **Document**: The basic unit of data, similar to a row or JSON object. Stored as BSON, consisting of field-value pairs. Each document has a unique `_id` field (primary key, often an ObjectId). Documents can nest other documents, arrays, or arrays of documents for complex data.

### Example Structure
```
Database: blogDB
└── Collection: posts
    ├── Document 1: { _id: ObjectId("..."), title: "First Post", author: "Alice", content: "...", comments: [ { user: "Bob", text: "Great!" } ] }
    └── Document 2: { _id: ObjectId("..."), title: "Second Post", author: "Charlie", tags: ["tech", "news"] }
└── Collection: users
    ├── Document 1: { _id: ObjectId("..."), name: "Alice", email: "alice@example.com", profile: { age: 30, location: "NY" } }
```

![[Pasted image 20251217143600.png]]
### Key Characteristics
- **Flexible Schema** — No fixed columns; evolve data easily without migrations.
- **Embedding vs. Referencing** — Model relationships by embedding related data (for fast reads) or referencing via IDs (for normalization and to avoid duplication).
- **Document Limits** — Max size: 16 MB per document.
- **Data Modeling** — Design based on query patterns: embed data accessed together for performance.

This structure makes MongoDB ideal for handling unstructured/semi-structured data, scalability, and rapid development in modern applications.

###### Tags : [[1 - MongoDB 🍂]]