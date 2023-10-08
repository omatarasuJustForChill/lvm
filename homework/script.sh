sudo su
# creating tmp lv for root
pvcreate /dev/vdb
vgcreate tmp_vg /dev/vdb
lvcreate tmp_vg -n tmp_root -l +100%FREE
mkfs.xfs /dev/tmp_vg/tmp_root
# copy root to tmp_lv
mount /dev/tmp_vg/tmp_root /mnt
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
# generate grub config and reboot
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;
s/.img//g"` --force; done
sed -i s/"rd.lvm.lv=VolGroup00\/LogVol00"/"rd.lvm.lv=tmp_vg\/tmp_root"/ grub2/grub.cfg
exit
reboot

# resize main root and copy data
sudo su
lvremove /dev/VolGroup00/LogVol00
lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
mkfs.xfs /dev/VolGroup00/LogVol00
mount /dev/VolGroup00/LogVol00 /mnt
xfsdump -J - /dev/tmp_vg/tmp_root | xfsrestore -J - /mnt
# generate grub config 
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;
s/.img//g"` --force; done
exit
reboot
# create lv raid1 for var and copy all data
pvcreate /dev/vde /dev/vdd
vgcreate var_vg /dev/vde /dev/vdd
lvcreate -L 950M -m1 -n var_lv var_vg
mkfs.ext4 /dev/var_vg/var_lv
mount /dev/var_vg/var_lv /mnt
cp -aR /var/* /mnt/
rm -rf /var/*
umount /mnt
mount /dev/var_vg/var_lv /var
echo "`blkid | grep var_lv: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
# remove tmp vg
lvremove /dev/tmp_vg/tmp_root 
vgremove tmp_vg 
pvremove /dev/vdb
# create lv for home and move it
lvcreate -n home_lv -L 2G VolGroup00 
mkfs.xfs /dev/VolGroup00/home_lv 
mount /dev/VolGroup00/home_lv /mnt/
cp -aR /home/* /mnt/
rm -rf /home/*
umount /mnt
mount /dev/VolGroup00/home_lv /home/
echo "`blkid | grep home_lv | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab 
# create snap and megre it
touch /home/file{1..20}
lvcreate -L 100M -s -n snap_home_lv VolGroup00/home_lv
rm -f /home/file{11..20}
umount /home
lvconvert --merge /dev/VolGroup00/snap_home_lv
mount /home