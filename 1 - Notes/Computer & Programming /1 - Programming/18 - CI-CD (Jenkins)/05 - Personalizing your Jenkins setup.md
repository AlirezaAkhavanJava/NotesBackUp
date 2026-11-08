

When you installed Jenkins, it came with the package's default behavior: start at boot, no shortcuts, long commands. What we did afterwards was **personalization**: small changes that live in _your_ home folder and your _own_ shell, and that make the tool fit how you work. Nothing we did changed Jenkins itself. We changed how you talk to it.

The useful thing to understand is that these changes live in three different places, and each place is read by a different part of the system. Once you know which layer does what, you can build the same kind of shortcut for any tool, not just Jenkins.

## The three layers

|Layer|What we did|Where it lives|Who reads it|
|---|---|---|---|
|1. Service behavior|Made Jenkins manual|systemd's boot list (`/etc/systemd/...`)|systemd, at boot|
|2. Aliases|`jstart`, `jstop`, `jstatus`, `jlog`|`~/.bashrc`|Your bash shell, every time you open a terminal|
|3. Scripts|`jenkins-up`, `jenkins-down`|`~/bin/`|Your shell, when you type the name|

## Layer 1: Making Jenkins manual

```bash
sudo systemctl disable --now jenkins
```

This is the one change that affects the whole machine, and it's the same two-switch idea from the systemd lesson. `disable` removed the shortcut that makes Jenkins start at boot, and `--now` also stopped it right away. That's why `jstatus` shows `disabled` on the `Loaded:` line. Everything below is just convenience on top of this.

## Layer 2: Aliases

An **alias** is a nickname for a longer command. You type the short word, and bash swaps in the long text before running it.

```bash
cat >> ~/.bashrc <<'EOF'

# Jenkins shortcuts
alias jstart='sudo systemctl start jenkins'
alias jstop='sudo systemctl stop jenkins'
alias jstatus='systemctl status jenkins --no-pager'
alias jlog='journalctl -u jenkins -n 50 --no-pager'
EOF
```

Reading it piece by piece:

- `~/.bashrc` is a text file in your home folder that bash reads **every time you open a terminal**. It's where personal settings go.
- `cat >> ~/.bashrc <<'EOF' ... EOF` is a trick for adding several lines to a file without opening an editor. Everything between the two `EOF` markers is written to the file.
- `>>` means **append** (add to the end). A single `>` would **replace** the whole file and erase your other settings. This is the most important character in the command.
- `alias jstart='...'` says "when I type `jstart`, run what's in the quotes."
- `--no-pager` on `systemctl status` and `journalctl` stops them from opening a scrolling viewer that you'd have to quit with `q`. The output just prints and returns.
- `-n 50` on `journalctl` means "only the last 50 lines."
- The line starting with `#` is a comment. It's only for you, to find this block later.

Then:

```bash
source ~/.bashrc
```

The file is only read when a terminal **opens**, so your already-open terminal didn't know about the new aliases. `source` tells it to read the file again right now. New terminals don't need this.

## Layer 3: Scripts in `~/bin`

An alias is a single line. When you need logic, such as waiting, repeating, or checking, you write a **script**: a text file of commands that you can run by name. Here's `jenkins-up`, line by line:

```bash
#!/usr/bin/env bash
PORT=8080

sudo systemctl start jenkins
echo "Waiting for Jenkins on port $PORT..."

for i in $(seq 1 60); do
  if curl -sf --noproxy '*' -o /dev/null "http://localhost:$PORT/login"; then
    echo "Jenkins is ready."
    xdg-open "http://localhost:$PORT" >/dev/null 2>&1
    exit 0
  fi
  sleep 3
done

echo "Not ready after 3 minutes. Check: journalctl -u jenkins -n 50 --no-pager"
exit 1
```

