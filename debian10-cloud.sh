#!/bin/bash
# Define variables used in this script
SRC_IMG="https://cloud.debian.org/images/cloud/buster/latest/debian-10-genericcloud-amd64.qcow2"
IMG_NAME="/root/debian-10-genericcloud-amd64.qcow2"

TEMPL_NAME="debian10-cloud"
VMID="9001"
MEM="512"
DISK_SIZE="20G"
DISK_STOR="local-lvm"
NET_BRIDGE="vmbr0"

# Step 1: Download the image
wget -O $IMG_NAME $SRC_IMG

# Step 2: Add QEMU Guest Agent
apt update
apt install -y libguestfs-tools
virt-customize --install qemu-guest-agent -a $IMG_NAME

# Step 3: Create a VM in Proxmox with required settings and convert to template
qm create $VMID --name $TEMPL_NAME --memory $MEM --net0 virtio,bridge=$NET_BRIDGE
qm importdisk $VMID $IMG_NAME $DISK_STOR
qm set $VMID --scsihw virtio-scsi-pci --scsi0 $DISK_STOR:vm-$VMID-disk-0
qm set $VMID --ide2 $DISK_STOR:cloudinit
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --serial0 socket --vga serial0
qm set $VMID --ipconfig0 ip=dhcp
qm set $VMID --agent enabled=1,fstrim_cloned_disks=1
qm resize $VMID scsi0 $DISK_SIZE
qm template $VMID

# Step 4: Remove downloaded image
rm $IMG_NAME
