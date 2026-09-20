**JavaFaker** (often just called **Faker**) is a popular open-source Java library for generating **fake (but realistic-looking) test data**. It's heavily inspired by the Ruby library **Faker** and the Python library **Faker**.

### Main Use Cases
- Generating test data for unit/integration tests
- Populating databases for development/demo environments
- Creating mock data for APIs, front-end prototypes, performance/load testing
- Anonymizing production data for safe testing

### How to Add JavaFaker to Your Project

**Maven** (recommended)
```xml
<dependency>
    <groupId>net.datafaker</groupId>
    <artifactId>datafaker</artifactId>
    <version>2.3.1</version>  <!-- check latest version -->
</dependency>
```

**Gradle**
```groovy
implementation 'net.datafaker:datafaker:2.3.1'
```

### Basic Usage Examples

```java
import net.datafaker.Faker;

public class FakerExample {
    public static void main(String[] args) {
        Faker faker = new Faker();

        // Basic fake data
        System.out.println("Name: " + faker.name().fullName());
        System.out.println("First name: " + faker.name().firstName());
        System.out.println("Last name: " + faker.name().lastName());
        System.out.println("Email: " + faker.internet().emailAddress());
        System.out.println("Phone: " + faker.phoneNumber().cellPhone());
        System.out.println("Address: " + faker.address().fullAddress());
        System.out.println("City: " + faker.address().city());
        System.out.println("Country: " + faker.address().country());
        System.out.println("Zip: " + faker.address().zipCode());

        // More specialized data
        System.out.println("Company: " + faker.company().name());
        System.out.println("IBAN: " + faker.finance().iban());
        System.out.println("Credit card: " + faker.finance().creditCard());
        System.out.println("UUID: " + faker.internet().uuid());
        System.out.println("ISBN: " + faker.code().isbn13());
        System.out.println("Beer name: " + faker.beer().name());
        System.out.println("Pokemon: " + faker.pokemon().name());
        System.out.println("Hacker phrase: " + faker.hacker().phrase());

        // Localized data (e.g., Dutch)
        Faker dutchFaker = new Faker(new Locale("nl"));
        System.out.println("Dutch name: " + dutchFaker.name().fullName());
        System.out.println("Dutch phone: " + dutchFaker.phoneNumber().cellPhone());

        // Random number / date
        System.out.println("Random int: " + faker.number().numberBetween(1, 1000));
        System.out.println("Random past date: " + faker.date().birthday(18, 65));
    }
}
```

### Useful Patterns

1. **Custom seed** (for reproducible fake data)
```java
Faker faker = new Faker(new Random(42)); // same seed → same fake data
```

2. **Generate many objects**
```java
List<Person> people = new ArrayList<>();
for (int i = 0; i < 100; i++) {
    people.add(new Person(
        faker.name().firstName(),
        faker.name().lastName(),
        faker.internet().emailAddress(),
        faker.date().birthday(18, 65)
    ));
}
```

3. **Using providers directly**
```java
String fakeStreet = faker.address().streetAddress();
String fakeAvatar = faker.avatar().image();
String fakeChuckNorris = faker.chuckNorris().fact();
```

### Popular Providers (categories)
| Category          | Examples of methods                                      |
|-------------------|----------------------------------------------------------|
| `name()`          | fullName(), firstName(), lastName(), username()          |
| `internet()`      | emailAddress(), domainName(), url(), uuid(), avatar()    |
| `address()`       | streetAddress(), city(), country(), zipCode()            |
| `phoneNumber()`   | cellPhone(), phoneNumber()                               |
| `finance()`       | iban(), bic(), creditCard()                              |
| `date()`          | birthday(), past(), future(), birthday()                 |
| `lorem()`         | sentence(), paragraph(), words()                         |
| `number()`        | numberBetween(), digits(), randomDigit()                 |
| `commerce()`      | productName(), department(), price()                     |
| `superhero()`     | name(), power()                                          |
| `gameOfThrones()` | character(), house(), quote()                            |

### Common Locales
```java
new Faker(Locale.ENGLISH);      // default
new Faker(Locale.GERMAN);
new Faker(new Locale("pt", "BR")); // Brazilian Portuguese
new Faker(new Locale("zh", "CN")); // Chinese
```

### Recommendation
**Use `net.datafaker:datafaker`** (the modern maintained fork) instead of the older `com.github.javafaker:javafaker` which is no longer actively developed.

That's the quick-start guide to **JavaFaker**!
###### Tags : [[0 - Spring Framework]]