# xSystems Machine

> Comprehensive (opinionated) guide to setup an Arch machine


## TL;DR

1. Download Arch Linux [here][arch_download]
2. Create a LiveUSB following [these steps][arch_live_usb]
3. Checkout this repository
4. Create from the several Markdown files executable scripts by running `build.sh`
5. Copy the scripts from `target/` to an other (USB) device
    > _**NOTE:** Following the above steps the LiveUSB will be read-only_
6. Boot from the LiveUSB
    > _**NOTE:** At the time of writing Secure Boot needs to be disabled to boot the LiveUSB, after the installation it can be enabled again_
7. Run the script `install.sh`
8. Reboot **without** the LiveUSB
9. Run the other scripts


## Contents

- [disk-add.sh](disk-add.md) - Add a fully encrypted disk to the system
- [install.sh](install.md) - Install Arch on an encrypted disk
- [setup-base.sh](setup-base.md) - Base post-install configuration
- [setup-laptop.sh](setup-laptop.md) - Laptop oriented post-install configuration (Optional)
- utils - Functions that group steps that belong together and abstract away complexities
  * [cpu.sh](utils/cpu.md)
  * [disk.sh](utils/disk.md)
  * [misc.sh](utils/misc.md)
  * [swap.sh](utils/swap.md)
  * [user.sh](utils/user.md)


[arch_download]: https://www.archlinux.org/download/ "Arch Linux Download"
[arch_live_usb]: https://wiki.archlinux.org/index.php/USB_flash_installation_media "Arch Linux USB Flash Installation Media"
