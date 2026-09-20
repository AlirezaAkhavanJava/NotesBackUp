**Abstract Factory** is a creational design pattern that lets you produce families of related objects without specifying their concrete classes.
![[abstract-factory-en.png]]


Imagine that you’re creating a furniture shop simulator. Your code consists of classes that represent:

1. A family of related products, say: `Chair` + `Sofa` + `CoffeeTable`.
    
2. Several variants of this family. For example, products `Chair` + `Sofa` + `CoffeeTable` are available in these variants: `Modern`, `Victorian`, `ArtDeco`.
    

![Product families and their variants.](https://refactoring.guru/images/patterns/diagrams/abstract-factory/problem-en.png)

Product families and their variants.

You need a way to create individual furniture objects so that they match other objects of the same family. Customers get quite mad when they receive non-matching furniture.

![](https://refactoring.guru/images/patterns/content/abstract-factory/abstract-factory-comic-1-en.png)

A Modern-style sofa doesn’t match Victorian-style chairs.

Also, you don’t want to change existing code when adding new products or families of products to the program. Furniture vendors update their catalogs very often, and you wouldn’t want to change the core code each time it happens.

##  Solution

The first thing the Abstract Factory pattern suggests is to explicitly declare interfaces for each distinct product of the product family (e.g., chair, sofa or coffee table). Then you can make all variants of products follow those interfaces. For example, all chair variants can implement the `Chair` interface; all coffee table variants can implement the `CoffeeTable` interface, and so on.

![The Chairs class hierarchy](https://refactoring.guru/images/patterns/diagrams/abstract-factory/solution1.png)

All variants of the same object must be moved to a single class hierarchy.

The next move is to declare the _Abstract Factory_—an interface with a list of creation methods for all products that are part of the product family (for example, `createChair`, `createSofa` and `createCoffeeTable`). These methods must return **abstract** product types represented by the interfaces we extracted previously: `Chair`, `Sofa`, `CoffeeTable` and so on.

![The _Factories_ class hierarchy](https://refactoring.guru/images/patterns/diagrams/abstract-factory/solution2.png)

Each concrete factory corresponds to a specific product variant.

Now, how about the product variants? For each variant of a product family, we create a separate factory class based on the `AbstractFactory` interface. A factory is a class that returns products of a particular kind. For example, the `ModernFurnitureFactory` can only create `ModernChair`, `ModernSofa` and `ModernCoffeeTable` objects.

The client code has to work with both factories and products via their respective abstract interfaces. This lets you change the type of a factory that you pass to the client code, as well as the product variant that the client code receives, without breaking the actual client code.

![](https://refactoring.guru/images/patterns/content/abstract-factory/abstract-factory-comic-2-en.png)

The client shouldn’t care about the concrete class of the factory it works with.

Say the client wants a factory to produce a chair. The client doesn’t have to be aware of the factory’s class, nor does it matter what kind of chair it gets. Whether it’s a Modern model or a Victorian-style chair, the client must treat all chairs in the same manner, using the abstract `Chair` interface. With this approach, the only thing that the client knows about the chair is that it implements the `sitOn` method in some way. Also, whichever variant of the chair is returned, it’ll always match the type of sofa or coffee table produced by the same factory object.

There’s one more thing left to clarify: if the client is only exposed to the abstract interfaces, what creates the actual factory objects? Usually, the application creates a concrete factory object at the initialization stage. Just before that, the app must select the factory type depending on the configuration or the environment settings.

##  Structure

![Abstract Factory design pattern](https://refactoring.guru/images/patterns/diagrams/abstract-factory/structure.png)

1. **Abstract Products** declare interfaces for a set of distinct but related products which make up a product family.
    
2. **Concrete Products** are various implementations of abstract products, grouped by variants. Each abstract product (chair/sofa) must be implemented in all given variants (Victorian/Modern).
    
3. The **Abstract Factory** interface declares a set of methods for creating each of the abstract products.
    
4. **Concrete Factories** implement creation methods of the abstract factory. Each concrete factory corresponds to a specific variant of products and creates only those product variants.
    
5. Although concrete factories instantiate concrete products, signatures of their creation methods must return corresponding _abstract_ products. This way the client code that uses a factory doesn’t get coupled to the specific variant of the product it gets from a factory. The **Client** can work with any concrete factory/product variant, as long as it communicates with their objects via abstract interfaces.
    

##  Pseudocode

This example illustrates how the **Abstract Factory** pattern can be used for creating cross-platform UI elements without coupling the client code to concrete UI classes, while keeping all created elements consistent with a selected operating system.

![The class diagram for the Abstract Factory pattern example](https://refactoring.guru/images/patterns/diagrams/abstract-factory/example.png)

##  Applicability

 Use the Abstract Factory when your code needs to work with various families of related products, but you don’t want it to depend on the concrete classes of those products—they might be unknown beforehand or you simply want to allow for future extensibility.

 The Abstract Factory provides you with an interface for creating objects from each class of the product family. As long as your code creates objects via this interface, you don’t have to worry about creating the wrong variant of a product which doesn’t match the products already created by your app.

 Consider implementing the Abstract Factory when you have a class with a set of [Factory Methods](https://refactoring.guru/design-patterns/factory-method) that blur its primary responsibility.

 In a well-designed program _each class is responsible only for one thing_. When a class deals with multiple product types, it may be worth extracting its factory methods into a stand-alone factory class or a full-blown Abstract Factory implementation.

##  How to Implement

1. Map out a matrix of distinct product types versus variants of these products.
    
2. Declare abstract product interfaces for all product types. Then make all concrete product classes implement these interfaces.
    
3. Declare the abstract factory interface with a set of creation methods for all abstract products.
    
4. Implement a set of concrete factory classes, one for each product variant.
    
5. Create factory initialization code somewhere in the app. It should instantiate one of the concrete factory classes, depending on the application configuration or the current environment. Pass this factory object to all classes that construct products.
    
6. Scan through the code and find all direct calls to product constructors. Replace them with calls to the appropriate creation method on the factory object.
    

##  Pros and Cons

-  You can be sure that the products you’re getting from a factory are compatible with each other.
-  You avoid tight coupling between concrete products and client code.
-  _Single Responsibility Principle_. You can extract the product creation code into one place, making the code easier to support.
-  _Open/Closed Principle_. You can introduce new variants of products without breaking existing client code.

-  The code may become more complicated than it should be, since a lot of new interfaces and classes are introduced along with the pattern.

---
**Abstract Factory** design pattern is a **creational pattern**. This means it's focused on **object creation**—specifically, how to create families of related objects without specifying their concrete classes.


### 🧩 What Is the Abstract Factory Pattern?

The Abstract Factory pattern provides an interface for creating families of related or dependent objects without specifying their concrete classes. It's often described as a "factory of factories," where a super-factory creates other factories that, in turn, create specific objects. This approach allows systems to be independent of how their products are created, composed, and represented.

---

### 🛠️ Components of the Abstract Factory Pattern

1. **Abstract Factory**: Declares creation methods for each type of product.
    
2. **Concrete Factory**: Implements the creation methods to instantiate specific product families.
    
3. **Abstract Product**: Defines the interface for a type of product object.
    
4. **Concrete Product**: Implements the abstract product interface, defining a specific product.
    
5. **Client**: Uses only interfaces declared by AbstractFactory and AbstractProduct classes.
    

---

### 🏗️ Example: Cross-Platform UI Elements

Imagine you're developing a cross-platform application that needs to render UI elements. The UI elements should behave similarly but look different under different operating systems. The Abstract Factory pattern can help you achieve this by creating families of related UI elements for each operating system.

- **Abstract Factory**: `GUIFactory` interface with methods like `createButton()` and `createCheckbox()`.
    
- **Concrete Factories**: `WindowsFactory` and `MacFactory`, each implementing the `GUIFactory` interface to create Windows-specific and Mac-specific UI elements, respectively.
    
- **Abstract Products**: `Button` and `Checkbox` interfaces.
    
- **Concrete Products**: `WindowsButton`, `MacButton`, `WindowsCheckbox`, and `MacCheckbox`, each implementing the respective abstract product interfaces.
    

This structure allows your application to create UI elements that are consistent with the operating system's look and feel, without the client code needing to know the specifics of each OS's UI components.

---

### ✅ Benefits of Using the Abstract Factory Pattern

- **Consistency**: Ensures that products from the same family are used together.
    
- **Flexibility**: Makes it easy to switch between different families of products.
    
- **Decoupling**: Isolates the client code from the concrete classes of the products, promoting loose coupling.
    

---

For a more in-depth understanding and additional examples, you can refer to the [Refactoring Guru's Abstract Factory page](https://refactoring.guru/design-patterns/abstract-factory).


#### Tags : [[Algorithm & Design Pattern]]
