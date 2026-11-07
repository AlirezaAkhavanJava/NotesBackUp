Chronologically, we're roughly at the **mid-2000s → early 2010s** now: Web 2.0 has made the Web interactive, and the next major shift is **social networking + smartphones + mobile Internet**.

There are actually **two parallel evolutions** that eventually merge:

```text
WEB 2.0
   │
   ├──────────────→ Social Web
   │                   │
   │                   ↓
   │              Social media
   │
   └──────────────→ Mobile Web
                       │
                       ↓
                  Smartphones
                       │
                       ↓
                 Mobile apps
                       │
                       └──────→ Social media everywhere
```

# 1. Before social media

The Web initially looked roughly like:

```text
Publisher
    ↓
Website
    ↓
User
```

Then Web 2.0 changed it:

```text
User
 ↓
creates content
 ↓
platform
 ↓
other users
```

This created the conditions for social networking.

---

# 2. What is a social network?

A **social network** is a system where users have persistent identities and relationships with other users.

Technically, you can model it as a graph:

```text
Alice ───── Bob
  │          │
  │          │
  └──── Charlie
```

Users are **nodes**.

Relationships are **edges**.

This is actually very similar to how PageRank viewed the Web:

```text
PageRank:

Page A ──→ Page B
```

versus social networks:

```text
User A ──→ User B
```

The difference is what the graph represents.

---

# 3. The early social-network era

There wasn't one single "first social media site."

Different services introduced different pieces of the concept.

### SixDegrees — 1997

SixDegrees.com launched in 1997.

It allowed users to:

- create profiles
    
- add friends
    
- browse friend networks
    

This is very close to what we now recognize as a social network.

Its core model was:

```text
User
 ├── profile
 ├── friends
 └── network
```

It was an important early example, but the Internet wasn't yet ready for mass social networking.

---

# 4. Why didn't SixDegrees dominate?

The technology and user base weren't mature enough.

Problems included:

```text
Slow Internet
     +
Few Internet users
     +
Dial-up
     +
Limited Web technology
     +
Few people online
```

You had the idea before you had the infrastructure for it to explode.

This happens repeatedly in computing history.

---

# 5. Friendster — 2002

Friendster launched in 2002.

It became one of the first major social-networking services.

The model:

```text
Create profile
      ↓
Find friends
      ↓
Connect
      ↓
See their profiles
      ↓
Build social graph
```

It became extremely popular, particularly in Asia.

But scaling and technical problems eventually hurt it badly.

---

# 6. MySpace — 2003

Myspace launched in 2003.

MySpace pushed social networking much further into mainstream culture.

Users could customize profiles, post content, connect with friends, and follow music.

The Web was increasingly becoming:

```text
Website
   ↓
Identity
   ↓
Social relationships
   ↓
User-generated content
```

---

# 7. Facebook — 2004

Then:

Facebook launched in 2004, initially for Harvard students.

It expanded to other universities and eventually the general public.

The important thing wasn't simply "another social network."

Facebook combined:

```text
Identity
   +
Social graph
   +
User-generated content
   +
News Feed
   +
Messaging
   +
Photos
   +
Applications
```

The **News Feed** became particularly important because users no longer had to visit individual profiles to discover content.

Instead:

```text
Friends
  ↓
content
  ↓
ranking
  ↓
personalized feed
```

This is another place where **ranking algorithms** became extremely important.

---

# 8. YouTube — 2005

YouTube launched in 2005.

It solved a different problem:

> How can ordinary users easily upload and distribute video over the Web?

Before:

```text
Video
 ↓
large file
 ↓
difficult hosting/distribution
```

YouTube:

```text
User
 ↓
Upload
 ↓
YouTube infrastructure
 ↓
encoding/storage
 ↓
streaming
 ↓
millions of viewers
```

This was another major Web 2.0 transformation.

---

# 9. Twitter — 2006

Twitter launched in 2006.

It introduced a different model:

```text
User
 ↓
short message
 ↓
followers
 ↓
real-time distribution
```

The important concept was **following** rather than requiring mutual friendship.

That created a directed social graph:

```text
Alice ─────→ Bob
```

Alice follows Bob.

Bob doesn't necessarily follow Alice.

---

# 10. But something else was happening: smartphones

At the same time, mobile phones were evolving.

Early mobile phones were primarily:

```text
Calls
SMS
Contacts
```

Then mobile devices gained:

```text
Web browsers
Email
Cameras
Music
Wi-Fi
Bluetooth
GPS
Better CPUs
Better displays
```

The phone was becoming a **general-purpose computer**.

---

# 11. BlackBerry

BlackBerry was extremely important before the iPhone.

BlackBerry devices were especially known for:

- email
    
- messaging
    
- physical keyboards
    
- mobile Internet
    
- enterprise communication
    

The major conceptual shift was:

```text
Internet
   ↓
not something you visit
   ↓
something you carry
```

---

# 12. iPhone — 2007

Then came the huge transition:

Apple introduced the first iPhone in **2007**.

It combined:

```text
Phone
+
iPod
+
Internet communicator
```

The important thing wasn't merely having a touchscreen.

It was bringing together:

