# DMZ Firewalls Installation and Deployment

This document shows the automated installation and deployment of the two Linux firewalls used to protect and segment the web server infrastructure.

---

## 1. Host and Virtual Machine Requirements

Check the CPU architecture of the host:

```bash
uname -m
```

Firewall virtual hardware

Both firewalls use:

- OS: Alpine Linux 3.24.1 (generic Linux is used only as the libvirt OS identifier).
- RAM: 512 MiB.
- CPUs: 1 vCPU.
- Storage: 4 GiB.
- Disk format: QCOW2.
- Network adapter model: VirtIO.
FW1 network interfaces
- NIC 1 → default → WAN → 192.168.122.0/24
- NIC 2 → web-dmz → DMZ → 10.0.0.32/28
FW2 network interfaces
- NIC 1 → web-dmz → DMZ → 10.0.0.32/28
- NIC 2 → internal-net → Internal → 10.0.0.0/27
- NIC 3 → management-net → Management → 10.0.0.48/29

This NICs design allows FW1 and FW2 to route and filter traffic between different security zones.



## 2. Automated Alpine Linux Installation with Packer

### 2.1 Prepare the answerfiles

The result of the Alpine installation answerfiles and packer templates must be this:

```bash
Nuno@ubuntu:~/projects/web-server/packer$ tree -L 2
.
├── answerfiles
│   ├── fw1-answerfile
│   └── fw2-answerfile
├── fw1.pkr.hcl
├── fw2.pkr.hcl
├── output
│   ├── fw1
│   └── fw2
└── secret.auto.pkrvars.hcl
```

These answerfiles fw1-answerfile and fw2-answerfile provide the configuration used by setup-alpine during the automated operating system installation.


### 2.2 Prepare the Packer templates

The firewall image definitions are stored in:

```bash
Nuno@ubuntu:~/projects/web-server/packer$ tree -L 1 -I "answerfiles|output|secret.auto.pkrvars.hcl"
.
├── fw1.pkr.hcl
└── fw2.pkr.hcl
```


## 3. Build the Firewall Images

From the directory initialize Packer

```bash
cd ~/projects/web-server/packer 
packer init fw1.pkr.hcl
```

Downloads and initialises the QEMU plugin required by Packer to create the virtual machine images. The example of output:

```bash
Installed plugin github.com/hashicorp/qemu v1.1.6 in "/home/vant/.config/packer/plugins/github.com/hashicorp/qemu/packer-plugin-qemu_v1.1.6_x5.0_linux_amd64"
```

Format the templates: 

```bash
packer fmt fw1.pkr.hcl
packer fmt fw2.pkr.hcl
```

Validate the templates:

```bash
packer validate -var-file=secret.auto.pkrvars.hcl fw1.pkr.hcl
packer validate -var-file=secret.auto.pkrvars.hcl fw2.pkr.hcl
```
Checks the Packer configuration and required variables before starting the build.

- secret.auto.pkrvars.hcl contains sensitive build variables and must not be committed to Git.

Now build FW1:

```bash
rm -rf output/fw1
packer build -var-file=secret.auto.pkrvars.hcl fw1.pkr.hcl
```

Build FW2:

```bash
rm -rf output/fw2
packer build -var-file=secret.auto.pkrvars.hcl fw2.pkr.hcl
```

To check the build process:

```bash
ls -lh ~/projects/web-server/packer/output/fw1/
ls -lh ~/projects/web-server/packer/output/fw2/
```

Checks if Packer is creating the firewall disk images and displays their current size.


Verify the final images to confirm that both automated firewall images were successfully created.

```bash
ls -lh output/fw1/fw1.qcow2
ls -lh output/fw2/fw2.qcow2
```


## 4. Deploy the Images with libvirt

Copy the generated images to the libvirt storage directory:

```bash
sudo cp output/fw1/fw1.qcow2 /var/lib/libvirt/images/fw1.qcow2
sudo cp output/fw2/fw2.qcow2 /var/lib/libvirt/images/fw2.qcow2
```

Copies the Packer-generated disks to the standard storage location used by the libvirt virtual machines.

Set the correct ownership:

```bash
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/fw1.qcow2
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/fw2.qcow2
```

This permissions allows the libvirt/QEMU process to access and modify the firewall disk images.



## 5. Verify the Virtual Networks

Before creating the firewall VMs:

```bash
virsh net-list --all
```

Lists all libvirt virtual networks and shows whether they are active, persistent and configured to start automatically.



## 6. Create FW1

```bash
sudo virt-install \
  --connect qemu:///system \
  --name fw1 \
  --memory 512 \
  --vcpus 1 \
  --import \
  --disk path=/var/lib/libvirt/images/fw1.qcow2,format=qcow2,bus=virtio \
  --network network=default,model=virtio \
  --network network=web-dmz,model=virtio \
  --graphics spice \
  --osinfo detect=on,require=off \
  --noautoconsole
```

Imports the Packer image as the fw1 virtual machine and connects it to the WAN and DMZ networks.



## 7. Create FW2

```bash
sudo virt-install \
  --connect qemu:///system \
  --name fw2 \
  --memory 512 \
  --vcpus 1 \
  --import \
  --disk path=/var/lib/libvirt/images/fw2.qcow2,format=qcow2,bus=virtio \
  --network network=web-dmz,model=virtio \
  --network network=internal-net,model=virtio \
  --network network=management-net,model=virtio \
  --graphics spice \
  --osinfo detect=on,require=off \
  --noautoconsole
```

Imports the Packer image as the fw2 virtual machine and connects it to the DMZ, Internal and Management networks.


## 8. Verify the Virtual Machines

```bash
virsh list --all
```


**Future Scope**

The following functions are outside the current implementation and may be evaluated in future versions:

- IDS/IPS with Snort.
- VPN.
- Dynamic routing with OSPF/BGP.
- High Availability (HA).
- Advanced NGFW functions for FW1.





## Resources

[1] Linux Professional Institute, *LPIC-2 Study Guide*, Topic 205, 
“Networking Configuration,” Objectives 205.1–205.3.

[2] Linux Professional Institute, *LPIC-2 Study Guide*, Topic 212, 
“System Security,” Objective 212.1, “Configuring a Router.”

[3] Alpine Linux, “Alpine Configuration Management Scripts — setup-alpine,” 
*Alpine Linux Wiki*. [Online]. Available: 
https://wiki.alpinelinux.org/wiki/Alpine_configuration_management_scripts#setup-alpine. 
[Accessed: Aug. 24, 2026].

[4] Alpine Linux, “Configure Networking,” *Alpine Linux Wiki*. [Online]. 
Available: https://wiki.alpinelinux.org/wiki/Configure_Networking. 
[Accessed: Aug. 24, 2026].

[5] HashiCorp, “QEMU Builder,” *Packer Documentation*. [Online]. Available: 
https://developer.hashicorp.com/packer/integrations/hashicorp/qemu/latest/components/builder/qemu. 
[Accessed: Aug. 24, 2026].

[6] libvirt Project, “Creating a New Virtual Machine in Virtual Machine Manager,” 
*libvirt Wiki*. [Online]. Available: 
https://wiki.libvirt.org/CreatingNewVM_in_VirtualMachineManager.html. 
[Accessed: Aug. 24, 2026].
