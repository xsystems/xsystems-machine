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
    sed --in-place '/^# %wheel ALL=(ALL:ALL) ALL/s/# //' /etc/sudoers

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

### Configure SSH for an user account:

> _**NOTE:** At the time of writing, GnuPG has a key size limit of 4096 bits_

```sh
user_configure_ssh() {
    if [ -z "$1" ] ; then
        echo "Argument 1 missing i.e. the USERNAME"
        return 1
    fi

    local USERNAME="$1"
    local AUTHORIZED_KEY="$2"

    pacman --quiet --sync --needed --noconfirm openssh

    cat <<- EOF > /home/${USERNAME}/.pam_environment
	SSH_AGENT_PID  DEFAULT=
	SSH_AUTH_SOCK  DEFAULT="${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh"
	EOF

    cat <<- EOF > /home/${USERNAME}/.bashrc
	export GPG_TTY=$(tty)
	gpg-connect-agent updatestartuptty /bye > /dev/null
	EOF

    if [ -f "${AUTHORIZED_KEY}" ] ; then
        mkdir /home/${USERNAME}/.ssh
        cat "${AUTHORIZED_KEY}" > /home/${USERNAME}/.ssh/authorized_keys
    fi

    systemctl enable sshd
    systemctl start sshd
}
```

### Configure automounting for an user account:
```sh
user_configure_automounting() {
    if [ -z "$1" ] ; then
        echo "Argument 1 missing i.e. the USERNAME"
        return 1
    fi

    local USERNAME="$1"

    pacman --quiet --sync --needed --noconfirm udiskie

    cat <<- EOF >> /home/${USERNAME}/.profile
	if ! pgrep --euid "${USERNAME}" udiskie > /dev/null; then
	    udiskie &
	fi
	EOF
}
```

### Configure audio for an user account:
```sh
user_configure_audio() {
    if [ -z "$1" ] ; then
        echo "Argument 1 missing i.e. the USERNAME"
        return 1
    fi

    local USERNAME="$1"

    pacman --quiet --sync --needed --noconfirm pulseaudio pulseaudio-alsa pulsemixer

    mkdir --parents /home/${USERNAME}/.config/pulse
    cat <<- EOF > /home/${USERNAME}/.config/pulse/default.pa
	.include /etc/pulse/default.pa
	
	### Automatically switch to newly connected devices
	load-module module-switch-on-connect
	EOF
}
```

### Configure bluetooth an user account:
```sh
user_configure_bluetooth() {
    if [ -z "$1" ] ; then
        echo "Argument 1 missing i.e. the USERNAME"
        return 1
    fi

    local USERNAME="$1"

    pacman --quiet --sync --needed --noconfirm bluez bluez-utils pulseaudio-bluetooth

    systemctl enable bluetooth
    systemctl start bluetooth

    gpasswd --add "${USERNAME}" lp

    sed --in-place '/#AutoEnable=false/s/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf
    cat <<- EOF > /etc/bluetooth/audio.conf
	[General]
	Enable=Source
	EOF
}
```
