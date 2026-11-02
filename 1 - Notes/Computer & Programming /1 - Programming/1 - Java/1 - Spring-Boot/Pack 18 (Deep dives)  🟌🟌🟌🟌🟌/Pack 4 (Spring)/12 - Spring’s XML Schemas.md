

This appendix page is about the **XML namespaces** that Spring's XML configuration files can use. In XML config, everything starts with the `beans` schema, which gives you `<bean/>`, `<property/>` and similar tags. On top of that, Spring ships extra schemas that add shorter, more readable tags for common jobs, such as creating a list, loading a properties file, or turning on annotation support. The page covers the four schemas for the core container: `util`, `aop`, `context` and `beans`.

You may think XML config is old, and for new code it mostly is. But you will still meet it in older projects and tutorials. Reading it is also a good way to see what annotations like `@Autowired` and `@ComponentScan` do behind the scenes. The page is from Spring Framework 7.0.10.

## First, how a namespace works

Every XML config file starts with a block like this:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:util="http://www.springframework.org/schema/util"
       xsi:schemaLocation="
           http://www.springframework.org/schema/beans https://www.springframework.org/schema/beans/spring-beans.xsd
           http://www.springframework.org/schema/util https://www.springframework.org/schema/util/spring-util.xsd">

    <!-- bean definitions here -->

</beans>
```

Line by line:

|Line|What it does|
|---|---|
|`xmlns="…/schema/beans"`|The **default** namespace. Tags with no prefix (`<bean/>`, `<property/>`) come from here.|
|`xmlns:xsi="…XMLSchema-instance"`|Lets you use the `xsi:schemaLocation` attribute below. It is standard XML, not Spring.|
|`xmlns:util="…/schema/util"`|Declares the prefix `util`. Now you can write `<util:list/>`.|
|`xsi:schemaLocation="…"`|Pairs of "namespace URI, then where its XSD file lives." It helps your IDE validate the file and autocomplete tags.|

Two small facts that save confusion:

- The namespace URI is just an **identifier**. It looks like a web address, but Spring does not download anything from it. The real XSD files are inside Spring's jars, and Spring maps the URLs to them (I'm adding this from my own knowledge; the page doesn't say it).
- Each schema you want needs **two** additions: an `xmlns:prefix` line and a matching pair in `schemaLocation`. Forget the second and the tags usually still work, but your IDE complains. Forget the first and you get a parse error.

## The `util` schema: small helpers

The page describes `util` as the schema for common utility jobs: configuring collections, referencing constants, and so on. Every `util` tag has the same story. There is a long, older way using a `FactoryBean`, and a short tag that does the same thing. So first, one quick concept.

**Related concept: `FactoryBean`.** It is a special bean whose job is to _produce_ another object. When you ask the container for a `FactoryBean`, you get the object it produces, not the factory itself. `util` tags are shortcuts that hide these factories.

### `<util:constant/>`: inject a constant

Suppose a bean needs the value of `java.sql.Connection.TRANSACTION_SERIALIZABLE`. The long way uses a `FieldRetrievingFactoryBean` as an inner bean:

```xml
<bean id="..." class="...">
    <property name="isolation">
        <bean id="java.sql.Connection.TRANSACTION_SERIALIZABLE"
              class="org.springframework.beans.factory.config.FieldRetrievingFactoryBean"/>
    </property>
</bean>
```

The short way:

```xml
<property name="isolation">
    <util:constant static-field="java.sql.Connection.TRANSACTION_SERIALIZABLE"/>
</property>
```

The short version says what you mean ("inject this constant") and hides Spring's plumbing.

The page goes deeper into `FieldRetrievingFactoryBean`, which has two extra tricks:

- You can set it up with an explicit property: `<property name="staticField" value="java.sql.Connection.TRANSACTION_SERIALIZABLE"/>`.
- **Bean-name shortcut:** if you set the bean `id` to the full field name, Spring reads the field from the name. This is very short, but you lose the freedom to choose the `id`, so every reference to it must use that long name. It works best as an **inner bean**, where no id is needed.
- It can also read non-static (instance) fields of another bean.

**Enums are even easier.** You don't need any of this for enum values. Given:

```java
public enum PersistenceContextType { TRANSACTION, EXTENDED }
```

and a class with `setPersistenceContextType(PersistenceContextType type)`, you just write the enum constant name as text:

```xml
<bean class="example.Client">
    <property name="persistenceContextType" value="TRANSACTION"/>
