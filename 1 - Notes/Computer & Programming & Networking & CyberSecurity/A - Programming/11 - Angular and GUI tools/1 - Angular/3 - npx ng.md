
# `npx ng`: what it means

## 1. The core intuition

Recall the **foreman** from the last lesson, `ng`. The question is how you _call_ him.

- **`npm`** is the **supplier**. It goes to the warehouse (the npm registry), fetches packages, and stocks your shelves (`node_modules`).
- **`npx`** is the **hire-a-specialist-for-one-job** service. It means "run this tool right now, and if I don't have it, fetch it first."

So `npx ng serve` reads as _"execute the `ng` tool with the argument `serve`"_. The Java parallel is `./mvnw compile`: you run the project's own pinned copy of a tool without installing it system-wide.

## 2. What actually happens when you type it

`npx` is a launcher that ships with npm, so you already have it. When you run `npx <command>`, it follows roughly this flow:

1. **Look in the current project** at `node_modules/.bin/`. Every installed package that provides a command drops a small launcher there. `@angular/cli` provides one called `ng`.
2. **Found it?** Run that local copy. This is the normal case inside an Angular project.
3. **Not found?** Download the package into a temporary cache, run it, and keep it out of your project. On modern npm it asks first: _"Need to install the following packages… Ok to proceed?"_

That shows why `npx ng serve` inside `shop-ui` uses **the exact Angular CLI version that project pinned**, whatever you have installed globally. It's the same guarantee I described last time, except it's explicit instead of relying on the global `ng` to hand over.

## 3. The big gotcha: package name ≠ command name

This trips almost every beginner. Two different names are involved:

|Thing|Name|
|---|---|
|The **package** on npm|`@angular/cli`|
|The **command** it provides|`ng`|

`npx` resolves _commands_ locally, but when it has to **download**, it searches by _package name_. Outside a project, `npx ng new app` would look for a package literally called `ng`, and that is a **different, unrelated package** on the registry. The correct form when you have no global install is:

```bash
npx @angular/cli new shop-ui        # package name, then its command's arguments
npx @angular/cli@20 new shop-ui     # pin a specific major version
```

Once you're inside a project (which has `@angular/cli` in `devDependencies`), plain `npx ng ...` works, because step 1 finds it locally.

## 4. Why use it instead of a global install

Recall `npm install -g @angular/cli` from earlier. Here is how the two approaches compare:

||Global `ng`|`npx`|
|---|---|---|
|Install step|once, permanent|none|
|Version|one, whichever you installed|can differ per project or per command|
|Stale risk|high, you forget to update|low, you fetch what you name|
|Typing|shortest|slightly longer|

For learning, a global install is fine and convenient. For **starting** a project on the newest version, `npx @angular/cli new` guarantees it isn't an outdated global copy. On teams and CI, `npx` or npm scripts guard against "works on my machine" version drift.

## 5. Useful variations and edge cases

```bash
npx ng version                     # inside a project: local CLI
npx --no ng version                # refuse to download; fail if not local (safe check)
npx -p @angular/cli ng new app     # explicit: "get this package, then run this command from it"
npm exec ng version                # npx is essentially a friendlier alias for npm exec
```

- **Security:** `npx` downloads and executes code from the internet with **your user's permissions**. Typos are a real attack vector, where someone publishes a malicious package with a name one letter off a popular one. Copy names exactly, and prefer scoped, official packages like `@angular/cli`.
- **Cache:** temporary downloads live under `~/.npm/_npx`. If you get odd behavior from a stale tool version, `npm cache clean --force` or deleting that folder resets it.
- **npm scripts** already do the local lookup for you: inside `package.json`, `"start": "ng serve"` finds the local `ng` without `npx`. That's why `npm start` just works.




[[1 - Angular]]