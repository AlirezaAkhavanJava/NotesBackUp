
Maven is a build automation and dependency management tool for Java projects. You describe your project in a single file, `pom.xml` (dependencies, Java version, plugins), and Maven handles downloading libraries, compiling, testing, and packaging (e.g., into a `.jar`).

**Analogy:** Think of `pom.xml` as a shopping list plus a recipe. The list says which libraries you need, and the recipe says how to build the final product. Maven fetches the ingredients and cooks.

On Debian 13 you can install it with `sudo apt install maven`, and the most common commands are `mvn compile`, `mvn test`, and `mvn package`.

In Spring Boot, Maven is what pulls in `spring-boot-starter-web` and the rest of your dependencies automatically.


[[Java]]
[[Spring Framework]]
[[Gradle]]