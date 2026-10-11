

---

## **1. Images & Containers Basics**

|Command|Purpose|Example|
|---|---|---|
|`docker pull <image>`|Download an image from Docker Hub|`docker pull postgres:16`|
|`docker images`|List all downloaded images|`docker images`|
|`docker rmi <image_id>`|Delete an image|`docker rmi postgres:16`|
|`docker run -it <image>`|Start a container interactively|`docker run -it ubuntu bash`|
|`docker ps`|List running containers|`docker ps`|
|`docker ps -a`|List all containers (running + stopped)|`docker ps -a`|
|`docker stop <container_id>`|Stop a running container|`docker stop mycontainer`|
|`docker start <container_id>`|Start a stopped container|`docker start mycontainer`|
|`docker rm <container_id>`|Delete a container|`docker rm mycontainer`|

---

## **2. Interacting with Containers**

|Command|Purpose|Example|
|---|---|---|
|`docker exec -it <container_id> bash`|Enter container shell|`docker exec -it mycontainer bash`|
|`docker logs <container_id>`|View container logs|`docker logs mycontainer`|
|`docker attach <container_id>`|Attach terminal to a container|`docker attach mycontainer`|

---

## **3. Building & Managing Images**

|Command|Purpose|Example|
|---|---|---|
|`docker build -t <name:tag> <path>`|Build image from Dockerfile|`docker build -t myapp:1.0 .`|
|`docker commit <container_id> <name:tag>`|Save container as an image|`docker commit mycontainer myapp:backup`|

---

## **4. Networking & Ports**

|Command|Purpose|Example|
|---|---|---|
|`docker run -p <host>:<container>`|Map ports|`docker run -p 5432:5432 postgres`|
|`docker network ls`|List networks|`docker network ls`|
|`docker network inspect <network>`|Inspect network details|`docker network inspect bridge`|

---

## **5. Volumes & Data Persistence**

|Command|Purpose|Example|
|---|---|---|
|`docker volume create <name>`|Create volume|`docker volume create pgdata`|
|`docker run -v <volume>:<container_path>`|Mount volume|`docker run -v pgdata:/var/lib/postgresql/data postgres`|
|`docker volume ls`|List volumes|`docker volume ls`|
|`docker volume rm <name>`|Remove volume|`docker volume rm pgdata`|

---

## **6. Java Backend Tips**

- Use a `Dockerfile` to package your Spring/Hibernate app:
    

```dockerfile
FROM openjdk:21-jdk
WORKDIR /app
COPY target/myapp.jar myapp.jar
EXPOSE 8080
CMD ["java", "-jar", "myapp.jar"]
```

- For PostgreSQL or MySQL, run DB in a container:
    

```bash
docker run -d --name mydb -e POSTGRES_PASSWORD=pass -p 5432:5432 postgres
```

- Link app to DB container using network:
    

```bash
docker network create mynetwork
docker network connect mynetwork myapp
docker network connect mynetwork mydb
```

##### Tags : [[1 - Docker 🧋]]