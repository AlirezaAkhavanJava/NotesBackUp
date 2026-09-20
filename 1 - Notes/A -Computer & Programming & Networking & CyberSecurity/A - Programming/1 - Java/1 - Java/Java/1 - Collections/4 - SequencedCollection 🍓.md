Encounter order is the order in which elements of a collection are visited when you iterate over it or process it with a stream. Some collections define this order clearly, like a `List` which follows index order, or a `LinkedHashSet` which follows insertion order, while others like `HashSet` do not guarantee any order at all. In stream operations, encounter order matters because certain operations rely on it—such as `limit`, `findFirst`, or `forEachOrdered`—and parallel streams may ignore this order unless explicitly told to preserve it.

In the *`SequencedCollection` interface* (introduced in Java 21), **encounter order** is _explicitly defined and guaranteed_. It means elements are processed in a stable, well-defined sequence from **first to last**, not randomly. This interface formalizes the idea that the collection has a meaningful order, allowing operations like `getFirst()`, `getLast()`, `addFirst()`, `addLast()`, and `reversed()` to work predictably. In short, a `SequencedCollection` promises that iteration, streaming, and access all follow the same consistent encounter order.

---

### SequencedCollection

A collection that has a well-defined encounter order, that supports operations at *both ends*, and that is reversible. The elements of a sequenced collection have an encounter order, where conceptually the elements have a linear arrangement from the first element to the last element. Given any two elements, one element is either before (closer to the first element) or after (closer to the last element) the other element.

Several methods inherited from the Collection interface are required to operate on elements according to this collection's encounter order. For instance, the iterator method provides elements starting from the first element, proceeding through successive elements, until the last element. Other methods that are required to operate on elements in encounter order include the following: forEach, parallelStream, spliterator, stream, and all overloads of the toArray method.

This interface also defines the reversed method, which provides a reverse-ordered view of this collection. In the reverse-ordered view, the concepts of first and last are inverted, as are the concepts of successor and predecessor. The first element of this collection is the last element of the reverse-ordered view, and vice-versa. The successor of some element in this collection is its predecessor in the reversed view, and vice-versa. All methods that respect the encounter order of the collection operate as if the encounter order is inverted. For instance, the iterator method of the reversed view reports the elements in order from the last element of this collection to the first. The availability of the reversed method, and its impact on the ordering semantics of all applicable methods, allow convenient iteration, searching, copying, and streaming of the elements of this collection in either forward order or reverse order.

![[ray-so-export (5).png]]

##### Tags : [[1 - Collection interface 🤑]]