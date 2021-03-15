# cpu.sh

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
