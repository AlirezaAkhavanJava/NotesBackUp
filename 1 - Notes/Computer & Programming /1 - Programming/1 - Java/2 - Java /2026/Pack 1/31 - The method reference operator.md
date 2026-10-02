
# The `::` Operator

## What it's called

`::` is the **method reference operator** (also called the "double colon operator"). It's not an operator in the traditional arithmetic sense (like `+` or `-`) — it's special syntax the compiler recognizes for exactly one purpose: **referring to a method or constructor without calling it**.

## What it actually means

`::` says: _"don't run this method now — hand me a reference to it, so something else can run it later."_

```java
ClassName::methodName
```

Compare that to normal method _calling_:

```java
ClassName.methodName()   // dot + parentheses → calls it right now
ClassName::methodName    // double colon, no parentheses → points at it, doesn't call it
```

That distinction — `.` calls, `::` points — is the entire meaning of the operator.

## Why it needs to exist as separate syntax

In Java, you can't just write a method's name by itself to "get" it the way you can get a variable:

```java
int x = someNumber;        // fine — variables are values you can hold
int y = someMethod;        // ERROR — a method isn't a value you can just grab like this
```

Methods aren't values in the same way objects and numbers are — until Java 8 introduced lambdas and functional interfaces (which we covered), there was no concept of "a method as a thing you can pass around." `::` is the syntax Java added specifically to say: _"treat this method as a value — package it up as an instance of whatever functional interface is expected here."_

## What `::` compiles into

`X::method` is really just compact notation for a lambda:

```java
String::length
// means the same thing as:
str -> str.length()
```

```java
System.out::println
// means the same thing as:
x -> System.out.println(x)
```

```java
User::new
// means the same thing as:
name -> new User(name)
```

The compiler figures out the equivalent lambda based on the _target type_ — whatever functional interface the reference is being assigned to or passed into. Under the hood, both lambdas and method references are implemented the same way (via `invokedynamic` and a mechanism called `LambdaMetafactory`) — `::` is purely a **convenience syntax** on top of the same underlying machinery lambdas use.

## The four things that can appear on the right side of `::`

|Form|Example|Meaning|
|---|---|---|
|A static method name|`Integer::sum`|reference to a `static` method|
|An instance method name|`String::length` or `obj::method`|reference to a non-static method|
|The literal word `new`|`ArrayList::new`|reference to a constructor|

That last one is the only "special word" — `new` isn't a real method name, but `::new` is valid syntax specifically to mean "reference the constructor."

## Quick summary

- **Name:** method reference operator
- **Meaning:** "refer to this method/constructor, don't invoke it"
- **Left side:** a class name or an object
- **Right side:** a method name, or `new` for a constructor
- **Result:** an instance of whatever functional interface it's assigned to — functionally identical to writing the equivalent lambda by hand, just shorter


[[Java]]