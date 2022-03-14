# install.sh


## Import dependencies

### Determine the directory where the script is located
```sh
BASEDIR=$(dirname "$0")
```

### Import util functions for [cpu](utils/cpu.md), [disk](utils/disk.md), [misc](utils/misc.md), [swap](utils/swap.md), and [user](utils/user.md):
```sh
. "${BASEDIR}/utils/cpu.sh"
. "${BASEDIR}/utils/disk.sh"
. "${BASEDIR}/utils/misc.sh"
. "${BASEDIR}/utils/swap.sh"
. "${BASEDIR}/utils/user.sh"
```


## Verify AND set prerequisites

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

Update the system clock:
```sh
timedatectl set-ntp true
```


## Install encrypted system (except EFI partition)

### Overview

Subsequent steps result in a fully [encrypted system][arch_system_encryption].
Encrypted data disks will be added later.

The disk layout will be similar to the following:
```
+------------------------------------------------------+------------------------------------------------------+
| EFI System partition                                 | System partition                                     |
| /efi                                              (5)| /                                                 (5)|
+------------------------------------------------------+------------------------------------------------------+
|                                                      | LVM: Logical volume 1                                |
|                                                      | /dev/mapper/system-root                           (4)|
|                                                      +------------------------------------------------------+
|                                                      | LUKS: Encrypted partition                            |
|                                                      | /dev/mapper/crypt-system                          (3)|
|                                                      +------------------------------------------------------+
| Partition Type: C12A7328-F81F-11D2-BA4B-00A0C93EC93B | Partition Type: CA7D7CCB-63ED-4C53-861C-1742536059CC |
| /dev/nvme0n1p1                                    (2)| /dev/nvme0n1p2                                    (2)|
+------------------------------------------------------+------------------------------------------------------+
| /dev/nvme0n1                                                                                             (1)|
+-------------------------------------------------------------------------------------------------------------+
```


### Collect user input AND set variables
Query the username:
```sh
read -p "Username: " USERNAME
```

Query a passphrase for the user:
```sh 
USER_PASSPHRASE=`passphrase "User passphrase"`
```

Query the hostname:
```sh
read -p "Hostname: " HOSTNAME
```

Query the "installation" disk:
```sh
DISK_PATH=`disk_select`
```

Query a disk passphrase:
```sh 
DISK_PASSPHRASE=`passphrase "Disk encryption passphrase"`
```

Set variable:
```sh
DISK_PARTITION_NUMBER_EFI=1
DISK_PARTITION_NUMBER_SYSTEM=2
DISK_PARTITION_EFI="`disk_partition_nth ${DISK_PATH} ${DISK_PARTITION_NUMBER_EFI}`"
DISK_PARTITION_SYSTEM="`disk_partition_nth ${DISK_PATH} ${DISK_PARTITION_NUMBER_SYSTEM}`"
```


### Generate encryption key file

The below generated key file will later be added to the encrypted devices:
```sh
mkdir /keys
mount --types ramfs ramfs /keys

dd bs=512 count=4 if=/dev/urandom of=/keys/luks.key
```


### Prepare System Drive

Create the partitions:
```sh
sgdisk "${DISK_PATH}" --clear
sgdisk "${DISK_PATH}" --new       "${DISK_PARTITION_NUMBER_EFI}:0:+512M"
sgdisk "${DISK_PATH}" --new       "${DISK_PARTITION_NUMBER_SYSTEM}:0:0"
sgdisk "${DISK_PATH}" --typecode  "${DISK_PARTITION_NUMBER_EFI}:C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
sgdisk "${DISK_PATH}" --typecode  "${DISK_PARTITION_NUMBER_SYSTEM}:CA7D7CCB-63ED-4C53-861C-1742536059CC"
```

Format the EFI System Partition:
```sh
mkfs.fat -F32 "${DISK_PARTITION_EFI}"
```

