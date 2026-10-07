


## 1. First: what were you trying to discover?

Your repository has this history:

```text
A --- B --- C --- D --- E --- F --- G --- H --- J --- K --- L --- M --- N --- O
                                                                                 ↑
                                                                                HEAD
```

More precisely, your relevant commits were:

```text
0d16f95 A
afd5c0c B
d999ac9 C
3ec5254 D
4ef5e22 E
038bf3d F
a0086a8 G
2fea9a8 H
20a9363 J
30f59b3 K
f490ca8 merge
d311e4b L
f3450b2 M
a9b350f N
b6c5f1b O
```

You had discovered a **regression**:

```text
OLD COMMIT                         CURRENT COMMIT
    ↓                                  ↓
    A  -----------------------------> O
   GOOD                              BAD
```

You didn't know which commit introduced the problem.

That's exactly the problem `git bisect` solves.

---

# 2. The definition

**Git bisect is a binary-search algorithm over commit history that finds the first bad commit between a known-good commit and a known-bad commit.**

The important word is:

> **first**

Suppose:

```text
A B C D E F G H
G G G G B B B B
        ↑
      first bad
```

The answer isn't "which commits are bad?"

You already know that everything after the regression may also be bad.

The interesting question is:

> **Which commit changed the repository from good → bad?**

---

# 3. Starting the investigation

You ran:

```bash
git bisect start
```

Git responded:

```text
status: waiting for both good and bad commits
```

At this point Git has entered **bisect mode**, but it doesn't know the boundaries yet.

Conceptually:

```text
Git:

I am ready.

Tell me:
    1. a BAD commit
    2. a GOOD commit
```

You then ran:

```bash
git bisect bad
```

Git said:

```text
status: waiting for good commit(s), bad commit known
```

Because `HEAD` was:

```text
b6c5f1b O
```

you just told Git:

```text
b6c5f1b = BAD
```

So now Git knew:

```text
BAD
 ↓
O
```

But it still didn't know how far backward it should search.

---

# 4. You gave Git the known-good boundary

You ran:

```bash
git bisect good 0d16f95
```

That's commit:

```text
A : The Founding of MegaCorp and the End of Art
```

Now Git had:

```text
0d16f95 A = GOOD

b6c5f1b O = BAD
```

So the search space became:

```text
A -------------------------------- O
↑                                  ↑
GOOD                              BAD
```

This is the **bisect range**.

Git knows:

> Somewhere between A and O, the repository transitioned from good to bad.

---

# 5. Why did Git choose H?

Git responded:

```text
Bisecting: 6 revisions left to test after this (roughly 3 steps)

[2fea9a8] H : What a multi-conflict situation
```

This is the important part.

Git performed a **binary search**.

Instead of testing:

```text
B
C
D
E
F
G
H
J
K
L
M
N
```

one by one, it chose a commit approximately in the middle:

```text
A B C D E F G [H] J K L M N O
                ↑
             test this
```

You were asked to determine:

> Is H GOOD or BAD?

---

# 6. Your test was `wc -l`

You ran:

```bash
cat scripts/scan.sh | wc -l
```

and got:

```text
1
```

Then:

```bash
cat scripts/scan.sh
```

showed:

```bash
# TODO: write the script
```

So at commit `H`, your script had not yet been implemented.

You classified that commit:

```bash
git bisect good
```

This means:

> "Whatever bug I'm investigating does not exist at H."

You have now eliminated half of the search space.

---

# 7. Git chooses the next commit

Git responded:

```text
Bisecting: 3 revisions left to test after this (roughly 2 steps)

[f490ca8] Merge pull request #1 from AlirezaAkhavanJava/add_scanner
```

Notice what happened.

Before:

```text
A ------------------------------- O
GOOD                             BAD
```

You established:

```text
H = GOOD
O = BAD
```

Therefore the interesting region is now:

```text
H ------------------------------- O
GOOD                             BAD
```

Everything before or at H can be ignored for the purpose of finding the **first bad commit**.

Git again picks a midpoint.

This time:

```text
H --- J --- K --- merge --- L --- M --- N --- O
                         ↑
                       test
```

It selected the merge commit:

```text
f490ca8
```

---

# 8. You tested the merge commit

You ran:

```bash
cat scripts/scan.sh | wc -l
```

