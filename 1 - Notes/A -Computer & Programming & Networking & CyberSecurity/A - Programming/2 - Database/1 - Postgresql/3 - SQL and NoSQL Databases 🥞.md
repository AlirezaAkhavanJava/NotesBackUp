
## SQL Databases (Relational DBMS)

SQL databases use Structured Query Language (SQL) for managing and manipulating data stored in a structured, tabular format with predefined schemas.

### Examples

- **MySQL**: An open-source relational database widely used for web applications, known for its performance and ease of use.
- **PostgreSQL**: An open-source, advanced RDBMS with strong support for complex queries, JSON data, and extensibility.
- **Oracle Database**: A robust, enterprise-grade RDBMS used for large-scale applications, offering high performance and advanced features.
- **Microsoft SQL Server**: A commercial RDBMS by Microsoft, popular for Windows-based enterprise environments and business intelligence.
- **SQLite**: A lightweight, serverless RDBMS ideal for embedded systems, mobile apps, and small-scale applications.

### Example SQL Query

```sql
SELECT name, age
FROM users
WHERE age > 25
ORDER BY name;
```

This query retrieves names and ages of users older than 25, sorted alphabetically by name.

## NoSQL Databases

NoSQL databases are designed for unstructured or semi-structured data, offering flexibility in schema design and scalability for large datasets.

### Examples

- **MongoDB**: A document-based NoSQL database that stores data in JSON-like BSON documents, ideal for flexible, hierarchical data.

- **Cassandra**: A distributed, column-family NoSQL database designed for high availability and handling large-scale data across multiple servers.

- **Redis**: An in-memory key-value store known for its speed, used for caching, real-time analytics, and session management.

- **CouchDB**: A document-based NoSQL database with a focus on replication and offline data access, using JSON documents.

- **DynamoDB**: A managed NoSQL database by AWS, offering low-latency performance and scalability for key-value and document data.

### Example MongoDB Query

```javascript
db.users.find({ age: { $gt: 25 } }, { name: 1, age: 1 }).sort({ name: 1 });
```

This MongoDB query retrieves names and ages of users older than 25, sorted alphabetically by name.

## Key Differences

- **Schema**: SQL databases have rigid, predefined schemas; NoSQL databases are schema-less or flexible.
- **Data Structure**: SQL uses tables; NoSQL uses documents, key-value pairs, columns, or graphs.
- **Scalability**: SQL databases scale vertically; NoSQL databases scale horizontally.
- **Use Cases**: SQL is suited for structured data and complex queries; NoSQL is ideal for unstructured data, big data, and rapid scaling.

[[1 - SQL 🥞]]