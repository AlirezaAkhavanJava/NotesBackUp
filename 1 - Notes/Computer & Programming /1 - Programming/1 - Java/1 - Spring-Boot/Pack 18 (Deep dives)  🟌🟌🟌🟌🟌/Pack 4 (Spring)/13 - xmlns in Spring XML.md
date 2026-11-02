

`xmlns` stands for **XML namespace**. It is an attribute you put on an XML element to say, "the tags inside here belong to _this_ vocabulary." In a Spring config file, the vocabulary is usually one of Spring's schemas: `beans`, `context`, `util`, `aop`, `tx` and so on. Each `xmlns` line you add unlocks one family of tags.

You can think of it like an `import` statement in Java. Before you can write `<context:component-scan/>`, you have to declare what `context:` means. The declaration is just a short name (the prefix) tied to a long identifier (the URI). Once you understand this one idea, every Spring XML preamble becomes easy to read and fix.

## The two forms of `xmlns`

|Form|Looks like|Meaning|
|---|---|---|
|**Default namespace**|`xmlns="http://www.springframework.org/schema/beans"`|Tags with **no prefix** belong here: `<bean/>`, `<property/>`|
|**Prefixed namespace**|`xmlns:context="http://www.springframework.org/schema/context"`|Tags that start with `context:` belong here|

A file has at most one default namespace, but any number of prefixed ones. That is why a typical Spring file looks like this:

```xml
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:context="http://www.springframework.org/schema/context">

    <bean id="orderService" class="com.example.OrderService"/>   <!-- beans: default -->
    <context:component-scan base-package="com.example"/>         <!-- context: prefixed -->

</beans>
```

Line by line:

- `<beans xmlns="…/beans">` makes `beans` the default. So `<bean/>` works with no prefix.
- `xmlns:context="…/context"` creates the prefix `context`.
- `<bean …/>` is resolved through the default namespace.
- `<context:component-scan …/>` is resolved through the `context` prefix.

## Two things people get wrong

**1. The prefix is only a nickname.** What really identifies the namespace is the **URI**. These two files mean exactly the same thing:

```xml
xmlns:context="http://www.springframework.org/schema/context"
xmlns:ctx="http://www.springframework.org/schema/context"
```

The second one would use `<ctx:component-scan/>`. Nobody does this, because everyone follows the standard prefixes, but it shows that the URI is what counts.

**2. The URI is not a download link.** It looks like a web address, but it's only a unique name. Spring never visits it. Because it is a name, it stays `http://` even though modern `schemaLocation` addresses use `https://`.

## Where `xsi:schemaLocation` fits in

`xmlns` says _which_ vocabulary. The `xsi:schemaLocation` attribute says _where its rule book (the XSD file) is_. To use `schemaLocation` you need one more namespace, `xsi`, which is a standard XML one, not a Spring one:

```xml
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="
           http://www.springframework.org/schema/beans
               https://www.springframework.org/schema/beans/spring-beans.xsd
           http://www.springframework.org/schema/context
               https://www.springframework.org/schema/context/spring-context.xsd">
```

The value is a list of **pairs**, separated by whitespace: `namespace-URI location`, then the next pair, and so on.

|Part|Role|
|---|---|
|`xmlns:xsi=…`|Declares the `xsi` prefix so that the attribute below is legal|
|`xsi:schemaLocation`|The list of pairs|
|First item of a pair|The namespace URI (must match an `xmlns` exactly)|
|Second item of a pair|The location of the XSD file|

**Rule of thumb:** every `xmlns` line (except `xsi` itself) gets its own pair in `schemaLocation`.

## What Spring does with all this

Two separate things use your namespaces, and it helps to keep them apart.

|Job|Who does it|Where it is configured|
|---|---|---|
|**Validation and IDE help**: checks your tags are legal and autocompletes them|The XML parser, using the XSD|`META-INF/spring.schemas` inside each Spring jar maps the schema URL to a local XSD file|
|**Making the tags work**: turning `<context:component-scan/>` into real bean definitions|A `NamespaceHandler` for that namespace|`META-INF/spring.handlers` inside the jar maps each namespace URI to a handler class|

The mapping files are part of how Spring works internally. The reference page you read doesn't cover them, but they explain two useful facts:

- Validation works **offline**, because the XSDs are read from the jars on your classpath.
- If a jar is missing, the handler is missing too, and you get an error (see the list of errors below).

