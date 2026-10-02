
**Vim** is a keyboard-driven text editor that runs in the terminal. **Neovim** is a modern fork (a continued, rebuilt version) of Vim with a cleaner codebase, better plugin support, and a more active ecosystem.

**Analogy:** A normal editor (like VS Code or Notepad) is a car with an automatic gearbox: you press keys and letters appear. Vim is a manual gearbox with a steep learning curve: keys do different things depending on the _mode_ you're in. Once you master it, you control everything without ever taking your hands off the keyboard, and it is very fast.

## Core idea: modes

In a normal editor, pressing `d` types the letter "d". In Vim, what a key does depends on the current mode:

|Mode|Purpose|How to enter|
|---|---|---|
|**Normal**|Navigate and run commands (the default)|`Esc`|
|**Insert**|Type text like a normal editor|`i`|
|**Visual**|Select text|`v`|
|**Command**|Run commands like save and quit|`:`|

This is the thing that confuses every beginner: you start in Normal mode, where typing letters does _not_ insert text.

## Vim's "language"

Commands combine like sentences: **verb + object**.

- `dw` = delete word
- `d$` = delete to end of line
- `ci"` = change text inside quotes
- `3dd` = delete 3 lines
- `yy` then `p` = copy a line, then paste it

Once you know a few verbs (`d` delete, `c` change, `y` copy) and objects (`w` word, `$` end of line, `"` quotes), you can combine them in ways you never memorized. That is why people say Vim is a _language_ for editing, not a set of shortcuts.

## Survival kit

```
i        start typing (Insert mode)
Esc      go back to Normal mode
:w       save
:q       quit
:wq      save and quit
:q!      quit without saving
```

On Debian 13:

```bash
sudo apt install vim        # Vim
sudo apt install neovim     # Neovim
vimtutor                    # built-in interactive tutorial (30 min, very good)
```

## Vim vs Neovim

||Vim|Neovim|
|---|---|---|
|**Config language**|Vimscript|Lua (plus Vimscript)|
|**Config file**|`~/.vimrc`|`~/.config/nvim/init.lua`|
|**Plugins & IDE features**|Possible, more awkward|Built-in LSP support (code completion, go-to-definition), strong plugin ecosystem|
|**Out of the box**|Ready, very stable|Similar, but built to be extended|
|**Best for**|Quick edits, servers, simplicity|Building a full custom coding environment|

The core editing (modes, verbs, objects) is **identical**. Learning one means you know the other.

## When to use them

**Use Vim when:**

- You SSH into a server and need to edit a config file. Vim (or its minimal cousin `vi`) is installed almost everywhere, and often nothing else is.
- You do quick edits in the terminal (`git commit` messages open in it by default).
- You want a tool that never changes and works on every machine.

**Use Neovim when:**

- You want to build a full coding environment in the terminal, with autocomplete, error highlighting, file tree, and Git integration.
- You enjoy customizing your tools and want modern plugins.

**Probably don't use either (yet) when:**

- You are learning Java and Spring Boot. An IDE like **IntelliJ IDEA** gives refactoring, debugging, and Spring support that a Vim setup struggles to match. Java is a heavy, tool-driven language, so an IDE pays off a lot more than it does for, say, a Python script.
- You would be fighting the editor instead of learning the language.

## Good compromise

Use IntelliJ or VS Code for your Java work, and learn Vim _gradually_ on the side. Both IntelliJ and VS Code have a **Vim plugin** (IdeaVim, VSCodeVim) that gives you Vim's keys inside a normal IDE. You get the best of both.

## Gotchas

- **The steep learning curve is real.** Expect to be slower for the first one to two weeks. Daily practice with `vimtutor` helps a lot.
- **"How do I exit Vim?"** is a famous joke because beginners get stuck. The answer: `Esc`, then `:q!` (or `:wq` to save).
- **Neovim is not automatically easier.** Its power comes from configuration, and a custom setup can eat a lot of time. Pre-made configurations (like LazyVim or kickstart.nvim) give you a working setup to start from.
- **Vim is a means, not a goal.** Many excellent developers use VS Code or IntelliJ and never touch Vim. Choose it for the speed and control, not because it's "what real programmers use."


[[Real Projects]]
[[Computer & Programming]]
[[2 - Tags/Pro/CS/Linux|Linux]]