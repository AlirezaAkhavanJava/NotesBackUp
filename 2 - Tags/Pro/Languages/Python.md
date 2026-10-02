**Python** is a high-level, interpreted, general-purpose programming language designed to be readable. It is the most popular language for scripting, data science, AI, and automation, and it is also widely used for back-ends.

**Analogy:** If C is a manual car with no safety systems, and Java is an automatic car with airbags, Python is a **taxi**: you say where you want to go, and someone else handles nearly all the driving details. It is slower than the other two, but you get there with far less effort.

## Core idea

Python's philosophy is that code should be read by humans first. There are no semicolons, no curly braces, and no type declarations. **Indentation is the syntax**: it defines blocks.

```python
def greet(name):
    if name:
        return f"Hello, {name}!"
    return "Hello, stranger!"

print(greet("Alireza"))
```

The same task in Java needs a class, a `main` method, type declarations, and a compile step. Python needs none of that.

## How it runs

```
C:       source -> machine code -> CPU
Java:    source -> bytecode -> JVM -> CPU
Python:  source -> bytecode -> Python interpreter (CPython) -> CPU
```

Python is **interpreted**: there is no separate compile step you run yourself. CPython (the standard implementation, written in C, as you saw in the C lesson) compiles your code to bytecode internally and executes it line by line. This makes it easy to experiment, but slower than Java or C.

## Dynamic typing

Variables have no declared type; the **value** has the type.

```python
x = 5          # int
x = "hello"    # now a str, and that's allowed
```

Compare to Java, where `int x = 5; x = "hello";` fails at compile time. Python only discovers type errors **while running**, the same trade-off you saw with JavaScript. Modern Python supports optional **type hints** (`def add(a: int, b: int) -> int`) that tools like `mypy` can check, similar in spirit to what TypeScript does for JS.

## Everything is an object, and built-ins are powerful

```python
books = ["Clean Code", "SICP"]            # list (like ArrayList)
ages = {"sam": 30, "lea": 25}             # dict (like HashMap)
unique = {1, 2, 2, 3}                     # set -> {1, 2, 3}

titles = [b.upper() for b in books]       # list comprehension
for name, age in ages.items():
    print(name, age)
```

Lists, dictionaries, and sets are built into the language itself, with no imports and no generics.

## Getting started on Debian 13

Debian ships with Python 3 already installed.

```bash
python3 --version
python3                      # interactive shell (REPL)
python3 hello.py             # run a file
```

For libraries you use **pip** (Python's Maven/npm) inside a **virtual environment**, which keeps each project's dependencies isolated:

```bash
sudo apt install python3-venv python3-pip
python3 -m venv .venv
source .venv/bin/activate
pip install requests
```

On Debian 13, installing packages system-wide with pip is blocked by default (to protect system tools that depend on Python), so a virtual environment is the correct way.

## Where Python is used

- **Data science and AI:** NumPy, pandas, scikit-learn, PyTorch, TensorFlow. This is Python's dominant area, and most AI work, including the models behind the prompt engineering lesson, is built with it.
- **Back-end web:** Django (full-featured), Flask (minimal), FastAPI (modern, fast to build REST APIs). These do the same job as Spring Boot.
- **Automation and scripting:** renaming files, scraping websites, gluing tools together.
- **Teaching and prototypes:** the easiest mainstream language to start with.

## Python as a back-end (connection to your REST lessons)

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/books/{book_id}")
def get_book(book_id: int):
    return {"id": book_id, "title": "Clean Code"}
```

Run it with `uvicorn main:app`, and it serves JSON on port 8000, the same architecture as before:

```
Angular --HTTP/JSON--> FastAPI/Django --SQL--> PostgreSQL
```

Python also has the `sqlite3` module built in, so you can use the SQLite you learned without installing anything.

## Python vs Java

||Python|Java|
|---|---|---|
|**Typing**|Dynamic|Static|
|**Execution**|Interpreted (CPython)|Bytecode on JVM (JIT)|
|**Speed**|Slower|Much faster|
|**Verbosity**|Very concise|More boilerplate|
|**Strength**|Data, AI, scripting, rapid development|Large, long-lived enterprise systems|
|**Concurrency**|Limited by the GIL for CPU-bound threads|True multithreading|
|**Block syntax**|Indentation|Braces|

Neither is "better". Large companies often use both: Python for data and AI, Java for core back-end services.

## Gotchas

- **Indentation errors:** mixing tabs and spaces, or misaligning a line, breaks your program. Use 4 spaces consistently.
- **The GIL (Global Interpreter Lock):** in standard CPython, only one thread runs Python bytecode at a time, so threads don't speed up CPU-heavy work. Use multiple processes or libraries written in C (like NumPy) instead. This is a real difference from Java's threads.
- **Mutable default arguments:** `def f(items=[])` shares one list across all calls, which is a classic trap. Use `None` and create the list inside.
- **Runtime type errors:** a typo or wrong type may only fail when that exact line runs in production. Tests and type hints matter more than in Java.
- **Python 2 vs 3:** Python 2 is long dead. Always use `python3`, and be careful with old tutorials.
- **Speed:** don't use Python for performance-critical inner loops. Its speed comes from calling C code underneath, which echoes the earlier point that C sits beneath nearly everything.
- **Dependency chaos without virtual environments:** installing everything globally leads to version conflicts between projects. Always use a `venv` per project.

[[Computer & Programming]]