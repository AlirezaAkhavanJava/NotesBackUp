
#  Splitting an Integer into Digits Using Streams in Java

Sometimes you want to **break a number into its individual digits**.  
For example:

- Input: `x = 78`
    
- Output: `[7, 8]`
    

A professional and concise way to do this in Java is:

```java
int[] split = String.valueOf(x)
                    .chars()
                    .map(c -> c - '0')
                    .toArray();
```

Let’s break this down step by step:

---

## 1. `String.valueOf(x)`

- Converts the integer into a string.
    
- Example: `78 → "78"`
    

---

## 2. `.chars()`

- Returns an **IntStream** of the characters’ Unicode values.
    
- Example: `"78".chars()` produces `[55, 56]` (because `'7'` = 55 and `'8'` = 56 in ASCII/Unicode).
    

---

## 3. `.map(c -> c - '0')`

- Each `c` is currently the Unicode value of a character.
    
- Subtracting `'0'` (which is 48 in ASCII) converts it into the real digit.
    

Example:

- `'7'` → `55 - 48 = 7`
    
- `'8'` → `56 - 48 = 8`
    

So we transform `[55, 56] → [7, 8]`.

---

## 4. `.toArray()`

- Collects the IntStream into a normal `int[]`.
    
- Result: `[7, 8]`
    

---

## ✅ Final Output

If `x = 78`, then `split = [7, 8]`.  
If `x = 12345`, then `split = [1, 2, 3, 4, 5]`.

---

## Why This Is Professional

- No loops, no manual parsing.
    
- Uses **Java Streams**, which are clean and expressive.
    
- Works for **any length of number**.
    

---

⚡ Quick Recap Formula:

```java
int[] digits = String.valueOf(x).chars().map(c -> c - '0').toArray();
```

---

Converting it to List

```java
int[] split = String.valueOf(x)  
        .chars().map(c -> c - '0')  
        .toArray();  
List<Integer> digits = 
	Arrays.stream(split).boxed().collect(Collectors.toList());
```


##### Tags : [[My mistakes in action]]