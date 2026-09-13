
```java
import java.util.stream.IntStream;
import java.util.stream.Stream;

public class IntStreamToStreamConversion {
    public static void main(String[] args) {
        // Create an IntStream
        IntStream intStream = IntStream.range(1, 6); // Represents numbers 1, 2, 3, 4, 5
        // Convert IntStream to Stream<Integer> using boxed()
        Stream<Integer> integerStream = intStream.boxed();
        // Print elements of the resulting Stream<Integer>
        integerStream.forEach(System.out::println);
    }
}
```


To convert an `IntStream` to a `Stream` in Java, the `boxed()` method is used. This method converts a stream of primitive `int` values into a `Stream<Integer>`, where each `int` is wrapped in its corresponding `Integer` wrapper class


###### *Tags : [[My mistakes in action]]