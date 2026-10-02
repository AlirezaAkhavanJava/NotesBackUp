
> Can I create a Docker Compose only for the UI and put the UI in a front-end folder inside another folder in the project to separate the back-end from the front-end? 

Yes, this is a completely valid (and common) way to structure a project — each side gets its **own folder, own `Dockerfile`, own `docker-compose.yml`**, and can be built, run, and deployed independently. Let's build it properly.

---

## 1. Why Separate Compose Files (not just separate folders)

Having separate folders alone doesn't give you separate _deployability_ — if they share one `docker-compose.yml`, they're still coupled: you can't spin up just the frontend without Compose also caring about the backend section. Giving each side its **own Compose file** means:

- A frontend developer can `cd frontend && docker compose up` without touching Postgres/Spring Boot at all
- You can deploy the frontend to a static host (Netlify, Vercel, an nginx server) completely independently of where the backend lives
- Matches real production reality: frontend and backend are almost always deployed to _different_ infrastructure entirely

This is the natural conclusion of the client/server split we covered in the High-Level Architecture tutorial — now we're making the _tooling_ respect that split too.

---

## 2. Project Structure

```
library-app/
├── backend/
│   ├── Dockerfile
│   ├── docker-compose.yml      ← backend + db, independent
│   ├── src/
│   └── pom.xml
└── frontend/
    ├── Dockerfile
    ├── docker-compose.yml      ← frontend only, independent
    ├── nginx.conf
    ├── src/
    └── package.json
```

Two completely self-contained projects. Neither folder needs to know the other exists on disk — they only need to agree on **how they'll talk over the network** once both are running.

---

## 3. The Frontend-Only `docker-compose.yml`

### Step 1 — Dockerfile (same multi-stage pattern as before)

`frontend/Dockerfile`:

```dockerfile
# ---- Stage 1: Build ----
FROM node:20 AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# ---- Stage 2: Serve ----
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

### Step 2 — nginx config (needed for client-side routing to work)

If you're using React Router (or Vue Router, etc.), a plain nginx setup will 404 on page refresh for any route other than `/`. This config fixes that:

`frontend/nginx.conf`:

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

`try_files ... /index.html` means: if nginx can't find a matching file (e.g., `/books/123` isn't a real file), fall back to serving `index.html` and let the JS router handle it client-side.

### Step 3 — the frontend-only Compose file

`frontend/docker-compose.yml`:

```yaml
services:
  frontend:
    build: .
    ports:
      - "3000:80"
    environment:
      - VITE_API_BASE_URL=http://localhost:8080
```

That's it — no `db`, no `backend` service, nothing else. This file's _only_ concern is the frontend container.

Run it standalone:

```bash
cd frontend
docker compose up --build
```

---

## 4. How the Frontend Finds the Backend (config, not hardcoding)

Since the two are now fully decoupled, the frontend needs to know the backend's URL via **configuration**, not a hardcoded value baked into the code — this connects back to the NFR we wrote early on: _"business rules must be configurable, not hardcoded."_ Same principle applies to the API base URL.

### Using Vite (common with React today)

Vite reads environment variables prefixed with `VITE_` at build time:

```javascript
// frontend/src/api/bookApi.js
const API_BASE = import.meta.env.VITE_API_BASE_URL;

export async function getBooks() {
  const res = await fetch(`${API_BASE}/books`);
  return res.json();
}
```

`.env` file in the frontend folder (for local `npm run dev`, outside Docker):

```
VITE_API_BASE_URL=http://localhost:8080
```

For the Dockerized version, you set it via Compose's `environment:` key (as shown above) or pass it as a build arg if you need it baked in at build time rather than runtime:

```dockerfile
# In frontend/Dockerfile, build stage
ARG VITE_API_BASE_URL
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
RUN npm run build
```

```yaml
services:
  frontend:
    build:
      context: .
      args:
        VITE_API_BASE_URL: http://localhost:8080
