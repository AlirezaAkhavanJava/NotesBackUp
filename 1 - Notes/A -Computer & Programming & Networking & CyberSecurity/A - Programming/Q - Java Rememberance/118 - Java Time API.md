

The **Java Time API** is the modern API for working with **dates, times, time zones, durations, and periods** in Java.

It was introduced in **Java 8** under:

```java
java.time
```

It replaced most uses of the older:

```java
java.util.Date
java.util.Calendar
```

The design is based heavily on **immutability**, **type safety**, and a clear separation between different concepts of time.

---

# 1. The fundamental idea

One of the biggest problems with older date/time APIs is that they mix different concepts.

For example:

```text
Date
Time
Date + Time
Time Zone
Duration
Period
Instant
```

The Java Time API gives each concept its own type.

```text
java.time
   │
   ├── LocalDate
   ├── LocalTime
   ├── LocalDateTime
   ├── ZonedDateTime
   ├── OffsetDateTime
   ├── Instant
   ├── Duration
   ├── Period
   ├── ZoneId
   └── ZoneOffset
```

This makes incorrect operations harder to express.

---

# 2. `LocalDate`

Represents a **calendar date without a time or time zone**.

```java
LocalDate date = LocalDate.now();
```

Example:

```text
2026-09-17
```

You can create one explicitly:

```java
LocalDate date =
        LocalDate.of(2026, 9, 17);
```

Access components:

```java
date.getYear();
date.getMonth();
date.getDayOfMonth();
date.getDayOfWeek();
```

Example:

```java
System.out.println(date.getYear());
```

```text
2026
```

### Use `LocalDate` when:

```text
Birthday
Holiday
Invoice date
Birth date
Due date
```

You generally **shouldn't use it for an event that represents a precise moment in the world**.

---

# 3. `LocalTime`

Represents a **time of day without a date or time zone**.

```java
LocalTime time = LocalTime.now();
```

Example:

```text
10:35:42.123
```

Or:

```java
LocalTime time =
        LocalTime.of(10, 30);
```

Access components:

```java
time.getHour();
time.getMinute();
time.getSecond();
time.getNano();
```

Useful for things like:

```text
Store opens at 09:00
Meeting starts at 14:30
Alarm at 07:00
```

---

# 4. `LocalDateTime`

Combines:

```text
LocalDate + LocalTime
```

```java
LocalDateTime dateTime =
        LocalDateTime.now();
```

Example:

```text
2026-09-17T10:35:42
```

Or:

```java
LocalDateTime dateTime =
        LocalDateTime.of(
                2026,
                9,
                17,
                10,
                30
        );
```

### Important

`LocalDateTime` **does not contain a time zone**.

This is a critical distinction.

```text
2026-09-17 10:30
```

doesn't tell us whether that means:

```text
Tehran
Berlin
Tokyo
New York
```

Therefore, don't use `LocalDateTime` when you need to represent a globally identifiable instant unless the surrounding context explicitly supplies the zone.

---

# 5. `Instant`

`Instant` represents a **specific point on the global timeline**.

```java
Instant instant = Instant.now();
```

Example:

```text
2026-09-17T07:05:42Z
```

`Z` means:

```text
UTC
```

Think of:

```text
Instant
   ↓
exact point on global timeline
```

For example:

```text
10:00 Tehran
       │
       ▼
specific Instant
       │
       ├── 06:30 UTC
       ├── 08:30 Berlin
       └── 15:30 Tokyo
```

All represent the **same instant**.

### Good uses

```text
Database timestamps
Event timestamps
Logs
Message queues
Distributed systems
Audit timestamps
```

For backend development, `Instant` is extremely important.

---

# 6. `ZonedDateTime`

Represents:

```text
Date + Time + Time Zone
```

Example:

```java
ZonedDateTime now =
        ZonedDateTime.now(
                ZoneId.of("Europe/Berlin")
        );
```

Conceptually:

```text
2026-09-17 10:30
Europe/Berlin
```

The zone matters because time-zone rules include things such as:

- UTC offsets
    
- daylight-saving transitions
    
- historical changes
    

---

# 7. `ZoneId`

Represents a **time-zone identifier**.

```java
ZoneId zone =
        ZoneId.of("Europe/Berlin");
```

Other examples:

```java
ZoneId.of("Asia/Tehran");
ZoneId.of("America/New_York");
ZoneId.of("Asia/Tokyo");
```

You can inspect available zones:

```java
Set<String> zones =
        ZoneId.getAvailableZoneIds();
```

Prefer IANA identifiers such as:

```text
Europe/Berlin
Asia/Tehran
America/New_York
```

rather than relying on ambiguous abbreviations such as:

```text
CST
IST
```

---

# 8. `ZoneOffset`

A `ZoneOffset` represents a fixed offset from UTC.

For example:

```java
ZoneOffset offset =
        ZoneOffset.of("+03:30");
```

