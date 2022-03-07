# setup-base.sh


## Import dependencies

### Determine the directory where the script is located
```sh
BASEDIR=$(dirname "$0")
```

### Import util functions for [user](utils/user.md):
```sh
. "${BASEDIR}/utils/user.sh"
```


## Read User Input
```sh
read -p "Username: " USERNAME
```


## Network

Install tools facilitating wireless network connectivity:
```sh
pacman --quiet --sync --needed --noconfirm iwd
systemctl enable iwd
systemctl start  iwd
```


## Time

To query time from one remote server and synchronizing the local clock to it, run:

```sh
timedatectl set-ntp true
```


## Security

Setup SSH and SSH Agent:
```sh
user_configure_ssh "${USERNAME}" "${BASEDIR}/ssh_key.pub"
```


## Audio
```sh
user_configure_audio "${USERNAME}"
```


## Bluetooth
```sh
user_configure_bluetooth "${USERNAME}"
```
