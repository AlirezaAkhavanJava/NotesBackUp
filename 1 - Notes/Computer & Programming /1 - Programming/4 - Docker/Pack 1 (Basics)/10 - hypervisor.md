


A **hypervisor** is software (sometimes helped by special CPU features) whose job is to create and run virtual machines. It sits between the real hardware and the guest operating systems, and it hands each guest a pretend computer: virtual CPUs, virtual memory, a virtual disk, a virtual network card. The guest OS boots on that pretend hardware and has no idea it isn't real.

## The problem it solves

An operating system kernel is written with a big assumption: _I am the only boss of this machine._ It expects to control all the memory, talk directly to the CPU in its most privileged mode, and own every device. If you try to boot two kernels on one machine, they fight, each one stomping on the other's memory and hardware settings.

The hypervisor is the referee that makes that possible. It lets each guest kernel _believe_ it's in charge, while secretly keeping real control itself. A rough technical analogy is how your kernel gives each normal process the illusion of having its own private memory. A hypervisor does the same trick one level up, giving each whole _operating system_ the illusion of having its own private machine. Where the analogy breaks down: a process only needs a fake memory space, but a guest OS needs fake _everything_, including the privileged CPU instructions, which is much harder to pull off.

## How it actually works

There are three main jobs the hypervisor does.

**CPU.** The guest kernel wants to run privileged instructions, the ones that normally only the OS may use. Letting it do that on the real CPU would be dangerous, because it could take over the whole machine. Modern CPUs solve this with hardware virtualization support, called **Intel VT-x** or **AMD-V**. These add a new, even more privileged mode for the hypervisor, so the guest kernel can run at full speed in a "guest mode" and the CPU automatically hands control to the hypervisor whenever the guest does something sensitive. Before this hardware support existed, hypervisors had to translate or trap those instructions in software, which was slow and complicated.

**Memory.** The guest thinks it owns physical memory starting at address zero. In reality, its "physical" addresses are just more virtual addresses. The hypervisor keeps a second layer of address translation (the CPU feature for this is called **EPT** on Intel and **NPT** on AMD) that maps the guest's pretend physical memory onto real chunks of RAM. Different guests get different real chunks, so they can't touch each other.

**Devices.** The guest wants a disk and a network card. The hypervisor presents virtual ones, either by emulating a real old device model, or, faster, by offering special **paravirtualized** devices (like **virtio**) that the guest knows are virtual and can talk to efficiently. When the guest writes to its "disk," the hypervisor turns that into a write to a file or block device on the host.

## Two types

This is the classification you'll see everywhere.

**Type 1 (bare-metal).** The hypervisor runs directly on the hardware, with no ordinary OS underneath it. Examples: VMware ESXi, Xen, Microsoft Hyper-V. This is common in data centers, where the machine exists only to host VMs.

**Type 2 (hosted).** The hypervisor runs as a program on top of a normal operating system. Examples: VirtualBox, VMware Workstation. This is what most people use on a laptop.

The tidy split gets blurry in real life. **KVM**, the one built into Linux, turns the Linux kernel itself into a Type 1 hypervisor: loading the `kvm` module makes your Debian kernel the thing that manages VMs. Yet it still looks like a Type 2 setup, because you're running a regular desktop OS. That's why people argue about which category it belongs in. The categories are a teaching aid, not a strict rule.

## What you'd use on Debian

The usual Linux stack is two cooperating pieces:

- **KVM** is the kernel part. It uses VT-x/AMD-V and does the CPU and memory work fast.
- **QEMU** is a userspace program that provides the virtual devices and actually launches the VM, using KVM underneath for speed.

Front ends like **virt-manager** or **libvirt** sit on top and give you a friendlier way to create and manage them. You can check whether your CPU supports the hardware features with:

```bash
lscpu | grep -i virtualization     # shows VT-x or AMD-V
ls /dev/kvm                        # exists if KVM is available
```

## Connecting it back to containers

Now the difference we discussed earlier has a precise form. A VM needs a hypervisor because it runs a _second kernel_ that has to be tricked into thinking it owns the machine. A container has no second kernel, so it needs **no hypervisor at all**. It just uses the one real kernel, with namespaces and cgroups limiting what the process sees and uses. That's exactly why containers start in a blink and VMs take longer: one is a restricted process, the other is a whole booted machine.

A good small experiment, if you want to feel it: install `virt-manager` or QEMU, boot a tiny Linux ISO as a VM, and run `uname -r` inside it. Compare that with `uname -r` inside a Docker container. The VM will report its _own_ kernel, and the container will report your host's. That one difference is the whole story.





[[Docker]]