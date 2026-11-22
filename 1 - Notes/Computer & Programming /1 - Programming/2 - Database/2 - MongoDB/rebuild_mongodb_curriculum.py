
#!/usr/bin/env python3

from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parent
TAG = "[[MongoDB]]"

created = 0
removed = 0
moved = 0
tagged = 0
skipped = 0
conflicts = 0

# ==================================================
# CURRICULUM
# ==================================================

packs = {
    "Pack 1 - MongoDB Fundamentals": [
        "MongoDB in Backend Development",
        "Why Use MongoDB",
        "When to Use MongoDB Instead of PostgreSQL",
        "MongoDB vs Relational Databases",
        "MongoDB Server and Database Concepts",
        "MongoDB Compass and mongosh",
        "Connecting to MongoDB Locally",
        "MongoDB Commands and Command Types",
        "Creating a Database in MongoDB",
    ],

    "Pack 2 - Documents and Data Modeling": [
        "Document-Oriented Data Model",
        "BSON and MongoDB Data Types",
        "Documents and Collections",
        "Creating Collections",
        "Embedded Documents and Nested Objects",
        "Arrays in MongoDB Documents",
        "Embedding vs Referencing Documents",
        "Designing Documents for Java Entities",
        "Schema Design for Spring Boot Applications",
        "One-to-One One-to-Many and Many-to-Many Relationships",
        "MongoDB Schema Design Mistakes",
    ],

    "Pack 3 - MongoDB Query Fundamentals": [
        "MongoDB Query Syntax",
        "find and findOne",
        "Filtering Documents",
        "Comparison Operators",
        "Logical Query Operators",
        "Element and Evaluation Query Operators",
        "Querying Nested Documents",
        "Querying Arrays",
        "Null and Missing Fields",
        "Query Method Chaining",
    ],

    "Pack 4 - Spring Data MongoDB Setup": [
        "Spring Data MongoDB Overview",
        "Adding Spring Data MongoDB Dependency",
        "MongoDB Configuration in application.yml",
        "MongoDB Connection URI",
        "MongoDB Authentication and Credentials",
        "MongoTemplate and MongoRepository",
        "Spring Boot MongoDB Auto Configuration",
        "Connecting Spring Boot to MongoDB with Docker",
    ],

    "Pack 5 - Java Object Mapping": [
        "@Document Annotation",
        "@Id and MongoDB ObjectId",
        "@Field Annotation",
        "@Transient Annotation",
        "Mapping Java Objects to MongoDB Documents",
        "Custom Converters",
        "MongoCustomConversions",
        "Handling Dates and Java Time Types",
        "Enum Mapping",
        "Mapping Nested Objects and Collections",
        "Auditing with Spring Data MongoDB",
    ],

    "Pack 6 - Repository and CRUD Operations": [
        "MongoRepository Interface",
        "Creating MongoDB Repositories",
        "Saving Documents with save",
        "Inserting Documents with insert",
        "Finding Documents by ID",
        "Finding All Documents",
        "Deleting Documents",
        "Checking Document Existence",
        "save vs insert",
        "MongoDB CRUD in REST Controllers and Services",
    ],

    "Pack 7 - Spring Data MongoDB Queries": [
        "Derived Query Methods",
        "Query Method Naming Conventions",
        "@Query Annotation",
        "Custom MongoDB Queries in Repositories",
        "MongoTemplate find Operations",
        "MongoTemplate Query and Criteria",
        "Combining Criteria",
        "Dynamic Queries",
        "Choosing Between MongoRepository and MongoTemplate",
    ],

    "Pack 8 - Updates and Atomic Operations": [
        "MongoDB Update Operators",
        "Updating Documents with MongoTemplate",
        "Update.set and Update.unset",
        "Incrementing Values with Update.inc",
        "Updating Nested Fields",
        "Updating Array Elements",
        "findAndModify",
        "findAndReplace",
        "Atomic Updates and Concurrency",
        "Upsert Operations",
    ],

    "Pack 9 - Sorting Pagination and Projections": [
        "Sorting Query Results",
        "Limiting Query Results",
        "Skip and Limit",
        "Pagination with Pageable",
        "Page vs Slice",
        "Sorting with Sort",
        "Field Projections",
        "DTO Projections",
        "Efficient Data Retrieval",
    ],

    "Pack 10 - Aggregation Pipeline": [
        "MongoDB Aggregation Overview",
        "Aggregation Pipeline Stages",
        "$match and $project",
        "$group and Accumulators",
        "$sort and $limit",
        "$unwind",
        "$lookup",
        "$cond and $switch",
        "Aggregation with MongoTemplate",
        "Aggregation Results and DTO Mapping",
        "Practical Aggregation Examples",
    ],

    "Pack 11 - Indexes and Performance": [
        "MongoDB Index Fundamentals",
        "Single Field Indexes",
        "Compound Indexes",
        "Unique Indexes",
        "TTL Indexes",
        "Indexes with Spring Data MongoDB",
        "Understanding Explain Plans",
        "Query Performance and Index Selection",
        "Common Indexing Mistakes",
    ],

    "Pack 12 - Transactions and Validation": [
        "MongoDB Validation Rules",
        "Bean Validation with MongoDB Entities",
        "Handling Duplicate Key Exceptions",
        "MongoDB Exception Handling in Spring Boot",
        "MongoDB Transactions",
        "MongoTransactionManager",
        "Replica Set Requirements for Transactions",
        "Optimistic Locking with @Version",
        "When Transactions Are Necessary",
    ],

    "Pack 13 - Testing Spring Data MongoDB": [
        "Testing MongoDB Repositories",
        "Testing with Testcontainers MongoDB",
        "MongoDB Integration Tests with Spring Boot",
        "Testing MongoTemplate Queries",
        "Testing Custom Converters",
        "Test Database Isolation",
        "Testing MongoDB REST Endpoints",
    ],

    "Pack 14 - MongoDB Production": [
        "MongoDB Docker Image",
        "MongoDB with Docker Compose",
        "MongoDB Environment Variables",
        "Production Connection Configuration",
        "Connection Pooling",
        "Read and Write Concerns",
        "Replica Sets Fundamentals",
        "MongoDB Backups and Restores",
        "MongoDB Logging and Monitoring",
        "MongoDB Security Fundamentals",
        "MongoDB Production Troubleshooting",
    ],
}


