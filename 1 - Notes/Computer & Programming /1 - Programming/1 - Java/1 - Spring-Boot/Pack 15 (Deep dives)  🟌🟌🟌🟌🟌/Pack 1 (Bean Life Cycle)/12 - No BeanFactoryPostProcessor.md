
If you don’t write any `BeanFactoryPostProcessor`, Spring doesn’t leave the metadata empty or broken. It just uses the `BeanDefinition`s exactly as they were first built from your configuration.

Here is where that “default metadata” comes from:

- **Component scanning**: `@Component`, `@Service`, `@Repository` and similar annotations produce a `BeanDefinition` with defaults such as singleton scope, eager initialization, and autowire by constructor or annotation.
- **`@Bean` methods**: each one becomes a definition whose factory method is the `@Bean` method.
- **XML**: each `<bean>` element becomes a definition with whatever attributes you wrote.

Then the container simply instantiates beans from those definitions, with no changes in between.

One small correction to the wording: you usually _do_ have some `BeanFactoryPostProcessor`s running, even if you never wrote one. Spring registers its own internally:

- `ConfigurationClassPostProcessor` processes `@Configuration`, `@Bean`, `@ComponentScan` and `@Import`. This is actually what turns your annotations into `BeanDefinition`s in the first place.
- `PropertySourcesPlaceholderConfigurer` (or Boot’s equivalent) resolves `${...}` placeholders inside definitions.

So “not implementing one” means you aren’t customizing the metadata yourself. The framework’s own post-processors still do their work.

In short, with no custom `BeanFactoryPostProcessor`, the metadata stays as the annotations, XML or Java config declared it. You only write one when you want to change that metadata (for example, switch a bean’s scope, change a property value, or register extra definitions) before any bean is created.


[[Spring Framework]]