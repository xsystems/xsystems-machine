# Full Disk Encryption

## TL;DR

1. Download Arch Linux [here][arch_download]
2. Create an LiveUSB following [these steps][arch_live_usb]
3. Checkout this repository
4. Create from this `README.md` file the executable setup script `target/setup.sh` by running `build.sh`
5. Copy `setup.sh` to the LiveUSB
6. Boot from the LiveUSB
7. Run `setup.sh`

## Overview

```
+----------------------+-----------------------------+-----------------------------+
| EFI System partition | Boot partition              | System partition            |
| /boot/efi         (5)| /boot                    (5)| /                        (5)|
+----------------------+-----------------------------+-----------------------------+
|                      |                             | LVM: Logical volume 1       |
|                      |                             | /dev/mapper/system-root  (4)|
|                      |                             +-----------------------------+
|                      | LUKS: Encrypted partition   | LUKS: Encrypted partition   |
|                      | /dev/mapper/crypt-boot   (3)| /dev/mapper/crypt-system (3)|
|                      +-----------------------------+-----------------------------+
| Partition: Type 8300 | Partition: Type 8300        | Partition: Type 8E00        |
| /dev/nvme0n1p1    (2)| /dev/nvme0n1p2           (2)| /dev/nvme0n1p3           (2)|
+----------------------+-----------------------------+-----------------------------+
| /dev/nvme0n1                                                                  (1)|
+----------------------------------------------------------------------------------+

+----------------------------------------------------+
| Data partition                                     |
| /media/data-00                                  (5)|
+----------------------------------------------------+
| LVM: Logical volume 2                              |
| /dev/mapper/data-00                             (4)|
+----------------------------------------------------+
| LUKS: Encrypted partition                          |
| /dev/mapper/crypt-data                          (3)|
+----------------------------------------------------+
| Partition: Type 8E00                               |
| /dev/sda1                                       (2)|
+----------------------------------------------------+
| /dev/sda                                        (1)|
+----------------------------------------------------+
```


## Verify Prerequisites and Collect User Input

Verify that UEFI boot mode is enabled:
```sh
if [ -d /sys/firmware/efi/efivars ]; then
  echo "[  OK  ] UEFI boot mode is enabled"
else
  echo "[FAILED] UEFI boot mode is enabled"
  HAS_UNMET_PREREQUISITE=true
fi
```

Verify that there is an internet connection:
```sh
if ping -c 4 google.com 2>&1 >/dev/null; then
  echo "[  OK  ] There is internet connection"
else
  echo "[FAILED] There is internet connection"
  HAS_UNMET_PREREQUISITE=true
fi
```

Continue ONLY when ALL the prerequisites are met:
```sh
if [ "${HAS_UNMET_PREREQUISITE}" = true ]; then
  exit 1
fi
```

Read all required user input at once:
```sh
read -p "Hostname: " HOSTNAME
read -p "Disk Encryption Passphrase: " -s DISK_ENCRYPTION_PASSPHRASE; echo
read -p "Disk Encryption Passphrase (verify): " -s DISK_ENCRYPTION_PASSPHRASE_VERIFY; echo

if [ "${DISK_ENCRYPTION_PASSPHRASE}" = "${DISK_ENCRYPTION_PASSPHRASE_VERIFY}" ]; then
  echo "[  OK  ] Disk encryption passphrase matches"
else
  echo "[FAILED] Disk encryption passphrase matches"
  exit 1
fi
```

Update the system clock:
```sh
timedatectl set-ntp true
```


## Prepare System Drive

Create the partitions:
```sh
sgdisk /dev/nvme0n1 --clear
sgdisk /dev/nvme0n1 --new=1:0:+512M
sgdisk /dev/nvme0n1 --new=2:0:+512M
sgdisk /dev/nvme0n1 --new=3:0:0
sgdisk /dev/nvme0n1 --typecode=1:C12A7328-F81F-11D2-BA4B-00A0C93EC93B
```

Generate encryption key file:
```sh
mkdir /keys
mount --types ramfs ramfs /keys

dd bs=512 count=4 if=/dev/urandom of=/keys/luks.key
```

Encrypt, setup LVM on, and format the system partition:
```sh
echo -n "${DISK_ENCRYPTION_PASSPHRASE}" | cryptsetup luksFormat --type luks2 /dev/nvme0n1p3 -
echo -n "${DISK_ENCRYPTION_PASSPHRASE}" | cryptsetup luksAddKey /dev/nvme0n1p3 /keys/luks.key -
echo -n "${DISK_ENCRYPTION_PASSPHRASE}" | cryptsetup open /dev/nvme0n1p3 crypt-system -

pvcreate /dev/mapper/crypt-system
vgcreate system /dev/mapper/crypt-system
lvcreate --name root --extents 100%FREE system

mkfs.ext4 /dev/mapper/system-root
```

