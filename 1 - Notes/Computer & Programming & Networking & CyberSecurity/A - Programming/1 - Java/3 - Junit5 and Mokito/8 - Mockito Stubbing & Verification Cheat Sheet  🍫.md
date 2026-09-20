

All the core methods you need for mocking in one scrollable block.

```java
import static org.mockito.Mockito.*;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import java.util.List;

class MockitoCheatSheet {

    @Test
    void cheatSheet() {
        // ======================
        // 1️⃣ Create a Mock
        // ======================
        List<String> mockList = mock(List.class); // fake object

        // ======================
        // 2️⃣ Stubbing with when()
        // ======================
        when(mockList.get(0)).thenReturn("Hello");   // return value
        when(mockList.get(1)).thenThrow(new RuntimeException("Nope")); // exception

        assertEquals("Hello", mockList.get(0));
        assertThrows(RuntimeException.class, () -> mockList.get(1));

        // ======================
        // 3️⃣ Chaining Stubs
        // ======================
        when(mockList.size()).thenReturn(1).thenReturn(2); // first call 1, next call 2
        assertEquals(1, mockList.size());
        assertEquals(2, mockList.size());

        // ======================
        // 4️⃣ Spying (partial mock)
        // ======================
        List<String> realList = new java.util.ArrayList<>();
        List<String> spyList = spy(realList);

        spyList.add("Hi");
        doReturn(100).when(spyList).size();  // override size method

        assertEquals(100, spyList.size());
        verify(spyList).add("Hi");           // real method still called

        // ======================
        // 5️⃣ Void Methods
        // ======================
        doNothing().when(mockList).clear();   // do nothing on clear()
        mockList.clear();
        verify(mockList).clear();

        doThrow(new RuntimeException("Oops")).when(mockList).clear(); // throw exception on void
        assertThrows(RuntimeException.class, () -> mockList.clear());

        // ======================
        // 6️⃣ Verify Interactions
        // ======================
        mockList.add("A");
        mockList.add("B");

        verify(mockList).add("A");            // called once
        verify(mockList, times(2)).add(anyString()); // called 2 times
        verify(mockList, never()).remove(any());     // never called

        // ======================
        // 7️⃣ Argument Matchers
        // ======================
        when(mockList.get(anyInt())).thenReturn("X");
        assertEquals("X", mockList.get(0));
        assertEquals("X", mockList.get(999));

        verify(mockList, atLeastOnce()).get(anyInt());
    }
}
```

✅ **Quick Notes:**

- `mock()` → create fake objects.
    
- `when(...).thenReturn(...)` → define behavior.
    
- `when(...).thenThrow(...)` → throw exception.
    
- `doNothing()/doThrow()` → use for void methods.
    
- `spy()` → wrap a real object, selectively override.
    
- `verify()` → check method calls.
    
- Argument matchers → `any()`, `anyInt()`, `anyString()`.
    

---

##### Tags : [[1 - Junit 5 🥭]]