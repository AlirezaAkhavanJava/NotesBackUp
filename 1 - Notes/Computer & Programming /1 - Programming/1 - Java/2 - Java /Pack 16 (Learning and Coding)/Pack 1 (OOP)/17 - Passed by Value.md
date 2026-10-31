
**Pass by value** means that when you hand a variable to a method, the method receives a **copy** of what is inside the variable. **Pass by reference** means the method receives the **variable itself** (an alias for it), so the method can change which thing your original variable holds. The difference is only about what gets handed over: a copy, or the original variable.

Here is the part that trips people up, and it is worth saying clearly right away: **Java is always pass by value. It has no pass by reference.** The confusion comes from what the copy contains. For a primitive, the copy is the number. For an object variable, the copy is the _address_ of the object. So the method can reach the same object, but it still cannot touch your original variable.

## Start with the mental model: photocopies and keys

Think of a variable as a sheet of paper.

- A primitive variable has the **value** written on the sheet: `5`.
- An object variable has the **address** of a house written on the sheet: "12 Oak Street."

Pass by value means the method gets a **photocopy** of your sheet.

- If the sheet says `5`, the method can scribble on its photocopy all day. Your sheet still says `5`.
- If the sheet says "12 Oak Street", the method can walk to that house and repaint the walls. You will see the new paint, because it is the same house. But if the method crosses out the address on its photocopy and writes "99 Elm Street", your sheet still says "12 Oak Street."

Pass by reference would mean the method gets **your actual sheet**. If it crossed out the address and wrote a new one, your variable would now point to the new house.

## Case 1: primitives

```java
static void addTen(int x) {
    x = x + 10;
    System.out.println("inside: " + x);
}

public static void main(String[] args) {
    int n = 5;
    addTen(n);
    System.out.println("outside: " + n);
}
```

Output:

```
inside: 20
outside: 5
```

Line by line:

- `int n = 5;` creates a box `n` holding 5.
- `addTen(n)` copies the 5 into a brand new box `x`, which belongs to the method.
- `x = x + 10` changes only that new box.
- Back in `main`, `n` was never touched.

## Case 2: objects (changing the object)

```java
static void rename(Dog d) {
    d.setName("Max");
}

public static void main(String[] args) {
    Dog rex = new Dog("Rex");
    rename(rex);
    System.out.println(rex.getName());   // Max
}
```

Line by line:

- `rex` holds an address, say `#A1`, of a `Dog` on the heap.
- `rename(rex)` copies `#A1` into the parameter `d`. Now two variables hold the same address.
- `d.setName("Max")` follows the address to the real dog and changes its name.
- `rex` points to that same dog, so it sees "Max".

This is the case that makes people say "Java passes objects by reference." It looks that way, because the change survived. But look at the next case.

## Case 3: objects (changing the variable) is the proof

```java
static void replace(Dog d) {
    d = new Dog("Other");      // the local copy now points somewhere new
    System.out.println("inside: " + d.getName());
}

public static void main(String[] args) {
    Dog rex = new Dog("Rex");
    replace(rex);
    System.out.println("outside: " + rex.getName());
}
```

Output:

```
inside: Other
outside: Rex
```

Here is what happens in memory:

|Step|`rex` (in main)|`d` (in replace)|Heap|
|---|---|---|---|
|Before call|#A1|n/a|Dog Rex at #A1|
|After copy|#A1|#A1|Dog Rex at #A1|
|After `d = new Dog("Other")`|#A1|#B2|Dog Rex at #A1, Dog Other at #B2|
|After method ends|#A1|gone|Dog Other is unreachable|

`d` was only a copy of the address. Pointing it at a new dog did not move `rex`. If Java were truly pass by reference, `rex` would now be "Other". It is not, so Java is pass by value.

## The classic proof: the swap test

In a pass by reference language, you can write a method that swaps two variables. In Java you cannot:

```java
static void swap(Dog a, Dog b) {
    Dog temp = a;
    a = b;
    b = temp;      // only swaps the local copies
}

Dog x = new Dog("X");
Dog y = new Dog("Y");
swap(x, y);
System.out.println(x.getName());   // still X
```

If you really need to "return two things" or change a caller's variable, return the new value instead (`x = process(x);`), or put the values in a small object, array, or record and change the contents.

## What about arrays, Strings, and collections?

They are all objects, so they follow Case 2 and Case 3.

```java
static void change(int[] arr) {
    arr[0] = 99;          // changes the real array
    arr = new int[]{7};   // only changes the local copy
}
```

After the call, the caller's array has `99` in position 0, and it is still the same array. `String` is different in one useful way: it is **immutable**, so there is no `setName`-style method to change it. The only thing a method can do with a `String` parameter is reassign its local copy, so the caller never sees a change.

```java
static void shout(String s) {
    s = s.toUpperCase();   // creates a new String, local copy only
}
```

## A cheat sheet

|You do inside the method|Does the caller see it?|
|---|---|
|Change a primitive parameter|No|
|Reassign an object parameter (`d = new ...`)|No|
|Call a method that changes the object (`d.setName(...)`)|Yes|
|Change an array element or a collection (`list.add(...)`)|Yes|
|Reassign a `String` or wrapper (`s = ...`)|No|

## Related concept: what real pass by reference looks like

Languages like C++ (with `int&`) or C# (with `ref` and `out`) really can pass the variable itself. In C++, `void swap(int& a, int& b)` genuinely swaps the caller's variables. Java deliberately left this out to keep things simpler: one rule, always copy. The trade-off is that you sometimes return values or wrap them in an object to get the effect.

## Short answer

Java is always **pass by value**. For primitives the copy is the value, and for objects the copy is the address. That is why a method can change the _contents_ of an object you pass in, but can never change _which object_ your variable points to.




[[Java]]