## **1. By Structure / Type**

|Index Type|Description|Typical Use Cases|
|---|---|---|
|**B-tree**|Default, balanced tree|Equality and range queries (`=`, `<`, `>`, `<=`, `>=`), `ORDER BY`|
|**Hash**|Hash table|Equality queries only (`=`), rarely used|
|**GIN** (Generalized Inverted Index)|Inverted index|Full-text search, JSONB, arrays|
|**GiST** (Generalized Search Tree)|Flexible tree|Geometric data, ranges, nearest-neighbor search|
|**BRIN** (Block Range Index)|Summarizes ranges of blocks|Very large, sequential data (timestamps, IDs)|
|**SP-GiST** (Space-partitioned GiST)|Specialized tree|Custom or sparse data structures, spatial queries|

---

## **2. By Usage / Purpose**

|Category|Description|Example|
|---|---|---|
|**Unique**|Ensures column values are unique|`CREATE UNIQUE INDEX idx_email ON users(email);`|
|**Primary Key**|Automatically creates a unique B-tree index|`PRIMARY KEY(id)`|
|**Partial**|Indexes only rows satisfying a condition|`CREATE INDEX idx_active ON users(name) WHERE active = true;`|
|**Expression**|Index based on an expression, not just a column|`CREATE INDEX idx_lower_name ON users(LOWER(name));`|

---

## **3. By Special Features**

|Feature|Description|
|---|---|
|**Multicolumn**|Index on multiple columns (`(col1, col2)`)|
|**Covering / INCLUDE**|Stores extra columns in the index for faster queries without fetching table rows|
|**Concurrent**|`CREATE INDEX CONCURRENTLY` → build index without locking writes|
|**Descending / Ascending**|Specify order for `ORDER BY` optimization|

---

✅ **Summary**:

- **B-tree** = default and general purpose.
    
- **GIN** = text/array/JSON search.
    
- **GiST / SP-GiST** = spatial or complex data.
    
- **BRIN** = huge sequential tables.
    
- **Partial / Expression / Multicolumn / Covering** = optimize for specific queries.
    


###### Tags : [[1 - SQL 🦬]]