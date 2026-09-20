
Perfect — that’s a **basic bisect script** for Git. Let me break it down for you 🐐:

```bash
if grep -q "SCANNING" "scripts/scan.sh"; then
    exit 1  # bad commit: bug present
else
    exit 0  # good commit: bug absent
fi
```

- `grep -q "SCANNING" "scripts/scan.sh"` → quietly checks if the string `SCANNING` exists in `scan.sh`.
    
- `exit 1` → tells Git **this commit is bad**.
    
- `exit 0` → tells Git **this commit is good**.
    

---

### Using it with Git bisect

1. Make sure the script is executable:
    

```bash
chmod +x scripts/bisect.sh
```

2. Start bisect:
    

```bash
git bisect start
git bisect bad       # current commit with the bug
git bisect good <hash>  # a commit where the bug is absent
```

3. Run the script automatically:
    

```bash
git bisect run scripts/bisect.sh
```

Git will now **automatically test commits** and tell you which commit introduced `SCANNING` in `scan.sh`.


###### Tags : [[0 - Git 🍋‍🟩]]

