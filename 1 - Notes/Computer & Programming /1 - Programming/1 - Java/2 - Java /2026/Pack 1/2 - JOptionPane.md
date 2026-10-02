`JOptionPane` is a class in Java's **Swing** library that provides an easy way to create **standard dialog boxes** for interacting with users. It can display messages, request input, or ask the user to make a choice without creating a custom window.

It belongs to the package:

```java
import javax.swing.JOptionPane;
```

### Common Uses of `JOptionPane`

1. **Show a Message**
    
    ```java
    import javax.swing.JOptionPane;
    
    public class Main {
        public static void main(String[] args) {
            JOptionPane.showMessageDialog(null, "Hello, World!");
        }
    }
    ```
    
    **Output:** A pop-up dialog displaying **"Hello, World!"**.
    
2. **Get User Input**
    
    ```java
    import javax.swing.JOptionPane;
    
    public class Main {
        public static void main(String[] args) {
            String name = JOptionPane.showInputDialog("Enter your name:");
            JOptionPane.showMessageDialog(null, "Hello, " + name);
        }
    }
    ```
    
3. **Show a Confirmation Dialog**
    
    ```java
    import javax.swing.JOptionPane;
    
    public class Main {
        public static void main(String[] args) {
            int choice = JOptionPane.showConfirmDialog(
                null,
                "Do you want to continue?"
            );
    
            if (choice == JOptionPane.YES_OPTION) {
                JOptionPane.showMessageDialog(null, "You clicked Yes.");
            } else {
                JOptionPane.showMessageDialog(null, "You did not click Yes.");
            }
        }
    }
    ```
    

### Common Methods

|Method|Purpose|
|---|---|
|`showMessageDialog()`|Displays a message to the user.|
|`showInputDialog()`|Prompts the user to enter text.|
|`showConfirmDialog()`|Asks the user to choose Yes, No, or Cancel.|
|`showOptionDialog()`|Creates a dialog with custom buttons and options.|

### Advantages

- Simple and quick to use.
    
- No need to create a full GUI window.
    
- Built into Java Swing.
    
- Useful for small desktop applications, notifications, and user prompts.
    

### Summary

`JOptionPane` is a Swing utility class used to create simple pop-up dialog boxes for:

- Displaying messages (`showMessageDialog`)
    
- Accepting user input (`showInputDialog`)
    
- Asking for confirmation (`showConfirmDialog`)
    
- Presenting custom options (`showOptionDialog`)

[[Java]]