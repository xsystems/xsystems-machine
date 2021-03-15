# user.sh

## User Utils

### Create an user account:
```sh
user_create() {
    if [ -z "$1" ] ; then
        echo "Argument 1 missing i.e. the USERNAME"
        return 1
    fi

    if [ -z "$2" ] ; then
        echo "Argument 2 missing i.e. the PASSPHRASE"
        return 1
    fi

    local USERNAME="$1"
    local PASSPHRASE="$2"

    pacman --quiet --sync --needed --noconfirm sudo

    useradd --create-home --gid users "${USERNAME}"

    echo "${USERNAME}:${PASSPHRASE}" | chpasswd

    gpasswd --add "${USERNAME}" wheel
    sed --in-place '/^# %wheel ALL=(ALL) ALL/s/# //' /etc/sudoers

    mkdir -p "/home/${USERNAME}/bin"

    cat <<- EOF > "/home/${USERNAME}/.profile"
	#!/bin/sh

	if [ -f ~/.environment ]; then
	    . ~/.environment
	fi

	if [ -d "$HOME/bin" ]; then
	    PATH="${HOME}/bin:${PATH}"
	fi
	EOF

    echo "[[ -f ~/.profile ]] && . ~/.profile" >> "/home/${USERNAME}/.bash_profile"
}
```