Conceptually:

```text
UTC
 │
 └── +03:30
```

Difference:

```text
ZoneOffset
    ↓
fixed offset

ZoneId
    ↓
time-zone rules
```

A `ZoneId` may change its offset because of daylight-saving or historical rules.

---

# 9. `OffsetDateTime`

Represents:

```text
Date + Time + UTC Offset
```

Example:

```java
OffsetDateTime dateTime =
        OffsetDateTime.now();
```

Conceptually:

```text
2026-09-17T10:30:00+03:30
```

Compare:

```text
LocalDateTime
    ↓
date + time

OffsetDateTime
    ↓
date + time + offset

ZonedDateTime
    ↓
date + time + zone rules
```

---

# 10. `Duration`

Represents an amount of **time measured in seconds/nanoseconds**.

For example:

```java
Duration duration =
        Duration.ofHours(2);
```

Or:

```java
Duration duration =
        Duration.between(
                startTime,
                endTime
        );
```

Example:

```java
LocalTime start = LocalTime.of(10, 0);
LocalTime end = LocalTime.of(12, 30);

Duration duration =
        Duration.between(start, end);
```

Result:

```text
2 hours 30 minutes
```

Good for:

```text
Timeouts
Elapsed time
Execution time
Network latency
Cache expiration
Task duration
```

---

# 11. `Period`

`Period` represents a **calendar-based amount of time**.

For example:

```java
Period period =
        Period.ofMonths(3);
```

Or:

```java
Period period =
        Period.between(
                LocalDate.of(2026, 1, 1),
                LocalDate.of(2026, 9, 17)
        );
```

It represents:

```text
years
months
days
```

### Important distinction

```text
Duration
    ↓
time-based
seconds/nanoseconds

Period
    ↓
date-based
years/months/days
```

---

# 12. Why `Period` and `Duration` are different

Consider:

```java
Period.ofMonths(1)
```

One month does **not always represent the same number of days**.

```text
January → 31 days
February → 28/29 days
April → 30 days
```

Therefore:

```text
1 month ≠ fixed number of seconds
```

That's why Java separates:

```text
Period → calendar arithmetic
Duration → clock/time arithmetic
```

---

# 13. Adding and subtracting time

Java Time objects are generally **immutable**.

This is important.

```java
LocalDate date =
        LocalDate.of(2026, 9, 17);

LocalDate future =
        date.plusDays(10);
```

The original `date` doesn't change.

```text
date
 │
 ├── plusDays(10)
 │
 ▼
new LocalDate
```

Common methods:

```java
plusDays()
plusWeeks()
plusMonths()
plusYears()

minusDays()
minusWeeks()
minusMonths()
minusYears()
```

For times:

```java
plusHours()
plusMinutes()
plusSeconds()
plusNanos()
```

---

# 14. Comparing dates and times

You can use:

```java
isBefore()
isAfter()
isEqual()
```

Example:

```java
LocalDate a =
        LocalDate.of(2026, 9, 17);

LocalDate b =
        LocalDate.of(2026, 9, 20);

a.isBefore(b); // true
a.isAfter(b);  // false
```

You can also use:

```java
equals()
```

but remember that `equals()` represents object equality semantics, while `isBefore()` / `isAfter()` explicitly express temporal ordering.

---

# 15. Formatting

Java provides:

```java
DateTimeFormatter
```

Example:

```java
DateTimeFormatter formatter =
        DateTimeFormatter.ofPattern(
                "yyyy-MM-dd"
        );
```

Then:

```java
String result =
        LocalDate.now().format(formatter);
```

Result:

```text
2026-09-17
```

---

# 16. Parsing

You can convert text into a date/time object.

```java
LocalDate date =
        LocalDate.parse("2026-09-17");
```

For a custom format:

```java
DateTimeFormatter formatter =
        DateTimeFormatter.ofPattern(
                "dd/MM/yyyy"
        );

LocalDate date =
        LocalDate.parse(
                "17/09/2026",
                formatter
        );
```

Conceptually:

```text
String
  ↓
parse()
  ↓
Temporal object
```

And the reverse:

```text
Temporal object
  ↓
format()
  ↓
String
```

---

# 17. `Temporal`

The Java Time API has a broader abstraction model.

Important interfaces include:

```text
Temporal
TemporalAccessor
TemporalAdjuster
TemporalAmount
```

You don't need to use these directly all the time, but understanding them helps explain the API.

Conceptually:

```text
java.time
    │
    ├── LocalDate
    ├── LocalTime
    ├── LocalDateTime
    ├── ZonedDateTime
    ├── OffsetDateTime
    └── Instant
```

They implement/use common temporal abstractions where appropriate.

---

# 18. `TemporalAdjuster`

Sometimes you don't want to simply say:

```java
plusDays(10)
```

You want something like:

> Give me the next Monday.

Java provides `TemporalAdjuster`.

