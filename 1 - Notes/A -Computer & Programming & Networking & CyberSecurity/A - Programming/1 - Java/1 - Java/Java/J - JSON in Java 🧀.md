**Date**: 2025-08-24  
**Tags**: [[Java]] 

## What is JSON?

JSON (JavaScript Object Notation) is a lightweight, text-based format for storing and exchanging data. It’s easy to read and write, widely used in web applications, APIs (especially REST), and configuration files. In Java, JSON is processed using libraries like Jackson, Gson, or the standard `javax.json` API, enabling seamless data serialization and deserialization.

## Key Concepts

- **Structure**: JSON uses key-value pairs (objects) and ordered lists (arrays).
    - Object: `{"name": "John", "age": 30}`
    - Array: `["apple", "banana"]`
- **Data Types**: Strings, numbers, booleans, null, objects, and arrays.
- **Use Cases**: REST API payloads, configuration files (e.g., Spring Boot’s `application.json`), and data exchange between client and server.
- **Java Libraries**:
    - **Jackson**: Popular for serializing (Java to JSON) and deserializing (JSON to Java).
    - **Gson**: Google’s lightweight library for JSON processing.
    - **javax.json (Jakarta JSON-P)**: Standard Java API for JSON parsing and generation.
    - **JSON-B (Jakarta JSON Binding)**: Standard API for mapping JSON to Java objects.

## Main Operations

- **Parsing JSON**: Converting JSON strings to Java objects or data structures.
- **Generating JSON**: Converting Java objects to JSON strings.
- **Validation**: Ensuring JSON is well-formed and matches expected structure.
- **Error Handling**: Managing invalid JSON or missing fields.

## Java APIs and Libraries

1. **Jackson**:
    - Fast, feature-rich, used in Spring Boot by default.
    - Key Classes: `ObjectMapper` for serialization/deserialization.
2. **Gson**:
    - Simple, lightweight, good for basic JSON tasks.
    - Key Class: `Gson` for JSON conversion.
3. **Jakarta JSON-P**:
    - Processes JSON as a tree (`JsonObject`) or stream (`JsonParser`).
    - Example: `javax.json.Json` for building JSON.
4. **Jakarta JSON-B**:
    - Maps JSON to Java objects using annotations (e.g., `@JsonbProperty`).
    - Similar to JAXB for XML.

## Common Issues

- **Invalid JSON**: Malformed JSON (e.g., missing commas) causes parsing errors.
    - **Fix**: Validate JSON with tools like JSONLint or try-catch blocks.
- **Performance**: Large JSON files can slow down processing.
    - **Fix**: Use streaming APIs (e.g., Jackson’s `JsonParser`) for large data.
- **Missing Fields**: Accessing non-existent fields can throw exceptions.
    - **Fix**: Use Optional or null checks in Java.
- **Type Mismatches**: JSON numbers parsed as wrong Java types (e.g., `int` vs. `double`).
    - **Fix**: Use flexible types (e.g., `Number`) or explicit mapping.

## Best Practices

1. Use Jackson or Gson for most projects due to their simplicity and performance.
2. Validate JSON input to prevent parsing errors.
3. Use `@JsonProperty` (Jackson) or `@SerializedName` (Gson) to map JSON keys to Java fields.
4. Handle exceptions with try-catch to manage invalid JSON gracefully.
5. Use streaming for large JSON files to reduce memory usage.
6. Secure APIs by validating and sanitizing JSON input to prevent injection attacks.

## Example Code

```java
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;

public class JsonExample {
    record Person(String name, int age) {}

    public static void main(String[] args) throws Exception {
        ObjectMapper mapper = new ObjectMapper();

        // JSON to Java (Deserialization)
        String json = "{\"name\":\"John\",\"age\":30}";
        Person person = mapper.readValue(json, Person.class);
        System.out.println("Parsed: " + person);

        // Java to JSON (Serialization)
        Person newPerson = new Person("Alice", 25);
        String jsonOutput = mapper.writeValueAsString(newPerson);
        System.out.println("Generated: " + jsonOutput);

        // Parsing JSON Array
        String jsonArray = "[{\"name\":\"Bob\",\"age\":40},{\"name\":\"Eve\",\"age\":35}]";
        List<Person> people = mapper.readValue(jsonArray, mapper.getTypeFactory().constructCollectionType(List.class, Person.class));
        System.out.println("Array: " + people);
    }
}
```

**Note**: Add `com.fasterxml.jackson.core:jackson-databind` to your project (e.g., via Maven/Gradle) to run the example. For Spring Boot, it’s included in `spring-boot-starter-web`.

## Summary

JSON is a simple, widely-used format for data exchange in Java web applications, especially REST APIs. Libraries like Jackson and Gson make it easy to parse and generate JSON, while Jakarta JSON-P and JSON-B provide standard APIs. By choosing the right library, validating input, and handling errors, developers can build robust, efficient JSON-based applications. Use Jackson for most projects, streaming for large data, and annotations for clean object mapping.