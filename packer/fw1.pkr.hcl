# Firewall 1

packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1.1"
    }
  }
}

variable "root_password" {
  type      = string
  sensitive = true
}

source "qemu" "fw1" {

  iso_url = "https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/x86_64/alpine-virt-3.24.1-x86_64.iso"

  iso_checksum = "file:https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/x86_64/alpine-virt-3.24.1-x86_64.iso.sha256"

  output_directory = "output/fw1"
  vm_name          = "fw1.qcow2"

  accelerator    = "kvm"
  format         = "qcow2"
  disk_size      = "4G"
  disk_interface = "virtio"

  cpus   = 1
  memory = 512

  net_device = "virtio-net"

  http_directory = "answerfiles"

  communicator = "none"

  headless = false

  boot_wait = "20s"

  boot_command = [
    "root<enter><wait>",
    "ifconfig eth0 up && udhcpc -i eth0<enter><wait5>",
    "wget http://{{ .HTTPIP }}:{{ .HTTPPort }}/fw1-answerfile -O /root/fw1-answerfile<enter><wait5>",
    "ERASE_DISKS=/dev/vda setup-alpine -f /root/fw1-answerfile && sync && poweroff<enter><wait5>",
    "${var.root_password}<enter><wait>",
    "${var.root_password}<enter><wait10m>"
  ]
}

build {
  sources = ["source.qemu.fw1"]
}
