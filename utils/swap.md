# swap.sh

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
