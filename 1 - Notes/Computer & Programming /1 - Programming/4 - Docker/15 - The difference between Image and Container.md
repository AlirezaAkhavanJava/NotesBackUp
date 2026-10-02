
The difference between a **Docker image** and a **container** is simple:

| Concept       | Description                                                                                                             | Analogy                           |
| ------------- | ----------------------------------------------------------------------------------------------------------------------- | --------------------------------- |
| **Image**     | A _blueprint_ or _template_ — contains the app, dependencies, and environment setup. It’s **static** and **read-only**. | A movie file                      |
| **Container** | A **running instance** of that image — it’s **live**, can change, and runs isolated.                                    |  The movie playing on your screen |

 In short:

- You **build or pull** an **image**.
    
- You **run** that image to create a **container**.
    
- You can have **many containers** from the **same image**.
    

Example:

```bash
docker pull nginx          # download image
docker run -d nginx        # start a container from it
docker ps                  # shows the running container
```

##### Tags : [[1 - Docker 🧋]]