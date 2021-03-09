# utils.sh


## Miscellaneous Utils

### Query user for Passphrase:
```sh
passphrase() {
    while true ; do
        read -p "$1: "          -s PASSPHRASE;          >&2 echo
        read -p "$1 (verify): " -s PASSPHRASE_VERIFY;   >&2 echo

        if [ "${PASSPHRASE}" = "${PASSPHRASE_VERIFY}" ]; then
            echo "${PASSPHRASE}"
            break
        fi
    done
}
```

### Query the amount of installed memory in Gigabyte
```sh
memory_installed_size() {
    echo `free --giga | grep Mem | awk '{print $2}'`
}
```


## Disk Utils

### Query disk information, show prompt to select a disk, and return the selected disk:
```sh
disk_select() {
    DISKS_AVAILABLE=`lsblk --nodeps --noheadings --paths --sort SIZE --output NAME,SIZE`

    local IFS=$'\n'
    select DISK in ${DISKS_AVAILABLE}; do
        echo "` cut --delimiter ' ' --fields 1 <<< "${DISK}" `"
        break
    done
}
```

### Query UUID of specified disk
```sh
disk_uuid() {
    echo `blkid --match-tag UUID --output value "$1"`
}
```

### Compute the first disk partition:
```sh
disk_partition_nth() {
    case "$1" in 
        /dev/nvme*) echo "$1p$2";; 
        *) echo "$1$2";; 
    esac
}
```


## CPU Utils

### Query CPU vendor:
```sh
cpu_vendor() {
    echo `cat /proc/cpuinfo | grep vendor_id | head --lines 1 | tr --delete " " | cut --delimiter ':' --fields 2`
}
```

### Compute required Microcode package:
```sh
cpu_microcode_package() {
    case `cpu_vendor` in
        GenuineIntel) echo "intel-ucode";;
        *) echo "amd-ucode";;
    esac
}
```


## Swap Utils

### Compute an appropriate swap size in Gigabyte:
```sh
swap_size() {
    echo "`memory_installed_size` + l(`memory_installed_size`)/l(2)" | bc --mathlib | xargs printf '%.0f'
}
```

### Compute the swap file offset:
```sh
swap_file_offset() {
    echo `filefrag -v $1 | awk '{if($1=="0:"){print $4}}' | sed '/\.\./s/\.\.//'`
}
```
