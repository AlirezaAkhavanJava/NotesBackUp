

# Networking Roadmap — Concept by Concept

## Phase 0 — Foundations of Communication

You are here.

1. **Telecommunication**
    
2. **Signals**
    
3. **Analog vs Digital**
    
4. **Bits and Bytes**
    
5. **Bandwidth**
    
6. **Latency**
    
7. **Throughput**
    
8. **Noise**
    
9. **Signal-to-Noise Ratio**
    
10. **Encoding**
    
11. **Modulation**
    
12. **Demodulation**
    
13. **Modem**
    
14. **Multiplexing**
    
15. **Circuit Switching**
    
16. **Packet Switching**
    
17. **Store-and-Forward**
    

**Goal:** Understand how information physically travels.

---

# Phase 1 — How Computers Connect Locally

18. **Computer Network**
    
19. **Network Interface**
    
20. **NIC**
    
21. **MAC Address**
    
22. **Ethernet**
    
23. **Ethernet Frame**
    
24. **Frame vs Packet**
    
25. **LAN**
    
26. **Switch**
    
27. **Hub**
    
28. **Broadcast**
    
29. **Unicast**
    
30. **Multicast**
    
31. **Collision**
    
32. **CSMA/CD**
    
33. **ARP**
    
34. **ARP Table**
    

Then Linux:

```bash
ip link
ip addr
ip neigh
```

**Goal:**

Understand:

```text
Computer
   ↓
NIC
   ↓
Ethernet
   ↓
Switch
   ↓
Another computer
```

---

# Phase 2 — IP Networking

35. **Why IP exists**
    
36. **IPv4**
    
37. **IPv4 Address**
    
38. **Network Address**
    
39. **Host Address**
    
40. **Subnet Mask**
    
41. **CIDR**
    
42. **Prefix Length**
    
43. **Subnetting**
    
44. **Default Gateway**
    
45. **Routing**
    
46. **Routing Table**
    
47. **Router**
    
48. **Hop**
    
49. **TTL**
    
50. **ICMP**
    
51. **Ping**
    
52. **Traceroute**
    

Linux:

```bash
ip addr
ip route
ping
traceroute
```

Then IPv6:

53. **Why IPv6 exists**
    
54. **IPv6 Address**
    
55. **IPv6 notation**
    
56. **IPv6 subnetting**
    
57. **Neighbor Discovery**
    
58. **IPv6 routing**
    

**Goal:**

Understand:

```text
Host A
  ↓
LAN
  ↓
Router
  ↓
Router
  ↓
LAN
  ↓
Host B
```

and understand exactly how an IP packet gets from A → B.

---

# Phase 3 — Routing

Now go deeper.

59. **Routing vs Forwarding**
    
60. **Routing Table**
    
61. **Longest Prefix Match**
    
62. **Static Routing**
    
63. **Dynamic Routing**
    
64. **Autonomous System**
    
65. **Interior Gateway Protocol**
    
66. **Exterior Gateway Protocol**
    
67. **RIP**
    
68. **OSPF**
    
69. **BGP**
    
70. **Internet routing**
    
71. **Peering**
    
72. **Transit**
    
73. **IXP**
    

Linux:

```bash
ip route
traceroute
```

Later:

```bash
tcpdump
```

**Goal:** Understand how the **Internet itself chooses paths**.

---

# Phase 4 — Transport Layer

Now we move above IP.

74. **Why TCP/UDP exist**
    
75. **Transport Layer**
    
76. **Port**
    
77. **Socket**
    
78. **TCP**
    
79. **UDP**
    
80. **TCP connection**
    
81. **TCP 3-way handshake**
    
82. **SYN**
    
83. **SYN-ACK**
    
84. **ACK**
    
85. **TCP sequence numbers**
    
86. **TCP acknowledgements**
    
87. **Retransmission**
    
88. **TCP ordering**
    
89. **Flow control**
    
90. **Congestion control**
    
91. **TCP connection termination**
    
92. **TCP states**
    
93. **UDP datagrams**
    
94. **TCP vs UDP**
    
95. **QUIC**
    

Linux:

```bash
ss
ss -t
ss -u
ss -lntp
```

**Goal:**

Understand:

```text
Application
     ↓
TCP / UDP
     ↓
IP
     ↓
Ethernet / Wi-Fi
```

---

# Phase 5 — Network Architecture & Layering

Now formalize everything you've learned.

96. **Protocol**
    
97. **Protocol Stack**
    
98. **Layering**
    
99. **Encapsulation**
    
100. **Decapsulation**
    
101. **OSI Model**
    
102. **TCP/IP Model**
    
103. **Application Layer**
    
104. **Transport Layer**
    
105. **Internet/Network Layer**
    
106. **Link Layer**
    
107. **Physical Layer**
    
108. **PDU**
    
109. **Frame**
    
110. **Packet**
    
111. **Segment**
    
112. **Datagram**
    

You should be able to visualize:

