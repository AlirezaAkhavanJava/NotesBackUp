


## 1. Mental model: an interpreter at the border

Your Java code speaks **objects**. The front-end and other services speak **JSON text**. Jackson is the **interpreter standing between them**. It reads a Java object and says it out loud in JSON, and it listens to JSON and builds the matching Java object.

```
Java object  ◀──── Jackson ────▶  JSON text
 Person("Alice", 25)               {"name":"Alice","age":25}
```

In one sentence: **Jackson is a library that converts Java objects to JSON and JSON to Java objects.**

## 2. Why you need a library at all

Java has no built-in JSON support. The JDK gives you native serialization (`Serializable`), but that produces Java-only binary bytes, which a browser or a Go service can't read. JSON is the common language of the web, so someone has to do the translation. Jackson is the most widely used tool for that job, and **Spring Boot includes it by default** (it comes with `spring-boot-starter-web`), which is why `@RequestBody` and `@RestController` "just work" without you writing any conversion code.

Its two operations have names you already know:

|Direction|Name|Where you see it in Spring|
|---|---|---|
|Object → JSON|serialization|The response of a `@GetMapping`|
|JSON → Object|deserialization|`@RequestBody` on a `@PostMapping`|

## 3. Scenario: what happens in one POST request

1. The browser sends `{"name":"Alice","age":25}` in the request body.
2. Spring sees `@RequestBody PersonDto dto` and hands the text to Jackson.
3. Jackson looks at `PersonDto` and finds it has the properties `name` and `age`.
4. It matches the JSON key `"name"` to the property `name`, and `"age"` to `age`.
5. It creates a `PersonDto` through the constructor (a record) or the setters.
6. Your controller method receives a normal Java object and never sees any JSON.
7. When you return an object, Jackson runs the same process backwards and writes the JSON response.

## 4. The code

You can use it by hand, without Spring, to see what it does:

```java
ObjectMapper mapper = new ObjectMapper();   // the interpreter

// Object -> JSON
String json = mapper.writeValueAsString(new PersonDto("Alice", 25));
// {"name":"Alice","age":25}

// JSON -> Object
PersonDto p = mapper.readValue(json, PersonDto.class);
```

`ObjectMapper` is the main class. You give it an object or a string, and it gives you the other form. The `PersonDto.class` argument tells Jackson **what to build**, so the sender doesn't choose the class.

```java
public record PersonDto(String name, int age) {}   // no Serializable needed
```

## 5. How it knows what to convert

Jackson doesn't read your mind. It uses rules:

1. **Names match.** The JSON key `"name"` goes to the property called `name`.
2. **Output uses getters or record accessors.** A getter `getName()` or a record's `name()` becomes the key `"name"`.
3. **Input needs a way in.** A record's constructor, or a no-arg constructor plus setters.

If a rule isn't met, you adjust it with annotations, such as `@JsonProperty("full_name")` to rename a key.

## 6. What Jackson is _not_

||Jackson|Java native serialization|
|---|---|---|
|Needs `Serializable`|No|Yes|
|Output|Readable JSON text|Java-only binary|
|Who can read it|Any language|Java only|
|Constructor runs|Yes (or setters)|No|

Jackson is also **not** the database layer. Hibernate handles objects to SQL rows, and Jackson handles objects to JSON. They sit at different borders of your application.

## 7. Related ideas

- Jackson also supports other formats (XML, YAML, CSV) through add-on modules, which is why it is described as a family of libraries rather than only a JSON tool.
- Under the hood it works with the streams we covered: it writes the JSON as UTF-8 bytes to the response's `OutputStream`.
- Spring Boot 3 uses Jackson 2 (`com.fasterxml.jackson...` imports), and Spring Boot 4 uses Jackson 3 (`tools.jackson...`). The ideas are identical, only imports and builders differ, so check your project's version.

## 8. Gotchas to remember

- Use **one shared** `ObjectMapper` (Spring gives you one). Creating a new one per request is slow, and a hand-made one loses Spring Boot's configuration.
- A missing JSON key becomes `null` (or `0` for `int`), silently.
- Never serialize JPA entities directly. Map them to DTOs first.




[[Serialization]]