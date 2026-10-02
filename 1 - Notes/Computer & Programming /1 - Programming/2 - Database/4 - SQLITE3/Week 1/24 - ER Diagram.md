![[Pasted image 20260909170118.png]]
This diagram is a very good example because it uses **Crow's Foot notation**. Let's read **every line in your exact diagram**.

## 1. First, understand the symbols

Your diagram uses three basic symbols:

```text
|      O      <

|      ○      Crow's foot
1      0      Many
```

They combine to express **minimum and maximum cardinality**:

|Symbol|Meaning|
|---|---|
|`|`|
|`O`|Zero / optional|
|Crow's foot|Many|

So:

```text
|────|   = exactly 1 to exactly 1
|────<   = 1 to many
O────<   = 0 to many
O────|   = 0 to 1
```

The critical rule is:

> **Look at the symbol at each END of the line.**

---

# 2. Customer → Product

Your diagram has:

```text
Customer                 Product

┌──────────┐             ┌──────────┐
│ Customer │             │ Product  │
└──────────┘             └──────────┘
      |──────────────O<─────
```

At the **Customer** side:

```text
|
```

At the **Product** side:

```text
O<
```

Therefore:

```text
Customer 1 ───── 0..N Product
```

### Read it as:

> **One Customer can be associated with zero or many Products.**

And from the other direction:

> **Each Product is associated with exactly one Customer.**

So:

```text
Customer
   │
   ├── Product
   ├── Product
   └── Product
```

---

# 3. Product → Shop

Your diagram has:

```text
Product                         Shop

┌──────────┐                   ┌──────────┐
│ Product  │                   │ Shop     │
└──────────┘                   └──────────┘
      >O────────────────────O<
```

Both ends have:

```text
O<
```

So this is:

```text
Product 0..N ───── 0..N Shop
```

### Meaning

> A Product can belong to zero or many Shops.

And:

> A Shop can contain zero or many Products.

This is a **Many-to-Many relationship**:

```text
Product N ───── N Shop
```

Usually, in a relational database, this requires a **junction table**:

```text
Product
   │
   │
   ▼
Product_Shop
   ▲
   │
   │
 Shop
```

---

# 4. Customer → Sales

Look at this line:

```text
Customer
    │
    │
    └───────────────────┐
                        │
                        O<
                       Sales
```

Customer's side:

```text
|
```

Sales' side:

```text
O<
```

Therefore:

```text
Customer 1 ───── 0..N Sales
```

### Meaning

> One Customer can have zero or many Sales.

For example:

```text
Customer #1
    │
    ├── Sale #1
    ├── Sale #2
    ├── Sale #3
    └── Sale #4
```

But each `Sale` belongs to **one Customer**.

---

# 5. Shop → Sales

This is essentially the same structure:

```text
Shop
 │
 │
 └───────────────────┐
                     │
                     O<
                    Sales
```

Therefore:

```text
Shop 1 ───── 0..N Sales
```

### Meaning

> One Shop can have zero or many Sales.

And:

> Each Sale is associated with exactly one Shop.

---

# 6. Vendor → Sales

At the bottom:

```text
Vendor                    Sales

┌──────────┐             ┌──────────┐
│ Vendor   │             │ Sales    │
└──────────┘             └──────────┘
      |──────────────O<─────
```

Again:

```text
Vendor 1 ───── 0..N Sales
```

### Meaning

> One Vendor can be associated with zero or many Sales.

And:

> Each Sale is associated with exactly one Vendor.

---

# 7. Product → Sales

This one is particularly interesting.

Your diagram has:

```text
             Product
                │
                O<
                │
                O<
                │
              Sales
```

Both sides have:

```text
O<
```

Therefore:

```text
Product 0..N ───── 0..N Sales
```

This is:

```text
Product N : N Sales
```

or **Many-to-Many**.

Meaning:

> A Product can appear in zero or many Sales.

And:

> A Sale can contain zero or many Products.

For example:

```text
Product A ──┐
Product B ──┼── Sale #100
Product C ──┘
```

And:

```text
Product A
   │
   ├── Sale #100
   ├── Sale #101
   └── Sale #102
```

That's why this relationship is fundamentally many-to-many.

---

# 8. Now read the whole diagram

We can simplify your entire ER diagram to:

```text
                    ┌───────────┐
                    │  Product  │
                    └───────────┘
                     │         │
                   N │         │ N
                     │         │
                     │         │
             N       │         │       N
Customer 1 ──────────┘         └───────── 1 Shop
    │                                      │
    │                                      │
    │ 1                                  1 │
    │                                      │
    │ N                                  N │
    └─────────────── Sales ────────────────┘
                         ▲
                         │
                         │ N
                         │
                    Vendor 1
```

There is one important thing to notice here:

### `Sales` acts like a connecting entity.

It connects:

```text
Customer
   │
   ▼
 Sales
   ▲
   │
 Shop
   ▲
   │
 Vendor
```

while `Product` also has a many-to-many relationship with `Sales`.

---

# 9. How to translate the diagram into database thinking

This is the really useful part for you as someone learning SQLite.

Your ER diagram:

```text
Customer 1 ─── N Sales
Shop     1 ─── N Sales
Vendor   1 ─── N Sales
Product  N ─── N Sales
Product  N ─── N Shop
```

would eventually become tables and foreign keys.

For example:

```sql
CREATE TABLE customer (
    customer_number INTEGER PRIMARY KEY,
    phone_number TEXT,
    name TEXT,
    address TEXT
);
```

Then:

```sql
CREATE TABLE sales (
    id INTEGER PRIMARY KEY,
    date TEXT,
    sum_total REAL,

    customer_id INTEGER,
    shop_id INTEGER,
    vendor_id INTEGER,

    FOREIGN KEY (customer_id)
        REFERENCES customer(customer_number),

    FOREIGN KEY (shop_id)
        REFERENCES shop(id),

    FOREIGN KEY (vendor_id)
        REFERENCES vendor(staff_number)
);
```

For the `Product ↔ Shop` N:M relationship, you'd normally need:

```sql
CREATE TABLE product_shop (
    product_id INTEGER,
    shop_id INTEGER,

    PRIMARY KEY (product_id, shop_id),

    FOREIGN KEY (product_id)
        REFERENCES product(id),

    FOREIGN KEY (shop_id)
        REFERENCES shop(id)
);
```

And similarly, `Product ↔ Sales` would normally need an associative/junction table.

---

# 10. The most important trick

Whenever you see an ER line, **don't read the line as a whole**.

Read it like this:

```text
             Customer                 Product
                 |                       O<
                 │                       │
                 └───────────────────────┘
                 ↑                       ↑
              exactly 1             zero or many
```

Then translate:

```text
Customer 1 ─── Product 0..N
```

Then ask:

> **"Which side is the ONE side, and which side is the MANY side?"**

For your diagram:

```text
Customer ─── Product
   1          0..N

Product ─── Shop
  0..N       0..N

Customer ─── Sales
    1         0..N

Shop ─────── Sales
  1            0..N

Vendor ───── Sales
   1           0..N

Product ──── Sales
  0..N         0..N
```

That is essentially **how you read the entire ER diagram**.

One final distinction worth memorizing:

```text
O = minimum 0
| = minimum 1

| = maximum 1
< = maximum many
```

So **`O<` literally means `0..many`**. That's the key to decoding Crow's Foot diagrams.

[[1 - WHAT IS SQLITE3 🍕]]