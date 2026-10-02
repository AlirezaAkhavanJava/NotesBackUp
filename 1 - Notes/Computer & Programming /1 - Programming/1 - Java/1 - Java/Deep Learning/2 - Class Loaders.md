
A class loader is an object that is responsible for loading classes. Further, class loaders load Java classes dynamically to the JVM (Java Virtual Machine) during runtime. They’re also part of the JRE (Java Runtime Environment). Therefore, the JVM doesn’t need to know about the underlying files or file systems to run Java programs thanks to class loaders.

Furthermore, the JVM doesn’t load these Java classes into memory all at once, but rather when an application requires them. This is where class loaders come into the picture. They’re responsible for loading classes into memory.

>A class loader is an object that is responsible for loading classes. The class ClassLoader is an abstract class. Given the binary name of a class, a class loader should attempt to locate or generate data that constitutes a definition for the class. A typical strategy is to transform the name into a file name and then read a "class file" of that name from a file system.

---
##### A class loader has two main functions:

- **Load Classes** – Different built-in and custom class loaders load classes. We can extend the _java.lang.ClassLoader_ abstract class to create class loader implementations
- **Locate Resources** – A resource is some data such as a _.class_ file, configuration information, or an image. We typically package resources with an application or library so that they are easy to locate

At the outset, class loaders don’t create objects for array classes. Instead,  the Java runtime creates them automatically as required. Therefore, when we use _Class#getClassLoader()_ to find the class loader for an array class, it returns the class loader for its element type. Accordingly, an array class has no class loader if the element type is a primitive data type.

|Class type|Loaded by which ClassLoader?|Example|
|---|---|---|
|Core JDK classes (java._, javax._, etc.)|**Bootstrap ClassLoader**|`java.util.LinkedList`, `java.lang.String`|
|Your application classes|**Application ClassLoader** (or Platform ClassLoader in Java 9+)|`com.myapp.MyClass`, `org.example.User`|
|Classes from JDK modules (non-base)|**Platform ClassLoader**|`java.sql.DriverManager` (from `java.sql`)|
|Custom-loaded classes|**Custom ClassLoader** (if you wrote one)|Plugins, OSGi bundles, etc.|

---

![[Pasted image 20251221081304.png]]

### Loading

Whenever JVM loads a file, it will load and read,

- Fully qualified class name
- Variable information (instance variables)
- Immediate parent information
- Whether class or interface or enum

When the class is loaded to the JVM, it creates an object of class type and is put into the heap area. This class type object will be created only the very first time the class is loaded to the JVM.

---
### What does the Bootstrap ClassLoader load?

The **Bootstrap ClassLoader** (also called **Primordial ClassLoader**) is the **root** ClassLoader in Java. It is **implemented in native code** (not Java) and is responsible for loading **only core JDK classes** that are part of the **Java SE platform**.

|Location / Module (Java 9+)|Examples of classes loaded by Bootstrap ClassLoader|
|---|---|
|**rt.jar** (Java 8 and earlier)|`java.lang.Object`, `java.lang.String`, `java.util.ArrayList`, etc.|
|**Core modules** (Java 9+)|`java.base` module (most core classes)|
|Specific packages:||
|- `java.lang.*`|`Object`, `String`, `System`, `Thread`, `Integer`, `Math`, etc.|
|- `java.util.*`|`ArrayList`, `HashMap`, `LinkedList`, `Collections`, etc.|
|- `java.io.*`, `java.net.*`, `java.nio.*`|`File`, `InputStream`, `URL`, `ByteBuffer`, etc.|
|- `sun.*` (internal)|Some internal JDK classes (not part of public API)|
### Quick mnemonic

- **Bootstrap** → **Core Java classes** (java.*, javax.* base packages)
- **Platform** → Other **JDK modules** (java.sql, java.xml, etc.)
- **Application** → **Your code** and third-party libraries (JARs on classpath)

##### Tags : [[Java]]