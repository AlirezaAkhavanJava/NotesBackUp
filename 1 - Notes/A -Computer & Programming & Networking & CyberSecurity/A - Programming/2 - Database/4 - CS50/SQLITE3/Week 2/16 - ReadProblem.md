
![[Screenshot From 2026-09-17 16-46-40 1.png]]

The error is a **path and working directory mismatch**—SQLite's `.read` command looks for `schema.sql` in the directory where you opened the terminal, not where your schema file actually lives.

### 🧭 Why This Happens
On your terminal, the current location is shown as `/mnt/hdd/Home/Programming Files/HarvardDatabase`, but your actual file is likely saved inside a subfolder, such as `src/`. Since `schema.sql` isn't in the root of that terminal path, SQLite reports `Error: cannot open "schema.sql"`.

### 🛠️ Recommended Solutions
You can resolve this by telling SQLite exactly where to find the file:

- **Step 1: Exit SQLite temporarily**. Press `Ctrl + C` or type `.exit` to return to your regular shell prompt.
- **Step 2: Navigate to the correct directory**. If you stored the file in a `src` folder, move there first with `cd src`.
- **Step 3: Start SQLite and read the file**. Since you want to set up your `mbtb.db` database, run:
  ```bash
  sqlite3 mbtb.db ".read schema.sql"
  ```
  Alternatively, from your original directory, you can specify the relative path directly:
  ```bash
  sqlite3 mbtb.db ".read src/schema.sql"
  ```

### 💡 Additional Checks
- **Check the file exists**: Run `ls` in the correct directory to confirm you can see `schema.sql` listed.
- **Trailing semicolons**: While SQL statements need semicolons, the `.read` command itself doesn't require them at the end of the filename.
- **Non-ASCII characters**: If your path contains spaces or special characters, wrapping the filename in quotes can help.
- **Permissions**: Ensure the database directory is writable by your user so SQLite can create the `mbtb.db` file if it doesn't already exist.


[[1 - WHAT IS SQLITE3]]