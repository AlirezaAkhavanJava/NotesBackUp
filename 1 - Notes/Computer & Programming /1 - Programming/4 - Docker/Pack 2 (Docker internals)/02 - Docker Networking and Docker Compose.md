


# Part 1: Docker Networking

## 1. The Core Idea

Remember from the namespaces lesson that each container gets its **own network namespace**: its own interfaces, IP address, routing table, and ports. By default that namespace is completely sealed off, with no way in or out.

Docker's networking job is to build **virtual cables and switches** that connect those sealed namespaces to each other and to the outside world. It uses ordinary Linux networking features to do it: veth pairs, bridges, and firewall rules.

## 2. The Building Blocks

|Piece|What it is|Role|
|---|---|---|
|**Network namespace**|A private network stack|One per container|
|**veth pair**|Two virtual interfaces joined like a cable|Connects a container to the host side|
|**Linux bridge**|A software switch inside the kernel|Joins many containers into one network|
|**iptables/nftables rules**|Kernel firewall and NAT rules|Handle outbound traffic and published ports|
|**Embedded DNS server**|A resolver inside the engine|Lets containers find each other by name|

Two analogies help here. A **veth pair** is like a patch cable: whatever goes in one end comes out the other. A **bridge** is like a network switch that all those cables plug into. Where they break down: neither is physical. Both ends of the cable live inside the same kernel, and the "switch" is just a kernel data structure. The bridge also has an IP address of its own on the host, which lets it act as the containers' gateway, something a plain switch doesn't do.

## 3. Build One by Hand

As with namespaces and OverlayFS, the best way to see that this isn't magic is to build a tiny version without Docker:

```bash
sudo ip netns add red                                   # a new network namespace
sudo ip link add veth-host type veth peer name veth-red # create the "cable"
sudo ip link set veth-red netns red                     # push one end into the namespace

sudo ip addr add 10.10.0.1/24 dev veth-host             # address the host end
sudo ip link set veth-host up

sudo ip netns exec red ip addr add 10.10.0.2/24 dev veth-red
sudo ip netns exec red ip link set veth-red up
sudo ip netns exec red ip link set lo up

ping -c 2 10.10.0.2                                     # host reaches the namespace
sudo ip netns exec red ping -c 2 10.10.0.1              # and the namespace reaches the host

sudo ip netns del red                                   # cleanup (also removes the veth pair)
```

That's the foundation of every container network. Docker does the same thing, but it plugs the host end of each cable into a **bridge** so many containers can share one network.

## 4. The Default Bridge Network

When Docker starts, it creates a bridge called **`docker0`** (typically with a subnet like `172.17.0.0/16`). Every container you start without special options is attached to it:

1. Docker creates a network namespace for the container.
2. It creates a veth pair: one end becomes `eth0` inside the container, the other end is plugged into `docker0` on the host.
3. It assigns the container an IP from the subnet, with the bridge as the **default gateway**.

You can see all of it from the host:

```bash
docker run -d --name c1 nginx
ip addr show docker0          # the bridge, usually 172.17.0.1
bridge link                   # veth interfaces plugged into the bridge
docker exec c1 cat /etc/hosts # the container's own view
docker network inspect bridge # subnet, gateway, attached containers
```

> **Important limitation:** the _default_ bridge does **not** provide name-based DNS between containers. Containers there can reach each other by IP, but IPs change every time a container is recreated. That's the main reason people create their own networks, which is the next section.

## 5. User-Defined Bridge Networks

You can make your own bridge network, and it behaves better than the default in a few ways:

```bash
docker network create appnet
docker run -d --name db  --network appnet postgres:17   # (needs POSTGRES_PASSWORD to stay up; just for illustration)
docker run -d --name web --network appnet nginx
docker exec web getent hosts db    # resolves "db" to its IP
```

The advantages over the default bridge:

- **Automatic DNS by container name.** The engine runs an embedded DNS server, and containers on user-defined networks use it. Check with `docker exec web cat /etc/resolv.conf`: you'll see `nameserver 127.0.0.11`, the embedded resolver. Names it doesn't know are forwarded to your normal DNS.
- **Better isolation.** Containers on different user-defined networks **cannot talk to each other** unless you attach them to a shared network.
- **Attach and detach on the fly** with `docker network connect` and `docker network disconnect`.

A container can be on several networks at once, and that's a powerful design tool, as you'll see in the Compose example.

## 6. Traffic Leaving the Container (Outbound)

A container with IP `172.17.0.2` can't be routed on the real internet, so Docker uses **NAT** (network address translation), just like a home router:

