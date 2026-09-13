# Cloud (Cloud Computing)

## Definition

**Cloud** (Cloud Computing) is the delivery of computing services — servers, storage, databases, networking, software, and more — over the **internet** ("the cloud") instead of using your own local hardware. You access these resources on-demand, pay only for what you use, and someone else manages the physical machines.

**Simple version:** Instead of buying and running your own servers, you rent them from a provider over the internet.

---

## Key Characteristics

| Feature | Description |
|---------|-------------|
| **On-demand** | Get resources instantly when needed |
| **Pay-as-you-go** | Pay only for what you use |
| **Scalable** | Scale up/down automatically |
| **Elastic** | Grow or shrink with demand |
| **Remote** | Accessed over the internet |
| **Managed** | Provider handles hardware, power, cooling |
| **Shared** | Multi-tenant (many users share infrastructure) |

---

## The 3 Main Service Models

| Model | Full Name | What You Get | Example |
|-------|-----------|--------------|---------|
| **IaaS** | Infrastructure as a Service | Virtual machines, storage, network | AWS EC2, Azure VMs |
| **PaaS** | Platform as a Service | Ready platform to deploy apps | Heroku, Google App Engine |
| **SaaS** | Software as a Service | Ready-to-use software | Gmail, Office 365, Netflix |

### Pizza Analogy 🍕

| Model | Analogy |
|-------|---------|
| **On-premise** | You grow wheat, make pizza at home |
| **IaaS** | You buy dough, make pizza at home |
| **PaaS** | You buy a ready pizza base, add toppings |
| **SaaS** | You order pizza delivery |

---

## The 4 Deployment Models

| Model | Description | Example |
|-------|-------------|---------|
| **Public Cloud** | Open to everyone, owned by provider | AWS, Azure, Google Cloud |
| **Private Cloud** | Single organization only | Company data center |
| **Hybrid Cloud** | Mix of public + private | Bank using both |
| **Community Cloud** | Shared by several orgs with same needs | Government agencies |

---

## How Cloud Works (Simple Diagram)

```
   WITHOUT CLOUD                      WITH CLOUD
   ─────────────                      ──────────

   🏢 Your building                   💻 Your device
   ┌──────────────┐                    |
   │ 🖥️ Server    │                    | internet
   │ 🖥️ Server    │                    ▼
   │ 💾 Storage   │              ☁️ Cloud Provider
   │ 🔌 Power     │              ┌──────────────┐
   │ ❄️ Cooling   │              │ 🖥️🖥️🖥️ Servers│
   │ 👨 IT staff  │              │ 💾 Storage    │
   └──────────────┘              │ 🌐 Network    │
   (you pay for all)             │ 🔒 Security   │
                                 └──────────────┘
                                 (you pay only for use)
```

---

## What Problem Does Cloud Solve?

| Problem | How Cloud Solves It |
|---------|---------------------|
| Buying servers is expensive | Rent instead, pay-as-you-go |
| Hardware can't handle traffic spikes | Auto-scale instantly |
| Managing hardware is hard | Provider handles it |
| Need global reach | Deploy in data centers worldwide |
| Backups and disasters | Built-in redundancy |
| Slow to set up new servers | Launch in minutes |
| Remote work | Access from anywhere |

---

## Major Cloud Providers

| Provider | Known For |
|----------|-----------|
| **AWS** (Amazon) | Largest, most services |
| **Azure** (Microsoft) | Enterprise, Windows integration |
| **Google Cloud (GCP)** | AI/ML, Kubernetes |
| **Oracle Cloud** | Databases, enterprise |
| **IBM Cloud** | Hybrid, AI |
| **Alibaba Cloud** | Asia region leader |

---

## Cloud vs Traditional (On-Premise)

| Aspect | **On-Premise** | **Cloud** |
|--------|----------------|-----------|
| **Ownership** | You own hardware | Provider owns hardware |
| **Cost** | Big upfront (CapEx) | Pay-as-you-go (OpEx) |
| **Setup time** | Weeks/months | Minutes |
| **Scaling** | Buy more hardware | Click a button |
| **Maintenance** | You do it | Provider does it |
| **Access** | Local network | Anywhere via internet |
| **Security** | You control | Shared responsibility |

---

## Real-Life Analogy

| Real world | Cloud |
|------------|-------|
| 🏠 Owning a house | On-premise server |
| 🏨 Renting a hotel room | Cloud (pay per night) |
| ⚡ Electricity from a utility | Cloud computing (pay for what you use) |
| 🚗 Owning a car | On-premise |
| 🚕 Using Uber | Cloud (on-demand) |

---

## Common Cloud Services You Use Daily

- 📧 Gmail / Outlook → SaaS
- 📸 Google Photos / iCloud → Storage
- 🎬 Netflix / YouTube → Streaming (cloud-hosted)
- 📄 Google Docs / Office 365 → SaaS
- 🎮 Online games → Cloud servers
- 💾 Dropbox / OneDrive → Cloud storage

---

## Linux Commands Related to Cloud

| Command | Definition | Example |
|---------|-----------|---------|
| `aws` | AWS CLI | `aws s3 ls` |
| `az` | Azure CLI | `az vm list` |
| `gcloud` | Google Cloud CLI | `gcloud compute instances list` |
| `kubectl` | Kubernetes control | `kubectl get pods` |
| `docker` | Container management | `docker ps` |
| `terraform` | Infrastructure as Code | `terraform apply` |
| `ansible` | Configuration management | `ansible-playbook site.yml` |
| `rclone` | Sync to cloud storage | `rclone sync /data remote:bucket` |
| `s3cmd` | S3 storage tool | `s3cmd ls s3://bucket` |
| `curl` | Access cloud APIs | `curl https://api.cloud.com` |

---

## Summary

- **Cloud** = renting computing over the internet instead of owning hardware.
- **3 service models:** IaaS, PaaS, SaaS.
- **4 deployment models:** Public, Private, Hybrid, Community.
- **Key benefits:** on-demand, scalable, pay-as-you-go, global, managed.
- **Big providers:** AWS, Azure, Google Cloud.
- **Not magic** — it's just someone else's computers, accessed over the internet.

[[Networking]]