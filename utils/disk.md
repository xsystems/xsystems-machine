# disk.sh

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