Encrypt and format the boot partition:
```sh
echo -n "${DISK_ENCRYPTION_PASSPHRASE}" | cryptsetup luksFormat /dev/nvme0n1p2 -
echo -n "${DISK_ENCRYPTION_PASSPHRASE}" | cryptsetup luksAddKey /dev/nvme0n1p2 /keys/luks.key -
echo -n "${DISK_ENCRYPTION_PASSPHRASE}" | cryptsetup open /dev/nvme0n1p2 crypt-boot -

mkfs.ext4 /dev/mapper/crypt-boot
```

Format the EFI System Partition:
```sh
mkfs.fat -F32 /dev/nvme0n1p1
```


## Prepare Data Drive

Create the partition:
```sh
sgdisk /dev/sda --clear
sgdisk /dev/sda --new=1:0:0
```

Encrypt, setup LVM on, and format the data partition:
```sh
echo -n "${DISK_ENCRYPTION_PASSPHRASE}" | cryptsetup luksFormat --type luks2 /dev/sda1 -
echo -n "${DISK_ENCRYPTION_PASSPHRASE}" | cryptsetup luksAddKey /dev/sda1 /keys/luks.key -
echo -n "${DISK_ENCRYPTION_PASSPHRASE}" | cryptsetup open /dev/sda1 crypt-data -

pvcreate /dev/mapper/crypt-data
vgcreate data /dev/mapper/crypt-data
lvcreate --name 00 --extents 100%FREE data

mkfs.ext4 /dev/mapper/data-00
```

## Mount the File Systems And Setup Swap

 Mount the File Systems:
```sh
mount /dev/mapper/system-root /mnt
mkdir /mnt/boot
mount /dev/mapper/crypt-boot /mnt/boot
mkdir /mnt/boot/efi
mount /dev/nvme0n1p1 /mnt/boot/efi
mkdir --parents /mnt/media/data-00
mount /dev/mapper/data-00 /mnt/media/data-00
```

Copy the encryption key file:
```sh
mkdir /mnt/keys
cp /keys/luks.key /mnt/keys/luks.key
chmod 000 /mnt/keys/luks.key
umount /keys
```

Create a swap file:
```sh
fallocate --length 20G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile
```


## Install Arch Linux

```sh
pacstrap /mnt base intel-ucode grub efibootmgr
genfstab -U /mnt >> /mnt/etc/fstab
sed --in-place "/^\/mnt\/swapfile/s/\/mnt\/swapfile/\/swapfile/" /mnt/etc/fstab
```

```sh
arch-chroot /mnt /bin/sh <<EOF
```

```sh
ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
hwclock --systohc

sed --in-place "/^#en_US.UTF-8 UTF-8/s/^#//" /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=us" >> /etc/vconsole.conf

echo "${HOSTNAME}" > /etc/hostname
```

```sh
FILES=(/crypto_keyfile.bin)
sed --in-place "/^FILES/s/=(/=(\/keys\/luks.key /" /etc/mkinitcpio.conf
sed --in-place "/^HOOKS/{/systemd/!s/base/base systemd/}" /etc/mkinitcpio.conf
sed --in-place "/^HOOKS/{/keyboard/!s/autodetect/autodetect keyboard/}" /etc/mkinitcpio.conf
sed --in-place "/^HOOKS/{/sd-vconsole/!s/keyboard/keyboard sd-vconsole/}" /etc/mkinitcpio.conf
sed --in-place "/^HOOKS/{/sd-encrypt/!s/block/block sd-encrypt/}" /etc/mkinitcpio.conf
sed --in-place "/^HOOKS/{/sd-lvm2/!s/sd-encrypt/sd-encrypt sd-lvm2/}" /etc/mkinitcpio.conf
sed --in-place "/^HOOKS/{/resume/!s/sd-lvm2/sd-lvm2 resume/}" /etc/mkinitcpio.conf

mkinitcpio --preset linux
```

```sh
sed --in-place "/^GRUB_CMDLINE_LINUX/s/^/#/" /etc/default/grub
sed --in-place "/^GRUB_ENABLE_CRYPTODISK/s/^/#/" /etc/default/grub
echo "GRUB_CMDLINE_LINUX=\"rd.luks.name=$(blkid --match-tag UUID --output value /dev/nvme0n1p3)=crypt-system \
                           rd.luks.name=$(blkid --match-tag UUID --output value /dev/nvme0n1p2)=crypt-boot \
                           rd.luks.name=$(blkid --match-tag UUID --output value /dev/sda1)=crypt-data \
                           rd.luks.key=/keys/luks.key \
                           resume=/dev/mapper/system-root \
                           resume_offset=$(filefrag -v /mnt/swapfile | awk '{if($1=="0:"){print $4}}' | sed '/\.\./s/\.\.//')\"" >> /etc/default/grub
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub

grub-mkconfig --output /boot/grub/grub.cfg
grub-install --recheck --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub 
```

```sh
EOF
```

[arch_download]: https://www.archlinux.org/download/ "Arch Linux Download"
[arch_live_usb]: https://wiki.archlinux.org/index.php/USB_flash_installation_media "Arch Linux USB Flash Installation Media"
[arch_install]: https://wiki.archlinux.org/index.php/installation_guide "Arch Linux Installation Guide"
[arch_system_encryption]: https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Encrypted_boot_partition_.28GRUB.29 "Arch Linux System Encryption"
