 SQLite has a startup configuration file called **`.sqliterc`**. Put your shell settings there once, and SQLite will load them every time you start `sqlite3`.

### 1. Create the config file

On Linux:

```bash
nano ~/.sqliterc
```

Put this inside:

```text
.mode table
.nullvalue NULL
```

Save and exit.

### 2. Start SQLite normally

```bash
sqlite3
```

Now your defaults will automatically be:

```text
.mode table
.nullvalue NULL
```

So you don't need to type them every session.

### You can put other SQLite shell settings there too

For example:

```text
.mode table
.headers on
.nullvalue NULL
```

Then every new SQLite session will automatically show:

```text
sqlite> SELECT * FROM users;
┌────┬──────────┬─────────────────┐
│ id │ username │      email      │
├────┼──────────┼─────────────────┤
│ 1  │ alice    │ alice@email.com │
│ 2  │ bob      │ NULL            │
└────┴──────────┴─────────────────┘
```

**For your Linux setup, `~/.sqliterc` is exactly what you want.** It is essentially SQLite CLI's personal configuration file.


[[1 - WHAT IS SQLITE3 🍕]]