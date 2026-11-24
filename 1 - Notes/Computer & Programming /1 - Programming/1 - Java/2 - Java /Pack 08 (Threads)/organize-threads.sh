
#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# Java Threads Pack Organizer
# Bash 4+
# ============================================================

ROOT="$(pwd)"
APPLY=false

if [[ "${1:-}" == "--apply" ]]; then
    APPLY=true
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--apply]"
    exit 1
fi

# ------------------------------------------------------------
# 1. Categories
# ------------------------------------------------------------

CATEGORIES=(
    "00 - Basics"
    "01 - Synchronization"
    "02 - Java Memory Model & Thread Safety"
    "03 - Executors & Thread Pools"
    "04 - Asynchronous Programming"
    "05 - Concurrent Utilities"
    "06 - Virtual Threads"
    "07 - Reactive Programming"
    "08 - Server & Database Concurrency"
    "09 - Diagnostics & Performance"
)

# ------------------------------------------------------------
# 2. Classification
# ------------------------------------------------------------

categorize() {
    local name="${1,,}"

    # Basics
    if [[ "$name" =~ what\ is\ a\ process|what\ is\ a\ thread|types\ of\ threads|ways\ to\ create\ a\ thread|where\ parallelism|concurrency\ and\ parallelism|concurrency\ and\ concurrent\ package|what\ is\ runnable|thread\ class|creation\ of\ threads|thread\ state|thread\ life-cycle|thread\ priority ]]; then
        echo "00 - Basics"

    # Diagnostics and Performance
    elif [[ "$name" =~ performance|jstack|thread\ dump|deadlock\ analysis|jfr|diagnostic|algos ]]; then
        echo "09 - Diagnostics & Performance"

    # Synchronization
    elif [[ "$name" =~ race\ condition|synchronization|synchronisation|volatile|wait\ and\ nodify|wait\ and\ notify|blocking\ lock|non-blocking\ lock|lock\ interface|java\ locks|locks\ and\ conditions|reentrantlock|readwritelock|stampedlock|intrinsic\ locks|monitor\ internals ]]; then
        echo "01 - Synchronization"

    # Java Memory Model and Thread Safety
    elif [[ "$name" =~ java\ memory\ model|happens-before|atomicity|visibility|ordering|safe\ publication|immutability|thread\ safety|thread\ confinement|ownership|compare-and-set|cas\ operations|false\ sharing|cache\ lines|lock-free|wait-free|deadlock|livelock|starvation|interruption|cancellation ]]; then
        echo "02 - Java Memory Model & Thread Safety"

    # Executors and Thread Pools
    elif [[ "$name" =~ thread\ management|thread\ pool|executors|executorservice|threadfactory|scheduledexecutor|fork.?join|work-stealing ]]; then
        echo "03 - Executors & Thread Pools"

    # Asynchronous Programming
    elif [[ "$name" =~ supplier|function\ and\ consumer|callable|future|completablefuture|asynchronous|async ]]; then
        echo "04 - Asynchronous Programming"

    # Concurrent Utilities
    elif [[ "$name" =~ producer-consumer|blockingqueue|countdown\ latch|cyclicbarrier|cycle\ barrier|exchanger|concurrent\ collections|concurrent\ package|java\ concurrent|concurrent\ data\ structures|collections ]]; then
        echo "05 - Concurrent Utilities"

    # Virtual Threads
    elif [[ "$name" =~ virtual\ thread|project\ loom|thread\ pinning|platform\ threads ]]; then
        echo "06 - Virtual Threads"

    # Reactive Programming
    elif [[ "$name" =~ reactor|mono|flux|backpressure|reactive\ streams ]]; then
        echo "07 - Reactive Programming"

    # Server and Database Concurrency
    elif [[ "$name" =~ webserver|web\ server|tomcat|database\ connection|spring\ web|webflux|scalable\ spring\ boot ]]; then
        echo "08 - Server & Database Concurrency"

    else
        echo ""
    fi
}

# ------------------------------------------------------------
# 3. Collect Markdown files
# ------------------------------------------------------------

mapfile -d '' FILES < <(
    find "$ROOT" \
        -maxdepth 2 \
        -type f \
        -name "*.md" \
        ! -path "$ROOT/.threads-organizer.*/*" \
        -print0
)

if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "No Markdown files found."
    exit 0
fi

# ------------------------------------------------------------
# 4. Build classification plan
# ------------------------------------------------------------

declare -A COUNTS=()

for category in "${CATEGORIES[@]}"; do
    COUNTS["$category"]=0
done

declare -a UNCLASSIFIED=()
declare -a MATCHED_FILES=()
declare -a MATCHED_CATEGORIES=()

echo
echo "=========================================="
echo "       JAVA THREADS PACK ORGANIZER"
echo "=========================================="
echo