```text
CPU
GPU
Operating system
Touch UI
Web browser
Camera
Wi-Fi
Cellular network
Sensors
```

into one mass-market device.

---

# 13. Android — 2008

Then:

Google and the Open Handset Alliance brought Android to the market.

The first commercially available Android phone was the **HTC Dream / T-Mobile G1**, released in 2008.

Now smartphones weren't limited to one ecosystem.

The mobile computing market expanded dramatically.

---

# 14. The App Store changed everything

Apple launched the **App Store in 2008**.

Before:

```text
Phone
 ↓
manufacturer/carrier software
```

After:

```text
Phone
 ↓
App ecosystem
 ├── Facebook
 ├── YouTube
 ├── games
 ├── banking
 ├── maps
 ├── messaging
 └── thousands of others
```

This was a major architectural change.

The smartphone became a **platform for third-party software**.

---

# 15. Social media + smartphone = huge transformation

Now combine the two timelines:

```text
Web 2.0
   ↓
User-generated content
   ↓
Social networks
   ↓
Facebook / YouTube / Twitter
```

and:

```text
Smartphones
   ↓
Mobile Internet
   ↓
Apps
   ↓
Camera + GPS + notifications
```

They merge:

```text
                 SMARTPHONE
                     │
       ┌─────────────┼─────────────┐
       ↓             ↓             ↓
    Camera          GPS        Notifications
       │             │             │
       └─────────────┼─────────────┘
                     ↓
                SOCIAL MEDIA
                     ↓
              Instant sharing
                     ↓
                 Everyone
```

This changed social media fundamentally.

---

# 16. The camera was particularly important

Before smartphones:

```text
Take photo
   ↓
Digital camera
   ↓
Transfer to computer
   ↓
Upload
   ↓
Share
```

Smartphone:

```text
Camera
  ↓
Photo
  ↓
App
  ↓
Internet
  ↓
Social network
```

The distance between **creating content** and **publishing content** became almost zero.

That's a massive reason social media exploded.

---

# 17. Notifications changed behavior

A traditional website:

```text
You
 ↓
open browser
 ↓
visit website
 ↓
check for updates
```

Smartphone:

```text
Someone posts
     ↓
server
     ↓
push notification
     ↓
your phone
     ↓
you immediately know
```

Now the Internet could actively **reach you**.

That is an enormous shift from the early Web.

---

# 18. Mobile architecture

Modern social apps increasingly looked like:

```text
             MOBILE APP
                  │
             HTTPS/JSON
                  │
                  ↓
             API SERVER
                  │
       ┌──────────┼──────────┐
       ↓          ↓          ↓
   Database     Cache      Storage
       │
       ↓
    users/posts
```

And behind large services:

```text
Mobile app
    ↓
Load balancers
    ↓
API servers
    ↓
Microservices
    ↓
Databases
    ↓
Caches
    ↓
Object storage
    ↓
CDNs
```

This is where **distributed systems** became increasingly necessary.

---

# 19. The problems created by this era

Social + mobile solved huge problems, but created new ones.

### Scale

Millions → hundreds of millions → billions of users.

### Privacy

Platforms now know enormous amounts about users.

### Surveillance / tracking

```text
User
 ↓
clicks
likes
searches
location
contacts
photos
messages
 ↓
platform
```

### Addiction / engagement optimization

Platforms began optimizing:

```text
"What keeps users engaged?"
```

rather than merely:

```text
"What information does the user need?"
```

### Misinformation

Anyone could publish instantly to millions of people.

### Moderation

Platforms had to determine:

```text
What content is allowed?
What should be removed?
What should be recommended?
```

### Security

Accounts became valuable targets:

```text
password theft
session theft
phishing
account takeover
malware
API attacks
```

---

# 20. The historical chain we're building

You can now see the whole progression:

```text
1960s
Packet switching
      ↓
1969
ARPANET
      ↓
1970s
TCP/IP
      ↓
1983
DNS
      ↓
1989–90
World Wide Web
      ↓
1993
Mosaic
      ↓
1990s
Commercial Web
      ↓
late 1990s
Search engines / Google
      ↓
2000s
Web 2.0
      ↓
AJAX + JavaScript + JSON + APIs
      ↓
Social Web
      ↓
2002
Friendster
      ↓
2003
MySpace
      ↓
2004
Facebook
      ↓
2005
YouTube
      ↓
2006
Twitter
      ↓
2007
iPhone
      ↓
2008
Android + App Store
      ↓
2010s
Mobile + Social
      ↓
Modern Internet
```

And the deepest transformation is:

```text
EARLY INTERNET
"Computers communicate."

        ↓

WEB
"Documents are connected."

        ↓

WEB 2.0
"Users interact and create."

        ↓

SOCIAL WEB
"Users connect to users."

        ↓

SMARTPHONE
"Everyone carries an Internet-connected computer."

        ↓

MODERN INTERNET
"People, applications, services, devices,
and distributed systems are continuously connected."
```

The next major historical step after this is **cloud computing, CDNs, mobile apps, app ecosystems, and the rise of large-scale distributed systems**—which connects directly to why modern backend engineering looks so different from the original Web server.



[[Networking]]