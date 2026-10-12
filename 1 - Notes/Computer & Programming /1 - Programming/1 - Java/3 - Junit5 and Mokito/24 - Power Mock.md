


Below is a concise, practical guide to **testing private methods** in Java using **PowerMock** (or PowerMockito). PowerMock extends Mockito and EasyMock to handle statics, constructors, final classes, and — most relevant here — **private methods**.

> **Warning: Prefer testing through public API**  
> Private methods are implementation details. Testing them directly couples your tests to internals and makes refactoring harder. Use PowerMock *only* when:
> - The private method contains complex logic not exercised elsewhere.
> - You're maintaining legacy code without public exposure.
> - You're writing a narrow regression test.

---

## 1. Add Dependencies (Maven example)

```xml
<dependencies>
    <!-- JUnit 5 (or 4) -->
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter</artifactId>
        <version>5.10.2</version>
        <scope>test</scope>
    </dependency>

    <!-- Mockito Core -->
    <dependency>
        <groupId>org.mockito</groupId>
        <artifactId>mockito-core</artifactId>
        <version>5.12.0</version>
        <scope>test</scope>
    </dependency>

    <!-- PowerMock -->
    <dependency>
        <groupId>org.powermock</groupId>
        <artifactId>powermock-module-junit5</artifactId>
        <version>2.0.9</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.powermock</groupId>
        <artifactId>powermock-api-mockito2</artifactId>
        <version>2.0.9</version>
        <scope>test</scope>
    </dependency>
</dependencies>
```

> **Note**: PowerMock 2.x works with Mockito 2+. For newer Mockito 5, you may need `powermock-api-mockito5` when it stabilizes (as of 2025, 2.0.9 is the latest stable).

---

## 2. Example Class

```java
public class Calculator {
    public int add(int a, int b) {
        return a + b + secretBonus();
    }

    private int secretBonus() {
        return 42;
    }
}
```

---

## 3. Test Private Method with PowerMockito

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.powermock.api.mockito.PowerMockito;
import org.powermock.core.classloader.annotations.PrepareForTest;
import org.powermock.modules.junit5.PowerMockExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;

@ExtendWith(PowerMockExtension.class)
@PrepareForTest(Calculator.class)   // Required for spying on the class
class CalculatorTest {

    @Test
    void shouldInvokePrivateMethod() throws Exception {
        // 1. Create a real instance (or spy)
        Calculator calc = PowerMockito.spy(new Calculator());

        // 2. Stub the private method
        PowerMockito.when(calc, "secretBonus").thenReturn(100);

        // 3. Call public method that uses the private one
        int result = calc.add(2, 3);

        assertEquals(105, result); // 2 + 3 + 100
    }

    @Test
    void shouldInvokePrivateMethodDirectly() throws Exception {
        Calculator calc = PowerMockito.spy(new Calculator());

        // Directly invoke private method using PowerMockito
        int bonus = PowerMockito.invoke(
                calc,
                "secretBonus",
                new Class<?>[0],   // no parameter types
                new Object[0]     // no arguments
        );

        assertEquals(42, bonus);
    }
}
```

### Key Annotations
| Annotation | Purpose |
|------------|---------|
| `@PrepareForTest(Calculator.class)` | Tells PowerMock to bytecode-manipulate the class (needed for spying on non-static private methods) |
| `@ExtendWith(PowerMockExtension.class)` | JUnit 5 integration |

---

## 4. Alternative: Reflection (No PowerMock)

If you want to avoid PowerMock’s heavy bytecode manipulation:

```java
import java.lang.reflect.Method;

@Test
void testPrivateViaReflection() throws Exception {
    Calculator calc = new Calculator();

    Method method = Calculator.class.getDeclaredMethod("secretBonus");
    method.setAccessible(true);
    int bonus = (int) method.invoke(calc);

    assertEquals(42, bonus);
}
```

Pros: Lightweight  
Cons: Brittle to refactoring, no stubbing

---

## 5. Best Practices

1. **Prefer public API tests** → Extract logic to a protected/package-private method in a testable class.
2. **Use PowerMock sparingly** → It slows test startup and can conflict with coverage tools.
3. **Mock only when necessary** → Stub private method *only* to isolate complex logic.
4. **Document why** → Add a comment in the test explaining the need for private access.

---

## 6. Troubleshooting Tips

| Issue | Fix |
|-------|-----|
| `Invalid byte tag in constant pool` | Ensure `@PrepareForTest` includes the class under test |
| `Mockito cannot mock this class` | Add `PowerMockito.spy()` instead of `Mockito.spy()` |
| Test runs slow | PowerMock manipulates bytecode → run these tests in a separate suite |

---

### TL;DR Code Snippet (PowerMockito)

```java
Calculator calc = PowerMockito.spy(new Calculator());
PowerMockito.when(calc, "secretBonus").thenReturn(7);
assertEquals(12, calc.add(3, 2)); // 3+2+7
```




##### Tags : [[1 - Junit 5 🥭]]