
#!/usr/bin/env bash

set -Eeuo pipefail

BASE_DIR="$(pwd)"

# Make sure this is the intended DSA package.
if [[ ! -f "$BASE_DIR/10 - DSA.md" ]]; then
    echo "Error: Run this script inside your DSA directory."
    exit 1
fi

created=0
skipped=0

create_note() {
    local filename="$1"
    local destination="$BASE_DIR/$filename"

    if [[ -e "$destination" ]]; then
        echo "[SKIP] $filename"
        ((skipped+=1))
        return
    fi

    mkdir -p "$(dirname "$destination")"

    {
        echo "[[DSA]]"
        echo
    } > "$destination"

    echo "[CREATED] $filename"
    ((created+=1))
}

# --------------------------------------------------
# 1. Foundations and mathematical analysis
# --------------------------------------------------

notes=(
"26 - Recursion.md"
"27 - Base Case and Recursive Case.md"
"28 - Call Stack.md"
"29 - Tail Recursion.md"
"30 - Recurrence Relations.md"
"31 - Master Theorem.md"
"32 - Amortized Analysis.md"
"33 - Best Average and Worst Case.md"
"34 - Space Complexity.md"
"35 - Auxiliary Space.md"
"36 - Time-Space Tradeoff.md"
"37 - Logarithms in DSA.md"
)

# --------------------------------------------------
# 2. Arrays and array techniques
# --------------------------------------------------

notes+=(
"38 - Dynamic Array.md"
"39 - Multidimensional Arrays.md"
"40 - Jagged Arrays.md"
"41 - Array Traversal.md"
"42 - Array Insertion and Deletion.md"
"43 - Two Pointers.md"
"44 - Sliding Window.md"
"45 - Prefix Sum.md"
"46 - Difference Array.md"
"47 - Kadane Algorithm.md"
"48 - Subarray and Subsequence.md"
"49 - In Place Algorithms.md"
"50 - Array Rotation.md"
"51 - Matrix Traversal.md"
"52 - Sparse Matrix.md"
)

# --------------------------------------------------
# 3. Linked Lists
# --------------------------------------------------

notes+=(
"53 - Singly Linked List.md"
"54 - Doubly Linked List.md"
"55 - Circular Linked List.md"
"56 - Linked List Operations.md"
"57 - Fast and Slow Pointers.md"
"58 - Linked List Reversal.md"
"59 - Cycle Detection in Linked List.md"
"60 - Middle of Linked List.md"
"61 - Merge Two Sorted Linked Lists.md"
)

# --------------------------------------------------
# 4. Stacks, Queues and Deques
# --------------------------------------------------

notes+=(
"62 - Deque.md"
"63 - Circular Queue.md"
"64 - Priority Queue.md"
"65 - Monotonic Stack.md"
"66 - Monotonic Queue.md"
"67 - Stack Applications.md"
"68 - Queue Applications.md"
"69 - Expression Evaluation.md"
"70 - Infix Prefix and Postfix.md"
"71 - Balanced Parentheses.md"
)

# --------------------------------------------------
# 5. Hashing
# --------------------------------------------------

notes+=(
"72 - Hashing.md"
"73 - Hash Function.md"
"74 - Hash Collisions.md"
"75 - Collision Resolution.md"
"76 - Separate Chaining.md"
"77 - Open Addressing.md"
"78 - Linear Probing.md"
"79 - Quadratic Probing.md"
"80 - Double Hashing.md"
"81 - HashMap.md"
"82 - HashSet.md"
"83 - Hash Table Complexity.md"
)

# --------------------------------------------------
# 6. Trees
# --------------------------------------------------

notes+=(
"84 - Tree Terminology.md"
"85 - Tree Traversal.md"
"86 - Preorder Traversal.md"
"87 - Inorder Traversal.md"
"88 - Postorder Traversal.md"
"89 - Level Order Traversal.md"
"90 - Binary Search Tree.md"
"91 - BST Insertion and Deletion.md"
"92 - BST Search.md"
"93 - Balanced Binary Tree.md"
"94 - AVL Tree.md"
"95 - Red Black Tree.md"
"96 - Heap.md"
"97 - Min Heap and Max Heap.md"
"98 - Heap Operations.md"
"99 - Heapify.md"
"100 - Trie.md"
"101 - Segment Tree.md"
"102 - Fenwick Tree.md"
"103 - B Tree.md"
"104 - B Plus Tree.md"
"105 - Lowest Common Ancestor.md"
"106 - Tree Diameter.md"
)

# --------------------------------------------------
# 7. Graphs
# --------------------------------------------------

notes+=(
"107 - Graph.md"
"108 - Directed and Undirected Graph.md"
"109 - Weighted and Unweighted Graph.md"
"110 - Graph Representation.md"
"111 - Adjacency Matrix.md"
"112 - Adjacency List.md"
"113 - Edge List.md"
"114 - Breadth First Search.md"
"115 - Depth First Search.md"
"116 - Connected Components.md"
"117 - Cycle Detection in Graph.md"
"118 - Topological Sorting.md"
"119 - Kahn Algorithm.md"
"120 - Shortest Path.md"
"121 - Dijkstra Algorithm.md"
"122 - Bellman Ford Algorithm.md"
"123 - Floyd Warshall Algorithm.md"
"124 - Minimum Spanning Tree.md"
"125 - Kruskal Algorithm.md"
"126 - Prim Algorithm.md"
"127 - Disjoint Set Union.md"
"128 - Union Find.md"
"129 - Strongly Connected Components.md"
"130 - Tarjan Algorithm.md"
"131 - Kosaraju Algorithm.md"
)

# --------------------------------------------------
# 8. Sorting algorithms
# --------------------------------------------------

