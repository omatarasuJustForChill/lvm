# LVM Tips
## 1. Basics
### create lvm phisical volume on /dev/vdb and /dev/vdc
```bash
pvcreate /dev/vdb
pvcreate /dev/vdc
```
### show lvm phisical volume
```bash
pvs
```
---
### create lvm vloume group from /dev/vdb /dev/vdc
```bash
vgcreate group-0 /dev/vdb /dev/vdc
```
### show lvm volume group
```bash
vgs
```
---
### create lvm logical volume
```bash
lvcreate group-0 -L 500M -n vol-0
lvcreate group-0 -L 1200M -n vol-1
```
### show logical volume 
```bash
lvs
```
---
### make file system on logical volume
```bash
mkfs.ext4 /dev/group-0/vol-0 
mkfs.ext4 /dev/group-0/vol-1
```
---
### add more disks
```bash 
pvcreate /dev/vdd /dev/vde
```
### extand lovume group
```bash
vgextend group-0 /dev/vdd /dev/vde
```
--- 
### extend vol-1
```bash
# add spce to logical volume
lvextend /dev/group-0/vol-1 -L +2G
# resize file system
resize2fs /dev/group-0/vol-1
```