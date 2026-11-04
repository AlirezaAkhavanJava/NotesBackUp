#!/usr/bin/env python3
"""Organize Git Pack 1 Markdown notes. Preview by default; use --apply to move files."""
from pathlib import Path
import argparse, re, unicodedata, sys

CATEGORIES = [
("00 - Git Fundamentals", ["git.md","porcelain","plumbing","repository","git states","states management","git files"]),
("01 - Git Configuration", ["config","configuration","set and unset"]),
("02 - Git Internals & Storage", ["hash","objects","inode","cat-file","xxd","trees and blob","stores data"]),
("03 - Commits & History", ["git commit","git log","log flags","reflog","amend"]),
("04 - Branches", ["branches","default branch","branch operations","no branch","duplicate branches","upstream"]),
("05 - Merging & Rebasing", ["merge","rebase","conflict","rerere","ours and theirs","squashing"]),
("06 - Remotes & Collaboration", ["remote","fetch","push","pull","github","fork","clone","upstream"]),
("07 - Undoing & Comparing Changes", ["reset","revert","cherry-pick","cherry pick","bisect","git diff"]),
("08 - Stashing", ["stash","pop"]),
("09 - Git Ignore Rules", ["gitignore"]),
("10 - Worktrees", ["worktree","work trees"]),
("11 - Tags & Versioning", ["tags","semver","conventional"]),
("12 - Scripting & Automation", ["script"]),
]
def clean_title(filename):
    stem = Path(filename).stem
    stem = re.sub(r"^\s*\d+(?:\.\d+)?\s*[-.)]?\s*", "", stem)
    stem = "".join(ch for ch in stem if not (unicodedata.category(ch) in ("So","Sk") or 0x1F300 <= ord(ch) <= 0x1FAFF))
    stem = re.sub(r"\s+", " ", stem).strip(" ._-")
    return stem or "Untitled"
def classify(filename):
    s = clean_title(filename).lower()
    if "gitignore" in s: return "09 - Git Ignore Rules"
    if "worktree" in s or "work trees" in s: return "10 - Worktrees"
    if "stash" in s or s == "pop": return "08 - Stashing"
    if any(x in s for x in ["config","configuration","set and unset"]): return "01 - Git Configuration"
    if any(x in s for x in ["reset","revert","cherry-pick","cherry pick","bisect","git diff"]): return "07 - Undoing & Comparing Changes"
    if any(x in s for x in ["merge","rebase","conflict","rerere","ours and theirs","squashing"]): return "05 - Merging & Rebasing"
    if any(x in s for x in ["remote","fetch","push","pull","github","fork","clone","upstream"]): return "06 - Remotes & Collaboration"
    if any(x in s for x in ["branch","no branch","duplicate branches"]): return "04 - Branches"
    if any(x in s for x in ["git log","log flags","reflog","git commit","amend"]): return "03 - Commits & History"
    if any(x in s for x in ["hash","objects","inode","cat-file","xxd","trees and blob","stores data"]): return "02 - Git Internals & Storage"
    if any(x in s for x in ["config","configuration","set and unset"]): return "01 - Git Configuration"
    if "script" in s: return "12 - Scripting & Automation"
    if any(x in s for x in ["tags","semver","conventional"]): return "11 - Tags & Versioning"
    if any(x in s for x in ["git","porcelain","plumbing","repository","states","files"]): return "00 - Git Fundamentals"
    return "99 - Review Manually"
def main():
    p = argparse.ArgumentParser()
    p.add_argument("--apply", action="store_true", help="perform the moves (default is preview only)")
    args = p.parse_args()
    root = Path.cwd()
    sources = sorted([x for x in root.iterdir() if x.is_file() and x.suffix.lower()==".md"], key=lambda x:x.name.lower())
    if not sources:
        print("No Markdown files found in", root); return 0
    buckets = {}
    for src in sources:
        folder = classify(src.name)
        buckets.setdefault(folder, []).append(src)
    plan=[]
    for folder, items in sorted(buckets.items()):
        for index, src in enumerate(sorted(items, key=lambda x:x.name.lower())):
            title = clean_title(src.name)
            dest = root / folder / f"{index:02d} - {title}.md"
            plan.append((src,dest))
    destinations=[d for _,d in plan]
    if len(destinations)!=len(set(destinations)):
        print("ERROR: duplicate destination names detected; no changes made."); return 2
    for src,dst in plan:
        if dst.exists() and dst.resolve()!=src.resolve():
            print(f"ERROR: destination already exists: {dst}\\nNo changes made."); return 2
    print(f"Found {len(sources)} Markdown files in: {root}\\n")
    for folder, items in sorted(buckets.items()):
        print(f"{folder} ({len(items)})")
        for src,dst in [pair for pair in plan if pair[1].parent.name==folder]:
            print(f"  {src.name}  ->  {folder}/{dst.name}")
    if not args.apply:
        print("\\nPREVIEW ONLY. Nothing was moved. Run with --apply to perform these moves.")
        return 0
    # Stage every source first so renames cannot collide with one another.
    import tempfile
    staged=[]
    try:
        with tempfile.TemporaryDirectory(prefix=".git-notes-stage-", dir=root) as td:
            td=Path(td)
            for i,(src,dst) in enumerate(plan):
                tmp=td/f"{i:04d}.md"
                src.rename(tmp); staged.append((tmp,dst))
            for tmp,dst in staged:
                dst.parent.mkdir(parents=True, exist_ok=True)
                tmp.rename(dst)
    except Exception as e:
        print("ERROR while moving files:", e)
        print("Some files may have been staged; inspect the directory before retrying.")
        return 1
    print(f"\\nDone. Organized {len(plan)} files into {len(buckets)} folders.")
    return 0
if __name__=="__main__": sys.exit(main())
