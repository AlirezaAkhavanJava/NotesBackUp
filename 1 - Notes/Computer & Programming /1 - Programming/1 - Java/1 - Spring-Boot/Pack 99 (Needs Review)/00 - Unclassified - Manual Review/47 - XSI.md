# XML Schema Instance

`xsi` is the prefix for a special, built-in XML namespace called **XML Schema Instance**, with the URI `http://www.w3.org/2001/XMLSchema-instance`. It belongs to the XML standard itself, not to Spring. Its job is to give your XML _document_ a few attributes for talking to the schema validator. In Spring files you use exactly one of them: `xsi:schemaLocation`, which tells the parser where to find the rule book (the XSD) for each namespace in the file.

The name makes sense once you read it as "schema stuff that lives **in the instance** (your document)." Your Spring file is an _instance_, one concrete document. The XSD is the _schema_ that describes what such documents may contain. `xsi` is the small bridge between the two.

## Three look-alikes that confuse everyone

Spring preambles contain three things whose names look alike. Separating them first makes the rest easy.

|Name|What it is|Where you see it|
|---|---|---|
|`xmlns`|The attribute that **declares** a namespace|`xmlns:xsi="…"`, `xmlns:context="…"`|
|`xsi`|A **namespace prefix** (bound to the XML Schema Instance URI)|`xsi:schemaLocation`|
|XSD|The **rule-book file** (`spring-beans.xsd`)|The second item of each pair in `schemaLocation`|

So the line `xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"` means: "I'm declaring a prefix named `xsi`, and it stands for the XML Schema Instance vocabulary." Only after that can you write `xsi:schemaLocation`.

## Why `xsi:schemaLocation` lives in its own namespace

`schemaLocation` is not part of _your_ vocabulary. It doesn't describe a bean, a list or a property. It's a note **about the document**, aimed at the parser. If it lived in the `beans` namespace, Spring's `beans` XSD would have to define it. Putting such attributes in one shared, standard namespace means they work the same way in every XML language: Spring config, Maven's `pom.xml`, `web.xml`, `persistence.xml` and so on.

You probably already have an example in your own projects. A Maven `pom.xml` starts like this:

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             https://maven.apache.org/xsd/maven-4.0.0.xsd">
```

It's the same pattern as in a Spring file: declare `xsi`, then give a `namespace location` pair.

## Reading a Spring `schemaLocation` line by line

```xml
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:util="http://www.springframework.org/schema/util"
       xsi:schemaLocation="
           http://www.springframework.org/schema/beans
               https://www.springframework.org/schema/beans/spring-beans.xsd
           http://www.springframework.org/schema/util
               https://www.springframework.org/schema/util/spring-util.xsd">
```

|Piece|Meaning|
|---|---|
|`xmlns:xsi="…XMLSchema-instance"`|Makes the `xsi:` prefix available|
|`xsi:schemaLocation="…"`|The attribute that holds the list of pairs|
|`http://…/schema/beans`|**Item 1 of pair 1:** the namespace URI. It must match an `xmlns` exactly.|
|`https://…/spring-beans.xsd`|**Item 2 of pair 1:** where that namespace's XSD can be found|
|`http://…/schema/util` + `…spring-util.xsd`|Pair 2, same idea|

The rules:

- The value is a **flat, whitespace-separated list**: `ns1 location1 ns2 location2 …`. Line breaks and indentation count as whitespace, which is why people split it across lines.
- The number of items must be **even**, because everything comes in pairs.
- The attribute is normally written once, on the root element. It can appear on other elements too.
- It is a **hint** to the parser. It doesn't import or load anything by itself.

## What happens to the location you write

You write an `https://…/spring-beans.xsd` address, but Spring does not normally download it. Spring checks its own table first (a `META-INF/spring.schemas` file in the Spring jars) that maps well-known schema URLs to XSD files **inside the jar**. So when your location is one that Spring knows, validation runs offline and fast.

This has a practical consequence: if you mistype the location, Spring doesn't recognize it. The parser then falls back to trying the network, and you might see slow startup or an offline failure (I'm adding this from my own knowledge; the reference page doesn't discuss it). Copy the standard lines from the docs and you stay safe.

**Tip: use the version-free file name** (`spring-beans.xsd`, not `spring-beans-3.0.xsd`). It gives you the XSD from the Spring version you actually use.

## What happens if you leave `xsi` out

Without the `xmlns:xsi` declaration, `xsi:schemaLocation` is not legal, and without `schemaLocation` the validator doesn't know where the rules for `context:` or `util:` are. You'll usually get an error like this:

> `cvc-complex-type.2.4.c: The matching wildcard is strict, but no declaration can be found for element 'context:component-scan'`

If you write an odd number of items (for example, forget one location), you'll see an error saying the value _must have even number of URI's_.

## The other `xsi` attributes (for completeness)

`xsi` has a few more attributes. Spring XML config doesn't use them, but you will meet them in other XML files.

|Attribute|Purpose|Example|
|---|---|---|
|`xsi:schemaLocation`|Pairs of namespace + XSD location|Spring, Maven (very common)|
|`xsi:noNamespaceSchemaLocation`|XSD location for a file that has **no** namespace (just one location, no pair)|Some older config formats|
|`xsi:type`|Says "this element is really this more specific type"|`<shape xsi:type="circle">`|
|`xsi:nil`|Marks an element as explicitly null|`<middleName xsi:nil="true"/>`|

## Related concept: the XSD itself

An XSD is a file that lists which tags and attributes a namespace allows and what type each value has. It's what lets your IDE underline a wrong attribute. XSD files themselves are XML, and they use their own namespace, `http://www.w3.org/2001/XMLSchema`, usually with the prefix `xs:` or `xsd:`. That's a _different_ namespace from `xsi`, which is another reason the two are easy to mix up.

## Recap

- `xsi` is just a prefix for the standard XML Schema Instance namespace; you declare it with `xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"`.
- Spring only needs one of its attributes: `xsi:schemaLocation`.
- `schemaLocation` holds `namespace location` **pairs**; every `xmlns` (except `xsi`) should have one.
- `xmlns` declares, `xsi` provides the attribute, and the **XSD** is the rule-book file the pair points to.


[[Spring Framework]]