## Common Spring namespaces

|Prefix|Namespace URI ends with|Gives you|Comes from|
|---|---|---|---|
|(default)|`/schema/beans`|`<bean>`, `<property>`, `<import>`|spring-beans|
|`context`|`/schema/context`|`component-scan`, `annotation-config`, `property-placeholder`|spring-context|
|`util`|`/schema/util`|`list`, `map`, `set`, `properties`, `constant`|spring-beans|
|`aop`|`/schema/aop`|`<aop:config>` and friends|spring-aop|
|`tx`|`/schema/tx`|`<tx:annotation-driven>`, `<tx:advice>`|spring-tx|
|`mvc`|`/schema/mvc`|`<mvc:annotation-driven>`|spring-webmvc|
|`jdbc`|`/schema/jdbc`|`<jdbc:embedded-database>`|spring-jdbc|
|`p`|`/schema/p`|Property shortcut attributes, e.g. `p:name="Rick"`|spring-beans|
|`c`|`/schema/c`|Constructor shortcut attributes|spring-beans|

All of them start with `http://www.springframework.org`. The `p` and `c` namespaces are special: they add **attributes**, not tags, and they have no XSD, so they need an `xmlns` line but no `schemaLocation` pair.

## Making `beans` a prefix instead of the default

You are free to choose which namespace is the default. Some files (Spring Security's XML config is a well-known example) make a different one the default and give `beans` a prefix:

```xml
<beans:beans xmlns="http://www.springframework.org/schema/security"
             xmlns:beans="http://www.springframework.org/schema/beans"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="
                 http://www.springframework.org/schema/beans
                     https://www.springframework.org/schema/beans/spring-beans.xsd
                 http://www.springframework.org/schema/security
                     https://www.springframework.org/schema/security/spring-security.xsd">

    <http>…</http>                       <!-- security: default, no prefix -->
    <beans:bean id="x" class="…"/>       <!-- beans needs its prefix now -->

</beans:beans>
```

Notice the root is now `<beans:beans>`. It works the same way. It is simply more typing for the beans tags.

## How to add a new namespace: a 3-step recipe

Say you want to use `<tx:annotation-driven/>` in a file that currently has only `beans`.

1. **Add the prefix declaration** to the root element:  
    `xmlns:tx="http://www.springframework.org/schema/tx"`
2. **Add the pair** to `xsi:schemaLocation`:  
    `http://www.springframework.org/schema/tx https://www.springframework.org/schema/tx/spring-tx.xsd`
3. **Make sure the jar is on the classpath** (`spring-tx` here).

Tip: use the **version-free** XSD name, like `spring-tx.xsd`, not `spring-tx-4.3.xsd`. The version-free name picks the XSD that matches the Spring version you actually have, so upgrades don't break your file.

## Reading the error messages

|Error (roughly)|Meaning|Fix|
|---|---|---|
|`The prefix "context" for element "context:component-scan" is not bound`|You used the prefix but never wrote `xmlns:context=…`|Add the `xmlns:context` line|
|`cvc-complex-type.2.4.c: The matching wildcard is strict, but no declaration can be found for element 'context:component-scan'`|The `xmlns` exists, but the `schemaLocation` pair is missing or has a typo|Add or fix the pair; the URI must match exactly|
|`Unable to locate Spring NamespaceHandler for XML schema namespace [...]`|The namespace is fine, but the jar that supplies its handler isn't on the classpath|Add the right Spring module as a dependency|

## Related concept: XSD

An **XSD** (XML Schema Definition) is a file that lists which tags and attributes are allowed in a namespace, and what type each value has. It is what lets your IDE say "this attribute doesn't exist." You don't write XSDs for Spring's own namespaces, because they come in the jars.

## Related concept: custom namespaces

Spring lets you create your **own** namespace, with its own tags, an XSD and a `NamespaceHandler`. This is how all the namespaces above are built. The next page in the Spring docs, "XML Schema Authoring", covers it.

## Recap

- `xmlns="URI"` sets the default namespace; `xmlns:prefix="URI"` creates a prefixed one.
- The **URI identifies** the namespace; the prefix is just a nickname.
- `xsi:schemaLocation` lists `URI location` pairs, so each namespace needs a matching pair.
- Missing prefix means "not bound"; missing pair means "no declaration can be found"; missing jar means "unable to locate NamespaceHandler."

[[Spring Framework]]