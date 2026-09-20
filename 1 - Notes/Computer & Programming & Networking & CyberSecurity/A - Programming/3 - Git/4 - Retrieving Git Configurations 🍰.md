Retrieving Git configurations is straightforward with the `git config` command. Below is a concise guide in Markdown format, focusing on commands to view, inspect, and retrieve Git configuration settings, as you requested, with examples and explanations.

---

Git stores configuration settings at three levels: **system** (all users), **global** (current user), and **local** (specific repository). You can retrieve these settings using `git config` commands to inspect or debug your setup. Here are the key commands to retrieve configurations.

## 1. List All Configurations
View all active Git configurations across all scopes (system, global, local).
```bash
git config --list

#OR

cat ~/.gitconfig

```
- **Output**: Displays all settings in `key=value` format, e.g., `user.name=Your Name`.
- **Note**: Settings are merged, with local overriding global, and global overriding system.

## 2. List Configurations by Scope
Filter configurations by their scope:
- **System**: Settings for all users on the machine.
  ```bash
  git config --system --list
  ```
  - Stored in `/etc/gitconfig`.
- **Global**: Settings for the current user.
  ```bash
  git config --global --list
  ```
  - Stored in `~/.gitconfig`.
- **Local**: Settings for the current repository.
  ```bash
  git config --local --list
  ```
  - Stored in `.git/config` (must be run inside a Git repository).

## 3. Retrieve a Specific Configuration
Get the value of a specific configuration key.
```bash
git config <key>
```
- **Example**: Check the user’s name.
  ```bash
  git config user.name
  ```
  - Output: `Your Name`
- **By scope**: Add `--global`, `--local`, or `--system`.
  ```bash
  git config --global user.email
  ```
  - Output: `your.email@example.com`

## 4. Show Configuration Sources
To see where a specific configuration is defined (system, global, or local).
```bash
git config --get --show-origin <key>
```
- **Example**:
  ```bash
  git config --get --show-origin user.name
  ```
  - Output: `file:/home/user/.gitconfig    Your Name`
- **Use case**: Helps debug which file is setting a particular value.

## 5. List All Settings with Details
For a verbose output, including values and their sources:
```bash
git config --list --show-origin
```
- **Output**: Shows each setting and the file it’s defined in, e.g.:
  ```
  file:/etc/gitconfig    core.editor=vim
  file:/home/user/.gitconfig    user.name=Your Name
  file:.git/config    branch.main.remote=origin
  ```

## 6. Search for Specific Configurations
Use `grep` to filter configurations by keyword.
```bash
git config --list | grep <keyword>
```
- **Example**: Find all alias-related settings.
  ```bash
  git config --list | grep alias
  ```
  - Output: `alias.st=status`, `alias.co=checkout`, etc.

## 7. Get All Values for a Multi-Valued Key
Some keys (e.g., `remote.<name>.url`) can have multiple values. Retrieve all:
```bash
git config --get-all <key>
```
- **Example**:
  ```bash
  git config --get-all remote.origin.url
  ```

## 8. Check Effective Configuration
To see the final value of a setting after merging all scopes:
```bash
git config --get <key>
```
- **Example**:
  ```bash
  git config --get core.editor
  ```
  - Returns the active editor (e.g., `nano`), respecting scope precedence.

## Tips
- Run `git config --list` inside a repository to include local settings; outside a repository, it shows only system and global settings.
- Use `cat ~/.gitconfig` or `cat .git/config` to view configuration files directly.
- If a setting isn’t found, Git returns nothing (no error).
- For more details, run `git help config` or check [Git documentation](https://git-scm.com/docs/git-config).

These commands cover all common ways to retrieve Git configurations. Let me know if you need examples for a specific use case!


##### *Tags : [[0 - Git 🍋‍🟩]]