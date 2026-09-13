### **Git Objects**
Git objects are the core data structures Git uses to store and manage a repository's content and history. They are stored in the `.git/objects/` directory and identified by their SHA-1 hashes. There are four main types of Git objects:

1. **Blob**:
   - Stores the content of a file (not its name or metadata, just raw content).
   - Hash is computed as `SHA-1("blob <size>\0<content>")`.
   - Example: If `example.txt` contains "Hello", its blob hash is unique to that content.
   - Used to deduplicate identical file content across the repository.

2. **Tree**:
   - Represents a directory, listing blobs (files) and other trees (subdirectories).
   - Contains entries with file names, permissions (e.g., `100644` for regular files), and references to blob or tree hashes.
   - Hash is computed from the tree's content (list of entries).
   - Example: A tree might reference `example.txt`’s blob hash and a subdirectory’s tree hash.

3. **Commit**:
   - Represents a snapshot of the repository at a point in time.
   - Contains metadata (author, committer, date, message) and a reference to a tree hash (the repository’s root directory at that commit).
   - May reference parent commit(s) for history.
   - Hash is computed from the commit’s content, including the tree hash and metadata.

4. **Tag**:
   - A reference to a specific commit, often used for releases (e.g., `v1.0.0`).
   - Can be lightweight (just a pointer to a commit) or annotated (includes metadata like tagger and message, stored as a separate object).

- **Storage**: Objects are stored as compressed files in `.git/objects/`, with the first two characters of the hash as the directory name and the rest as the filename (e.g., `.git/objects/e6/9de29...`).
- **Deduplication**: Identical content (e.g., same file in multiple commits) shares the same blob hash, saving space.
- **Commands to inspect**:
  - `git cat-file -p <hash>`: View object content.
  - `git ls-tree <tree-hash>`: List a tree’s contents.
  - `git show <commit-hash>`: View commit details.

##### *Tags : [[0 - Git 🍋‍🟩]]