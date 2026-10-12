

Last time we covered the engine's components. Now we'll open up the thing those components move around: the **image**. This is where the "containers are cheap and fast" claim comes from, and it explains several Dockerfile habits you've already seen.

## 1. What an Image Really Is

An image isn't one big file. It's a small bundle of three kinds of things:

|Piece|What it is|
|---|---|
|**Layers**|Compressed tar archives, each holding a set of file changes|
|**Config**|A JSON file: environment variables, default command, exposed ports, and the ordered list of layers|
|**Manifest**|A JSON file that lists the config and the layers, each by hash|

Every one of these is stored by the **SHA-256 hash of its contents**. This is called _content-addressable storage_. The nearest analogy is Git: objects are named by their hash, so identical content is stored once, and you can verify nothing has been tampered with. Where the analogy breaks down: Git tracks history as a chain of commits, while an image is a fixed stack, with no branching or merging.

You can see this yourself:

```bash
docker pull nginx
docker save nginx -o nginx.tar
mkdir nginx-img && tar -xf nginx.tar -C nginx-img
ls nginx-img        # manifest, config JSON, and the layer blobs
```

Everything is hashes and tarballs, nothing magical.

## 2. Layers: Diffs Stacked in Order

Each Dockerfile instruction that changes the filesystem (`RUN`, `COPY`, `ADD`) produces a layer containing only **what changed**. Instructions like `ENV`, `CMD`, and `EXPOSE` just change the config and add no files.

```bash
docker history nginx    # one row per step, with the size each added
```

Three consequences are worth remembering:

- **Sharing.** If ten images start from the same base, that base layer is stored once on disk and downloaded once.
- **Caching.** If a step's instruction and inputs haven't changed, Docker reuses the cached layer. That's the build-cache behavior from earlier, now with its cause visible.
- **Layers only add up, never subtract.** If one layer adds a 500 MB file and a later layer deletes it, the image is still about 500 MB. The deletion is recorded in the _upper_ layer, but the data still sits in the lower one. This is why you should clean up in the **same** `RUN` step that created the mess, or use multi-stage builds, as we did with the Spring Boot Dockerfile.

## 3. OverlayFS: How Layers Become One Filesystem

The container needs to see all the layers as a single ordinary directory tree. On Linux, the `overlay2` storage driver does this with **OverlayFS**, a feature built into the kernel.

OverlayFS merges directories using four parts:

|Part|Meaning|
|---|---|
|**lowerdir**|One or more read-only directories (the image layers)|
|**upperdir**|A writable directory (the container's own layer)|
|**workdir**|Scratch space the kernel needs internally|
|**merged**|The combined view the container actually sees|

The rules are simple:

- **Reading:** the kernel looks in the upper layer first, then down through the lower layers, and returns the first match.
- **Writing to a file that exists in a lower layer:** the kernel first **copies it up** into the upper layer, then modifies the copy. This is **copy-on-write**. The original in the lower layer is never touched, which is why many containers can safely share one image.
- **Deleting a file from a lower layer:** the kernel can't remove it, so it places a **whiteout** marker in the upper layer. A whiteout is a special entry that hides the lower file from the merged view. (Image tarballs encode the same idea as files named `.wh.<filename>`.)

A fair way to picture it is a stack of transparent sheets: you see the topmost mark at each position. Where it breaks down: a real transparent sheet could be peeled off to reveal what's below, but here the lower layers are _shared_ among containers and stay strictly read-only.

## 4. Try OverlayFS by Hand

This takes Docker out of the picture entirely, which is the best proof that it's a kernel feature:

```bash
mkdir -p /tmp/ov/{lower,upper,work,merged}
echo "from lower" > /tmp/ov/lower/a.txt
echo "also lower" > /tmp/ov/lower/b.txt

sudo mount -t overlay overlay \
  -o lowerdir=/tmp/ov/lower,upperdir=/tmp/ov/upper,workdir=/tmp/ov/work \
  /tmp/ov/merged

ls /tmp/ov/merged                      # a.txt and b.txt, both visible
echo "changed" >> /tmp/ov/merged/a.txt # modify a lower file
rm /tmp/ov/merged/b.txt                # delete a lower file

cat /tmp/ov/lower/a.txt                # unchanged! the original is untouched
ls /tmp/ov/upper                       # the modified copy of a.txt, plus a whiteout for b.txt
ls -l /tmp/ov/upper/b.txt              # a special "character device" entry: that's the whiteout

sudo umount /tmp/ov/merged
```

After running it, you've reproduced copy-up and whiteouts yourself. A container is doing exactly this, with the image's layers as `lowerdir`.

## 5. Looking at a Real Container's Layers

Ask Docker where a running container's pieces live:

```bash
docker run -d --name demo nginx
docker inspect -f '{{json .GraphDriver.Data}}' demo
```

You'll see `LowerDir`, `UpperDir`, `WorkDir`, and `MergedDir` pointing into `/var/lib/docker/overlay2/`. Then try:

```bash
docker exec demo touch /hello.txt
sudo ls /var/lib/docker/overlay2/<id>/diff     # use the UpperDir path; hello.txt appears here
docker diff demo                               # Docker's own summary of changes: A added, C changed, D deleted
```

Your new file shows up in the container's upper layer, and `docker diff` lists it. If you remove the container with `docker rm -f demo`, that upper directory is deleted, which is exactly why container data disappears unless it lives in a volume.

> **Version note:** newer Docker Engine releases can use containerd's own image store instead of the classic `overlay2` store. The concepts are identical, but the on-disk paths can look different, so if `/var/lib/docker/overlay2` isn't where you expect, check `docker info` for the storage driver or image store in use.

## 6. Tags, Digests, and Registries

Names point at content, and it's worth knowing how:

- A **tag** like `postgres:17` is a movable label. The publisher can point it at a new image tomorrow.
- A **digest** like `postgres@sha256:...` is the hash of the manifest. It identifies exactly one image forever.
- A **registry** (Docker Hub, GitHub Container Registry, your own) stores manifests and blobs. When you `docker pull`, the engine fetches the manifest, then downloads only the layer blobs it doesn't already have.

If you need a build to be exactly reproducible, pinning by digest is the strictest option. Pinning a specific version tag, as we discussed, is the practical middle ground.

## 7. Why This Design Pays Off

|Feature|How layers make it work|
|---|---|
|**Fast container start**|No copying: OverlayFS just mounts the layers and adds an empty writable one|
|**Small downloads**|Only missing layers are pulled|
|**Efficient disk use**|Shared layers are stored once, however many images use them|
|**Fast rebuilds**|Unchanged layers come from the cache|

The tradeoff is that writes to the container layer are slower than writes to a real filesystem, because of copy-up and the extra indirection. That's another reason databases should use **volumes**, which bypass the overlay entirely and write straight to the host filesystem.

## 8. Quick Recap

- An image is **layers + config + manifest**, all stored by content hash.
- Layers are **diffs** and only ever add up, so clean up in the same step that created the mess.
- **OverlayFS** merges read-only lower layers with a writable upper layer, using **copy-on-write** and **whiteouts**.
- A container is an image's layers plus a thin writable layer, which vanishes with the container.
- Tags move, digests don't.

A good exercise is to run the manual OverlayFS experiment, then run `docker diff` on a container where you've created and deleted a few files, and match each entry to what you did. Do those two and the storage model will feel solid.






[[Docker]]