1. The container sends a packet to the gateway (the bridge).
2. The host kernel forwards it and applies a **masquerade** rule, rewriting the source address to the host's own address.
3. Replies come back to the host and are translated back to the container.

This is why containers can reach the internet with no setup, as long as IP forwarding is enabled, which Docker takes care of.

## 7. Traffic Entering the Container (Published Ports)

Nothing outside can reach a container by default, since its IP is private. **Publishing a port** with `-p` adds a **DNAT** rule that redirects traffic arriving at a host port to the container:

```bash
docker run -d -p 8080:80 nginx        # host:8080 -> container:80
docker run -d -p 127.0.0.1:5432:5432 postgres:17   # reachable only from this machine
```

You can look at the rules Docker added:

```bash
sudo iptables -t nat -L -n | grep -i docker
```

Debian uses the nftables backend underneath, so depending on your setup you may need `sudo nft list ruleset` to see them instead. Either way, you'll find a DNAT rule for your published port.

Three details trip people up:

- **`EXPOSE` in a Dockerfile publishes nothing.** It's documentation only. Only `-p` (or `ports:` in Compose) opens a port to the host.
- **Published ports bind to all interfaces by default** (`0.0.0.0`), which means anyone who can reach your machine can reach that port.
- **Docker's firewall rules usually take effect before your own firewall's rules**, so a tool like `ufw` saying "deny" may not actually block a published container port. For databases and other private services in development, bind to loopback (`127.0.0.1:...`) or don't publish them at all.

## 8. Other Network Drivers (Brief)

You've seen the table before, so here is the practical summary:

- **`bridge`**: the everyday choice on a single machine.
- **`host`**: the container shares the host's network stack, with no isolation and no port mapping. Fast and simple, but ports can collide with host services.
- **`none`**: no network at all.
- **`overlay`** and **`macvlan`**: for multi-host clusters and for giving containers real LAN addresses.

## 9. Networking Recap

- Each container has its own network namespace, connected by a **veth pair** to a **bridge**.
- **Outbound** traffic works through NAT/masquerade; **inbound** traffic needs a published port (DNAT).
- **User-defined networks** give you DNS by name and better isolation, and the default bridge doesn't.
- `localhost` inside a container means the container itself.
- Publishing a port exposes it to the world unless you bind it to `127.0.0.1`.

---

# Part 2: Docker Compose

## 10. What Compose Is

**Docker Compose** lets you describe a multi-container application in one YAML file and manage it with single commands. It's a **client of the Docker Engine**, as we saw earlier: it reads your file, then makes API calls to create networks, volumes, and containers.

A fair analogy is `pom.xml`: you _declare_ what you want, and the tool works out the steps. Where it breaks down: Maven resolves a full dependency graph, while Compose only handles startup ordering, and even that has a catch we'll cover in section 13.

Modern Compose is a Docker CLI plugin, so you run `docker compose ...` (with a space). The older standalone `docker-compose` command is legacy.

## 11. The File Layout

The preferred file name is **`compose.yaml`** (`docker-compose.yml` still works). A file has up to four top-level sections:

|Section|Purpose|
|---|---|
|**`services`**|The containers: image or build, ports, environment, and so on|
|**`networks`**|Custom networks|
|**`volumes`**|Named volumes|
|**`configs` / `secrets`**|Injected configuration files and sensitive values|

The old top-level `version:` key is obsolete. You can leave it out.

## 12. A Complete Example

This puts an Angular front end (served by nginx), a Spring Boot backend, and PostgreSQL together, using two networks:

```yaml
services:
  web:
    build: ./frontend
    ports:
      - "80:80"
    networks: [frontend]
    depends_on: [app]

  app:
    build: ./backend
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://db:5432/appdb
      SPRING_DATASOURCE_USERNAME: ${DB_USER}
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD}
    networks: [frontend, backend]
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  db:
    image: postgres:17
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - dbdata:/var/lib/postgresql/data
    networks: [backend]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d appdb"]
      interval: 5s
      timeout: 3s
      retries: 10
    restart: unless-stopped

networks:
  frontend:
  backend:

volumes:
  dbdata:
```

And a `.env` file beside it, which Compose reads automatically for the `${...}` values:

```
DB_USER=appuser
DB_PASSWORD=change-me
```

Keep `.env` out of version control (add it to `.gitignore`).

## 13. Reading the Example, Piece by Piece

**Two kinds of services.** `web` and `app` use `build:`, so Compose builds them from Dockerfiles. `db` uses `image:`, so Compose pulls it from a registry.

