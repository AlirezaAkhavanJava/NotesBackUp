### **Pagination**

Pagination is the process of **splitting a large dataset into smaller “pages”** so that you don’t load everything at once.

- Example: You have 10,000 students, but your UI shows **20 per page**.
    
- Page 1 → students 1–20
    
- Page 2 → students 21–40
    
- And so on…
    

**Why:**

- Improves performance
    
- Reduces memory usage
    
- Makes UI manageable
    

---

### **Pageable (Spring Data)**

`Pageable` is a **Spring Data interface** used to **represent pagination information**.  
It contains:

1. **Page number** (which page you want, starting at 0)
    
2. **Page size** (how many items per page)
    
3. **Sort information** (optional: sort by field, ascending/descending)
    

**Example:**

```java
@GetMapping("/students")
public Page<Students> getStudents(Pageable pageable) {
    return studentRepository.findAll(pageable);
}
```

**Usage:**

```java
Pageable pageable = PageRequest.of(0, 20, Sort.by("mark").descending());
Page<Students> page = studentRepository.findAll(pageable);
```

- `0` → page number (first page)
    
- `20` → page size
    
- `Sort.by("mark").descending()` → sort by mark descending
    

`Page<Students>` contains:

- The list of students for that page
    
- Total pages
    
- Total elements
    
- Whether it’s first/last page
    

---

In short:

- **Pagination** = the concept of splitting results into pages
    
- **Pageable** = Spring’s way to define page number, size, and sorting
    

---



##### Tags : [[0 - Spring Framework]]