notes+=(
"132 - Heap Sort.md"
"133 - Counting Sort.md"
"134 - Radix Sort.md"
"135 - Bucket Sort.md"
"136 - Shell Sort.md"
"137 - Tim Sort.md"
"138 - Stable and Unstable Sorting.md"
"139 - In Place and Out of Place Sorting.md"
"140 - Comparison Based Sorting.md"
"141 - Sorting Algorithm Comparison.md"
)

# --------------------------------------------------
# 9. Searching algorithms
# --------------------------------------------------

notes+=(
"142 - Jump Search.md"
"143 - Interpolation Search.md"
"144 - Exponential Search.md"
"145 - Ternary Search.md"
"146 - Binary Search on Answer.md"
"147 - Lower Bound and Upper Bound.md"
"148 - Search in Rotated Sorted Array.md"
"149 - Search in Two Dimensional Matrix.md"
)

# --------------------------------------------------
# 10. Algorithm design paradigms
# --------------------------------------------------

notes+=(
"150 - Divide and Conquer.md"
"151 - Greedy Algorithms.md"
"152 - Backtracking.md"
"153 - Dynamic Programming.md"
"154 - Memoization.md"
"155 - Tabulation.md"
"156 - State Transition.md"
"157 - Optimal Substructure.md"
"158 - Overlapping Subproblems.md"
"159 - Knapsack Problem.md"
"160 - Longest Common Subsequence.md"
"161 - Longest Increasing Subsequence.md"
"162 - Coin Change Problem.md"
"163 - Matrix Chain Multiplication.md"
"164 - Interval Scheduling.md"
"165 - Branch and Bound.md"
)

# --------------------------------------------------
# 11. Advanced problem-solving patterns
# --------------------------------------------------

notes+=(
"166 - Prefix and Suffix Techniques.md"
"167 - Binary Search Patterns.md"
"168 - Merge Intervals.md"
"169 - Sweep Line Algorithm.md"
"170 - Bit Manipulation.md"
"171 - Bitwise AND OR XOR.md"
"172 - Bitmasking.md"
"173 - Counting Techniques.md"
"174 - Coordinate Compression.md"
"175 - Randomized Algorithms.md"
"176 - Reservoir Sampling.md"
"177 - KMP Algorithm.md"
"178 - Rabin Karp Algorithm.md"
"179 - Z Algorithm.md"
"180 - Aho Corasick Algorithm.md"
"181 - Manacher Algorithm.md"
"182 - String Matching.md"
"183 - String Algorithms.md"
)

# --------------------------------------------------
# 12. Mathematical algorithms
# --------------------------------------------------

notes+=(
"184 - Number Theory.md"
"185 - Euclidean Algorithm.md"
"186 - Greatest Common Divisor.md"
"187 - Least Common Multiple.md"
"188 - Prime Numbers.md"
"189 - Sieve of Eratosthenes.md"
"190 - Modular Arithmetic.md"
"191 - Modular Exponentiation.md"
"192 - Combinatorics.md"
"193 - Permutations and Combinations.md"
"194 - Probability in Algorithms.md"
)

# --------------------------------------------------
# 13. Java Collections and DSA implementation
# --------------------------------------------------

notes+=(
"195 - Java Collections Framework.md"
"196 - Collection Interface.md"
"197 - List Interface.md"
"198 - Set Interface.md"
"199 - Queue Interface.md"
"200 - Map Interface.md"
"201 - ArrayList.md"
"202 - LinkedList Implementation in Java.md"
"203 - ArrayDeque.md"
"204 - HashMap Implementation.md"
"205 - HashSet Implementation.md"
"206 - TreeMap.md"
"207 - TreeSet.md"
"208 - PriorityQueue in Java.md"
"209 - Comparable Interface.md"
"210 - Comparator Interface.md"
"211 - equals and hashCode Contract.md"
"212 - Generics in Data Structures.md"
"213 - Iterators and Iterables.md"
"214 - Fail Fast and Fail Safe Iterators.md"
)

# --------------------------------------------------
# 14. DSA applications in backend development
# --------------------------------------------------

notes+=(
"215 - Data Structures in Backend Development.md"
"216 - Database Indexing Fundamentals.md"
"217 - PostgreSQL B Tree Index.md"
"218 - PostgreSQL Hash Index.md"
"219 - Database Query Complexity.md"
"220 - LRU Cache.md"
"221 - LFU Cache.md"
"222 - Cache Eviction Policies.md"
"223 - Rate Limiting Algorithms.md"
"224 - Token Bucket Algorithm.md"
"225 - Leaky Bucket Algorithm.md"
"226 - Scheduling Algorithms.md"
"227 - Graph Applications in Backend Systems.md"
"228 - Priority Queues in Task Processing.md"
"229 - Search and Indexing Systems.md"
)

# --------------------------------------------------
# 15. Complexity analysis and interview practice
# --------------------------------------------------

notes+=(
"230 - Data Structure Complexity Comparison.md"
"231 - Algorithm Complexity Comparison.md"
"232 - Choosing the Right Data Structure.md"
"233 - Choosing the Right Algorithm.md"
"234 - DSA Problem Solving Methodology.md"
"235 - Edge Cases in Algorithms.md"
"236 - DSA Testing and Verification.md"
"237 - Common Algorithmic Pitfalls.md"
"238 - DSA Interview Patterns.md"
)

# --------------------------------------------------
# Create all notes
# --------------------------------------------------

echo
echo "Starting DSA curriculum completion..."
echo "Directory: $BASE_DIR"
echo

for note in "${notes[@]}"; do
    create_note "$note"
done

echo
echo "========================================"
echo "DSA curriculum completion finished."
echo "Created: $created"
echo "Skipped: $skipped"
echo "========================================"