**Two networks, with a purpose.** `app` sits on both networks and acts as the bridge between them. `web` is only on `frontend`, and `db` is only on `backend`. So `web` **cannot reach the database at all**, which is exactly the isolation from section 5 put to work. Inside `web`'s nginx config, the backend is reachable at `http://app:8080`, and `app` reaches the database at `db:5432`.

**Only `web` publishes a port.** The backend and database are reachable only by name from inside their networks, so nothing outside can touch them directly. (During development you might temporarily add `"127.0.0.1:8080:8080"` to `app` so you can test it from your browser.)

**Startup order versus readiness.** This is the most common Compose misunderstanding. A plain `depends_on: [db]` only waits until the database container has _started_, not until Postgres is _ready to accept connections_. Postgres takes a few seconds to initialize, so your app could start, fail to connect, and crash. The fix is shown above: give `db` a **healthcheck**, and use `condition: service_healthy` so `app` waits for it to pass.

**Restart policy.** `unless-stopped` brings the container back after a crash or a reboot, unless you stopped it yourself.

**Environment variables.** `${DB_USER}` is substituted by Compose from `.env` or your shell _before_ anything starts. Spring Boot then maps `SPRING_DATASOURCE_URL` to the `spring.datasource.url` property automatically. For many variables, an `env_file:` entry or a `.env`-style file is tidier than a long `environment:` block.

**Volumes.** `dbdata` is a named volume, so the database files survive container deletion.

## 14. What Compose Creates for You

When you run `docker compose up`, Compose derives a **project name** (by default, the folder name) and prefixes everything with it. For a folder called `myapp`, you'd get:

- containers named like `myapp-app-1`, `myapp-db-1`
- networks named `myapp_frontend` and `myapp_backend`
- a volume named `myapp_dbdata`

If you don't define any networks at all, Compose creates one default network (`myapp_default`) and puts every service on it, which is why the simple example from earlier worked with no network configuration. Every service name becomes a DNS name on the networks it joins.

## 15. The Commands You'll Use Daily

|Command|What it does|
|---|---|
|`docker compose up -d`|Create and start everything in the background|
|`docker compose up -d --build`|Rebuild images first, then start|
|`docker compose ps`|Show the project's containers and their status|
|`docker compose logs -f app`|Follow one service's logs|
|`docker compose exec app bash`|Open a shell in a running service|
|`docker compose stop` / `start`|Stop or start without removing anything|
|`docker compose down`|Stop and remove containers and networks (**volumes are kept**)|
|`docker compose down -v`|Same, but **also deletes volumes**, which wipes your database|
|`docker compose config`|Print the final, fully resolved file, great for debugging|

Be careful with `down -v`. It's the one that destroys data.

## 16. Features Worth Knowing Early

- **Override files.** A `compose.override.yaml` next to your main file is merged in automatically, which is handy for dev-only settings like extra published ports or bind-mounted source code.
- **Profiles.** Tag optional services (like a database admin tool) with `profiles: [tools]`, and they only start when you ask: `docker compose --profile tools up`.
- **Bind mounts for development.** Mapping your source folder into a container (`./src:/app/src`) lets you edit code on the host while the container sees the changes.
- **Scaling.** `docker compose up -d --scale app=3` runs three copies of a service. Other containers resolving `app` get the addresses of all three, which is a basic form of load distribution.

## 17. Where Compose Stops

Compose manages containers on **one host**. It doesn't spread containers across many machines or heal itself when a server dies. For that, people move to an orchestrator like **Kubernetes**. For development, small deployments, and learning, Compose is exactly the right tool, and understanding it makes Kubernetes much easier to approach later.

---

# Putting It Together

You can now trace the whole picture. `docker compose up` reads your file, asks the **engine** to create two **bridge networks**, builds and pulls **images**, creates containers whose filesystems are **OverlayFS** stacks, attaches each one to its networks with **veth pairs**, registers their names with the **embedded DNS**, and adds a **DNAT rule** for the one published port. Every concept from this series appears in that single command.

## Exercises

1. Build the manual **veth/namespace** setup from section 3 and ping across it.
2. Create a small Compose file with two services on a custom network, then run `docker compose exec` on one and `getent hosts` the other's name.
3. Run `docker network inspect` on your Compose network and match the container IPs to what you see in `ip addr` inside a container.
4. Remove the healthcheck from the database in the example, run `docker compose up`, and see if your app starts before the database is ready. Then add it back and compare.




[[Docker]]