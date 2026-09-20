
## 🗂️ **Structure of `hibernate.cfg.xml`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE hibernate-configuration PUBLIC
        "-//Hibernate/Hibernate Configuration DTD 3.0//EN"
        "http://hibernate.sourceforge.net/hibernate-configuration-3.0.dtd">

<hibernate-configuration>

    <session-factory>

        <!-- 1️⃣ Database Connection Settings -->
        <property name="hibernate.connection.driver_class">com.mysql.cj.jdbc.Driver</property>
        <property name="hibernate.connection.url">jdbc:mysql://localhost:3306/studentdb</property>
        <property name="hibernate.connection.username">root</property>
        <property name="hibernate.connection.password">1234</property>

        <!-- 2️⃣ Hibernate Dialect -->
        <property name="hibernate.dialect">org.hibernate.dialect.MySQL8Dialect</property>

        <!-- 3️⃣ Schema Generation -->
        <property name="hibernate.hbm2ddl.auto">update</property>

        <!-- 4️⃣ SQL Logging -->
        <property name="hibernate.show_sql">true</property>
        <property name="hibernate.format_sql">true</property>

        <!-- 5️⃣ Entity Class Mapping -->
        <mapping class="com.arcade.bootapplication.entity.Student"/>
        <mapping class="com.arcade.bootapplication.entity.Course"/>

    </session-factory>

</hibernate-configuration>
```

---

## 🔹 **Tag Explanation**

|Tag|Description|
|---|---|
|`<hibernate-configuration>`|Root element of the configuration file.|
|`<session-factory>`|Defines one Hibernate session factory (contains all configuration details).|
|`<property>`|Defines a Hibernate or database property (connection, dialect, etc.).|
|`<mapping>`|Tells Hibernate which entity class (or XML mapping file) to load.|
|`<mapping resource="...">`|If you use `.hbm.xml` mapping files instead of annotations.|

---

## 🔹 Common `property` Settings

|Property Name|Meaning|
|---|---|
|`hibernate.connection.driver_class`|Database JDBC driver class.|
|`hibernate.connection.url`|JDBC connection URL.|
|`hibernate.connection.username`|DB username.|
|`hibernate.connection.password`|DB password.|
|`hibernate.dialect`|Tells Hibernate which SQL dialect to use.|
|`hibernate.hbm2ddl.auto`|Auto schema update (`create`, `update`, `validate`, `none`, `create-drop`).|
|`hibernate.show_sql`|Prints SQL to console.|
|`hibernate.format_sql`|Formats SQL output neatly.|

---

## 🧠 Summary

|Section|Tag|Purpose|
|---|---|---|
|Root|`<hibernate-configuration>`|Wraps the whole config.|
|Main block|`<session-factory>`|Holds DB + entity info.|
|Database config|`<property>`|Connection + Hibernate behavior.|
|Entity mapping|`<mapping>`|Register entity classes or mapping files.|

---

##### Tags : [[1 - ORM 🍪]]