Encrypt [with LUKS1][arch_boot_encryption], setup LVM on, and format the system partition:
```sh
echo -n "${DISK_PASSPHRASE}" | cryptsetup luksFormat --type luks1 "${DISK_PARTITION_SYSTEM}" -
echo -n "${DISK_PASSPHRASE}" | cryptsetup luksAddKey "${DISK_PARTITION_SYSTEM}" /keys/luks.key -
echo -n "${DISK_PASSPHRASE}" | cryptsetup open "${DISK_PARTITION_SYSTEM}" crypt-system -

pvcreate /dev/mapper/crypt-system
vgcreate system /dev/mapper/crypt-system
lvcreate --name root --extents 100%FREE system

mkfs.ext4 /dev/mapper/system-root
```


### Mount the File Systems And Setup Swap

 Mount the File Systems:
```sh
mount /dev/mapper/system-root /mnt
mkdir /mnt/efi
mount "${DISK_PARTITION_EFI}" /mnt/efi
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
fallocate --length "`swap_size`G" /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile
```


### Make some information available for use later on
```sh
SWAP_FILE_OFFSET=`swap_file_offset /mnt/swapfile`
DISK_PARTITION_SYSTEM_UUID=`disk_uuid ${DISK_PARTITION_SYSTEM}`
```


## Install Arch Linux

[Install Arch Linux][arch_install]'s `base` package, Linux kernel, firmware for common hardware, and other required packages:
```sh
pacstrap  /mnt \
          base \
          efibootmgr \
          grub \
          lvm2 \
          `cpu_microcode_package` \
          linux \
          linux-lts \
          linux-firmware \
          nano
```

Generate a filesystem table as an `fstab` file:
```sh
genfstab -U /mnt >> /mnt/etc/fstab
sed --in-place "/^\/mnt\/swapfile/s/\/mnt\/swapfile/\/swapfile/" /mnt/etc/fstab
```

Configure networking:
```sh
cp /etc/systemd/network/20-ethernet.network /mnt/etc/systemd/network/
cp /etc/systemd/network/20-wlan.network     /mnt/etc/systemd/network/
cp /etc/systemd/network/20-wwan.network     /mnt/etc/systemd/network/
```

Run the following commands in a change root environent:
```sh
arch-chroot /mnt /bin/sh <<EOCHROOT
```

Make some functions available in the change root environment:
```sh
`type user_create | sed '1d'`
`type user_configure_automounting | sed '1d'`
```

Set the time zone, locale, and hostname:
```sh
ln --symbolic --force /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
hwclock --systohc

sed --in-place "/^#en_US.UTF-8 UTF-8/s/^#//" /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=us" >> /etc/vconsole.conf

echo "${HOSTNAME}" > /etc/hostname
```

Enable networking:
```sh
systemctl enable systemd-networkd
systemctl enable systemd-resolved
```

Create the user:
```sh
user_create "${USERNAME}" "${USER_PASSPHRASE}"
```

Setup automounting:
```sh
user_configure_automounting "${USERNAME}"
```

Configure and create an initial ramdisk environment:
```sh
mv /etc/mkinitcpio.conf /etc/mkinitcpio.conf.default

cat << EOF > /etc/mkinitcpio.conf
FILES=(/keys/luks.key)
HOOKS=(base systemd keyboard autodetect sd-vconsole modconf block sd-encrypt lvm2 filesystems fsck)
EOF

mkinitcpio --allpresets
```

Configure GRUB, install the GRUB EFI application, and generate the `grub.cfg` file:
```sh
mv /etc/default/grub /etc/default/grub.default

cat << EOF > /etc/default/grub
GRUB_DEFAULT="1>2"
GRUB_DISTRIBUTOR="Arch"
GRUB_ENABLE_CRYPTODISK=y
GRUB_DISABLE_RECOVERY=true
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
GRUB_CMDLINE_LINUX="rd.luks.name=${DISK_PARTITION_SYSTEM_UUID}=crypt-system rd.luks.key=/keys/luks.key resume=/dev/mapper/system-root resume_offset=${SWAP_FILE_OFFSET}"
EOF

grub-install --recheck --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig --output /boot/grub/grub.cfg
```

Exit the change root environment:
```sh
EOCHROOT
```


[arch_boot_encryption]: https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Encrypted_boot_partition_.28GRUB.29 "Arch Linux Boot Encryption"
[arch_system_encryption]: https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS "Arch Linux System Encryption"
[arch_install]: https://wiki.archlinux.org/index.php/installation_guide "Arch Linux Installation Guide"
