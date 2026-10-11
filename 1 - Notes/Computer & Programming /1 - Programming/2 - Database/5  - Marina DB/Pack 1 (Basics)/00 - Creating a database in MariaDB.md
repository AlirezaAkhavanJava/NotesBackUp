
Creating a database in MariaDB is a short job, and once you've done it a couple of times it becomes muscle memory. Let's walk through it from the very start.

## Step 1: Log in to the MariaDB shell

Open your terminal and connect as the root user:

```bash
sudo mariadb
```

On Debian, the root database account is usually tied to your system's `sudo` rights, so that's often all you need. If you've set a password for a user instead, you'd do:

```bash
mariadb -u your_username -p
```

You'll know it worked when your prompt changes to something like `MariaDB [(none)]>`. That `(none)` is a helpful hint, by the way: it means you're connected to the server but haven't selected any database yet.

## Step 2: Create the database

```sql
CREATE DATABASE my_database;
```

Two things worth knowing right away:

- **Every SQL statement ends with a semicolon.** If you forget it, the shell just waits for more input (you'll see a `->` prompt). Type `;` and press Enter to finish.
- **Keywords aren't case-sensitive, but database names can be**, depending on your operating system. Linux filesystems are case-sensitive, so `MyDB` and `mydb` are different databases on Debian. A good habit is to stick with lowercase and underscores.

If you want to avoid an error when the database already exists, use this safer form:

```sql
CREATE DATABASE IF NOT EXISTS my_database;
```

You can also choose a character set up front, which is a good idea if you'll store text from many languages or emoji:

```sql
CREATE DATABASE my_database
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

## Step 3: Check that it exists

```sql
SHOW DATABASES;
```

You'll see a list that includes `my_database`, along with a few system databases like `information_schema` and `mysql`. Leave those system ones alone for now; they hold MariaDB's own internal bookkeeping.

## Step 4: Switch to it

This is the part that trips people up, because it's different from `CREATE`. Creating a database does **not** automatically select it. You have to tell MariaDB you want to work inside it:

```sql
USE my_database;
```

You'll get `Database changed`, and your prompt becomes `MariaDB [my_database]>`. From now on, any table you create or query lands in that database.

To double-check where you are at any time:

```sql
SELECT DATABASE();
```

## A quick bonus: connect straight into it

You can skip `USE` by naming the database when you log in:

```bash
sudo mariadb my_database
```

## Putting it all together

```sql
CREATE DATABASE IF NOT EXISTS my_database
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE my_database;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL
);
```

## A note for your Spring Boot work

When you connect from Spring Boot later, the `USE` step isn't something you run yourself. The database name goes into the JDBC URL instead, like `jdbc:mariadb://localhost:3306/my_database`. The idea is the same, you're just choosing the database at connection time rather than inside the shell.

Also, creating a dedicated user for each project (instead of always using root) is the habit that separates tidy setups from messy ones. When you're ready for that, it's a natural next lesson: `CREATE USER` and `GRANT`.


[[MySQL]]