```

**Why this matters:** when you eventually deploy to production, the frontend's `.env.production` just points `VITE_API_BASE_URL` at your real backend domain — nothing in the source code changes.

---

## 5. Running Both Independently, But Together

Two separate Compose projects, run separately, but still need to reach each other over HTTP from the browser:

```bash
# Terminal 1
cd backend
docker compose up

# Terminal 2
cd frontend
docker compose up
```

Since the browser (not a container) is what actually calls the backend, this works exactly like our earlier setup: the browser hits `http://localhost:8080` for the API and `http://localhost:3000` for the UI. **Two separate Compose projects never need to be on the same Docker network**, because the browser — sitting outside Docker entirely — is what bridges them.

This is actually simpler than the combined setup, precisely _because_ they're decoupled: no `depends_on`, no shared network, no service-name resolution to worry about between them.

---

## 6. The One Gotcha: CORS

Because your frontend (`localhost:3000`) and backend (`localhost:8080`) are now different **origins** (different ports count as different origins!), the browser will block API calls by default — this is the browser's **CORS** (Cross-Origin Resource Sharing) policy protecting users from malicious cross-site requests.

You'll see this error in the browser console:

```
Access to fetch at 'http://localhost:8080/books' from origin 'http://localhost:3000'
has been blocked by CORS policy
```

### Fix it in Spring Boot

```java
@Configuration
public class CorsConfig {

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")
                    .allowedOrigins("http://localhost:3000")  // your frontend's origin
                    .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE")
                    .allowedHeaders("*");
            }
        };
    }
}
```

This lives in your **backend** project (`shared/config/CorsConfig.java`, following our package structure from earlier) — it's the backend explicitly granting permission for the frontend's origin to call it. Without this, full separation genuinely doesn't work from a browser.

**Practical tip:** use an environment variable for `allowedOrigins` too, so it's `http://localhost:3000` in dev and your real frontend domain in production — same configurability principle as everywhere else.

---

## 7. Optional: A Root-Level "Convenience" Compose (without losing separation)

If you like running both together sometimes but still want them independently deployable, you can add a **third**, thin Compose file at the project root that just references the other two — without duplicating any config:

`library-app/docker-compose.yml`:

```yaml
include:
  - backend/docker-compose.yml
  - frontend/docker-compose.yml
```

`docker compose up` from the root now starts everything, while `backend/docker-compose.yml` and `frontend/docker-compose.yml` remain fully valid, independent files you can also run on their own. (The `include` key needs a reasonably recent Docker Compose version — v2.20+; check with `docker compose version` on your Debian machine.)

---

## 8. Summary of the Full Setup

```
library-app/
├── docker-compose.yml          ← optional convenience wrapper (include:)
├── backend/
│   ├── Dockerfile
│   ├── docker-compose.yml      ← backend + db, runs standalone
│   ├── src/main/java/.../shared/config/CorsConfig.java
│   └── pom.xml
└── frontend/
    ├── Dockerfile
    ├── docker-compose.yml      ← frontend only, runs standalone
    ├── nginx.conf
    ├── .env                     ← VITE_API_BASE_URL for local dev
    └── package.json
```

|Concern|Where it's handled|
|---|---|
|Frontend knows backend's URL|`VITE_API_BASE_URL` env var, not hardcoded|
|Backend allows frontend's origin|`CorsConfig` in the backend|
|Frontend routes work on refresh|`nginx.conf` fallback to `index.html`|
|Run frontend alone|`cd frontend && docker compose up`|
|Run backend alone|`cd backend && docker compose up`|
|Run everything together|root `docker-compose.yml` with `include:`|

---

## Quick Summary

1. Give each side its **own folder + own `Dockerfile` + own `docker-compose.yml`** — true independence, not just separate directories
2. The frontend gets the backend's URL via an **environment variable**, never hardcoded
3. Two independent Compose projects don't need a shared Docker network — the **browser** is what connects them, both exposed on `localhost` with different ports
4. Different ports = different origins = you **must** configure CORS on the backend, or every API call gets blocked
5. An optional root `docker-compose.yml` using `include:` lets you run both together without losing the ability to run either standalone




[[Java]]
[[1 - Docker 🧋]]
[[0 - Spring Framework]]