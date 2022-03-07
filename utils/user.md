# user.sh

## User Utils

### Create directory or file owned by given user
```sh
user_create_directory() {
    if [ -z "$1" ] ; then
        echo "Argument 1 missing i.e. the USERNAME"
        return 1
    fi

    if [ -z "$2" ] ; then
        echo "Argument 2 missing i.e. the DIRECTORY"
        return 1
    fi

    local USERNAME="$1"
    local DIRECTORY="$2"

    install --owner "${USERNAME}" --group "users" --directory "${DIRECTORY}"
}

user_create_file() {
    if [ -z "$1" ] ; then
        echo "Argument 1 missing i.e. the USERNAME"
        return 1
    fi

    if [ -z "$2" ] ; then
        echo "Argument 2 missing i.e. the FILE"
        return 1
    fi

    local USERNAME="$1"
    local FILE="$2"

    install --owner "${USERNAME}" --group "users" /dev/null "${FILE}"
}
```

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

    user_create_directory   "${USERNAME}" "/home/${USERNAME}/bin"
    user_create_file        "${USERNAME}" "/home/${USERNAME}/.profile"

    cat <<- EOF >> "/home/${USERNAME}/.profile"
	#!/bin/sh

	if [ -f ~/.environment ]; then
	    . ~/.environment
	fi

	if [ -d "\${HOME}/bin" ]; then
	    PATH="\${HOME}/bin:${PATH}"
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

    user_create_file "${USERNAME}" "/home/${USERNAME}/.pam_environment"
    cat <<- EOF >> /home/${USERNAME}/.pam_environment
	SSH_AGENT_PID  DEFAULT=
	SSH_AUTH_SOCK  DEFAULT="${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh"
	EOF

    user_create_file "${USERNAME}"  "/home/${USERNAME}/.bashrc"
    cat <<- EOF >> /home/${USERNAME}/.bashrc
	export GPG_TTY=$(tty)
	gpg-connect-agent updatestartuptty /bye > /dev/null
	EOF

    if [ -f "${AUTHORIZED_KEY}" ] ; then
        user_create_directory   "${USERNAME}"  "/home/${USERNAME}/.ssh"
        user_create_file        "${USERNAME}"  "/home/${USERNAME}/.ssh/authorized_keys"
        cat "${AUTHORIZED_KEY}" >> /home/${USERNAME}/.ssh/authorized_keys
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

	if ! pgrep --euid "\${USER}" udiskie > /dev/null; then
	    udiskie --smart-tray --no-file-manager --no-notify &
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

    user_create_directory   "${USERNAME}" "/home/${USERNAME}/.config/pulse"
    user_create_file        "${USERNAME}" "/home/${USERNAME}/.config/pulse/default.pa"
    cat <<- EOF >> /home/${USERNAME}/.config/pulse/default.pa
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
