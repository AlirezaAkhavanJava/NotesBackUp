The `git config` command in Git is used to set, view, or modify configuration settings that control how Git operates. These settings can be applied at different levels (system, global, or local) and are stored in configuration files. They define user information, behavior preferences, aliases, and more.

### Configuration Levels
1. **System**: Applies to all users on the system. Stored in `/etc/gitconfig`.
   - Modified with `--system` flag.
2. **Global**: Applies to all repositories for a specific user. Stored in `~/.gitconfig` or `~/.config/git/config`.
   - Modified with `--global` flag.
3. **Local**: Applies to a single repository. Stored in `.git/config` within the repository.
   - Modified with `--local` flag (default if no flag is specified).

### Common `git config` Commands
Here are the primary commands and their uses, with examples:

1. **Set a Configuration Value**
   - Command: `git config [--level] <key> <value>`
   - Sets a configuration value for the specified key.
   - Example:
     ```bash
     git config --global user.name "John Doe"
     git config --global user.email "john@example.com"
     ```
     Sets the user’s name and email for commits globally.

2. **View a Configuration Value**
   - Command: `git config [--level] <key>`
   - Retrieves the value for a specific key.
   - Example:
     ```bash
     git config --global user.name
     ```
     Outputs: `John Doe`

3. **List All Configurations**
   - Command: `git config --list [--level]`
   - Displays all configuration settings at the specified level (or all levels if no level is specified).
   - Example:
     ```bash
     git config --list
     ```
     Outputs all settings, e.g.:
     ```
     user.name=John Doe
     user.email=john@example.com
     core.editor=vim
     ```

4. **Edit Configuration File Directly**
   - Command: `git config [--level] --edit`
   - Opens the configuration file in the default editor for manual editing.
   - Example:
     ```bash
     git config --global --edit
     ```
     Opens `~/.gitconfig` in the editor (e.g., Vim).

5. **Add a Configuration Value**
   - Command: `git config [--level] --add <key> <value>`
   - Adds a new value to a multi-valued key (e.g., for aliases or remotes).
   - Example:
     ```bash
     git config --global alias.co checkout
     git config --global --add alias.co commit
     ```
     Adds multiple aliases for the same key.

6. **Remove a Configuration Value**
   - Command: `git config [--level] --unset <key>`
   - Removes a specific configuration key.
   - Example:
     ```bash
     git config --global --unset user.name
     ```
     Removes the `user.name` setting from the global config.

7. **Get All Values for a Multi-Valued Key**
   - Command: `git config [--level] --get-all <key>`
   - Lists all values for a key that supports multiple values.
   - Example:
     ```bash
     git config --global --get-all alias.co
     ```
     Outputs all aliases assigned to `co`.

8. **Replace All Values for a Key**
   - Command: `git config [--level] <key> --replace-all <value>`
   - Replaces all existing values for a key with a new value.
   - Example:
     ```bash
     git config --global alias.co checkout
     ```
     Replaces any existing `alias.co` values with `checkout`.

### Common Configuration Keys
- **User Information**:
  - `user.name`: Your name for commits.
  - `user.email`: Your email for commits.
  - Example: `git config --global user.name "Jane Doe"`

- **Editor**:
  - `core.editor`: Default editor for Git operations (e.g., commit messages).
  - Example: `git config --global core.editor vim`

- **Aliases**:
  - `alias.<name>`: Shortcuts for Git commands.
  - Example: `git config --global alias.st status` (runs `git status` when you type `git st`).

- **Default Branch**:
  - `init.defaultBranch`: Sets the default branch name for new repositories.
  - Example: `git config --global init.defaultBranch main`

- **Merge and Diff Tools**:
  - `merge.tool`: Specifies the tool for resolving merge conflicts.
  - Example: `git config --global merge.tool vimdiff`

- **Color Output**:
  - `color.ui`: Enables/disables colored output (e.g., `true`, `false`, `always`).
  - Example: `git config --global color.ui auto`

- **Push Behavior**:
  - `push.default`: Defines how `git push` behaves (e.g., `simple`, `current`).
  - Example: `git config --global push.default simple`

### Configuration File Example
A `.gitconfig` file might look like this:
```ini
[user]
    name = John Doe
    email = john@example.com
[core]
    editor = vim
[alias]
    st = status
    co = checkout
[color]
    ui = auto
```

### Notes
- If no level (`--system`, `--global`, `--local`) is specified, `git config` defaults to the local repository’s configuration.
- Use `--show-origin` with `git config --list` to see where each setting is stored:
  ```bash
  git config --list --show-origin
  ```
- For sensitive data (e.g., credentials), consider `git credential` or external credential managers instead of storing in `git config`.

For more details, check the official Git documentation: https://git-scm.com/docs/git-config


##### *Tags : [[0 - Git 🍋‍🟩]]