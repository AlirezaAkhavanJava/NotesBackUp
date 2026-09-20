
In **Spring**, `@ResponseBody` tells Spring that the **return value of a method should be written directly to the HTTP response body** (instead of being interpreted as a view name).

Basically: it’s how you return **raw data** (JSON, XML, text, etc.) from a controller.

Example:

```java
@RestController
public class EmployeeController {

    @GetMapping("/employee/{id}")
    @ResponseBody
    public Employee getEmployee(@PathVariable Long id) {
        // The Employee object will be converted to JSON automatically
        return employeeService.findById(id);
    }
}
```

Key points:

- `@RestController` **already includes `@ResponseBody`**, so you don’t need it on each method.
    
- Without `@ResponseBody`, Spring would try to find a **view template** with the name of the returned object.
    

⚡ Tip: Use `@ResponseBody` when you **only want raw data**, not HTML pages.


##### Tags : [[0 - Spring Framework]]