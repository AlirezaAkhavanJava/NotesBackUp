## What is Virtual Machine?

Before jump into the JVM, let’s discuss the concept of the virtual machine(VM). A virtual machine is some machine that physically does not exist. But VM will make the environment that you feel as it’s real. VM can be an operating system or application environment that is installed on software. There are two categories of VM as shown below.

![[Pasted image 20251221073651.png]]

System-based VM allows the sharing of the underlying physical machine resources (at least one hardware) between different virtual machines. But application-based VM does not have any hardware and it requires some application or software to create their virtual environment. That environment(platform) involves running some kind of a language and converting it into a different language. JVM is also under the application-based VM.

---

### Java Development Kit (JDK)

The *Java Development Kit (JDK)* is a software development environment used for developing Java applications and applets. It includes the Java Runtime Environment (JRE), an interpreter/loader (Java), a compiler (javac), an archiver (jar), a documentation generator (Javadoc), and other tools needed in Java development.

### Java Runtime Environment (JRE)

The Java Runtime Environment provides the minimum requirements for executing a Java application. It consists of the Java Virtual Machine (JVM), java core packages, classes, and supporting files.

### Java Virtual Machine (JVM)

The Java Virtual Machine is a specification that provides a runtime environment in which java bytecode can be executed. It means JVM creates a platform to run Java bytecode(.class file) and converting into different languages (native machine language) which the computer hardware can understand. Actually, there is nothing to install as JVM. When the JRE is installed, it will deploy the code to create a JVM for the particular platform. JVMs are available for many hardware and software platforms.

![[Pasted image 20251221074056.png]]
##### Tags [[Java]]