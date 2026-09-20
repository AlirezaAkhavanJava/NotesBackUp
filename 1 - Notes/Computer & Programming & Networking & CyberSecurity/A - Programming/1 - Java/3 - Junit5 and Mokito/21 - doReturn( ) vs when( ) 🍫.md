Both `doReturn()` and `when()` are used for stubbing method calls in Mockito, but they serve different purposes and have important distinctions.

## `when()` - The Standard Approach

`when()` is the most commonly used method for stubbing in Mockito:

```java
// Standard when() syntax
when(mockList.get(0)).thenReturn("first element");
when(mockList.size()).thenReturn(10);
when(mockService.process(anyString())).thenReturn(true);

// Using with exceptions
when(mockRepository.findById(1L)).thenThrow(new RuntimeException("Not found"));

// Using with multiple return values
when(mockGenerator.nextInt()).thenReturn(1, 2, 3, 4);
```

## `doReturn()` - The Alternative Approach

`doReturn()` is used in specific scenarios where `when()` doesn't work:

```java
// doReturn() syntax
doReturn("value").when(mockList).get(0);
doReturn(10).when(mockList).size();
doReturn(true).when(mockService).process(anyString());
```

## Key Differences

### 1. **Exception Handling**
```java
List<String> spyList = spy(new ArrayList<>());

// This would call real method and might throw exception
// when(spyList.get(0)).thenReturn("first"); // Could throw IndexOutOfBoundsException

// This is safe - doesn't call real method
doReturn("first").when(spyList).get(0);
```

### 2. **Void Methods**
```java
// For void methods, you MUST use doThrow/doAnswer/doNothing
doThrow(new RuntimeException()).when(mockList).clear();
doNothing().when(mockList).add(anyString());
```

### 3. **Spy Objects**
```java
List<String> realList = new ArrayList<>();
List<String> spyList = spy(realList);

// This would call the real add method (side effect)
// when(spyList.size()).thenReturn(100);

// This stubs without calling real method
doReturn(100).when(spyList).size();
```

## When to Use Which

### Use `when()` for:
- Most common stubbing scenarios
- Non-void methods on regular mocks
- Situations where you want readable, fluent syntax

```java
// Preferred for regular mocking
when(userService.findUser(1L)).thenReturn(new User("John"));
```

### Use `doReturn()` for:
- Stubbing methods on **spy objects**
- **Overriding** existing stubbing
- When the real method might throw exceptions
- Working with **final methods** (with certain Mockito configurations)

```java
List<String> spyList = spy(Arrays.asList("a", "b"));

// Safe stubbing on spy
doReturn("overridden").when(spyList).get(0);
```

## Complete Example

```java
@Test
public void testWhenVsDoReturn() {
    // Regular mock
    List<String> mockList = mock(List.class);
    
    // Standard approach
    when(mockList.get(0)).thenReturn("first");
    
    // Spy example
    List<String> realList = new ArrayList<>();
    realList.add("real");
    List<String> spyList = spy(realList);
    
    // This would call real method and might fail
    // when(spyList.get(1)).thenReturn("second"); // Index 1 doesn't exist
    
    // This is safe
    doReturn("second").when(spyList).get(1);
    
    // Void method stubbing
    doThrow(RuntimeException.class).when(mockList).clear();
    
    assertEquals("first", mockList.get(0));
    assertEquals("second", spyList.get(1));
}
```

## Best Practices

1. **Prefer `when()`** for regular mocking - it's more readable
2. **Use `doReturn()`** when working with spies
3. **Always use `doThrow/doAnswer/doNothing`** for void methods
4. Use `doReturn()` when you need to **override** previous stubbing

```java
// Overriding example
when(mock.getData()).thenReturn("first");
// Later in test...
doReturn("overridden").when(mock).getData();
```

The choice depends on your specific use case, but `when()` should be your default choice for most scenarios.
##### Tags : [[1 - Junit 5 🥭]]