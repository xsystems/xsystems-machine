# misc.sh

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
