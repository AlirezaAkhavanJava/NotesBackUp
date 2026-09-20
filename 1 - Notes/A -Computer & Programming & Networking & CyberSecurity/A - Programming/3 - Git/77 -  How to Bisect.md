The workflow for **Git bisect** : 

1. **Start bisecting**:
    

```bash
git bisect start
```

2. **Mark a known good commit** (bug-free):
    

```bash
git bisect good <commit-hash>
```

3. **Mark a known bad commit** (where the bug exists):
    

```bash
git bisect bad <commit-hash>
```

4. Git automatically checks out a commit **in the middle** between good and bad. Test it.
    
5. Mark the commit based on your test:
    

- Bug is **present**:
    

```bash
git bisect bad
```

- Bug is **absent**:
    

```bash
git bisect good
```

6. Git will continue narrowing down. Repeat step 5 until it finds the **first bad commit**.
    
7. **Finish bisecting**:
    

```bash
git bisect reset
```

- Returns you to your original branch.
    

---

💡 Tip: You can automate this with a script using `git bisect run <script>` if the test can be automated.


---

### 1. Start bisect

```bash
git bisect start
```

---

### 2. Tell Git the bad commit

```bash
git bisect bad
```

- Usually your current commit where the bug exists.
    

---

### 3. Tell Git the good commit

```bash
git bisect good <commit-hash>
```

- Pick a commit **where the bug didn’t exist**.
    

Git now automatically checks out a commit halfway between `good` and `bad`.

---

### 4. Test the commit

- Run your tests or check if the bug exists:
    

```bash
# if buggy
git bisect bad

# if clean
git bisect good
```

- Git will move halfway again and repeat until it finds the **first bad commit**.
    

---

### 5. Finish bisect

```bash
git bisect reset
```

- Returns to your original branch and stops bisecting.
    

---

💡 Tip: You can automate testing with a script:

```bash
git bisect run ./test-script.sh
```

- Git will automatically mark commits as good or bad based on the script exit code.
    

---





##### Tags : [[0 - Git 🍋‍🟩]]