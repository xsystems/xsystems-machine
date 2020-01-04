# xSystems Laptop

> Comprehensive (opinionated) guide to setup a laptop


## TL;DR

1. Download Arch Linux [here][arch_download]
2. Create an LiveUSB following [these steps][arch_live_usb]
3. Checkout this repository
4. Create from the several Markdown files executable scripts, located in `target/`, by running `build.sh`
5. Copy the scripts to the LiveUSB
6. Boot from the LiveUSB
7. Run the script `install.sh`
8. Reboot **without** the LiveUSB
9. Run the other scripts


## Contents

- [install.sh](install.md)
  * [Verify Prerequisites and Collect User Input](install.md#verify-prerequisites-and-collect-user-input)
  * [Full System Encryption](install.md#full-system-encryption)
    + [Overview](install.md#overview)
    + [Generate encryption key file](install.md#generate-encryption-key-file)
    + [Prepare System Drive](install.md#prepare-system-drive)
    + [Prepare Data Drive](install.md#prepare-data-drive)
    + [Mount the File Systems And Setup Swap](install.md#mount-the-file-systems-and-setup-swap)
  * [Install Arch Linux](install.md#install-arch-linux)
- [setup.sh](setup.md)
  * [Read User Input](setup.md#read-user-input)
  * [Network](setup.md#network)
  * [Create User Account](setup.md#create-user-account)
  * [Time](setup.md#time)
  * [Security](setup.md#security)
  * [Storage](setup.md#storage)
  * [Audio](setup.md#audio)
  * [Bluetooth](setup.md#bluetooth)
  * [Video](setup.md#video)
  * [Buttons and Power Management](setup.md#buttons-and-power-management)
  * [KeePassXC](setup.md#keepassxc)
  * [Change User Home Owner and Group](setup.md#change-user-home-owner-and-group)
- [extra.sh](extra.md)
  * [HDD shock protection HP Laptop](setup.md#hdd-shock-protection-hp-laptop)


[arch_download]: https://www.archlinux.org/download/ "Arch Linux Download"
[arch_live_usb]: https://wiki.archlinux.org/index.php/USB_flash_installation_media "Arch Linux USB Flash Installation Media"
