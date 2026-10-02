
# Checking your Node, npm, and Angular versions

## The core intuition

Three layers are stacked, and each one constrains the one above it:

**Node** (the engine) → **npm** (the supplier, ships bundled with Node) → **Angular CLI and framework** (the product built on both).

Angular only supports specific Node ranges, so when something breaks mysteriously, you check the stack from the bottom up.

## The commands

```bash
node -v                    # Node.js version
npm -v                     # npm version
ng version                 # Angular CLI + framework + Node + OS (the all-in-one)
```

Recall `ng version` from the CLI lesson. Run it inside a project folder to see the project's own pinned versions, and outside a project to see the global CLI only.

## Reading `ng version` output

Inside a project it prints a table like this (numbers are illustrative):

```
Angular CLI: 20.x.x
Node: 22.x.x
Package Manager: npm 10.x.x
OS: linux x64

Angular: 20.x.x
... core, common, compiler, router, forms ...
```

It shows the CLI version, the framework packages, and the Node it is running on. It also warns you if your Node is unsupported.

## More precise checks

```bash
npm ls @angular/core            # exact framework version this project resolved
npm ls @angular/cli
npm ls -g --depth=0             # everything installed GLOBALLY (is @angular/cli there?)
npm view @angular/cli version   # latest version available on the registry
which node                      # which binary is used (nvm path vs /usr/bin)
nvm ls                          # all Node versions you've installed via nvm
```

The comparison between `npm ls @angular/cli` (local) and `npm ls -g` (global) reveals the "two different CLI versions" situation I mentioned earlier.

## Gotchas

- **Node compatibility is strict.** Each Angular major supports certain Node ranges (typically even-numbered LTS releases, with a minimum minor version, like 20.19+ or 22.12+). Odd-numbered Node releases such as 21 or 23 are not supported. The authoritative table is in the Angular docs under "Version compatibility", and you can also check `engines` inside the installed package with:
    
    ```bash
    npm view @angular/cli engines
    ```
    
- **Debian trap:** `apt` may have installed an older `nodejs` in `/usr/bin` while `nvm` provides another. `which node` tells you which one wins. Since you're using nvm, run `nvm use --lts` if the wrong one is active.
- **Switching versions per project:** put a file named `.nvmrc` containing e.g. `22` in the project root, then run `nvm use` inside it. It's a way to record the Node version alongside the code, like Maven's `<java.version>`.



[[1 - Angular]]