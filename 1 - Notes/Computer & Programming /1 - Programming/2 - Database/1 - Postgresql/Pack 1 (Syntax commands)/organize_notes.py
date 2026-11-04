#!/usr/bin/env python3
"""
Organize PostgreSQL Markdown notes into topic folders.

Safe by default:
    python3 organize_notes.py          # preview only
    python3 organize_notes.py --apply  # perform moves/renames

Run this script from the directory containing the Markdown notes.
It does not change note contents.
"""

from pathlib import Path
import argparse
import re
import shutil
import unicodedata

ROOT = Path.cwd()

FOLDER_ORDER = [
    "00 - Database Fundamentals",
    "01 - SQL Queries & Commands",
    "02 - Filtering & Sorting",
    "03 - Joins & Set Operations",
    "04 - Subqueries & CTEs",
    "05 - Functions & Expressions",
    "06 - Window Functions & Analytics",
    "07 - Views & Database Objects",
    "08 - Database Constraints & Integrity",
    "09 - Procedures, Variables & Triggers",
    "10 - Indexes",
    "11 - Data Storage Structures",
    "12 - Storage & Database Internals",
    "13 - Performance & Optimization",
    "14 - Advanced PostgreSQL",
    "15 - Data Architecture & Engineering",
    "99 - Review Manually",
]

# Remove emoji characters while preserving ordinary punctuation and text.
# Covers common emoji blocks, flags, skin tones, variation selectors and ZWJ.
EMOJI_RE = re.compile(
    "["
    "\U0001F000-\U0001FAFF"
    "\U0001FC00-\U0001FFFD"
    "\U00002600-\U000027BF"
    "\U00002300-\U000023FF"
    "\U00002B00-\U00002BFF"
    "\U0001F1E6-\U0001F1FF"
    "\U0001F3FB-\U0001F3FF"
    "\uFE0E-\uFE0F"
    "\u200D"
    "\u20E3"
    "]+"
)

# Also remove stray emoji presentation marks and normalize whitespace.
NUMBER_PREFIX_RE = re.compile(
    r"^\s*\d+(?:\s*\.\s*\d+)*\s*(?:[-–—.]?\s*)"
)

def clean_title(filename: str) -> str:
    """Remove leading numbering and emoji from a Markdown filename."""
    title = Path(filename).stem
    title = NUMBER_PREFIX_RE.sub("", title, count=1)
    title = EMOJI_RE.sub("", title)
    title = title.replace("\uFE0F", "").replace("\u200D", "")
    title = re.sub(r"\s+", " ", title)
    title = re.sub(r"\s+([,;:])", r"\1", title)
    title = title.strip(" \t-–—._")
    return title or "Untitled"

def has_any(text: str, phrases) -> bool:
    return any(phrase in text for phrase in phrases)

def classify(title: str) -> str:
    """Specific rules first; avoid broad keyword matches where possible."""
    t = title.casefold()
    compact = re.sub(r"[^a-z0-9%]+", " ", t).strip()
    words = set(compact.split())

    # Database constraints and integrity
    if has_any(t, [
        "constraint", "primary key", "foreign key", "unique constraint",
        "check constraint", "not null constraint"
    ]):
        return "08 - Database Constraints & Integrity"

    # Window functions: OVER is a window clause in this note collection.
    if t.strip() == "over" or has_any(t, [
        "window", " over", "over ", "running total", "rolling total",
        "rolling average", "rolling max", "ranking function",
        "data segmentation", "window value", "window aggregate",
        "totals"
    ]):
        return "06 - Window Functions & Analytics"

    # Set operations belong with joins, not subqueries.
    if has_any(t, [
        "union", "except", "intersect", "join", "anti-join",
        "anti join", "set and join", "null handeling in joins",
        "null handling in joins"
    ]):
        return "03 - Joins & Set Operations"

    # Subqueries and CTEs, including common misspellings in the filenames.
    if has_any(t, [
        "subquery", "subqueries", "sub query", "sunquery",
        "correlated", "non-correlated", "non correlated",
        "cte", "recursive cte", "dependencies", " any",
        " all", "exist", "exists", "result types"
    ]) or t.strip() in {"any", "all", "exist", "exists"}:
        return "04 - Subqueries & CTEs"

    # Index health and tuning topics belong under performance.
    if has_any(t, [
        "missing index", "duplicate index", "update statistics",
        "statistics update", "fragmentation", "reorganize",
        "rebuild", "monitor fragmentation", "execution plan",
        "stress testing", "explain"
    ]):
        return "13 - Performance & Optimization"

    # Index concepts
    if has_any(t, [
        "index", "b-tree", "btree", "gin index", "uniqueindex",
        "unique index", "filtered index", "filterindex",
        "clustered and non-clustered"
    ]):
        return "10 - Indexes"

    # Table/storage structures
    if has_any(t, [
        "rowstore", "row-store", "columnstore", "column-store",
        "heap", "data file", "data page", "disk storage",
        "storage areas"
    ]):
        return "11 - Data Storage Structures"

    # Performance and tuning
    if has_any(t, [
        "query performance", "performance tuning", "optimization"
    ]):
        return "13 - Performance & Optimization"

    # Database internals
    if has_any(t, [
        "database engine", "cache", "buffer pool", "wal",
        "system catalog", "information schema", "disk",
        "storage", "database internals"
    ]):
        return "12 - Storage & Database Internals"

    # Advanced PostgreSQL features
    if has_any(t, [
        "jsonb", "advisory lock", "advisory locks",
        "partitioning", "partition"
    ]):
        return "14 - Advanced PostgreSQL"

    # Data architecture and engineering
    if has_any(t, [
        "data mart", "data marts", "data warehouse", "data wherehouse",
        "data model", "oltp", "olap", "etl", "data migration"
    ]):
        return "15 - Data Architecture & Engineering"

    # Stored procedures, PL/pgSQL variables and triggers
    if has_any(t, [
        "stored procedure", "stored procedures", "procedure parameter",
        "procedure parameters", "procedure variable", "procedure variables",
        "default parameter", "parameter value", "%type", "%rowtype",
        "trigger", "error handling", "variables"
    ]):
        return "09 - Procedures, Variables & Triggers"

    # Views and database objects
    if has_any(t, [
        "view", "views", "schema", "ctas", "temp table",
        "temporary table", "server, database", "session"
    ]):
        return "07 - Views & Database Objects"

    # Functions and expressions
    if has_any(t, [
        "function", "functions", "case", "mapping", "cast",
        "convert", "format", "dateadd", "datediff", "isdate",
        "null function", "datalength", "conditional aggregation",
        "conditional aggrigation", "aggregate", "analytical",
        "numeric", "numberic", "date & time", "date and time",
        "postgresql and sql date", " if"
    ]) or t.strip() == "if":
        return "05 - Functions & Expressions"

    # Filtering and sorting
    if has_any(t, [
        "where", "order by", "group by", "having", "distinct",
        "conditions", "filter"
    ]):
        return "02 - Filtering & Sorting"

    # SQL language and command fundamentals
    if has_any(t, [
        "ddl command", "dml command", "dql command", "sql query",
        "select query", "insert", "update", "delete", "returning",
        "alter", "drop", "top,limit", "top limit", "sql command"
    ]) or t.strip() in {"select"}:
        return "01 - SQL Queries & Commands"

    # Database fundamentals
    if has_any(t, [
        "postgresql", "dbms", "sql and nosql", "data types in sql",
        "server, database", "database, schema"
    ]) or t.strip() == "sql":
        return "00 - Database Fundamentals"

    # These filenames need a human decision rather than a guessed placement.
    return "99 - Review Manually"

