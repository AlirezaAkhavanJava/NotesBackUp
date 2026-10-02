A class implements the Cloneable interface to indicate to the Object.clone() method that it is legal for that method to make a field-for-field copy of instances of that class.
Invoking Object's clone method on an instance that does not implement the Cloneable interface results in the exception CloneNotSupportedException being thrown.
By convention, classes that implement this interface should override Object.clone (which is protected) with a public method. See Object.clone() for details on overriding this method.
Note that this interface does not contain the clone method. Therefore, it is not possible to clone an object merely by virtue of the fact that it implements this interface. Even if the clone method is invoked reflectively, there is no guarantee that it will succeed.


**`Cloneable`** in Java is a _marker interface_ (it has no methods) that tells the JVM: “this object is allowed to be cloned.”

If a class **does not implement `Cloneable`**, calling `Object.clone()` on its instance throws **`CloneNotSupportedException`**.  
If it **does implement `Cloneable`**, `Object.clone()` performs a **shallow copy** of the object.

So `Cloneable` doesn’t _do_ cloning. It’s a permission slip.

![[ray-so-export (6).png]]

##### Tags : [[8 - ArrayList 🍓]]