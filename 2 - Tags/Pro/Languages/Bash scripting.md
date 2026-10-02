
**Bash scripting** means writing a plain text file of shell commands, the same ones you type in the terminal, so the computer runs them in order automatically. Bash is the default shell on Debian, and a script is how you turn "I type these 6 commands every day" into "I run one file."

**Analogy:** A **recipe card** for the terminal. You could cook by remembering and typing each step, but writing it down means anyone (or a scheduler at 3 a.m.) can repeat it exactly the same way. It also connects to earlier lessons: Maven, Docker, and Git are all just commands, so a script can chain them into one workflow.

## Core idea

Bash is a **glue language**. It is not built for complex logic (that is what Java and Python are for). It is built to **launch programs, pass their output to each other, and react to whether they succeeded**. Everything is text and processes.

## Your first script

```bash
#!/usr/bin/env bash
echo "Hello, $USER! Today is $(date +%F)"
```

```bash
chmod +x hello.sh     # make it executable
./hello.sh            # run it
```

- `#!/usr/bin/env bash` is the **shebang**: the first line tells the OS which interpreter runs the file.
- `chmod +x` sets the executable permission. Without it you get "Permission denied" (or run it with `bash hello.sh`).

## Variables

```bash
name="Alireza"          # NO spaces around =
echo "Hello, $name"     # double quotes: variables expand
echo 'Hello, $name'     # single quotes: printed literally
today=$(date +%F)       # command substitution: capture a command's output
```

Variables are **strings** by default. Math needs `$(( ))`:

```bash
echo $(( 5 + 3 ))       # 8
```

## Arguments

```bash
#!/usr/bin/env bash
echo "Script: $0"
echo "First arg: $1"
echo "All args: $@"
echo "Count: $#"
```

`./script.sh a b` gives `$1=a`, `$2=b`. Like `String[] args` in Java's `main`.

## Conditions

```bash
if [[ -f "pom.xml" ]]; then
    echo "Maven project"
elif [[ -f "build.gradle.kts" ]]; then
    echo "Gradle project"
else
    echo "Unknown project"
fi
```

|Test|Meaning|
|---|---|
|`-f file`|file exists|
|`-d dir`|directory exists|
|`-z "$x"`|string is empty|
|`"$a" == "$b"`|strings equal|
|`$n -gt 5`|number greater than 5 (`-lt`, `-eq`, `-ne`)|

## Loops

```bash
for file in *.java; do
    echo "Found $file"
done

count=1
while [[ $count -le 3 ]]; do
    echo "Round $count"
    ((count++))
done
```

## Functions

```bash
log() {
    echo "[$(date +%T)] $1"
}

log "Building..."
```

## The big idea: exit codes

Every command ends with a number: **0 means success, anything else means failure**. Bash `if` doesn't test true/false, it tests _did the command succeed?_

```bash
mvn test
echo $?              # 0 if tests passed, non-zero if they failed

if mvn test; then
    echo "Tests passed"
else
    echo "Tests failed"
fi
```

This is the same signal Maven and CI servers use to decide whether a build is red or green.

## Pipes and redirection (the superpower)

Small programs that do one thing, chained together:

```bash
grep ERROR logs/app.log | wc -l            # count error lines
cat app.log | grep "id=7" | tail -n 5      # last 5 lines about id 7

echo "done" > out.txt        # overwrite file
echo "more" >> out.txt       # append
mvn test > test.log 2>&1     # stdout AND errors into a file
```

`|` sends one command's output into the next one's input. `2>&1` merges the error stream (stderr) into the normal stream (stdout). This is why the logging lesson's `grep` and `tail` commands are so useful.

## A realistic example: build and deploy helper

```bash
#!/usr/bin/env bash
set -euo pipefail

APP_NAME="my-app"
VERSION="${1:-latest}"          # first argument, default "latest"

log() { echo "[$(date +%T)] $*"; }

log "Running tests..."
./mvnw test

log "Packaging..."
./mvnw package -DskipTests

log "Building Docker image $APP_NAME:$VERSION"
docker build -t "$APP_NAME:$VERSION" .

log "Restarting container"
docker rm -f "$APP_NAME" 2>/dev/null || true
docker run -d --name "$APP_NAME" -p 8080:8080 "$APP_NAME:$VERSION"

log "Done."
```

It combines the Maven, Docker, and testing lessons into one command.

## The safety line: `set -euo pipefail`

Put this near the top of nearly every script:

- `-e`: stop immediately if any command fails (otherwise bash happily continues after errors).
- `-u`: treat an unset variable as an error (catches typos).
- `-o pipefail`: a pipeline fails if _any_ part fails, not just the last.

## Useful on Debian 13

```bash
cron                         # schedule scripts (crontab -e)
shellcheck script.sh         # linter: finds bugs (sudo apt install shellcheck)
bash -x script.sh            # debug: print each command as it runs
```

Cron example, run a backup every day at 2:30 a.m.:

```
30 2 * * * /home/alireza/backup.sh
```

## When to use bash, and when not

**Use bash for:** automating command sequences, build and deploy helpers, backups, file renaming, quick log analysis, glue between tools, startup scripts.

**Switch to Python or Java when:** you need complex logic, data structures, JSON parsing, real error handling, or the script passes roughly 100 lines. Bash gets painful fast.

## Gotchas

- **Always quote variables:** `"$file"`, not `$file`. Unquoted variables break on spaces and expand wildcards. `rm $dir/*` with an empty `$dir` can become `rm /*`, a classic disaster. `set -u` helps catch this.
- **No spaces around `=`:** `name = "x"` is an error; it must be `name="x"`.
- **Spaces inside `[[ ]]` are required:** `[[ $a == $b ]]`, with spaces after `[[` and before `]]`.
- **Use `[[ ]]`, not `[ ]`,** in bash scripts; it's safer and more capable. (Plain `sh` scripts only support `[ ]`.)
- **`sh` is not `bash`:** on Debian, `/bin/sh` is `dash`, a smaller shell. Running `sh script.sh` can break bash-only features. Use `bash script.sh` or the shebang.
- **Windows line endings** (`\r\n`) break scripts with errors like `bad interpreter`. Convert them with `dos2unix`.
- **Test destructive commands first:** put `echo` in front of an `rm` or `mv` to see what it _would_ do.
- **Never put secrets in scripts** or commit them to Git; read them from environment variables, as in the Docker and Git lessons.
- **Variables in a pipe's subshell don't survive:** `cmd | while read x; do total=...; done` changes `total` in a separate process, so it's lost afterward.
- **Spaces in filenames** break naive loops. Quoting and `for f in *` handle it; parsing `ls` output does not.



[[Computer & Programming]]