```text
HTTP message
     ↓
TCP segment
     ↓
IP packet
     ↓
Ethernet frame
     ↓
bits/signals
```

And in reverse at the receiver.

---

# Phase 6 — DNS

Now enter the protocols you actually use every day.

113. **DNS**
    
114. **Domain name**
    
115. **DNS hierarchy**
    
116. **Root**
    
117. **TLD**
    
118. **Authoritative DNS server**
    
119. **Recursive resolver**
    
120. **DNS resolution**
    
121. **DNS caching**
    
122. **TTL**
    
123. **A record**
    
124. **AAAA record**
    
125. **CNAME**
    
126. **MX**
    
127. **NS**
    
128. **TXT**
    
129. **PTR**
    
130. **Reverse DNS**
    
131. **DNS over HTTPS**
    
132. **DNS over TLS**
    

Linux:

```bash
dig
host
nslookup
```

---

# Phase 7 — HTTP & Web Networking

You already know the basic HTTP concept, so now go deep.

133. **HTTP**
    
134. **HTTP request**
    
135. **HTTP response**
    
136. **Methods**
    
137. **GET**
    
138. **POST**
    
139. **PUT**
    
140. **PATCH**
    
141. **DELETE**
    
142. **HTTP headers**
    
143. **HTTP body**
    
144. **Status codes**
    
145. **Cookies**
    
146. **Sessions**
    
147. **Caching**
    
148. **Content negotiation**
    
149. **Keep-Alive**
    
150. **HTTP/1.0**
    
151. **HTTP/1.1**
    
152. **HTTP/2**
    
153. **HTTP/3**
    
154. **QUIC**
    

Linux:

```bash
curl
curl -v
curl -I
```

---

# Phase 8 — TLS & HTTPS

This is extremely important for a backend developer.

155. **Cryptography basics**
    
156. **Symmetric encryption**
    
157. **Asymmetric encryption**
    
158. **Hashing**
    
159. **Digital signatures**
    
160. **Public/private keys**
    
161. **Certificates**
    
162. **Certificate Authorities**
    
163. **PKI**
    
164. **TLS**
    
165. **TLS handshake**
    
166. **HTTPS**
    
167. **Certificate validation**
    
168. **Perfect Forward Secrecy**
    
169. **TLS 1.2**
    
170. **TLS 1.3**
    

Then inspect it:

```bash
curl -v https://example.com
openssl s_client -connect example.com:443
```

---

# Phase 9 — NAT, DHCP & Real Home Networks

Now understand the network you literally use.

171. **Private IP addresses**
    
172. **Public IP addresses**
    
173. **NAT**
    
174. **PAT**
    
175. **Port forwarding**
    
176. **DHCP**
    
177. **DHCP Discover**
    
178. **DHCP Offer**
    
179. **DHCP Request**
    
180. **DHCP ACK**
    
181. **DNS + DHCP relationship**
    
182. **Home router**
    
183. **ISP**
    
184. **CGNAT**
    

You should understand:

```text
Your PC
  ↓
192.168.x.x
  ↓
Home Router
  ↓
NAT
  ↓
Public IP
  ↓
ISP
  ↓
Internet
```

---

# Phase 10 — Wi-Fi & Wireless

You already know the conceptual history; now learn the engineering.

185. **802.11**
    
186. **Wi-Fi**
    
187. **Access Point**
    
188. **SSID**
    
189. **BSSID**
    
190. **Wi-Fi channels**
    
191. **2.4 GHz**
    
192. **5 GHz**
    
193. **6 GHz**
    
194. **Wi-Fi association**
    
195. **Wi-Fi authentication**
    
196. **WPA2**
    
197. **WPA3**
    
198. **Wi-Fi interference**
    
199. **Signal strength**
    
200. **Roaming**
    

Linux:

```bash
ip link
iw
nmcli
```

---

# Phase 11 — Network Services

201. **DHCP**
    
202. **DNS**
    
203. **NTP**
    
204. **SSH**
    
205. **FTP**
    
206. **SFTP**
    
207. **SMTP**
    
208. **IMAP**
    
209. **POP3**
    
210. **SNMP**
    
211. **LDAP**
    

You'll start seeing how different applications use the same lower layers.

---

# Phase 12 — Firewalls & Network Security

212. **Threat model**
    
213. **Attack surface**
    
214. **Firewall**
    
215. **Packet filtering**
    
216. **Stateful firewall**
    
217. **iptables**
    
218. **nftables**
    
219. **Linux firewall**
    
220. **Ingress**
    
221. **Egress**
    
222. **Network segmentation**
    
223. **DMZ**
    
224. **VPN**
    
225. **IPsec**
    
226. **WireGuard**
    
227. **IDS**
    
228. **IPS**
    

Linux:

```bash
ss
ip
nft
tcpdump
```

---

# Phase 13 — Network Diagnostics

This is where networking becomes practical.

229. **ping**
    
230. **traceroute**
    
231. **dig**
    
232. **curl**
    
233. **ss**
    
