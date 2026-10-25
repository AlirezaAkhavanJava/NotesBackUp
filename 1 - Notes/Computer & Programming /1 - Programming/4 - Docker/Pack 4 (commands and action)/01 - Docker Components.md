Docker is a platform for developing, shipping, and running applications inside containers. Its core components work together to enable containerization. Below is a concise definition of the key Docker components:

1. **Docker Engine**: The core runtime that builds and runs containers. It includes a daemon (dockerd) for managing container processes, a REST API for interaction, and a CLI (Docker command-line interface) for user commands.



2. **Docker Images**: Lightweight, portable templates used to create containers. Images are built from a series of layers defined in a Dockerfile, containing application code, dependencies, and configurations.




3. **Docker Containers**: Runnable instances of Docker images. Containers are isolated environments that include everything needed to run an application, such as code, runtime, libraries, and settings.
> are made out of exactly one image


4. **Dockerfile**: A script containing instructions to build a Docker image. It specifies the base image, application code, dependencies, and runtime configurations.



5. **Docker Registry**: A storage and distribution system for Docker images. Docker Hub is the default public registry, but private registries can also be used to store and share images.



6. **Docker Compose**: A tool for defining and managing multi-container applications using YAML files. It allows you to configure services, networks, and volumes in a single file for easy orchestration.




7. **Docker Volumes**: Persistent storage for containers, allowing data to be stored outside the container’s filesystem and shared between containers or with the host.




8. **Docker Networks**: Enable communication between containers and between containers and the host. Docker supports various network drivers (e.g., bridge, host, overlay) to control connectivity and isolation.




9. **Docker CLI**: The command-line interface used to interact with the Docker Engine, allowing users to build, run, manage, and inspect containers, images, and other resources.



10. **Docker Swarm**: A native orchestration tool for managing a cluster of Docker nodes. It enables deploying and scaling containers across multiple hosts, providing features like load balancing and service discovery.

These components collectively enable Docker’s ability to create, deploy, and manage containerized applications efficiently. 

[[1 - Docker 🧋]]