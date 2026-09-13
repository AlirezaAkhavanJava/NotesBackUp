Date : 2025-09-06



In the context of `git config`, the **set** and **unset** operations are used to manage configuration settings by adding or modifying values (`set`) and removing values (`unset`) for specific keys. Below is a detailed explanation of these operations and their associated commands.

### **Set a Configuration Value**
The `set` operation assigns or updates a value for a specific key in a Git configuration file (system, global, or local level).

- **Command**: `git config [--level] <key> <value>`
  - Sets the value for the specified key at the given configuration level (`--system`, `--global`, or `--local`).
  - If the key already exists, the new value overwrites the old one unless the key supports multiple values.
  - If no level is specified, it defaults to `--local` (repository-specific).

- **Examples**:
  - Set the user’s name globally:
    ```bash
    git config --global user.name "John Doe"
    ```
    This updates or creates the `user.name` key in `~/.gitconfig` with the value `"John Doe"`.
  - Set the default editor for a specific repository:
    ```bash
    git config --local core.editor vim
    ```
    This sets `core.editor` to `vim` in the repository’s `.git/config`.

- **Notes**:
  - For keys that support multiple values (e.g., `alias.<name>` or `remote.<name>.url`), you can use `--add` to append a new value without overwriting existing ones:
    ```bash
    git config --global --add alias.co checkout
    ```
  - To replace all values for a multi-valued key with a single value, use `--replace-all`:
    ```bash
    git config --global alias.co --replace-all status
    ```

### **Unset a Configuration Value**
The `unset` operation removes a specific key or its value from the configuration file.

- **Command**: `git config [--level] --unset <key>`
  - Removes the specified key and its value from the configuration file at the given level.
  - If the key has multiple values, only one instance is removed unless `--unset-all` is used.

- **Examples**:
  - Remove the user’s name from the global configuration:
    ```bash
    git config --global --unset user.name
    ```
    This deletes the `user.name` key from `~/.gitconfig`.
  - Remove a specific alias from a repository’s configuration:
    ```bash
    git config --local --unset alias.st
    ```
    This removes the `alias.st` key from the repository’s `.git/config`.

- **Remove All Values for a Key**:
  - Command: `git config [--level] --unset-all <key>`
  - Removes all instances of a key with multiple values.
  - Example:
    ```bash
    git config --global --unset-all alias.co
    ```
    This removes all values associated with `alias.co` in the global configuration.

### **Key Points**
- **Levels**:
  - `--system`: Affects all users (`/etc/gitconfig`).
  - `--global`: Affects all repositories for a user (`~/.gitconfig`).
  - `--local`: Affects only the current repository (`.git/config`).
  - If no level is specified, `--local` is assumed for both `set` and `unset`.

- **Behavior with Multiple Values**:
  - `set` (via `git config <key> <value>`) typically overwrites the existing value for single-value keys.
  - For multi-value keys, use `--add` to append or `--replace-all` to overwrite all values.
  - `unset` removes one value; use `--unset-all` to remove all values for a multi-value key.

- **Verification**:
  - After setting or unsetting, use `git config --list` or `git config <key>` to verify changes:
    ```bash
    git config --global --list
    ```
  - To see the source file of a setting, use `--show-origin`:
    ```bash
    git config --list --show-origin
    ```

- **Error Handling**:
  - If you try to `unset` a non-existent key, Git will silently ignore the command (no error is thrown).
  - If you `set` a key in a repository with no `.git/config` (e.g., not a Git repository), Git will return an error.

### Example Workflow
1. Set user details globally:
   ```bash
   git config --global user.name "Jane Doe"
   git config --global user.email "jane@example.com"
   ```
2. Check the settings:
   ```bash
   git config --global user.name
   ```
   Output: `Jane Doe`
3. Unset the email:
   ```bash
   git config --global --unset user.email
   ```
4. Verify the email is removed:
   ```bash
   git config --global user.email
   ```
   Output: (nothing, as the key is unset)
5. Remove a whole section
	```bash 
	git config --remove-section section
	```

For more details, refer to the Git documentation: https://git-scm.com/docs/git-config.


##### *Tags : [[0 - Git 🍋‍🟩]]