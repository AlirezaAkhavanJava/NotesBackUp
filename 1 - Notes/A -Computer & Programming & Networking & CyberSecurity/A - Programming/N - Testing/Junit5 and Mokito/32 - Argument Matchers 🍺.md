
## 🧩 1️⃣ What Are Argument Matchers?

When verifying or stubbing mocks in Mockito, **argument matchers** let you specify _flexible_ conditions for method parameters, instead of exact values.

For example:

```java
when(repo.findById(anyLong())).thenReturn(user);
```

Here, `anyLong()` is a matcher — it matches _any long value_ passed to the method.

✅ You use them:

- In `when(...)` stubbings
    
- In `verify(...)` verifications
    

📦 Package:

```java
import static org.mockito.ArgumentMatchers.*;
```

---

## 🧩 2️⃣ Why We Need Matchers

Without matchers, Mockito uses **exact value comparison**:

```java
when(repo.findById(1L)).thenReturn(user);
```

That only works for **1L**.  
If the code calls `repo.findById(2L)`, the stub won’t match.

Using a matcher:

```java
when(repo.findById(anyLong())).thenReturn(user);
```

… makes it **flexible** and **less brittle**.

---

## 🧩 3️⃣ ⚠️ Matcher Rules (Important!)

|Rule|Explanation|
|---|---|
|**1. Use matchers consistently**|If you use _one_ matcher, you must use matchers for _all_ parameters of that method.|
|**2. Matchers are not actual values**|You can’t assign them to variables or print them.|
|**3. Don’t mix real values with matchers**|This will cause: `Invalid use of argument matchers`.|

✅ Correct:

```java
verify(service).save(any(), anyBoolean());
```

❌ Incorrect:

```java
verify(service).save(new User("Ethan"), anyBoolean()); // ❌ mixed
```

---

## 🧩 4️⃣ Core Matchers (The “any” family)

These match **any value** of the given type.

|Matcher|Matches|Example|
|---|---|---|
|`any()`|Any object (any type)|`any()`|
|`anyString()`|Any String|`when(repo.find(anyString()))`|
|`anyInt()`|Any int|`when(calc.add(anyInt(), anyInt()))`|
|`anyLong()`|Any long|`verify(repo).findById(anyLong())`|
|`anyDouble()`|Any double|`when(math.pow(anyDouble(), anyDouble()))`|
|`anyBoolean()`|Any boolean|`verify(flagSetter).set(anyBoolean())`|
|`anyList()`|Any List|`when(service.process(anyList()))`|
|`anyMap()`|Any Map|`when(service.parse(anyMap()))`|
|`anySet()`|Any Set|`when(service.join(anySet()))`|
|`anyCollection()`|Any Collection|`verify(repo).saveAll(anyCollection())`|
|`any(Class<T>)`|Any object of given class|`any(User.class)`|

📘 Example:

```java
when(userService.createUser(anyString(), anyInt())).thenReturn(true);
verify(repo).save(any(User.class));
```

---

## 🧩 5️⃣ Equality Matchers (The “eq” family)

Use these when you need to match **exact values**.

|Matcher|Description|Example|
|---|---|---|
|`eq(value)`|Matches if equal to `value`|`eq("Ethan")`, `eq(5L)`|
|`same(value)`|Matches the **same instance** (object identity)|`same(user)`|
|`refEq(value)`|Matches if fields are equal (deep comparison)|`refEq(expectedUser)`|

📘 Example:

```java
verify(repo).save(eq(new User("Ethan")));  // compares using equals()
verify(repo).save(same(existingUser));     // compares object identity
```

🧠 Use `refEq()` when comparing objects with many fields, and you don’t want to write `equals()`.

---

## 🧩 6️⃣ Null Matchers

|Matcher|Description|Example|
|---|---|---|
|`isNull()`|Matches `null`|`verify(repo).save(isNull())`|
|`isNotNull()`|Matches non-null values|`verify(repo).save(isNotNull())`|
|`nullable(Class<T>)`|Matches null or instance of class|`verify(repo).save(nullable(User.class))`|

📘 Example:

```java
when(repo.save(isNull())).thenThrow(new NullPointerException());
```

---

## 🧩 7️⃣ String Matchers

|Matcher|Description|Example|
|---|---|---|
|`contains("text")`|Argument containing text|`verify(log).info(contains("error"))`|
|`startsWith("prefix")`|Argument starts with prefix|`verify(log).warn(startsWith("WARN"))`|
|`endsWith("suffix")`|Argument ends with suffix|`verify(log).error(endsWith(".txt"))`|
|`matches("regex")`|Matches regex pattern|`verify(repo).find(matches("[a-z]+"))`|

📘 Example:

```java
verify(log).info(contains("Ethan"));
verify(log).error(matches("Error.*404"));
```

---

## 🧩 8️⃣ Number Matchers

Mockito doesn’t have built-in numeric range matchers — but you can use **custom argument matchers** (next section).  
However, you can combine matchers like this:

```java
verify(calc).multiply(eq(5), anyInt());
```

---

## 🧩 9️⃣ Custom Matchers with `argThat()`

When built-ins aren’t enough, define custom logic with a lambda or predicate.

📘 Example:

```java
verify(repo).save(argThat(user -> user.getName().startsWith("E")));
```

You can also combine with assert-like logic:

```java
verify(repo).save(argThat(user -> {
    assertThat(user.getAge()).isBetween(18, 30);
    return true;
}));
```

🧠 `argThat()` returns `true` if your condition passes — otherwise it fails matching.

---

## 🧩 🔟 Combining Matchers

You can use multiple matchers in the same call — just remember the “matcher consistency” rule.

📘 Example:

```java
verify(repo).save(any(User.class), eq(true));
```

✅ All arguments either:

- use matchers (`any()`, `eq()`), or
    
- use real values (no matchers at all).
    

---

## 🧩 11️⃣ Argument Matchers with `verify()`

`verify()` confirms the mock method was called with certain arguments.

Example:

```java
verify(repo).save(eq(new User("Ethan")));
verify(repo).findById(anyLong());
verify(repo, times(2)).save(any(User.class));
```

🧠 You can also combine `verify()` with `ArgumentCaptor`:

```java
verify(repo).save(captor.capture());
assertThat(captor.getValue().getName()).isEqualTo("Ethan");
```

---

## 🧩 12️⃣ Argument Matchers with `when()`

Use them to stub flexible responses:

```java
when(repo.findByName(anyString())).thenReturn(user);
when(repo.findById(eq(1L))).thenThrow(new RuntimeException());
```

Mockito will apply the stub when _any_ matching argument is passed.

---

## 🧩 13️⃣ BDDMockito Style (then / given)

Same logic, BDD syntax:

```java
given(repo.findById(anyLong())).willReturn(user);
then(repo).should().save(any(User.class));
```

---

## 🧩 14️⃣ Advanced: Argument Matchers for Collections

|Matcher|Example|
|---|---|
|`anyList()`|`verify(service).process(anyList())`|
|`argThat(list -> list.size() == 3)`|Custom match|
|`argThat(map -> map.containsKey("id"))`|Custom match for Map|

📘 Example:

```java
verify(service).process(argThat(list ->
    list.contains("Ethan") && list.size() == 2
));
```

---

## 🧩 15️⃣ Common Mistakes & Fixes

|Mistake|Cause|Fix|
|---|---|---|
|❌ `Invalid use of argument matchers`|Mixing matchers with real values|Use matchers for all parameters|
|❌ `Wanted but not invoked`|Method never called|Ensure your test actually triggers the mock|
|❌ `NullPointerException`|Using matcher outside verify/when|Matchers only valid _inside_ Mockito calls|
|❌ Wrong matching|Custom `argThat()` logic returns false|Return true for success conditions|

---

## 🧩 16️⃣ Example Summary Table

|Matcher|Description|Example|
|---|---|---|
|`any()`|Any object|`any()`|
|`anyInt()`|Any int|`anyInt()`|
|`anyString()`|Any String|`anyString()`|
|`anyList()`|Any List|`anyList()`|
|`eq(value)`|Equal to value|`eq(5)`|
|`same(obj)`|Same instance|`same(user)`|
|`refEq(obj)`|Equal fields|`refEq(user)`|
|`isNull()`|Is null|`isNull()`|
|`isNotNull()`|Not null|`isNotNull()`|
|`nullable(Class)`|Null or class instance|`nullable(User.class)`|
|`contains("x")`|String contains|`contains("Ethan")`|
|`startsWith("x")`|String starts with|`startsWith("Err")`|
|`endsWith("x")`|String ends with|`endsWith(".txt")`|
|`matches("regex")`|Regex match|`matches("\\d+")`|
|`argThat()`|Custom predicate|`argThat(u -> u.getAge() > 18)`|

---

## 🧩 17️⃣ Example: Combine Matchers + Captor + AssertJ

```java
verify(repo).save(argThat(user ->
    user.getName().startsWith("E") && user.getAge() > 18
));
```

Or with `ArgumentCaptor`:

```java
verify(repo).save(captor.capture());
assertThat(captor.getValue())
    .extracting(User::getName)
    .isEqualTo("Ethan");
```

---

## 🧠 Final Recap

|Concept|Description|
|---|---|
|**Matchers**|Allow flexible argument verification or stubbing|
|**Key Types**|`any*()`, `eq()`, `isNull()`, `argThat()`|
|**Rule**|Don’t mix matchers with real values|
|**Use Cases**|Used inside `when()` and `verify()`|
|**Advanced**|Combine with `ArgumentCaptor`, custom lambdas, AssertJ|
|**BDD**|Same matchers apply to `given()` and `then()`|


##### Tags : [[1 - Junit 5 🥭]]