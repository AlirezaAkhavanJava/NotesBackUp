

---
![[CPU-Components-.webp]]
## **1. Basic CPU Components**

A CPU (Central Processing Unit) is basically a **data-processing engine**. Its main components:

1. **Control Unit (CU):**
    
    - Directs the flow of data and instructions.
        
    - Decides which instruction to execute next.
        
2. **Arithmetic Logic Unit (ALU):**
    
    - Performs all **arithmetic** (add, subtract) and **logic operations** (AND, OR, comparisons).
        
3. **Registers:**
    
    - Tiny, ultra-fast storage inside the CPU.
        
    - Hold temporary data like instruction counters, operands, and results.
        
4. **Cache Memory:**
    
    - Small, fast memory close to cores for quick access to frequently used data.
        
    - **L1:** per core, fastest, very small.
        
    - **L2:** per core, bigger, slower.
        
    - **L3:** shared among cores, slower than L1/L2 but still much faster than RAM.
        
5. **Buses & Interconnects:**
    
    - Channels for **data movement** between CPU, memory, and peripherals.
        
    - Includes **system bus**, **cache coherency interconnect**, etc.
        

---

## **2. CPU Cores**

- **Single-core:** one execution unit — only one instruction at a time.
    
- **Multi-core:** multiple cores in one CPU — multiple instructions **can execute in parallel**.
    
- **Hyperthreading / SMT:** one physical core maintains **two logical threads**, sharing execution units to improve utilization.
    

---

## **3. Instruction Pipeline**

CPUs don’t execute one instruction start-to-finish sequentially. They use **pipelining**:

1. **Fetch** – get instruction from memory.
    
2. **Decode** – understand the instruction.
    
3. **Execute** – run the instruction in ALU/FPU.
    
4. **Memory Access** – read/write memory if needed.
    
5. **Write Back** – store result in register/cache.
    

- Multiple instructions are **in different stages simultaneously** → increases throughput.
    

---

## **4. Memory Hierarchy & Inter-Core Communication**

- Registers → L1 → L2 → L3 → RAM → Storage (slowest).
    
- **Cache coherency protocols** (MESI/MOESI) ensure multiple cores have a **consistent view of memory**.
    
- Shared caches and interconnects are key for multi-core CPUs to communicate efficiently.
    

---

## **5. CPU Task Types**

- **CPU-bound:** intensive calculations, benefit from **parallel cores**, limited by execution units.
    
- **I/O-bound:** waiting for external resources, benefit from **virtual threads**, less CPU intensive.
    

---

✅ **Key Takeaways**

- Modern CPUs are **multi-core, pipelined, and heavily cached**.
    
- Hyperthreading improves **utilization**, not raw parallelism.
    
- CPU design balances **speed (ALU, pipelines)**, **memory access (caches)**, and **multi-threading (cores + SMT)**.
    

---

![[CPU-Cache-new.webp]]



### **What cache is**

- Cache is **super-fast memory inside the CPU**.
    
- It stores **copies of data that the CPU uses frequently** so the CPU doesn’t have to wait for slower main memory (RAM).
    

---

### **How it works**

1. **CPU needs data** → looks in **L1 cache** first (smallest, fastest).
    
2. If not found → checks **L2 cache** (bigger, slower).
    
3. If still not found → checks **L3 cache** (shared among cores, bigger/slower).
    
4. If not in any cache → goes to **RAM** (slowest).
    

✅ This is called the **memory hierarchy**: fast but small → slower but bigger → slowest but huge.

---

### **Cache in action (example)**

- CPU needs variable `x`.
    
- **Step 1:** Check L1 → found → use it instantly.
    
- **Step 2:** Not in L1 → check L2 → found → copy to L1, then use.
    
- **Step 3:** Not in L1/L2 → check L3 → copy to L2 & L1, then use.
    
- **Step 4:** Not in cache → fetch from RAM → store in L3/L2/L1 → use.
    
- The **goal**: most of the time, the CPU finds data in cache → avoids slow RAM access.
    

---

### **Extra tip**

- Multi-core CPUs have **private L1/L2 caches per core** and a **shared L3**.
    
- Cache also helps **cores communicate quickly** and **maintain memory consistency**.



CPU cache sizes vary by level and CPU model:

|Cache Level|Size (typical)|Notes|
|---|---|---|
|**L1**|32–128 KB per core|Very small, extremely fast, stores instructions + data for immediate use|
|**L2**|256 KB – 2 MB per core|Bigger, slower than L1, private to each core|
|**L3**|2 – 128 MB shared|Shared among cores, slower than L1/L2 but still faster than RAM|

- Example: **AMD Ryzen 9 9900X3D**
    
    - L1: 768 KB total (~64 KB per core × 12 cores)
        
    - L2: 6 MB total (512 KB per core × 12 cores)
        
    - L3: 64 MB shared
        

> So **CPU cache is tiny compared to RAM**, but **extremely fast**, and that’s why it matters so much for performance.

- **Cache stores a “copy” of data** from main memory, but it doesn’t usually store huge amounts — it stores **small chunks called cache lines** (typically 64 bytes each).
    
- When the CPU requests a large dataset:
    
    1. Cache fetches **the part it needs first** (the cache line containing that data).
        
    2. Subsequent nearby data accesses are often already in cache (this is called **spatial locality**).
        
- So even if the total data is “big” (megabytes or gigabytes), only **small pieces are loaded into cache at a time**, and the CPU works on those pieces extremely fast.
    

✅ Key idea: **Cache doesn’t hold the whole memory; it holds the “hot” parts** the CPU is using right now.




### **1. Cache Basics**

- Cache is a **small, very fast memory** that stores copies of data from **main memory (RAM)**.
    
- CPU caches are divided into **lines** (or blocks), usually **64 bytes each**.
    
- Each line stores:
    
    1. **The data** itself (64 bytes from RAM)
        
    2. **Tag / address info** – tells the CPU which part of RAM this line came from
        
    3. **Metadata** – like validity bit, dirty bit (if modified), etc.
        

---

### **2. Cache Organization**

1. **Direct-mapped cache**
    
    - Each memory block can go to **exactly one cache line**.
        
    - Fast, but high chance of conflicts.
        
2. **Fully associative cache**
    
    - Any memory block can go in **any cache line**.
        
    - Flexible, less conflicts, but slower to search.
        
3. **Set-associative cache (common in modern CPUs)**
    
    - Compromise: cache is divided into **sets**, each set has multiple lines.
        
    - Memory block maps to a **set**, but can go in **any line inside that set**.
        
    - Balances speed and flexibility.
        

---

### **3. How data is saved**

When CPU accesses memory:

1. Check **L1 cache**:
    
    - If line with needed address exists → **cache hit**, use it.
        
    - If not → **cache miss**, go to L2/L3 or RAM.
        
2. On **cache miss**:
    
    - Fetch memory block (64 bytes) from lower memory level.
        
    - Store it in **cache line**, updating tag and metadata.
        
3. If data is modified:
    
    - **Write-through:** update cache **and** RAM immediately.
        
    - **Write-back:** update cache only; mark line as “dirty”; RAM updated later.
        

---

### ✅ **Summary**

- Each cache saves **small chunks of memory (cache lines)**, not full variables or huge arrays.
    
- Each line has **data + tag + metadata**.
    
- Modern CPUs use **set-associative caches** with **write-back** and **write-allocate** policies.
    

---



[[Computer & Programming & Networking & CyberSecurity]]

