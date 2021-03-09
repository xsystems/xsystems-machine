# disk-add.sh

Subsequent steps add a fully [encrypted disk][arch_system_encryption] to the system.

The disk layout will be similar to the following:
```
+------------------------------------------------------+
| Data partition                                       |
| /media/data-00                                    (5)|
+------------------------------------------------------+
| LVM: Logical volume 2                                |
| /dev/mapper/data-00                               (4)|
+------------------------------------------------------+
| LUKS: Encrypted partition                            |
| /dev/mapper/crypt-data-00                         (3)|
+------------------------------------------------------+
| Partition Type: CA7D7CCB-63ED-4C53-861C-1742536059CC |
| /dev/sda1                                         (2)|
+------------------------------------------------------+
| /dev/sda                                          (1)|
+------------------------------------------------------+
```


## Import dependencies

### Determine the directory where the script is located
```sh
BASEDIR=$(dirname "$0")
```

### Import [several utility function](./utils.md)
```sh
. "${BASEDIR}/utils.sh"
```


## Collect User Input AND set variables
Select a disk:
```sh
DISK_PATH=`disk_select`
```

Provide a disk name:
```sh
read -p "Enter a disk name: " DISK_NAME
```

Provide a disk passphrase:
```sh 
DISK_PASSPHRASE=`disk_passphrase`
```

Set variable:
```sh
DISK_PARTITION="`disk_partition_nth ${DISK_PATH} 1`"
DISK_CRYPT_NAME="crypt-data-${DISK_NAME}"
DISK_CRYPT="/dev/mapper/${DISK_CRYPT_NAME}"
DISK_LVM="/dev/mapper/data-${DISK_NAME}"
DISK_MOUNT_POINT="/media/data-${DISK_NAME}"
```


### Prepare Data Drive
Create the partition:
```sh
sgdisk "${DISK_PATH}" --clear
sgdisk "${DISK_PATH}" --new         "1:0:0"
sgdisk "${DISK_PATH}" --typecode    "1:CA7D7CCB-63ED-4C53-861C-1742536059CC"
```

Encrypt, setup LVM on the data partition, and format it:
```sh
echo -n "${DISK_PASSPHRASE}" | cryptsetup luksFormat --type luks2 "${DISK_PARTITION}" -
echo -n "${DISK_PASSPHRASE}" | cryptsetup luksAddKey "${DISK_PARTITION}" /keys/luks.key -
echo -n "${DISK_PASSPHRASE}" | cryptsetup open "${DISK_PARTITION}" "${DISK_CRYPT_NAME}" -

pvcreate "${DISK_CRYPT}"
vgcreate data "${DISK_CRYPT}"
lvcreate --name "${DISK_NAME}" --extents 100%FREE data

mkfs.ext4 "${DISK_LVM}"
```


### Mount the File System, update `/etc/fstab`, and update GRUB

Mount the File System:
```sh
mkdir --parents "${DISK_MOUNT_POINT}"
mount "${DISK_LVM}" "${DISK_MOUNT_POINT}"
```

Update `/etc/fstab`:
```sh
echo "# ${DISK_LVM}" >> /etc/fstab
echo "UUID=`disk_uuid ${DISK_LVM}`    ${DISK_MOUNT_POINT}    ext4    rw,relatime,data=ordered    0 2" >> /etc/fstab
echo >> /etc/fstab
```

Update GRUB:
```sh
RD_LUKS_NAME="rd.luks.name=`disk_uuid ${DISK_PARTITION}`=${DISK_CRYPT_NAME}"
sed --in-place "/^GRUB_CMDLINE_LINUX/{/rd\.luks\.key/!s/${RD_LUKS_NAME}/${RD_LUKS_NAME} rd\.luks\.key/}" /etc/default/grub
```

[arch_system_encryption]: https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS "Arch Linux System Encryption"
