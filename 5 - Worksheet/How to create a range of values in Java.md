

##### Utilizing `java.time.temporal.ValueRange` (JDK 8+):

For representing a range of `long` values, `java.time.temporal.ValueRange` can be used. This class is part of the Java Date and Time API and provides methods for checking if a value is within the range.

```java
import java.time.temporal.ValueRange;

ValueRange range = ValueRange.of(1, 100); // Represents a range from 1 to 100 (inclusive)
boolean isInRange = range.isValidIntValue(50); // true
```

[[My mistakes in action]]