# Extra

## HDD shock protection (HP Laptop)
```sh
pacman --quiet --sync --needed --noconfirm base-devel

mkdir -p /aur
curl -L https://aur.archlinux.org/cgit/aur.git/snapshot/hpfall-git.tar.gz | tar --extract --gzip --directory /aur
chgrp users /aur/hpfall-git 
cd /aur/hpfall-git
makepkg --syncdeps --needed --install

systemctl enable hpfall
systemctl start hpfall
```
