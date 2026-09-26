`git log` is the command used to view the commit history of a Git repository. It provides a record of everything that has happened to the project, allowing you to see who made changes, when, and why.

### 📜 What is `git log`?

At its core, `git log` lists commits that are reachable by following the parent links from a given commit (usually `HEAD`). By default, it outputs this history in **reverse chronological order** (newest commits first).

A standard `git log` entry contains several key pieces of information:
*   **Commit Hash:** A unique 40-character SHA-1 checksum that identifies the commit.
*   **Author:** The name and email of the person who made the commit.
*   **Date:** The timestamp of when the commit was created.
*   **Commit Message:** The description of the changes.

### 🚩 Essential `git log` Flags

You can customize the output of `git log` using various flags. These can be broadly categorized into formatting, filtering, and file-specific options.

#### Formatting Output
These flags change how the information is displayed.

*   **`--oneline`**: Condenses each commit to a single line, showing the abbreviated commit hash and the first line of the commit message. This is perfect for a quick overview.
*   **`--graph`**: Displays a text-based graphical representation of the branch structure on the left side of the output. It is most useful when combined with `--oneline`.
*   **`--decorate`**: Shows references (like branch names, tags, and `HEAD`) that point to each commit. For example, `(HEAD -> main, origin/main)`.
*   **`--stat`**: Displays a summary of the changes made in each commit, including the files changed and the number of insertions and deletions.
*   **`-p`** or **`--patch`**: Shows the full diff (the actual code changes) introduced by each commit.

#### Filtering and Limiting Output
These flags help you narrow down which commits are shown.

*   **`-n <number>`** or **`-<number>`**: Limits the output to the most recent `<number>` commits. For example, `git log -5` shows the last five commits.
*   **`--author=<pattern>`**: Shows only commits made by an author whose name or email matches the given pattern.
*   **`--grep=<pattern>`**: Searches the commit messages for a specific pattern and shows only matching commits.
*   **`--since=<date>`** / **`--until=<date>`**: Shows commits made after or before a specific date. You can use relative dates like `"2 weeks ago"` or `"2023-01-01"`.
*   **`--all`**: Shows commits from all branches and refs, not just the current branch.
*   **`--merges`** / **`--no-merges`**: Shows only merge commits or excludes merge commits.

#### File-Specific Options
These flags focus on the history of specific files.

*   **`-- <path>`**: Shows only commits that affected the specified file or directory. For example, `git log -- src/main.c`.
*   **`--follow`**: Continues listing the history of a file even if it has been renamed. This works only when a single file is specified.

### 💻 Key `git log` Commands in Practice

Here are some common and powerful ways to use `git log`:

*   **Basic History**: View the full commit history of the current branch.
    ```bash
    git log
    ```

*   **Concise Overview**: Get a quick, one-line-per-commit summary.
    ```bash
    git log --oneline
    ```

*   **Visualize Branches**: See a graph of the branch structure with concise messages.
    ```bash
    git log --graph --oneline --decorate --all
    ```

*   **Filter by Author**: See what a specific person has committed.
    ```bash
    git log --author="Jane Doe"
    ```

*   **Search Commit Messages**: Find commits that mention a specific keyword.
    ```bash
    git log --grep="fix bug"

    ```

*   **View Changes in a File**: See the history of a specific file, including full diffs.
    ```bash
    git log -p -- path/to/file.txt
    ```

*   **Compare Branches**: See commits that are in `branch-b` but not in `branch-a`.
    ```bash
    git log branch-a..branch-b
    ```

### 🔍 Deeper Logging Concepts

Beyond the basic command, there are other important logging concepts in Git.

#### `git log` vs. `git reflog`
It's important to understand the difference between the **log** and the **reflog**. The `git log` shows the commit history of a branch (the official, public record). The `git reflog` (reference log) records every time a reference (like `HEAD` or a branch tip) is updated locally, including operations like `commit`, `checkout`, `reset`, and `merge`. The reflog is a local safety net that can help you recover commits that seem lost after a `reset`.

#### Custom Formatting with `--pretty`
For complete control over the output, you can use `--pretty=format:"..."`. This allows you to create your own log format using placeholders like `%h` (abbreviated hash), `%an` (author name), `%s` (subject), and many others. For example:
```bash
git log --pretty=format:"%h - %an, %ar : %s"
```

If you find yourself using the same set of `git log` flags repeatedly, you can create a **Git alias**. For instance, `git config --global alias.lg "log --oneline --graph --decorate --all"` lets you simply type `git lg` to get a beautiful, compact history graph.



[[0 - Git 🍋‍🟩]]