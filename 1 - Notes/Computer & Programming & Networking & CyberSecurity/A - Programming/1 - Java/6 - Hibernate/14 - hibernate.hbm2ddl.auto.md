The property

```xml
<property name="hibernate.hbm2ddl.auto">update</property>
```

is a **Hibernate configuration setting** that controls **how Hibernate handles the database schema** automatically.

---

## 🔹 What it does

- `hibernate.hbm2ddl.auto` tells Hibernate whether it should **create, update, validate, or drop tables** based on your entity classes.
    
- With `update`, Hibernate will:
    
    - **Compare your entity classes with the existing tables** in the database.
        
    - **Automatically add new tables or columns** if they don’t exist.
        
    - **Preserve existing data** — it won’t drop tables or columns.
        

---

## 🔹 Common Values

|Value|Description|
|---|---|
|`create`|Drops existing tables and creates new ones every time (data is lost).|
|`create-drop`|Same as `create`, but also drops tables when the SessionFactory is closed.|
|`update`|Updates the schema to match entity classes without deleting existing data.|
|`validate`|Checks if tables match entity mappings; throws error if mismatch.|
|`none`|Does nothing (default if property is not set).|

---

## 🔹 Example in XML

```xml
<property name="hibernate.hbm2ddl.auto">update</property>
```

Or in `application.properties` (Spring Boot):

```properties
spring.jpa.hibernate.ddl-auto=update
```

---

### 🧠 Notes

- `update` is **safe for development**, but for production you usually use `validate` or manage schema manually.
    
- Using `create` or `create-drop` in production can **delete all your data**!
    

---

> In short: `update` makes Hibernate **automatically adjust the DB schema to match your entities**, without dropping existing data.

##### Tags : [[1 - ORM 🍪]]