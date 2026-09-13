

## 🧱 **1. BASIC LEVEL**

### 🔹 Definition

**Numeric functions** perform mathematical or statistical operations on numeric data types.  
They work with:

- `INT`, `BIGINT`, `DECIMAL`, `NUMERIC`, `FLOAT`, `REAL`, `DOUBLE PRECISION`
    

---

### 🔹 Common Basic Numeric Functions

|Function|Description|Example|Output|
|---|---|---|---|
|`ABS(x)`|Absolute value|`ABS(-5)`|`5`|
|`CEIL(x)` / `CEILING(x)`|Round **up**|`CEIL(2.1)`|`3`|
|`FLOOR(x)`|Round **down**|`FLOOR(2.9)`|`2`|
|`ROUND(x[,d])`|Round to nearest integer or decimal places|`ROUND(12.345,2)`|`12.35`|
|`POWER(x,y)`|x raised to power y|`POWER(2,3)`|`8`|
|`SQRT(x)`|Square root|`SQRT(9)`|`3`|
|`SIGN(x)`|Returns -1, 0, or 1 depending on sign|`SIGN(-5)`|`-1`|

---

### 🔹 Example

```sql
SELECT salary, ROUND(salary * 1.05, 2) AS increased_salary
FROM employees;
```

---

## ⚙️ **2. INTERMEDIATE LEVEL**

### 🔹 Trigonometric Functions

|Function|Description|Example|Output|
|---|---|---|---|
|`SIN(x)`|Sine of angle (radians)|`SIN(PI()/2)`|`1`|
|`COS(x)`|Cosine|`COS(PI())`|`-1`|
|`TAN(x)`|Tangent|`TAN(PI()/4)`|`1`|
|`ASIN(x)`|Arc sine|`ASIN(1)`|`1.570796`|
|`ACOS(x)`|Arc cosine|`ACOS(0)`|`1.570796`|
|`ATAN(x)`|Arc tangent|`ATAN(1)`|`0.785398`|
|`ATAN2(y,x)`|Arc tangent of y/x (handles sign correctly)|`ATAN2(2,2)`|`0.785398`|

---

### 🔹 Exponential & Logarithmic Functions

|Function|Description|Example|Output|
|---|---|---|---|
|`EXP(x)`|e^x (exponential)|`EXP(1)`|`2.71828`|
|`LN(x)`|Natural logarithm|`LN(2.71828)`|`1`|
|`LOG(x)`|Same as `LN(x)`|`LOG(10)`|`2.302585`|
|`LOG(base, x)`|Logarithm to custom base|`LOG(10,100)`|`2`|

---

### 🔹 Random & Modulo

|Function|Description|Example|Output|
|---|---|---|---|
|`RANDOM()`|Random float between 0 and 1|`RANDOM()`|`0.5342...`|
|`SETSEED(x)`|Sets random seed (-1 to 1)|`SETSEED(0.5)`|`OK`|
|`MOD(x, y)`|Modulus (remainder)|`MOD(10,3)`|`1`|

---

### 🔹 Numeric Conversion

|Function|Description|Example|Output|
|---|---|---|---|
|`CAST(x AS type)`|Convert numeric type|`CAST(12.7 AS INT)`|`12`|
|`::`|Short form|`12.7::INT`|`12`|

---

## 🧠 **3. ADVANCED LEVEL (PostgreSQL-Specific)**

### 🔹 Mathematical Constants

|Constant|Description|Example|
|---|---|---|
|`PI()`|π = 3.141592653589793|`SELECT PI();`|
|`E()`|Euler’s number (e = 2.7182818)|`SELECT EXP(1);`|

---

### 🔹 Statistical / Aggregate Functions

|Function|Description|Example|
|---|---|---|
|`AVG(x)`|Average|`AVG(salary)`|
|`SUM(x)`|Sum|`SUM(price)`|
|`MIN(x)` / `MAX(x)`|Minimum / Maximum|`MIN(age)`|
|`STDDEV(x)`|Standard deviation|`STDDEV(salary)`|
|`VARIANCE(x)`|Variance|`VARIANCE(salary)`|

