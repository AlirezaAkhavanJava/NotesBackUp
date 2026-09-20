

## 🧩 1. **XML Configuration File — `hibernate.cfg.xml`**

This is the **classic** Hibernate configuration method.  
It lives in your project’s `src/main/resources` directory.

### 🔹 Example: `hibernate.cfg.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE hibernate-configuration PUBLIC
        "-//Hibernate/Hibernate Configuration DTD 3.0//EN"
        "http://hibernate.sourceforge.net/hibernate-configuration-3.0.dtd">

<hibernate-configuration>
    <session-factory>

        <!-- Database connection settings -->
        <property name="hibernate.connection.driver_class">com.mysql.cj.jdbc.Driver</property>
        <property name="hibernate.connection.url">jdbc:mysql://localhost:3306/schooldb</property>
        <property name="hibernate.connection.username">root</property>
        <property name="hibernate.connection.password">password</property>

        <!-- Hibernate settings -->
        <property name="hibernate.dialect">org.hibernate.dialect.MySQLDialect</property>
        <property name="hibernate.hbm2ddl.auto">update</property>
        <property name="hibernate.show_sql">true</property>

        <!-- Entity class -->
        <mapping class="com.example.entity.Student"/>

    </session-factory>
</hibernate-configuration>
```

### 🔹 How it’s used:

```java
SessionFactory factory = new Configuration()
        .configure("hibernate.cfg.xml")
        .buildSessionFactory();
```

---

## ⚙️ 2. **Properties File — `hibernate.properties`**

Instead of XML, you can define the same settings in a **key=value** format.

### 🔹 Example: `hibernate.properties`

```properties
hibernate.connection.driver_class=com.mysql.cj.jdbc.Driver
hibernate.connection.url=jdbc:mysql://localhost:3306/schooldb
hibernate.connection.username=root
hibernate.connection.password=password

hibernate.dialect=org.hibernate.dialect.MySQLDialect
hibernate.hbm2ddl.auto=update
hibernate.show_sql=true

hibernate.current_session_context_class=thread
```

### 🔹 How it’s used:

```java
Configuration cfg = new Configuration();
cfg.configure(); // automatically loads hibernate.properties if found
SessionFactory factory = cfg.buildSessionFactory();
```

---

## 🔍 Difference between the two

|Feature|`hibernate.cfg.xml`|`hibernate.properties`|
|---|---|---|
|Format|XML|Key=value|
|Can include `<mapping>` elements|✅ Yes|❌ No (must register classes manually)|
|Readability|More structured|Simpler|
|Common usage today|Legacy / explicit|Often used in simple setups or Spring Boot|

---

### 🧭 Summary

> Both files define Hibernate’s connection and behavior settings.
> 
> - Use **XML** if you need to declare mappings directly.
>     
> - Use **properties** for lightweight or Spring-based configurations.
>     


##### Tags : [[1 - ORM 🍪]]