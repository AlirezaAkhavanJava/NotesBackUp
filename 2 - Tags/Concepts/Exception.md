

# Exception in Computer Science

An **exception** is an **event that interrupts the normal flow of a program because something unexpected or abnormal happened during execution**.

In simple terms:

> An exception is a signal from the running program that says: "I cannot continue normally; something needs to be handled."

---

## 1. Normal Program Flow

Normally, a program executes instructions sequentially:

```
Start
  |
  v
Read input
  |
  v
Process data
  |
  v
Save result
  |
  v
End
```

Example:

```java
int a = 10;
int b = 5;

int result = a / b;

System.out.println(result);
```

Output:

```
2
```

Nothing interrupts the flow.

---

# 2. When an Exception Happens

Example:

```java
int a = 10;
int b = 0;

int result = a / b;
```

Mathematically:

```
10 / 0
```

is undefined.

The JVM detects this problem and throws:

```
java.lang.ArithmeticException: / by zero
```

The normal flow stops:

```
Start
 |
 v
Divide numbers
 |
 X  <--- Exception occurs
 |
 v
Program stops
```

---

# 3. Exception vs Error

In computer science, failures are usually divided into:

```
Throwable
│
├── Exception
│     │
│     ├── Checked Exception
│     │
│     └── Runtime Exception
│
└── Error
```

(Java example)

---

## Exception

Usually a problem that a program **can recover from**.

Examples:

- File does not exist
    
- Network connection failed
    
- Invalid user input
    
- Database unavailable
    

Example:

```java
FileReader file = new FileReader("data.txt");
```

The file may not exist.

The program can handle it:

```
Try opening file
       |
       X
       |
File missing
       |
Create file / show message
```

---

## Error

Usually a serious problem that the application cannot reasonably recover from.

Examples:

```
OutOfMemoryError
StackOverflowError
```

Example:

```java
while(true) {
    new Object();
}
```

Eventually:

```
java.lang.OutOfMemoryError
```

The JVM has no memory left.

---

# 4. Exception Handling

Instead of crashing, programs can catch exceptions.

Java example:

```java
try {
    int result = 10 / 0;
}
catch (ArithmeticException e) {
    System.out.println("Cannot divide by zero");
}
```

Flow:

```
try block
    |
    |
exception occurs
    |
    v
catch block handles it
    |
    v
program continues
```

Output:

```
Cannot divide by zero
```

---

# 5. Why Exceptions Exist

Without exceptions:

```java
openFile();
readFile();
processFile();
```

If the file fails:

```
Program crashes
```

With exceptions:

```
openFile()
    |
    X
    |
catch failure
    |
use backup file
    |
continue
```

Exceptions provide:

### 1. Separation of normal logic and failure logic

Bad:

```java
if(fileExists){
    readFile();
}
else{
    showError();
}
```

Large programs become full of checks.

Better:

```java
try {
    readFile();
}
catch(FileNotFoundException e){
    showError();
}
```

---

### 2. Propagation

An exception can move upward through function calls.

Example:

```
main()
 |
 v
service()
 |
 v
repository()
 |
 v
database()
 |
 X
SQLException
```

The database layer throws an exception.

It travels upward:

```
database()
     |
     v
repository()
     |
     v
service()
     |
     v
controller()
```

A higher layer decides how to handle it.

This is common in Spring Boot:

```
Controller
     |
Service
     |
Repository
     |
Database
```

---

# 6. Exception Terminology

## Throw

Creating an exception:

```java
throw new IllegalArgumentException("Invalid age");
```

Meaning:

> "Something is wrong. Stop normal execution."

---

## Catch

Receiving an exception:

```java
catch(Exception e)
```

Meaning:

> "I know how to handle this problem."

---

## Stack Trace

A report showing where the exception happened.

Example:

```
ArithmeticException: / by zero

at Calculator.divide(Calculator.java:10)
at Main.main(Main.java:5)
```

It shows the call path:

```
main()
 |
Calculator.divide()
 |
error
```

---

# 7. Real World Analogy

Think of a restaurant.

Normal flow:

```
Customer orders
      |
Kitchen cooks
      |
Food served
```

Exception:

```
Customer orders steak
      |
Kitchen has no steak
      |
Exception: ingredient missing
```

Handling:

```
Offer chicken instead
```

The restaurant does not collapse; it handles the abnormal situation.

---

# 8. Computer Science Perspective

Exceptions are part of **control flow management**.

A program has two types of flow:

Normal flow:

```
A → B → C → D
```

Exceptional flow:

```
A → B → Exception → Handler → Recovery
```

Modern languages implement exceptions using mechanisms like:

- stack unwinding
    
- runtime metadata
    
- exception tables
    
- special CPU/runtime instructions
    

In Java, the JVM maintains information about where exception handlers exist and transfers execution when an exception is thrown.

---

# 9. Exceptions in Different Languages

### Java

```java
try {
}
catch(Exception e) {
}
```

---

### Python

```python
try:
    x = 10 / 0
except ZeroDivisionError:
    print("Error")
```

---

### C

C does not have built-in exceptions.

Usually uses:

- return values
    
- error codes
    
- `errno`
    

Example:

```c
if(file == NULL)
{
    printf("File error");
}
```

---

### C++

C++ has exceptions:

```cpp
try {
    throw runtime_error("failed");
}
catch(exception& e) {
}
```

---

# 10. In Backend Development (Spring Boot)

Exceptions are everywhere:

Example:

```
HTTP Request
      |
Controller
      |
Service
      |
Repository
      |
Database
      |
Exception
```

Common Spring exceptions:

```
EntityNotFoundException
DataAccessException
MethodArgumentNotValidException
AuthenticationException
```

Usually handled globally:

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<?> handle(EntityNotFoundException e){
        return ResponseEntity.notFound().build();
    }
}
```

Instead of:

```
500 Internal Server Error
```

the API returns:

```json
{
    "message": "User not found",
    "status": 404
}
```

---

## Mental Model

Think of an exception as:

```
Unexpected event
        |
        v
Interrupt normal execution
        |
        v
Create exception object
        |
        v
Search for handler
        |
        v
Recover or terminate
```

Exceptions are not "bugs"; they are a **mechanism for managing abnormal situations in software systems**. A bug may cause an exception, but exceptions themselves are a designed feature of programming languages.




[[Computer & Programming]]