---

### 🔹 Rounding Behavior Rules

PostgreSQL supports multiple rounding methods:

|Function|Behavior|Example|Output|
|---|---|---|---|
|`ROUND(12.5)`|Round to nearest even|`ROUND(12.5)`|`12`|
|`TRUNC(12.9)`|Truncate (no rounding)|`TRUNC(12.9)`|`12`|
|`CEIL(12.1)`|Always up|`13`||
|`FLOOR(12.9)`|Always down|`12`||

---

### 🔹 Combined / Nested Numeric Functions

You can **nest** numeric functions like:

```sql
SELECT ROUND(SQRT(POWER(3,2) + POWER(4,2)),2);
-- Calculates sqrt(3² + 4²) = 5.00
```

Or even use with aggregates:

```sql
SELECT ROUND(AVG(salary),2) FROM employees;
```

---

## ⚔️ **4. RULES & PITFALLS**

|Rule|Explanation|
|---|---|
|🧩 **Type compatibility**|Use numeric functions only with numeric types, or cast explicitly.|
|⚠ **Division behavior**|Integer division truncates results: `3/2 = 1`. Use decimals: `3.0/2 = 1.5`.|
|🚫 **NULL propagation**|`ABS(NULL)` → `NULL`. Use `COALESCE` if needed.|
|🎯 **Order of execution**|Inner functions (in nested calls) run first.|
|💡 **Precision**|Use `NUMERIC(p,s)` for financial data to avoid float rounding errors.|
|🔒 **Performance**|Avoid overusing complex nested math in SELECT for huge tables — precompute if possible.|
|🎲 **Random reproducibility**|Use `SETSEED()` before `RANDOM()` for reproducible randoms.|

---

## 🚀 **5. REAL-WORLD USE CASES**

1. **Salary Adjustment**
    

```sql
SELECT employee_id, ROUND(salary * 1.07, 2) AS adjusted_salary FROM employees;
```

2. **Distance Formula**
    

```sql
SELECT SQRT(POWER(x2-x1,2) + POWER(y2-y1,2)) AS distance FROM coordinates;
```

3. **Normalize Scores**
    

```sql
SELECT (score - MIN(score) OVER()) / (MAX(score) OVER() - MIN(score) OVER()) AS normalized FROM test_results;
```

4. **Random Sampling**
    

```sql
SELECT * FROM users ORDER BY RANDOM() LIMIT 10;
```

5. **Statistical Reporting**
    

```sql
SELECT ROUND(AVG(salary),2), STDDEV(salary), VARIANCE(salary) FROM employees;
```

---

## 📋 **6. Quick Cheat Sheet**

|Category|Function|Example|
|---|---|---|
|Basic Math|`ABS`, `ROUND`, `CEIL`, `FLOOR`, `SIGN`, `POWER`, `SQRT`|`ROUND(POWER(2,3),2)`|
|Trig|`SIN`, `COS`, `TAN`, `ASIN`, `ACOS`, `ATAN`, `ATAN2`|`SIN(PI()/2)`|
|Log/Exp|`EXP`, `LN`, `LOG`, `LOG(base,x)`|`LOG(10,100)`|
|Random|`RANDOM`, `SETSEED`|`RANDOM()`|
|Modulo|`MOD`|`MOD(10,3)`|
|Aggregates|`AVG`, `SUM`, `MIN`, `MAX`, `STDDEV`, `VARIANCE`|`AVG(salary)`|
|Conversion|`CAST`, `::`|`'12.3'::NUMERIC`|

---

🐐 **Mental model:**  
Numeric functions are your **math toolbox** — from simple rounding to full-on trigonometry and statistics.  
They power **calculations, analytics, and transformations** on numeric data.

---


### Tags : [[1 - SQL 🥞]]