# ==================================================
# EXISTING NOTES
# Original filename -> destination pack
# ==================================================

existing_notes = {
    "1 - MongoDB 🍂.md":
        "Pack 1 - MongoDB Fundamentals",

    "2 - MongoDB Spring Boot 🍂.md":
        "Pack 4 - Spring Data MongoDB Setup",

    "3 - DataBase 🍂.md":
        "Pack 1 - MongoDB Fundamentals",

    "4 - Structure 🍂.md":
        "Pack 2 - Documents and Data Modeling",

    "5 - Creating a Database in MongoDB 🍂.md":
        "Pack 1 - MongoDB Fundamentals",

    "6 - Creating a Collection in MongoDB 🍂.md":
        "Pack 2 - Documents and Data Modeling",

    "7 - Querying Data in MongoDB 🍂.md":
        "Pack 3 - MongoDB Query Fundamentals",

    "8 - Types of Commands in MongoDB 🍂.md":
        "Pack 1 - MongoDB Fundamentals",

    "9 - sorting and limiting.md":
        "Pack 9 - Sorting Pagination and Projections",

    "10 - Filtering.md":
        "Pack 3 - MongoDB Query Fundamentals",

    "11 - method chaining.md":
        "Pack 3 - MongoDB Query Fundamentals",

    "12 - CRUD.md":
        "Pack 6 - Repository and CRUD Operations",

    "13 - Query and Projection.md":
        "Pack 9 - Sorting Pagination and Projections",

    "14 - Update.md":
        "Pack 8 - Updates and Atomic Operations",

    "15 - conditionals.md":
        "Pack 10 - Aggregation Pipeline",

    "16 - $cond and $switch.md":
        "Pack 10 - Aggregation Pipeline",

    "17 - delete.md":
        "Pack 6 - Repository and CRUD Operations",

    "18 - Comparision.md":
        "Pack 3 - MongoDB Query Fundamentals",

    "Spring Boot + MongoDB/1 - Why MongoDB.md":
        "Pack 1 - MongoDB Fundamentals",
}