for file in "${FILES[@]}"; do

    filename="$(basename "$file")"
    category="$(categorize "$filename")"

    if [[ -z "$category" ]]; then
        UNCLASSIFIED+=("$filename")
        continue
    fi

    MATCHED_FILES+=("$file")
    MATCHED_CATEGORIES+=("$category")

    ((COUNTS["$category"] += 1))

    printf '[%-42s] %s\n' "$category" "$filename"

done

echo
echo "------------------------------------------"
echo "Total Markdown files: ${#FILES[@]}"
echo "Classified:           ${#MATCHED_FILES[@]}"
echo "Unclassified:         ${#UNCLASSIFIED[@]}"
echo "------------------------------------------"

if [[ ${#UNCLASSIFIED[@]} -gt 0 ]]; then
    echo
    echo "Unclassified files (will remain untouched):"

    for filename in "${UNCLASSIFIED[@]}"; do
        echo "  - $filename"
    done
fi

# ------------------------------------------------------------
# 5. Dry-run
# ------------------------------------------------------------

if [[ "$APPLY" != true ]]; then

    echo
    echo "DRY RUN: No files have been changed."
    echo
    echo "To apply the organization:"
    echo "./organize-threads.sh --apply"
    exit 0

fi

# ------------------------------------------------------------
# 6. Create staging directory
# ------------------------------------------------------------

STAGING="$(mktemp -d "$ROOT/.threads-organizer.XXXXXX")"

cleanup() {
    if [[ -d "$STAGING" ]]; then
        rm -rf -- "$STAGING"
    fi
}

trap cleanup EXIT

# ------------------------------------------------------------
# 7. Stage classified files
# ------------------------------------------------------------

echo
echo "Staging files..."

for category in "${CATEGORIES[@]}"; do
    mkdir -p "$STAGING/$category"
done

for i in "${!MATCHED_FILES[@]}"; do

    file="${MATCHED_FILES[$i]}"
    category="${MATCHED_CATEGORIES[$i]}"

    destination="$STAGING/$category/$(basename "$file")"

    mv -- "$file" "$destination"

done

# ------------------------------------------------------------
# 8. Prepare and validate destination filenames
# ------------------------------------------------------------

declare -a PLAN_SOURCES=()
declare -a PLAN_DESTINATIONS=()

for category in "${CATEGORIES[@]}"; do

    mapfile -d '' SORTED_FILES < <(
        find "$STAGING/$category" \
            -maxdepth 1 \
            -type f \
            -name "*.md" \
            -print0 | LC_ALL=C sort -z -V
    )

    counter=0

    for file in "${SORTED_FILES[@]}"; do

        filename="$(basename "$file")"

        # Remove the old numeric prefix.
        if [[ "$filename" =~ ^[0-9]+[[:space:]]*-[[:space:]]*(.*)$ ]]; then
            title="${BASH_REMATCH[1]}"
        else
            title="$filename"
        fi

        new_name="$(printf "%02d - %s" "$counter" "$title")"

        destination="$ROOT/$category/$new_name"

        # Never overwrite an existing file.
        if [[ -e "$destination" ]]; then
            echo
            echo "ERROR: Destination already exists:"
            echo "$destination"
            echo
            echo "No staged files have been moved into destination folders."
            echo "Your staged files will be preserved at:"
            echo "$STAGING"
            trap - EXIT
            exit 1
        fi

        PLAN_SOURCES+=("$file")
        PLAN_DESTINATIONS+=("$destination")

        ((counter += 1))

    done

done

# ------------------------------------------------------------
# 9. Create destination folders
# ------------------------------------------------------------

for category in "${CATEGORIES[@]}"; do

    if [[ "${COUNTS[$category]}" -gt 0 ]]; then
        mkdir -p "$ROOT/$category"
    fi

done

# ------------------------------------------------------------
# 10. Move and rename files
# ------------------------------------------------------------

echo
echo "Organizing files..."

for i in "${!PLAN_SOURCES[@]}"; do

    source="${PLAN_SOURCES[$i]}"
    destination="${PLAN_DESTINATIONS[$i]}"

    mv -- "$source" "$destination"

    printf '[MOVED] %s\n' "${destination#"$ROOT"/}"

done

# ------------------------------------------------------------
# 11. Remove empty old folders
# ------------------------------------------------------------

if [[ -d "$ROOT/0 - Basics" ]]; then
    rmdir "$ROOT/0 - Basics" 2>/dev/null || true
fi

# ------------------------------------------------------------
# 12. Final result
# ------------------------------------------------------------

echo
echo "=========================================="
echo "       ORGANIZATION COMPLETED"
echo "=========================================="
echo

tree "$ROOT"