```java
LocalDate nextMonday =
        date.with(
                TemporalAdjusters.next(DayOfWeek.MONDAY)
        );
```

Other useful adjusters:

```java
firstDayOfMonth()
lastDayOfMonth()
firstDayOfNextMonth()
next()
previous()
```

This is useful for calendar logic.

---

# 19. `DayOfWeek`

Java has an enum:

```java
DayOfWeek
```

with:

```text
MONDAY
TUESDAY
WEDNESDAY
THURSDAY
FRIDAY
SATURDAY
SUNDAY
```

Example:

```java
DayOfWeek day =
        LocalDate.now().getDayOfWeek();
```

---

# 20. `Month`

Likewise:

```java
Month
```

is an enum:

```text
JANUARY
FEBRUARY
...
DECEMBER
```

Example:

```java
Month month =
        LocalDate.now().getMonth();
```

---

# 21. Clock

There is also:

```java
java.time.Clock
```

Instead of directly calling:

```java
Instant.now();
```

you can provide a clock:

```java
Clock clock = Clock.systemUTC();

Instant now = Instant.now(clock);
```

This becomes particularly useful for **testing**.

You can create a fixed clock:

```java
Clock clock =
        Clock.fixed(
                Instant.parse("2026-01-01T00:00:00Z"),
                ZoneOffset.UTC
        );
```

Now code using that clock sees a predictable time.

This is extremely useful in unit tests.

---

# 22. The most important types

For practical Java development, memorize this table:

|Type|Represents|Example|
|---|---|---|
|`LocalDate`|Date only|`2026-09-17`|
|`LocalTime`|Time only|`10:30:00`|
|`LocalDateTime`|Date + time, no zone|`2026-09-17T10:30`|
|`Instant`|Exact global moment|`2026-09-17T07:00:00Z`|
|`ZonedDateTime`|Date + time + time-zone rules|`2026-09-17T10:00+03:00[Europe/Berlin]`|
|`OffsetDateTime`|Date + time + fixed offset|`2026-09-17T10:00+03:00`|
|`ZoneId`|Time-zone rules/region|`Europe/Berlin`|
|`ZoneOffset`|Fixed UTC offset|`+03:00`|
|`Duration`|Time-based amount|`2h 30m`|
|`Period`|Calendar-based amount|`2 months 5 days`|
|`DateTimeFormatter`|Formatting/parsing|`17/09/2026`|
|`Clock`|Source of current time|system/fixed clock|

---

# 23. The most important design rule

Don't choose a time type based on what looks convenient.

Choose it based on **what the value means**.

```text
What does this value represent?
             │
      ┌──────┴──────┐
      │             │
 Calendar        Moment
      │             │
      ▼             ▼
LocalDate        Instant
LocalTime
LocalDateTime
      │
      │
      ▼
Need a timezone?
      │
   ┌──┴──┐
  No     Yes
  │       │
  ▼       ▼
Local    ZonedDateTime
         / OffsetDateTime
```

### Typical backend choices

```text
Birthday
    → LocalDate

Business opening time
    → LocalTime

Database event timestamp
    → Instant

Meeting in a particular timezone
    → ZonedDateTime

"Created at" / "Updated at"
    → Instant

How long a request took
    → Duration

"Three months from today"
    → Period
```

---

# 24. Why the Java Time API is better than `Date` / `Calendar`

The modern API was designed around several principles:

### Immutability

```java
LocalDate tomorrow =
        today.plusDays(1);
```

Instead of modifying `today`.

### Type safety

A:

```java
LocalDate
```

cannot accidentally be treated as a:

```java
Duration
```

### Clear semantics

```text
LocalDate       → date
LocalTime       → time
Instant         → moment
Duration        → elapsed time
Period          → calendar amount
ZoneId          → timezone rules
```

### Better timezone support

The API integrates with the IANA time-zone database through `ZoneId`.

---

# 25. Core mental model

Think about Java Time as **three dimensions**:

```text
                    TIME
                     │
        ┌────────────┼────────────┐
        │            │            │
      DATE          CLOCK        TIMELINE
        │            │            │
        ▼            ▼            ▼
   LocalDate     LocalTime     Instant
        │            │
        └──────┬─────┘
               ▼
        LocalDateTime
               │
          timezone?
          /       \
        no         yes
        │           │
        │      ZonedDateTime
        │      OffsetDateTime
        │
        ▼
    Calendar
```

And amounts of time are separate:

```text
Duration → elapsed time
Period   → calendar amount
```

## The rule to remember

> **Use the most semantically precise Java Time type for the thing you're representing.**

For backend development, the three types I would make absolutely automatic are:

```java
LocalDate     // calendar date
Instant       // exact moment
ZonedDateTime // moment expressed in a timezone
```

And understand **`Duration` vs `Period`** very well, because that distinction prevents a lot of subtle date/time bugs.


[[Java]]