


An image can't be updated in place. Once built, it never changes. When Debian (or anyone else) publishes a fixed version, they build a **new image** and move the tag, like `trixie-backports`, so it points at the new one. Your local copy stays exactly as it was until you ask Docker to fetch the new one.

 **you don't need to remove the old image first.** Run `docker pull` and Docker downloads the new version, moves the tag to it, and leaves the old one behind as an unlabelled image you can delete later.

---

## First, let's read your output

```
IMAGE          CREATED         CREATED BY                                      SIZE      COMMENT
5a0d9645cd57   12 months ago   RUN /bin/sh -c echo 'deb http://deb.debian.o…   55B       buildkit.dockerfile.v0
<missing>      12 months ago   # debian.sh --arch 'amd64' out/ 'trixie' '@1…   120MB     debuerreotype 0.16
```

`docker history` lists the **layers** of an image, newest on top.

|Row|What it is|
|---|---|
|Bottom (`debian.sh ... trixie`, 120MB)|The base Debian trixie filesystem. This is the big layer.|
|Top (`RUN ... echo 'deb http://deb.debian.o…`, 55B)|One small line added to the apt sources, enabling the **backports** repository.|
|`<missing>`|Normal. It means the layer was built on another machine and you only downloaded the result. It isn't an error.|
|`12 months ago`|When this image was **built**, not when you pulled it.|

The `trixie-backports` image is just plain `trixie` plus one line that turns on backports. That's why it's so small on top.

---

## The problem it solves

Old images carry old packages. A 12-month-old Debian image may include outdated libraries and unpatched security issues. You want the fresh version without breaking things or wasting time and disk space.

---

## How a tag really works (ASCII picture)

A **tag** is only a label that points at an image. The image itself is identified by a **digest**, a long `sha256:...` fingerprint. The registry can move a tag to a different image at any time.

```
 BEFORE (a year ago)                    NOW (on Docker Hub)

 debian:trixie-backports                debian:trixie-backports
          │                                      │
          ▼                                      ▼
   ┌──────────────┐                       ┌──────────────┐
   │ image 5a0d.. │                       │ image 9f3e.. │  (rebuilt, newer)
   │ (old)        │                       │ (new)        │
   └──────────────┘                       └──────────────┘


 YOUR MACHINE after `docker pull`:

   debian:trixie-backports ───────────►  image 9f3e..  (new)
   <none>:<none>           ───────────►  image 5a0d..  (old, now "dangling")
```

The old image isn't deleted by `pull`. It just loses its name and is called **dangling**. You can clean it up afterwards.

---

## Step by step: update the image

**1. Pull it again**

```bash
docker pull debian:trixie-backports
```

Read the last lines of the output, because they tell you what happened:

|Message|Meaning|
|---|---|
|`Status: Downloaded newer image for debian:trixie-backports`|A newer version existed. Your tag now points to it.|
|`Status: Image is up to date for debian:trixie-backports`|Nothing newer on the registry. You already have the latest.|

Docker compares **digests**, not dates, so it knows exactly whether anything changed.

**2. Check the result**

```bash
docker images
```

You may now see two entries:

```
REPOSITORY   TAG                 IMAGE ID       CREATED        SIZE
debian       trixie-backports    9f3e........   2 weeks ago    121MB
<none>       <none>              5a0d9645cd57   12 months ago  120MB
```

The `<none>` row is your old image.

**3. Confirm with history (optional)**

```bash
docker history debian:trixie-backports
```

The `CREATED` column should now show a recent date.

**4. Delete the old one when you're happy**

```bash
docker rmi 5a0d9645cd57
```

Or remove all dangling images at once:

```bash
docker image prune
```

---

## Why not remove first?

||Pull directly|Remove, then pull|
|---|---|---|
|Works if a container uses the old image|Yes|**No**, `rmi` fails while any container (even stopped) uses it|
|Reuses layers that haven't changed|**Yes**, saves download time|No, everything is downloaded again|
|Easy rollback if the new one breaks things|**Yes**, old image still exists|No, it's gone|
|Risk|Very low|Higher|

Pulling first is faster and safer. Remove the old image only after the new one proves fine.

---

## Important: running containers don't update themselves

This catches many people out. A container is created from a specific image **at the moment you run it**. Pulling a newer image doesn't touch containers that already exist.

```
 old image 5a0d..  ◄─── container "web"  (still running the OLD image!)
 new image 9f3e..       (nothing uses it yet)
```

To actually use the new image, recreate the container:

```bash
docker stop web
docker rm web
docker run -d --name web -p 8080:80 debian:trixie-backports ...
```

Your data survives this if it lives in a **volume** (storage outside the container). Anything stored only inside the old container is lost when you remove it, which is the reason volumes matter.

To find which containers use an image:

```bash
docker ps -a --filter ancestor=5a0d9645cd57
```

---

## Another gotcha: `docker run` won't update for you

If the image already exists locally, `docker run debian:trixie-backports` happily uses your **old** copy and doesn't check the registry. You have two options:

```bash
docker pull debian:trixie-backports && docker run ...    # pull manually first
docker run --pull always debian:trixie-backports ...     # pull on every run
```

`--pull always` checks the registry each time. It's a nice safety net for tags that change often.

---

## What about updating packages inside the container?

You could run `apt update && apt upgrade` inside a running container. It works, but it's the wrong tool:

- The changes live only in that container. Remove it and they're gone.
- Two containers from the same image can drift apart.
- It's not repeatable.

The better approach is to **bake updates into an image** with a Dockerfile:

```dockerfile
FROM debian:trixie-backports
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
```

Line by line:

|Line|What it does|
|---|---|
|`FROM debian:trixie-backports`|Start from the base image.|
|`RUN apt-get update`|Refresh the package lists.|
|`&& apt-get upgrade -y`|Install newer versions of installed packages. `-y` answers "yes" automatically.|
|`&& rm -rf /var/lib/apt/lists/*`|Delete the downloaded package lists so the image stays small.|

Chaining with `&&` in one `RUN` makes a single layer instead of three.

When you rebuild, make sure Docker doesn't reuse stale cached layers or an old base:

```bash
docker build --pull --no-cache -t my-debian:1.1 .
```

- `--pull` fetches the newest base image first.
- `--no-cache` ignores cached layers so `apt upgrade` really runs again.

---

## If you use Docker Compose

```bash
docker compose pull        # download newer images for all services
docker compose up -d       # recreates only containers whose image changed
```

Compose is smart here. It notices a service's image changed and recreates just that container.

---

## Related concepts, in short

- **Digest:** the unique `sha256:...` fingerprint of an exact image. See yours with `docker images --digests`.
- **Pinning by digest:** `image: debian@sha256:...` guarantees you always get the exact same image, even if the tag moves. Great for reproducible builds, but you must update it by hand.
- **Dangling image:** an image with no tag (`<none>:<none>`), usually left over after a pull or rebuild.
- **Rollback:** because the old image stays until you delete it, you can still run it by ID: `docker run 5a0d9645cd57`.

---

## Quick recap

1. Images are immutable. You never "edit" one. You pull or build a new one.
2. `docker pull name:tag` moves your local tag to the newest image. No need to remove anything first.
3. The old image becomes `<none>:<none>`. Delete it later with `docker rmi` or `docker image prune`.
4. Existing containers keep using the old image until you remove and recreate them.
5. For your own images, rebuild with `docker build --pull --no-cache`.




[[Docker]]