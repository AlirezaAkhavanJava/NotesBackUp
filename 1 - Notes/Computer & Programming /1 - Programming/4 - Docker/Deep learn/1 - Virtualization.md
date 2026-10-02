## What is virtualization?

Virtualization is a technology that enables the creation of virtual environments from a single physical machine, allowing for more efficient use of resources by distributing them across computing environments.

**Virtualization** is the technique of using software to create a _virtual_ version of something physical—most commonly a computer, operating system, storage device, or network.

In plain terms: one physical machine pretends to be many machines.

A **hypervisor** (the boss software) sits between the hardware and the virtual machines (VMs). It slices up CPU, memory, storage, and networking, then hands those slices to each VM so they behave like independent computers—even though they’re sharing the same physical box.

Why humans invented this clever illusion:

- Better hardware utilization (no idle servers collecting dust)
    
- Isolation (one VM crashes, others keep living)
    
- Flexibility (spin up, clone, snapshot, delete machines fast)
    
- Cost savings (fewer physical machines, less power, less pain)
    

Classic example:  
One laptop → runs Windows, Linux, and a test server **at the same time**, all isolated, all convinced they’re real.

Virtualization is basically Plato’s Cave for computers—shadows that still get real work done.

---

## Types of virtualization 


![[Pasted image 20251221181236.png]]

#### 1. Hardware / Server Virtualization

Server virtualization is *the process of dividing a physical server into multiple unique and isolated virtual servers by means of a software application*. Each virtual server can run its own operating systems independently.

![[Pasted image 20251221181820.png]]

**What is virtualized:** Physical hardware  
**How:** Hypervisor (Type 1 or Type 2)  
**Result:** Multiple full virtual machines, each with its own OS

Examples: VMware, VirtualBox, KVM, Hyper-V  
Truth: This is the _foundation_ on which cloud and Docker often sit.

---

## 2. Operating System Virtualization (Containers)


##### Tags : [[1 - Docker 🧋]]