# ==================================================
# HELPERS
# ==================================================

def ensure_tag(path: Path) -> None:
    global tagged

    content = path.read_text(encoding="utf-8")

    if TAG in content.splitlines():
        return

    if content.strip():
        content = TAG + "\n\n" + content.lstrip("\n")
    else:
        content = TAG + "\n"

    path.write_text(content, encoding="utf-8")
    tagged += 1

    print(f"[TAGGED] {path.relative_to(ROOT)}")


# ==================================================
# STEP 1 - CLEAN FAILED PLACEHOLDERS
#
# Only removes files whose entire content is TAG.
# Notes containing actual content are preserved.
# ==================================================

print("\n========== CLEANING FAILED PLACEHOLDERS ==========\n")

for pack_name in packs:
    directory = ROOT / pack_name

    if not directory.is_dir():
        continue

    for file in directory.glob("*.md"):
        try:
            content = file.read_text(encoding="utf-8")

            if content.strip() == TAG:
                file.unlink()
                removed += 1
                print(f"[REMOVED PLACEHOLDER] {file.relative_to(ROOT)}")

        except (OSError, UnicodeError) as error:
            print(f"[ERROR] Could not inspect {file}: {error}")


# ==================================================
# STEP 2 - CREATE PACK DIRECTORIES
# ==================================================

print("\n========== CREATING PACKS ==========\n")

for pack_name in packs:
    directory = ROOT / pack_name
    directory.mkdir(parents=True, exist_ok=True)
    print(f"[PACK] {pack_name}")


# ==================================================
# STEP 3 - MOVE EXISTING NOTES
# ==================================================

print("\n========== ORGANIZING EXISTING NOTES ==========\n")

for filename, pack_name in existing_notes.items():

    source = ROOT / filename
    destination_dir = ROOT / pack_name
    destination = destination_dir / Path(filename).name

    if source.is_file():

        if destination.exists():
            print(f"[CONFLICT] Both source and destination exist:")
            print(f"           {filename}")
            conflicts += 1
            continue

        destination_dir.mkdir(parents=True, exist_ok=True)
        shutil.move(str(source), str(destination))

        ensure_tag(destination)

        moved += 1
        print(f"[MOVED] {filename} -> {pack_name}/")

    elif destination.is_file():

        # Supports recovery if a note was already moved.
        ensure_tag(destination)
        print(f"[ALREADY ORGANIZED] {filename}")

    else:
        print(f"[NOT FOUND] {filename}")


# ==================================================
# STEP 4 - REMOVE OLD EMPTY DIRECTORY
# ==================================================

old_directory = ROOT / "Spring Boot + MongoDB"

if old_directory.is_dir():
    try:
        old_directory.rmdir()
        print("\n[REMOVED EMPTY DIRECTORY] Spring Boot + MongoDB")
    except OSError:
        print("\n[KEPT] Spring Boot + MongoDB is not empty")


# ==================================================
# STEP 5 - CREATE MISSING CURRICULUM NOTES
# ==================================================

print("\n========== CREATING CURRICULUM NOTES ==========\n")

for pack_name, notes in packs.items():

    directory = ROOT / pack_name

    for index, note_name in enumerate(notes):

        filename = f"{index:02d} - {note_name}.md"
        filepath = directory / filename

        if filepath.exists():
            ensure_tag(filepath)
            skipped += 1
            print(f"[PRESERVED] {pack_name}/{filename}")
            continue

        filepath.write_text(TAG + "\n", encoding="utf-8")

        created += 1
        print(f"[CREATED] {pack_name}/{filename}")


# ==================================================
# SUMMARY
# ==================================================

print("\n========== REBUILD SUMMARY ==========\n")

print(f"Removed failed placeholders: {removed}")
print(f"Moved existing notes:        {moved}")
print(f"New curriculum notes:        {created}")
print(f"Existing notes tagged:       {tagged}")
print(f"Existing notes preserved:    {skipped}")
print(f"Conflicts:                   {conflicts}")

print("\nCurriculum location:")
print(ROOT)

print("\nRebuild completed.")
