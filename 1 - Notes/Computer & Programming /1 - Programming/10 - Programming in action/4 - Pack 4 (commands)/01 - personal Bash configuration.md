

`~/.bashrc` is essentially your **personal Bash configuration file**.

## `~/.bashrc`


When you start an interactive Bash shell, Bash reads:

```bash
~/.bashrc
```

You put things there that configure your shell environment, such as:

```bash
# Aliases
alias ll='ls -lah'
alias gs='git status'

# Environment variables
export EDITOR=nvim

# PATH modifications
export PATH="$HOME/bin:$PATH"

# Functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}
```

So your workflow can be:

```bash
nano ~/.bashrc
```

Add/change configuration, save it, then:

```bash
source ~/.bashrc
```

## What does `source` do?

```bash
source ~/.bashrc
```

tells Bash:

> **Read this file and execute its commands in the current shell.**

The shorter equivalent is:

```bash
. ~/.bashrc
```

For example, suppose you add:

```bash
alias codebase='cd "/mnt/hdd/Home/Programming Files/"'
```

Normally, you'd need to open a **new terminal** for `.bashrc` to be read.

Instead:

```bash
source ~/.bashrc
```

Now the alias immediately exists in your current shell:

```bash
codebase
```

### Important distinction

```bash
bash ~/.bashrc
```

runs `.bashrc` in a **new Bash process**.

```bash
source ~/.bashrc
```

runs it in your **current Bash process**.

That's why `source` matters for things like:

```bash
export PATH="..."
alias ...
cd ...
function ...
```

because their effects need to remain in your current shell.

### Typical Bash configuration structure

A `.bashrc` might look like:

```bash
# ~/.bashrc

# Environment
export EDITOR=nvim

# PATH
export PATH="$HOME/bin:$PATH"

# Aliases
alias ll='ls -lah'
alias gs='git status'

# Functions
codebase() {
    cd "/mnt/hdd/Home/Programming Files/"
}

# Load additional configuration
source ~/.bash_aliases
```

Think of it as:

```text
~/.bashrc
    │
    ├── environment variables
    ├── PATH
    ├── aliases
    ├── functions
    ├── shell options
    └── other Bash configuration
```

And:

```bash
source ~/.bashrc
```

means **"reload my Bash configuration right now."**

[[2 - Tags/Pro/CS/Linux|Linux]]