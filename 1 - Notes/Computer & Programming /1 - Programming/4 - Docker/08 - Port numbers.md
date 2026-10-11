
Port numbers range from **0 to 65535** (16-bit unsigned integer).

Here’s the breakdown:

|Range|Name|Usage|
|---|---|---|
|**0–1023**|_Well-known ports_|Reserved for system services (e.g., 22=SSH, 80=HTTP, 443=HTTPS). You usually **don’t** use these unless running as root.|
|**1024–49151**|_Registered ports_|Used by common applications (e.g., 3306=MySQL, 5432=PostgreSQL). You can use them if they’re not taken.|
|**49152–65535**|_Dynamic / Ephemeral ports_|Temporary ports used for outgoing connections — safe for container or test use.|

👉 For Docker or local apps, it’s best to use ports in the **3000–9000** range (common practice and avoids conflicts).

**Example:**

```bash
docker run -p 8080:80 nginx
```

Here, 8080 is the **host port** — you can choose any unused one.

##### Tags : [[1 - Docker 🧋]]