and got:

```text
10
```

Then inspected it:

```bash
cat scripts/scan.sh
```

Now the script contained the actual scanner:

```bash
printf "\n====== SCANNING FOR CREDIT CARD NUMBERS ======\n"

grep -rE ...

...
```

So the behavior you were investigating was present.

You told Git:

```bash
git bisect bad
```

Now Git knows:

```text
H = GOOD
merge = BAD
```

So the first bad commit must be somewhere between them.

---

# 9. Git narrowed the search again

Git selected:

```text
30f59b3 K : Karate
```

Now you had:

```text
H -------- K -------- merge
GOOD       ?           BAD
```

You inspected:

```bash
cat scripts/scan.sh | wc -l
```

and got:

```text
10
```

The scanner existed.

Therefore:

```bash
git bisect bad
```

You were saying:

> "K already contains the problem."

This is extremely important:

**You are not telling Git "K is a bad commit" in the sense that the commit itself is necessarily defective.**

You're telling Git:

> **"The bug/regression I'm searching for exists at K."**

---

# 10. Git has almost isolated the culprit

Git said:

```text
Bisecting: 0 revisions left to test after this (roughly 0 steps)

[20a9363] J : Redacted
```

Now the interesting range was essentially:

```text
J -------- K
?          BAD
```

You tested J:

```bash
cat scripts/scan.sh | wc -l
```

Result:

```text
1
```

The script was still:

```bash
# TODO: write the script
```

So J was good:

```bash
git bisect good
```

Now Git had enough information to conclude:

```text
J = GOOD
K = BAD
```

Therefore:

> **K is the first bad commit.**

And Git told you exactly that:

```text
30f59b3278e07948e2bd430faaecf972dcf1837d is the first bad commit
```

---

# 11. Why K is the answer

This is the most important piece of reasoning.

You established:

```text
J = GOOD
K = BAD
```

And J directly precedes K on that branch:

```text
J
│
▼
K
```

Therefore the transition is:

```text
GOOD ────────> BAD
   J             K
```

So K is the first commit where the bad behavior appears.

Git gives you:

```text
commit 30f59b3278e07948e2bd430faaecf972dcf1837d
```

and:

```text
K : Karate
```

Then Git even tells you the affected file:

```text
scripts/scan.sh | 11 ++++++++++-
```

That is incredibly useful for debugging.

---

# 12. What actually changed in K?

Git says:

```text
1 file changed, 10 insertions(+), 1 deletion(-)
```

So your next debugging step would naturally be:

```bash
git show 30f59b3
```

That shows the exact patch introduced by K.

You'd probably see something conceptually like:

```diff
- # TODO: write the script
+ printf ...
+ grep ...
+ grep ...
+ ...
```

Now you can investigate:

> "Which of these changes introduced the bug?"

That is the point where `bisect` hands the investigation back to you.

---

# 13. The entire workflow you performed

Your actual workflow was:

```text
1. Start bisect
       ↓
git bisect start

2. Tell Git current commit is broken
       ↓
git bisect bad

3. Give Git a known-good historical commit
       ↓
git bisect good 0d16f95

4. Git chooses a middle commit
       ↓
       H

5. Test H
       ↓
   GOOD
       ↓
git bisect good

6. Git chooses another middle commit
       ↓
     merge

7. Test merge
       ↓
    BAD
       ↓
git bisect bad

8. Git chooses K
       ↓
    BAD
       ↓
git bisect bad

9. Git chooses J
       ↓
   GOOD
       ↓
git bisect good

10. Git concludes
       ↓
K = first bad commit
```

This is binary search applied to **Git history**.

---

# 14. What does "good" and "bad" actually mean?

This is a subtle but important concept.

`good` and `bad` are **labels you provide for the behavior you're investigating**.

They don't mean:

```text
GOOD = professionally written code
BAD  = shitty code
```

They mean:

```text
GOOD = the bug does NOT occur

BAD = the bug DOES occur
```

For example, suppose your bug is:

> `scripts/scan.sh` should contain 10 lines.

Then:

```bash
git bisect good
```

means:

> "At this commit, `scan.sh` behaves correctly."

And:

```bash
git bisect bad
```

means:

> "At this commit, `scan.sh` exhibits the problem."

---