</bean>
```

Spring converts the string `"TRANSACTION"` to the enum for you.

### `<util:property-path/>`: read a property of another bean

Imagine a bean `testBean` that has an `age` of 10 and a `spouse` whose age is 11. You want a bean whose value is `testBean.age`.

|Style|Config|Result|
|---|---|---|
|Long|`<bean id="testBean.age" class="…PropertyPathFactoryBean"/>`|`10`|
|Short|`<util:property-path id="name" path="testBean.age"/>`|`10`|

The `path` attribute has the form `beanName.beanProperty`. You can go deeper with dots, like `person.spouse.age`, which gives `11`.

The long `PropertyPathFactoryBean` form is more flexible. You can point it at a bean by name, or at an inner bean directly:

```xml
<!-- by bean name -->
<bean id="theAge" class="org.springframework.beans.factory.config.PropertyPathFactoryBean">
    <property name="targetBeanName" value="person"/>
    <property name="propertyPath" value="spouse.age"/>
</bean>

<!-- against an inner bean -->
<bean id="theAge" class="org.springframework.beans.factory.config.PropertyPathFactoryBean">
    <property name="targetObject">
        <bean class="org.springframework.beans.TestBean">
            <property name="age" value="12"/>
        </bean>
    </property>
    <property name="propertyPath" value="age"/>
</bean>
```

There is also a shortcut where the bean id _is_ the path (`id="person.age"`). Same trade-off as before: the name is no longer your choice. It is handy as an inner bean. The page also notes you can set the result type explicitly, which is rarely needed.

### `<util:properties/>`: load a properties file into a `Properties` object

```xml
<util:properties id="jdbcConfiguration"
                 location="classpath:com/foo/jdbc-production.properties"/>
```

This creates a `java.util.Properties` bean named `jdbcConfiguration`, filled from the file. The long version uses `PropertiesFactoryBean` with a `location` property.

This is different from the `<context:property-placeholder/>` tag you'll see later. `util:properties` gives you the **whole file as one bean** that you can inject. A placeholder lets you use `${key}` inside other definitions.

### `<util:list/>`, `<util:map/>`, `<util:set/>`: collections as beans

These three work the same way. Here is the list:

```xml
<util:list id="emails">
    <value>admin@example.com</value>
    <value>support@example.com</value>
</util:list>
```

This creates a `List` bean called `emails`. Without the tag you would write a `ListFactoryBean` with a `sourceList` property holding a nested `<list>`. The map and set versions use `MapFactoryBean` (`sourceMap`) and `SetFactoryBean` (`sourceSet`):

```xml
<util:map id="contacts">
    <entry key="alice" value="alice@example.com"/>
    <entry key="bob"   value="bob@example.com"/>
