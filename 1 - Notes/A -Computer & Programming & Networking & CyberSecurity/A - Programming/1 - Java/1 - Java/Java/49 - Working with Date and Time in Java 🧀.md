

### Core Classes (`java.time` – use these always)
| Class             | Meaning                            | Has Timezone? |
|-------------------|------------------------------------|---------------|
| `LocalDate`       | 2025-09-04                         | No            |
| `LocalTime`       | 14:30:25                           | No            |
| `LocalDateTime`   | 2025-09-04T14:30:25                | No            |
| `ZonedDateTime`   | 2025-09-04T14:30:25-04:00[America/New_York] | Yes |
| `Instant`         | 2025-09-04T18:30:25Z (UTC)         | UTC only      |

### Most Useful Code Snippets

```java
// Now
LocalDate today = LocalDate.now();
LocalDateTime now = LocalDateTime.now();
ZonedDateTime nyc = ZonedDateTime.now(ZoneId.of("America/New_York"));
Instant timestamp = Instant.now();

// Create specific date
LocalDate date = LocalDate.of(2025, 9, 4);
LocalDateTime dt = LocalDateTime.of(2025, 9, 4, 14, 30);

// Manipulate
LocalDate nextWeek = today.plusWeeks(1);
LocalDate lastMonth = today.minusMonths(1);

// Compare
boolean isFuture = date.isAfter(LocalDate.now());

// Parse & format
DateTimeFormatter eu = DateTimeFormatter.ofPattern("dd/MM/yyyy");
String text = date.format(eu);                   // "04/09/2025"
LocalDate parsed = LocalDate.parse("04/09/2025", eu);

// Timezones
ZonedDateTime tokyo = nyc.withZoneSameInstant(ZoneId.of("Asia/Tokyo"));

// Intervals
Period p = Period.between(LocalDate.of(2025,1,1), LocalDate.of(2025,9,4)); // P8M3D
Duration d = Duration.between(startTime, endTime); // PT2H30M

// Legacy → Modern
LocalDateTime fromLegacy = new Date().toInstant()
    .atZone(ZoneId.systemDefault())
    .toLocalDateTime();
```

### Best Practices (2025)
1. Never use `java.util.Date` or `Calendar` in new code.
2. Use `LocalDateTime` for local times, `ZonedDateTime` when timezone matters, `Instant` for storage/logging.
3. All `java.time` objects are immutable & thread-safe.
4. Use virtual threads (Java 21+) for high-concurrency date processing.

### Quick Formatter Patterns
| Pattern       | Example Output     |
|---------------|--------------------|
| "yyyy-MM-dd"  | 2025-09-04         |
| "dd/MM/yyyy"  | 04/09/2025         |
| "MMM d, yyyy" | Sep 4, 2025        |
| "E, MMMM dd"  | Thu, September 04  |

### Bonus: One-liner for ISO timestamps (common in APIs)
```java
String iso = OffsetDateTime.now(ZoneOffset.UTC).toString(); // 2025-09-04T18:30:45Z
```

[[Java]]