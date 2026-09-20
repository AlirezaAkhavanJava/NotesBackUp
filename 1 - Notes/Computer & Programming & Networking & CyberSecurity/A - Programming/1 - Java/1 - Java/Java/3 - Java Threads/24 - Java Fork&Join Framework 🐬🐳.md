
The **Fork/Join Framework** in Java, part of the `java.util.concurrent` package, is a tool for parallel programming. It simplifies dividing large tasks into smaller subtasks, processing them concurrently across multiple threads, and combining their results. Introduced in Java 7, it’s designed for tasks that can be split recursively, leveraging multi-core processors for better performance.

---
## Key Concepts

- **Fork**: Splits a task into smaller subtasks that run in parallel.
- **Join**: Waits for subtasks to complete and combines their results.
- **Work-Stealing**: Idle threads "steal" tasks from busy threads to balance workload.

## Main Components

### 1. **ForkJoinPool**

- **Purpose**: A thread pool that manages worker threads for executing fork/join tasks.
- **Key Methods**:
    - `submit(ForkJoinTask<?> task)`: Submits a task for execution.
    - `invoke(ForkJoinTask<?> task)`: Runs a task and waits for its result.
    - `getParallelism()`: Returns the number of worker threads.
- **Use Case**: Creating a pool to run parallel tasks.

### 2. **ForkJoinTask**

- **Purpose**: Abstract class representing a task that can be forked and joined.
- **Key Subclasses**:
    - `RecursiveTask<V>`: For tasks that return a result.
    - `RecursiveAction`: For tasks that don’t return a result.
- **Key Methods**:
    - `fork()`: Starts a task asynchronously.
    - `join()`: Waits for a task to complete and returns its result.
    - `compute()`: Defines the task’s logic (overridden in subclasses).

## How It Works

1. Split a large task into smaller subtasks using `fork()`.
2. Process subtasks in parallel using a `ForkJoinPool`.
3. Combine results with `join()`.

## Example

```java
import java.util.concurrent.RecursiveTask;
import java.util.concurrent.ForkJoinPool;

public class SumTask extends RecursiveTask<Long> {
    private final int[] numbers;
    private final int start, end;
    private static final int THRESHOLD = 10;

    public SumTask(int[] numbers, int start, int end) {
        this.numbers = numbers;
        this.start = start;
        this.end = end;
    }

    @Override
    protected Long compute() {
        if (end - start <= THRESHOLD) {
            long sum = 0;
            for (int i = start; i < end; i++) {
                sum += numbers[i];
            }
            return sum;
        } else {
            int mid = (start + end) / 2;
            SumTask leftTask = new SumTask(numbers, start, mid);
            SumTask rightTask = new SumTask(numbers, mid, end);
            leftTask.fork();
            return rightTask.compute() + leftTask.join();
        }
    }

    public static void main(String[] args) {
        int[] numbers = new int[100]; // Array of 100 numbers
        for (int i = 0; i < numbers.length; i++) {
            numbers[i] = i + 1;
        }
        ForkJoinPool pool = new ForkJoinPool();
        long result = pool.invoke(new SumTask(numbers, 0, numbers.length));
        System.out.println("Sum: " + result); // Output: Sum: 5050
    }
}
```

## Benefits

- Simplifies parallel programming for recursive tasks.
- Efficiently uses multi-core processors.
- Work-stealing reduces thread idle time.

## Limitations

- Best for CPU-intensive, recursive tasks (e.g., divide-and-conquer algorithms).
- Not ideal for I/O-bound tasks or simple operations.

## Resources

- Oracle Documentation: [java.util.concurrent](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/concurrent/package-summary.html)


##### Tags : [[44 - Threads 🧀]] 