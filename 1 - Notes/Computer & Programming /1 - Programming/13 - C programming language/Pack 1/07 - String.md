In **C**, a string is an array of characters ending with a special null character `'\0'`.

```c
#include <stdio.h>

int main(void) {
    char str[] = "Hello";

    printf("%s\n", str);
    return 0;
}
```

Here, `"Hello"` is stored as:

```text
'H' 'e' 'l' 'l' 'o' '\0'
```

You can declare strings in several ways:

```c
char str1[] = "Hello";
char str2[20] = "Hello";
char *str3 = "Hello";
```

For common string operations such as `strlen()`, `strcpy()`, `strcmp()`, and `strcat()`, include:

```c
#include <string.h>
```

---





[[C]]
[[CS 50]]