
# Angular CLI: the command layer

## 1. Core intuition

The CLI (`ng`) is a **foreman**. It doesn't build anything itself, it reads a blueprint (`angular.json`) and dispatches specialists. It is Maven's lifecycle, Spring Initializr, and a code generator in one tool.

The mental model that makes every command predictable: **`ng <command> [target] [options]`**, where a command is either

- a **task** defined in `angular.json` under `architect`: `build`, `serve`, `test`, `lint`, or
- a **schematic** (a code-transformation recipe): `new`, `generate`, `add`, `update`.

Tasks _run_ your project, and schematics _rewrite_ your project. That split explains a lot of behavior below.

## 2. Tasks: running the project

You've already used `ng serve` and `ng build`, so here is what's beneath them.

```bash
ng serve --port 4300 --open            # different port, auto-open browser
ng serve --host 0.0.0.0                # reachable from phone/other PC on your LAN
ng serve --proxy-config proxy.conf.json
ng build --configuration development   # unminified, with source maps
ng test                                # unit tests (watch mode by default)
ng test --no-watch                     # single run, what CI uses
ng lint                                # only works after `ng add angular-eslint`
```

**Configurations** are named override sets in `angular.json`. `ng build` uses `production` by default (minify, tree-shake, hash filenames for cache-busting). `development` is faster to compile and easier to debug. You can add your own, like `staging`, with a different API URL. This is the Maven-profile idea.

**Gotcha, Debian specific:** if `ng serve` dies with `ENOSPC: System limit for number of file watchers reached`, Linux is limiting how many files can be watched. Fix it with:

```bash
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.d/99-inotify.conf
sudo sysctl --system
```

## 3. `ng generate`: the schematic you'll use daily

Aliases: `ng g`. General form: `ng g <type> <path/name>`.

|Type|Shorthand|Produces|
|---|---|---|
|`component`|`c`|brick: class + template + style (+ spec)|
|`service`|`s`|injectable worker|
|`directive`|`d`|behavior attached to existing elements|
|`pipe`|`p`|template formatter (`{{ x \| myPipe }}`)|
|`guard`||route protection (functional by default)|
|`interceptor`||HTTP middleware, like a servlet filter|
|`resolver`||preload data before a route activates|
|`interface` / `enum` / `class`|`i` / `e` / `cl`|plain TS types|
|`environments`||creates environment config files|

The **path** decides where things go, and missing folders are created:

```bash
ng g c features/products/product-list
ng g s features/products/product
ng g interceptor core/interceptors/auth
ng g guard core/guards/auth
ng g i features/products/product --type=model   # → product.model.ts
```

The options worth knowing:

```bash
--dry-run (-d)        # PRINT what would be created, touch nothing
--skip-tests          # no .spec.ts file
--inline-template (-t) --inline-style (-s)   # keep small components in one file
--flat                # no wrapping folder
--change-detection OnPush   # opt into the efficient rendering strategy
```

Get in the habit of using `--dry-run` first. Generators also **edit existing files** in some cases, such as registering a route, so you want to see the plan first. Generated file names vary across versions (older ones add `.component`/`.service` suffixes, and newer ones drop them), and `--dry-run` shows exactly what your version does.

## 4. `ng new`, the useful flags

```bash
ng new shop-ui --routing --style=scss --ssr=false --skip-git --package-manager=npm
ng new --help        # every command has this, it's the source of truth for your version
```

- `--skip-git`: don't `git init` (use it when the folder is already inside a repo).
- `--minimal`: strips testing setup. Fine for experiments, bad for real projects.
- `--prefix=shop`: selectors become `shop-product-list` instead of `app-product-list`, which avoids collisions with third-party components.

## 5. `ng add` and `ng update`: the dependency schematics

**`ng add <package>`** is **`npm install` plus a setup script**. A plain `npm install` only downloads the package, while `ng add` also modifies your project to use it:

```bash
ng add @angular/material     # installs, adds theme, fonts, animations config
ng add angular-eslint        # installs and wires `ng lint`
```

**`ng update`** upgrades Angular _and migrates your code_. It runs schematics that rewrite deprecated syntax for you:

```bash
ng update                                  # lists what can be updated
ng update @angular/core @angular/cli       # upgrade the framework
```

The rules: commit everything first, and go **one major version at a time** (v18 → v19 → v20, never skip). The [update guide](https://angular.dev/update-guide) on angular.dev gives version-specific steps. This is the equivalent of Spring Boot's OpenRewrite migrations, but built in.

## 6. Housekeeping commands

```bash
ng version                # Angular, Node, and package versions (first thing to paste in a bug report)
ng config                 # read/write angular.json values without hand-editing
ng cache clean            # fixes weird stale-build behavior
ng cache info
ng analytics disable      # opt out of usage telemetry
ng completion             # shell tab-completion for ng
ng doc <keyword>          # opens angular.dev search in browser
```

## 7. Nuance: `ng` vs npm scripts

`package.json` has a `scripts` section, and `npm start` usually just runs `ng serve`. They are equivalent, and scripts are useful for bundling flags together:

```json
"scripts": {
  "start": "ng serve --proxy-config proxy.conf.json",
  "build:prod": "ng build --configuration production"
}
```

Then `npm start` gives the whole team the same setup. The Java parallel is a Maven profile or a `make` target, so nobody has to memorize flags.

Also note that `ng` is installed **globally** (`npm i -g @angular/cli`), but each project pins its **own local** CLI version in `devDependencies`. When you run `ng` inside a project, the global one hands over to the local one. That means two projects on different Angular versions can coexist on one machine, much like the Maven wrapper (`mvnw`) does.



[[1 - Angular]]