</util:map>
```

**Choosing the exact collection type.** By default Spring picks an implementation. If you need a specific one, use these attributes:

|Tag|Attribute|Example|
|---|---|---|
|`<util:list>`|`list-class`|`list-class="java.util.LinkedList"`|
|`<util:map>`|`map-class`|`map-class="java.util.TreeMap"`|
|`<util:set>`|`set-class`|`set-class="java.util.TreeSet"`|

_Java config comparison (my addition):_ a `util:list` is roughly a `@Bean` method returning a `List<String>`, like `@Bean List<String> emails() { return List.of("admin@example.com", "support@example.com"); }`.

## The `aop` schema

The page keeps this one short: the `aop` tags configure everything AOP in Spring, both Spring's own proxy-based AOP and its integration with AspectJ. They are fully covered in the AOP chapter, so the page only gives the preamble. You add `xmlns:aop="http://www.springframework.org/schema/aop"` and the matching `spring-aop.xsd` pair. Later, when you study AOP, you will use tags such as `<aop:config>` here (my note; the page doesn't list them).

## The `context` schema: the plumbing

The page describes `context` as holding tags for `ApplicationContext` setup, the "grunt work" beans such as `BeanFactoryPostProcessor`s. In other words, not business beans, but the infrastructure that makes the container smarter. Here are the elements the page lists:

### `<context:property-placeholder/>`

This turns on `${…}` replacement, using a properties file you point to as a resource location:

```xml
<context:property-placeholder location="classpath:application.properties"/>
```

It is a convenience that sets up a `PropertySourcesPlaceholderConfigurer` bean for you. This is the XML tag I mentioned in your earlier question about raw Spring and `application.properties`. If you need more control, you can declare that configurer bean yourself.

The page adds an important warning:

- Define **only one** such element per application, containing all the properties it needs. Several placeholders are possible only if they use different placeholder syntax.
- If you want to split properties across modules, don't make several placeholder configurers. Instead, each module should contribute a `PropertySource` to the `Environment`. Or you can write one custom `PropertySourcesPlaceholderConfigurer` bean that gathers them all.

That second suggestion is exactly the `@PropertySource` approach from your last lesson.

### `<context:annotation-config/>`

This switches on annotation processing for bean classes. It activates support for:

|Group|Annotations|
|---|---|
|Spring|`@Configuration` model, `@Autowired` / `@Inject`, `@Value`, `@Lookup`, `@EventListener`|
|JSR-250 (if available)|`@Resource`, `@PostConstruct`, `@PreDestroy`|
|Others (if available)|`@WebServiceRef`, `@EJB`, `@PersistenceContext`, `@PersistenceUnit`|

You can instead enable the individual `BeanPostProcessor`s one by one.

**What it does NOT turn on:**

- `@Transactional`: use `<tx:annotation-driven/>` for that.
- Caching annotations: they must be enabled explicitly too.

So `annotation-config` is not "enable every annotation in Spring." It covers the injection and lifecycle family only.

### `<context:component-scan/>`

The page doesn't explain this here; it points to the annotation-based configuration chapter. This is the XML twin of `@ComponentScan`. One extra note from my own knowledge: component-scan also registers the same annotation processors, so you normally don't need both tags.

### The three advanced elements

The page only points to other sections for these:

|Element|What it is for|
|---|---|
|`<context:load-time-weaver/>`|AspectJ load-time weaving|
|`<context:spring-configured/>`|Using AspectJ to inject dependencies into domain objects|
|`<context:mbean-export/>`|Annotation-based JMX MBean export|

## The `beans` schema: the original

The page calls this the schema "since the very dawn of the framework". It holds `<bean/>`, `<property/>`, `<constructor-arg/>` and so on. The page does not repeat those, because they are covered in the dependencies chapter. The one thing it does show is the **`<meta/>`** element:

```xml
<bean id="foo" class="x.y.Foo">
    <meta key="cacheName" value="foo"/>
    <property name="name" value="Rick"/>
</bean>
```

`<meta/>` attaches extra key/value metadata to a bean definition. On its own it does nothing. It is only useful if **your own code** reads it, for example custom logic that sees `cacheName=foo` and sets up caching for that bean. That is why it usually appears together with custom XML elements, which the next appendix page, "XML Schema Authoring", explains.

_How you could read it (my addition, ties into your BeanDefinition lesson):_

```java
BeanDefinition def = beanFactory.getBeanDefinition("foo");
Object cacheName = def.getAttribute("cacheName");   // "foo"
```

The metadata lives on the `BeanDefinition`, the blueprint, not on the bean object.

## Quick reference

|Schema|Prefix|Main purpose|Tags from this page|
|---|---|---|---|
|`beans`|(default)|Define beans and wiring|`<bean>`, `<meta>`, …|
|`util`|`util`|Utility shortcuts|`constant`, `property-path`, `properties`, `list`, `map`, `set`|
|`context`|`context`|Container plumbing|`property-placeholder`, `annotation-config`, `component-scan`, `load-time-weaver`, `spring-configured`, `mbean-export`|
|`aop`|`aop`|AOP configuration|(see AOP chapter)|

## Things to remember

- A prefix like `util:` only works after you declare **both** the `xmlns:util` line and the `schemaLocation` pair.
- Most `util` tags are short forms of a `FactoryBean` definition. Knowing the long form helps when you read older config.
- `annotation-config` does not enable `@Transactional` or caching.
- Use one `property-placeholder`; for many property files, contribute `PropertySource`s instead.
- `<meta/>` is inert until your own code reads it.



[[Spring Framework]]