def original_sort_key(filename: str):
    """Keep the old numeric sequence as a guide, including decimal mistakes."""
    match = re.match(r"^\s*(\d+(?:\s*\.\s*\d+)*)", filename)
    if not match:
        return (float("inf"), filename.casefold())
    try:
        number = float(re.sub(r"\s+", "", match.group(1)))
    except ValueError:
        number = float("inf")
    return (number, filename.casefold())

def main():
    parser = argparse.ArgumentParser(description="Organize PostgreSQL Markdown notes.")
    parser.add_argument(
        "--apply", action="store_true",
        help="Actually create folders and move/rename notes. Default is preview only."
    )
    args = parser.parse_args()

    # Only process Markdown files directly inside the current directory.
    files = sorted(
        [p for p in ROOT.iterdir() if p.is_file() and p.suffix.lower() == ".md"],
        key=lambda p: p.name.casefold()
    )

    if not files:
        print(f"No Markdown files found directly inside: {ROOT}")
        return

    groups = {folder: [] for folder in FOLDER_ORDER}
    for source in files:
        title = clean_title(source.name)
        folder = classify(title)
        groups[folder].append((source, title))

    planned = []
    print(f"\nRoot: {ROOT}")
    print(f"Found {len(files)} Markdown notes.")
    print("Mode:", "APPLY" if args.apply else "PREVIEW ONLY")

    for folder in FOLDER_ORDER:
        notes = sorted(groups[folder], key=lambda item: original_sort_key(item[0].name))
        if not notes:
            continue

        print(f"\n{folder}/  ({len(notes)} notes)")
        for number, (source, title) in enumerate(notes):
            destination = ROOT / folder / f"{number:02d} - {title}.md"
            planned.append((source, destination))
            print(f"  {source.name}  ->  {destination.relative_to(ROOT)}")

    # Detect duplicate target paths before making any changes.
    destinations = [dest for _, dest in planned]
    duplicate_targets = sorted({
        str(path) for path in destinations if destinations.count(path) > 1
    })
    existing_conflicts = [
        dest for source, dest in planned
        if dest.exists() and dest != source
    ]

    if duplicate_targets or existing_conflicts:
        print("\nABORTED: destination-name conflicts detected.")
        for item in duplicate_targets:
            print("  Duplicate planned destination:", item)
        for item in existing_conflicts:
            print("  Destination already exists:", item)
        print("Resolve these conflicts before applying.")
        return

    if not args.apply:
        print("\nPREVIEW ONLY — nothing has been moved or renamed.")
        print("Review the folders and filenames above.")
        print("When satisfied, run: python3 organize_notes.py --apply")
        return

    # Stage all files in a temporary directory first. This prevents
    # renaming collisions when source and destination names overlap.
    staging = ROOT / ".organize_notes_staging"
    if staging.exists():
        print(f"\nABORTED: staging directory already exists: {staging}")
        print("Inspect it before trying again.")
        return

    staging.mkdir()
    try:
        staged = []
        for index, (source, destination) in enumerate(planned):
            temp = staging / f"{index:04d}.md"
            shutil.move(str(source), str(temp))
            staged.append((temp, destination))

        for temp, destination in staged:
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(temp), str(destination))

        print(f"\nSuccessfully organized {len(planned)} notes into topic folders.")
    except Exception:
        print("\nAn error occurred while moving files.")
        print("Remaining staged files are in:", staging)
        print("Do not delete that directory; it may contain notes to recover.")
        raise
    else:
        staging.rmdir()

if __name__ == "__main__":
    main()
