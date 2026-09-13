

|Type|Meaning|Example SQL idea|
|---|---|---|
|**Overall Total**|Sum of **all rows** in the whole table|`SUM(sales) OVER()`|
|**Total per Group**|Sum of rows **per category/group**|`SUM(sales) OVER(PARTITION BY country)`|
|**Running Total**|Sum of **all rows up to current row**|`SUM(sales) OVER(ORDER BY date)`|
|**Rolling Total**|Sum of **a limited frame of rows** (e.g. last 3)|`SUM(sales) OVER(ORDER BY date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)`|

🐐 In short:

> Overall → everyone.  
> Per group → each team.  
> Running → everyone so far.  
> Rolling → just the recent few.

##### Tags : [[0 - Git 🍋‍🟩]]