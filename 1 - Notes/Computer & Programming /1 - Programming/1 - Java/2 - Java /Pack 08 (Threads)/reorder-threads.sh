
#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Java Pack 08 - Threads
# Reorder 68 Markdown notes according to the requested order.
# ============================================================

declare -a source_files=()
declare -a target_files=()

# Format:
# ORIGINAL_FILENAME_PATTERN|NEW_FILENAME

while IFS='|' read -r pattern target; do
    [[ -z "$pattern" ]] && continue

    # Resolve the original filename.
    # Wildcards handle possible whitespace/character differences.
    mapfile -d '' matches < <(
        find . -maxdepth 1 -type f -name "$pattern" -print0
    )

    if (( ${#matches[@]} != 1 )); then
        echo "ERROR: Expected exactly one match for:"
        echo "  $pattern"
        echo "Found: ${#matches[@]}"
        exit 1
    fi

    source_files+=("${matches[0]#./}")
    target_files+=("$target")

done <<'MAP'
52 - What is a Process?.md|00 - What is a Process?.md
56 - Process and Thread.md|01 - Process and Thread.md
47 - Process & Multi-Tasking.md|02 - Process & Multi-Tasking.md
53 - Thread.md|03 - Thread.md
54 - Threads (computer science).md|04 - Threads (computer science).md
51 - Threading.md|05 - Threading.md
61 - CPU Scheduler, Time Sharing, Cores, and Threads.md|06 - CPU Scheduler, Time Sharing, Cores, and Threads.md
07 - Context Switching.md|07 - Context Switching.md
57 - Concurrency.md|08 - Concurrency.md
58 - Parallelism.md|09 - Parallelism.md
00 - Concurrency and Parallelism ✧.md|10 - Concurrency and Parallelism ✧.md
46 - Multithreading & Resources.md|11 - Multithreading & Resources.md
01 - Types of Threads ✧.md|12 - Types of Threads ✧.md
02 - Platform threads ✧.md|13 - Platform threads ✧.md
03 - The Thread Class*.md|14 - The Thread Class ✧.md
62 - Thread Class — Methods Reference (with Examples).md|15 - Thread Class — Methods Reference (with Examples).md
04 - Creation of Threads ✧.md|16 - Creation of Threads ✧.md
59 - Runnable.md|17 - Runnable.md
60 - Working with Threads.md|18 - Working with Threads.md
05 - Thread Life-cycle ✧.md|19 - Thread Life-cycle ✧.md
55 - Java Thread Lifecycle.md|20 - Java Thread Lifecycle.md
65 - Thread State in Java.md|21 - Thread State in Java.md
63 - Thread Priority and Sleep in Java.md|22 - Thread Priority and Sleep in Java.md
06 -*Thread Management.md|23 - Thread Management.md
09 - Definitions of Key Concepts.md|24 - Definitions of Key Concepts.md
64 - Race Conditions.md|25 - Race Conditions.md
08 - Concurrency Issues.md|26 - Concurrency Issues.md
38 - Java Memory Model (JMM).md|27 - Java Memory Model (JMM).md
09 - Java Synchronization Mechanisms.md|28 - Java Synchronization Mechanisms.md
08 - Synchronization && Locks.md|29 - Synchronization && Locks.md
13 - Java Volatile Keyword.md|30 - Java Volatile Keyword.md
14 - Java Atomic Package.md|31 - Java Atomic Package.md
17 - wait and nodify.md|32 - wait and nodify.md
66 - Wait and Nodify.md|33 - Wait and Nodify.md
10 - Blocking Lock && Non-blocking Lock IO.md|34 - Blocking Lock && Non-blocking Lock IO.md
11 - Lock Interface.md|35 - Lock Interface.md
22 - Locks.md|36 - Locks.md
18 - Java Locks and Conditions.md|37 - Java Locks and Conditions.md
12 - Semaphore.md|38 - Semaphore.md
39 - Advanced Synchronization in Java.md|39 - Advanced Synchronization in Java.md
40 - ThreadLocal and InheritableThreadLocal in Java.md|40 - ThreadLocal and InheritableThreadLocal in Java.md
15 - Java Thread-Safe Data Structures.md|41 - Java Thread-Safe Data Structures.md
19 - Thread Pools.md|42 - Thread Pools.md
20 - Thread Pools Guide.md|43 - Thread Pools Guide.md
23 - Java Executors.md|44 - Java Executors.md
21 - ThreadPoolExecutor.md|45 - ThreadPoolExecutor.md
24 - Java ThreadFactory Guide.md|46 - Java ThreadFactory Guide.md
25 - Asynchronous.md|47 - Asynchronous.md
26 - Future Task.md|48 - Future Task.md
27 - CompletableFuture.md|49 - CompletableFuture.md
28 - Java Fork&Join Framework.md|50 - Java Fork&Join Framework.md
16 - Producer-Consumer.md|51 - Producer-Consumer.md
32 - BlockingQueue.md|52 - BlockingQueue.md
29 - Countdown Latch.md|53 - Countdown Latch.md
30 - CyclicBarrier.md|54 - CyclicBarrier.md
31 - Cycle Barrier vs CountdownLatch.md|55 - Cycle Barrier vs CountdownLatch.md
33 - Exchanger.md|56 - Exchanger.md
34 - Java Exchanger Tutorial.md|57 - Java Exchanger Tutorial.md
35 - Java Concurrent Collections.md|58 - Java Concurrent Collections.md
36 - Collections.md|59 - Collections.md
37 - Java Concurrent Package.md|60 - Java Concurrent Package.md
41 - Virtual Threads theory.md|61 - Virtual Threads theory.md
42 - Virtual Threads in Java (Project Loom, Java 21+).md|62 - Virtual Threads in Java (Project Loom, Java 21+).md
48 - Multi-Threaded webservers.md|63 - Multi-Threaded webservers.md
45 - Performance Tuning.md|64 - Performance Tuning.md
44 - Jstack.md|65 - Jstack.md
49 - Project Reactor Tutorial ,  From Simple to Advanced.md|66 - Project Reactor Tutorial ,  From Simple to Advanced.md
50 - Algos.md|67 - Algos.md
MAP

EXPECTED=68

# ============================================================
# VALIDATION
# ============================================================

if (( ${#source_files[@]} != EXPECTED )); then
    echo "ERROR: Expected $EXPECTED files."
    exit 1
fi

declare -A seen_sources=()
declare -A seen_targets=()

for i in "${!source_files[@]}"; do
    src="${source_files[$i]}"
    dst="${target_files[$i]}"

    if [[ -n "${seen_sources[$src]+exists}" ]]; then
        echo "ERROR: Duplicate source: $src"
        exit 1
    fi

    if [[ -n "${seen_targets[$dst]+exists}" ]]; then
        echo "ERROR: Duplicate destination: $dst"
        exit 1
    fi

    seen_sources["$src"]=1
    seen_targets["$dst"]=1
done

# Ensure existing destination files belong to this rename operation.
for dst in "${target_files[@]}"; do
    if [[ -e "$dst" && -z "${seen_sources[$dst]+exists}" ]]; then
        echo "ERROR: Destination already exists: $dst"
        exit 1
    fi
done

# ============================================================
# PREVIEW
# ============================================================

echo
echo "========== RENAME PREVIEW =========="
echo

for i in "${!source_files[@]}"; do
    printf '%02d. %s\n    -> %s\n\n' \
        "$((i))" "${source_files[$i]}" "${target_files[$i]}"
done

echo "Total files: ${#source_files[@]}"
echo

# Preview is the default. --apply performs the rename.
if [[ "${1:-}" != "--apply" ]]; then
    echo "PREVIEW ONLY. Nothing has been renamed."
    echo "Run with --apply to execute."
    exit 0
fi

# ============================================================
# TWO-PHASE RENAME WITH ROLLBACK
# ============================================================

stage=$(mktemp -d ./.threads-reorder-stage.XXXXXX)

stage_count=0
final_count=0

rollback() {
    local status=$?

    trap - ERR INT TERM
    set +e

    echo
    echo "ERROR: Rename failed. Rolling back..."

    # Move completed destinations back into staging.
    for ((i = 0; i < final_count; i++)); do
        mv -- "${target_files[$i]}" "$stage/$i"
    done

    # Restore original filenames.
    for ((i = 0; i < stage_count; i++)); do
        if [[ -e "$stage/$i" ]]; then
            mv -- "$stage/$i" "${source_files[$i]}"
        fi
    done

    rmdir -- "$stage" 2>/dev/null

    echo "Rollback attempted. Check the directory before retrying."
    exit "$status"
}

trap rollback ERR
trap 'exit 130' INT TERM

echo "Phase 1: Moving original files to temporary storage..."

for i in "${!source_files[@]}"; do
    mv -- "${source_files[$i]}" "$stage/$i"
    stage_count=$((stage_count + 1))
done

echo "Phase 2: Assigning new filenames..."

for i in "${!target_files[@]}"; do
    mv -- "$stage/$i" "${target_files[$i]}"
    final_count=$((final_count + 1))
done

trap - ERR INT TERM

rmdir -- "$stage"

echo
echo "SUCCESS: All 68 notes have been reordered."
echo "New numbering: 00 through 67."