# 15. Your `wc -l` was effectively a test

This:

```bash
cat scripts/scan.sh | wc -l
```

wasn't just random inspection.

You were using an **oracle**.

An oracle is simply a test that gives you a binary answer:

```text
Does this commit have the bug?

        ↓

      YES / NO
```

Your test was:

```text
lines == 1
    ↓
GOOD

lines == 10
    ↓
BAD
```

That is exactly what `bisect` needs.

It doesn't necessarily need a test suite.

You can use:

```bash
./gradlew test
```

or:

```bash
mvn test
```

or:

```bash
./scripts/scan.sh
```

or:

```bash
grep ...
```

or even manually inspect the application.

The requirement is simply:

> **You need to reliably classify each tested commit as good or bad.**

---

# 16. This is where automated bisect becomes powerful

You manually did:

```bash
cat scripts/scan.sh | wc -l
```

Then:

```bash
git bisect good
```

or:

```bash
git bisect bad
```

But you could turn that into a test.

For example, suppose:

```bash
test "$(wc -l < scripts/scan.sh)" -eq 1
```

means good.

Then you could create a script:

```bash
#!/bin/bash

if [ "$(wc -l < scripts/scan.sh)" -eq 1 ]; then
    exit 0
else
    exit 1
fi
```

Then:

```bash
git bisect run ./test.sh
```

Git can perform the entire search automatically:

```text
checkout commit
      ↓
run test.sh
      ↓
exit 0?
   /     \
 YES      NO
 ↓         ↓
GOOD      BAD
   \       /
    ↓     ↓
choose next commit
        ↓
      repeat
```

That's `bisect` at its full potential.

---

# 17. One thing you should understand about `HEAD`

During your bisect, you started at:

```text
b6c5f1b O
```

But Git subsequently checked out:

```text
2fea9a8 H
f490ca8 merge
30f59b3 K
20a9363 J
```

So during bisect:

```bash
git log --oneline
```

would show a different `HEAD` each time.

This is normal.

Git is temporarily moving your working tree around to test historical snapshots.

Conceptually:

```text
normal Git:

HEAD
 ↓
O

bisect:

HEAD → H
HEAD → merge
HEAD → K
HEAD → J
```

Git is effectively saying:

> "Let's temporarily travel through history and test these snapshots."

---

# 18. Why you must eventually run `bisect reset`

After finding K, you should normally run:

```bash
git bisect reset
```

This ends bisect mode and returns you to the branch/commit you were on before the investigation.

You can think of it as:

```text
START
  ↓
enter bisect
  ↓
Git moves HEAD around
  ↓
find first bad commit
  ↓
git bisect reset
  ↓
return to normal Git workflow
```

You don't want to leave yourself sitting on some historical bisect commit accidentally.

---

# 19. One subtle problem: merge commits

Your investigation happened to hit:

```text
f490ca8 Merge pull request #1 from AlirezaAkhavanJava/add_scanner
```

That's a **merge commit**.

This matters because your history isn't simply one straight line. You had:

```text
                  K
                 /
... --- H ------ ...
          \
           ...
```

More accurately, your repository has multiple parent relationships around that merge.

`git bisect` can still navigate this history, but when you're dealing with complicated merge histories, understanding **which parent introduced the behavior** can become important.

For basic bisecting, don't overcomplicate this yet. Your investigation worked correctly.

---

# 20. The senior mental model

Don't memorize the commands first.

Memorize the problem:

```text
"I know it worked here."
        ↓
     GOOD
        │
        │ unknown commits
        │
        ↓
     BAD
"I know it's broken here."
```

`git bisect` asks:

> **"Where did GOOD become BAD?"**

Then it repeatedly performs:

```text
             commit range
                  │
             split in half
                  │
             test midpoint
             /           \
          GOOD            BAD
           ↓               ↓
   discard later half   discard earlier half
           \               /
            \             /
             repeat
                ↓
        first bad commit
```

So the essence is:

> **`git bisect` = binary search over commit history using your test as the judge.**

And your actual investigation demonstrated the complete idea:

```text
A ... H ... J ... K ... merge ... O
    GOOD   GOOD  BAD          BAD
                  ↑
             FIRST BAD
```

**K (`30f59b3`) is where your repository crossed the boundary from good to bad.**



[[Git & Github]]