234. **ip**
    
235. **tcpdump**
    
236. **Wireshark**
    
237. **nmap**
    
238. **netcat**
    
239. **mtr**
    
240. **openssl**
    

Learn to answer:

> "My Spring Boot application cannot connect to PostgreSQL. Why?"

Instead of randomly changing configuration.

---

# Phase 14 — Network Programming

Now connect networking directly to Java.

241. **Java Socket**
    
242. **ServerSocket**
    
243. **TCP server**
    
244. **TCP client**
    
245. **UDP sockets**
    
246. **Blocking I/O**
    
247. **Non-blocking I/O**
    
248. **Java NIO**
    
249. **Channels**
    
250. **Buffers**
    
251. **Selectors**
    
252. **Connection pools**
    
253. **HTTP clients**
    
254. **Connection timeout**
    
255. **Read timeout**
    
256. **Connection reset**
    
257. **DNS failures**
    
258. **TLS failures**
    

Then Spring:

```text
Browser
   ↓ HTTPS
Spring Boot
   ↓ JDBC
PostgreSQL
```

---

# Phase 15 — Web Infrastructure

259. **Reverse proxy**
    
260. **Forward proxy**
    
261. **Load balancer**
    
262. **L4 load balancing**
    
263. **L7 load balancing**
    
264. **Nginx**
    
265. **HAProxy**
    
266. **API Gateway**
    
267. **Service discovery**
    
268. **Health checks**
    
269. **Connection pooling**
    
270. **Timeouts**
    
271. **Retries**
    
272. **Circuit breakers**
    

---

# Phase 16 — Distributed Systems Networking

Now networking becomes much more interesting.

273. **Distributed system**
    
274. **Partial failure**
    
275. **Network partitions**
    
276. **Latency**
    
277. **Timeouts**
    
278. **Retries**
    
279. **Idempotency**
    
280. **At-least-once delivery**
    
281. **At-most-once delivery**
    
282. **Exactly-once semantics**
    
283. **Message queues**
    
284. **Kafka**
    
285. **RabbitMQ**
    
286. **Event-driven architecture**
    
287. **Service-to-service communication**
    
288. **gRPC**
    
289. **REST vs gRPC**
    
290. **Service mesh**
    

---

# Phase 17 — Scale

291. **Horizontal scaling**
    
292. **Vertical scaling**
    
293. **Load balancing**
    
294. **CDN**
    
295. **Caching**
    
296. **Redis**
    
297. **Database replication**
    
298. **Read replicas**
    
299. **Connection pooling**
    
300. **Distributed caching**
    
301. **Distributed tracing**
    
302. **Observability**
    
303. **Metrics**
    
304. **Logs**
    
305. **OpenTelemetry**
    

---

# Phase 18 — Advanced Networking

After the foundation is solid:

306. **VLAN**
    
307. **802.1Q**
    
308. **STP**
    
309. **LACP**
    
310. **Link aggregation**
    
311. **VXLAN**
    
312. **Overlay networks**
    
313. **SDN**
    
314. **MPLS**
    
315. **Anycast**
    
316. **Multicast**
    
317. **IPv6 advanced routing**
    
318. **BGP advanced**
    
319. **Network virtualization**
    
320. **eBPF**
    

---

# Phase 19 — Modern Infrastructure

Finally:

321. **Docker networking**
    
322. **Docker bridge networks**
    
323. **Container DNS**
    
324. **Port publishing**
    
325. **Kubernetes networking**
    
326. **Services**
    
327. **Ingress**
    
328. **CNI**
    
329. **Service discovery**
    
330. **Kubernetes NetworkPolicy**
    
331. **Cloud networking**
    
332. **VPC**
    
333. **Subnets**
    
334. **Security groups**
    
335. **Cloud load balancers**
    
336. **Cloud NAT**
    
337. **Private networks**
    

---

# The actual dependency chain

Don't memorize 337 topics independently. The important thing is the dependency structure:

```text
Physical communication
        ↓
Signals
        ↓
Encoding / Modulation
        ↓
Ethernet / Wi-Fi
        ↓
MAC / Frames
        ↓
Switches / LAN
        ↓
IP
        ↓
Subnetting
        ↓
Routers / Routing
        ↓
TCP / UDP
        ↓
Ports / Sockets
        ↓
DNS
        ↓
HTTP
        ↓
TLS
        ↓
HTTPS
        ↓
NAT / DHCP
        ↓
Firewalls
        ↓
Proxies / Load Balancers
        ↓
Distributed Systems
        ↓
Containers / Kubernetes / Cloud
```

And underneath **everything**:

```text
Application
     ↓
Transport
     ↓
IP
     ↓
Link
     ↓
Physical
```

### Where I would put you right now

You've already covered the historical/conceptual foundation through:

```text
Telecommunication
      ↓
Telegraph
      ↓
Telephone
      ↓
Circuit switching
      ↓
Computer communication
      ↓
Modems
      ↓
Modulation
```



[[Networking]]