|Line|What it does|
|---|---|
|`#!/usr/bin/env bash`|The **shebang**. It tells Linux which program should run this file (bash). It must be the first line.|
|`PORT=8080`|Stores the port in a variable. No spaces around `=`. This is the single value you edit if you change Jenkins's port.|
|`sudo systemctl start jenkins`|Starts the service.|
|`for i in $(seq 1 60); do`|Repeat up to 60 times. `$(seq 1 60)` produces the numbers 1 to 60.|
|`curl -sf ... /login`|Ask the login page for an answer. `-s` is quiet and `-f` means "treat an error reply as failure." While Jenkins boots, it answers with an error, so this fails until it's truly ready.|
|`--noproxy '*'`|Ignore the stale proxy variables in your shell, which you saw in the apt problem.|
|`-o /dev/null`|Throw the page text away. We only care whether it worked.|
|`if ...; then`|If curl succeeded, run the lines until `fi`.|
|`xdg-open ... >/dev/null 2>&1`|Open the browser and hide any noise.|
|`exit 0`|Finish with code 0, which means "success."|
|`sleep 3`|Wait 3 seconds before the next try.|
|`exit 1`|Reached only if all 60 tries failed. Code 1 means "failure."|

`jenkins-down` is the same idea in two lines: stop the service, then print `$(systemctl is-active jenkins)`. The `$(...)` part runs a command and pastes its output into the text, which is why you saw `Jenkins is now: inactive`.

### Making a file runnable

```bash
chmod +x ~/bin/jenkins-up
```

A new text file is not allowed to run. `chmod +x` adds the **execute** permission. Without it, you'd get "Permission denied."

### Making it runnable by name: PATH

When you type a command, bash looks through a list of folders called **PATH**, in order, and runs the first match. `~/bin` isn't in that list by default, so we added it:

```bash
export PATH="$HOME/bin:$PATH"
```

This says "put `~/bin` at the front of the list, then keep the old list." `export` makes it visible to programs started from that terminal. This line only lasts for the terminal you typed it in. At **login**, Debian's `~/.profile` adds `~/bin` automatically _if that folder already exists_, which is why a logout and login makes it permanent.

You can see your list with `echo $PATH`, and check what bash will run with `which jenkins-up`.

## A detail that matters: `'EOF'` with quotes

Both files were created with `<<'EOF'`, with quotes around `EOF`. The quotes tell bash **not to expand anything** in the text. Our script contains `$PORT`, `$i` and `$(seq 1 60)`. Without the quotes, bash would fill those in **while creating the file**, usually with empty values, and you'd get a broken script. With the quotes, the text is saved exactly as written and expanded later, when the script runs.

## Aliases vs scripts

||Alias|Script|
|---|---|---|
|Best for|One short command|Several steps, loops, checks|
|Lives in|`~/.bashrc`|A file in `~/bin`|
|Needs `chmod +x`|No|Yes|
|Works inside other scripts|No, only in your interactive terminal|Yes|
|Needs `source` or re-login|Yes, to load|Only PATH needs to include the folder|

That third row is why `jenkins-up` calls `sudo systemctl start jenkins` in full instead of using `jstart`. Aliases are only expanded in your interactive shell, not inside scripts.

## Things worth knowing

- **Passwords:** the scripts and aliases call `sudo`, so a new session asks for your password once, and then remembers it for a few minutes.
- **Port changes:** if you move Jenkins to another port, update `PORT=` in `jenkins-up`, as covered in the ports lesson.
- **Name clashes:** before inventing an alias, run `type jstart`. If it says "not found", the name is free. Avoid names like `ls` or `cd`.

## Related concepts, briefly

- **Shell functions** are like aliases that can take arguments and have several lines. You'd define them in `~/.bashrc` too, for example a function that opens the log of any service you name.
- **Dotfiles** are files like `.bashrc` that start with a dot. Many developers keep them in a Git repository, using what you learned about Git, so they can restore their setup on a new machine.
- **systemd overrides** (`systemctl edit`) are the _service-side_ version of personalization. You used one for the port. Aliases personalize how _you_ call a service. Overrides personalize how the _service itself_ runs.

## Undo everything

|To remove|Do this|
|---|---|
|The aliases|Delete the "Jenkins shortcuts" block from `~/.bashrc`, then open a new terminal|
|The scripts|`rm ~/bin/jenkins-up ~/bin/jenkins-down`|
|Manual mode|`sudo systemctl enable jenkins` to start at boot again|

## Quick practice

Predict each result before running it:

```bash
type jstart
which jenkins-up
echo $PATH
cat ~/bin/jenkins-down
```

The first shows the alias text, the second the script's path, the third your list of folders (with `/home/ethan/bin` in it), and the fourth the two lines of the stop script. If you can explain why `jstart` works inside your terminal but wouldn't work inside `jenkins-up`, you've understood the difference between aliases and scripts.


[[CICD]]