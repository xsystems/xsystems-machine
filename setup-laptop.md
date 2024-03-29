# setup-laptop.sh


## Read User Input
```sh
read -p "Username: " USERNAME
```


## Security
Setup a firewall:
```sh
pacman --quiet --sync --needed --noconfirm ufw
systemctl enable ufw
systemctl start  ufw
ufw enable
```


## Video
```sh
pacman  --quiet --sync --needed --noconfirm \
        arandr \
        autorandr \
        bash-completion \
        dmenu \
        dunst \
        feh \
        i3-wm \
        i3status \
        intel-media-driver \
        maim \
        mesa \
        noto-fonts \
        pavucontrol \
        picom \
        readline \
        rxvt-unicode \
        urxvt-perls \
        vulkan-icd-loader \
        vulkan-intel \
        xbindkeys \
        xclip \
        xorg-server \
        xorg-xinit \
        xorg-xrandr \
        xorg-xrdb \
        xscreensaver
```

```sh
cat << 'EOF' >> /home/${USERNAME}/.profile
if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  exec startx > /tmp/x.log 2>&1
fi
EOF
```

```sh
cat << 'EOF' > /home/${USERNAME}/.xinitrc
#!/bin/sh
if [ -f ~/.Xresources ]; then
  xrdb -merge ~/.Xresources
fi
if [ -f ~/.xbindkeysrc ] && ! pgrep --euid "${USERNAME}" xbindkeys > /dev/null; then
  xbindkeys
fi
if [ ! -f ~/.config/i3/config ]; then
  . ~/bin/i3-configure
fi
picom &
xscreensaver -no-splash &
dunst &
screen_layout &
exec i3
EOF
```

```sh
cat << 'EOF' > /home/${USERNAME}/.Xresources
*vt100.foreground: gray90
*vt100.background: black
*vt100.faceName: xft:Noto Sans Mono:size=14:antialias=true

URxvt.foreground: gray90
URxvt.background: black
URxvt.font: xft:Noto Sans Mono:size=14:antialias=true
URxvt.scrollBar: false

URxvt.perl-ext-common:      default,clipboard,selection-to-clipboard,url-select,keyboard-select,resize-font

URxvt.clipboard.autocopy:   true
URxvt.keysym.M-c:           perl:clipboard:copy
URxvt.keysym.M-v:           perl:clipboard:paste

URxvt.url-select.launcher:  xdg-open
URxvt.url-select.underline: true
URxvt.keysym.M-u:           perl:url-select:select_next
URxvt.keysym.M-Escape:      perl:keyboard-select:activate
URxvt.keysym.M-s:           perl:keyboard-select:search

URxvt.iso14755: false
URxvt.iso14755_52: false
EOF
```

```sh
cat << 'EOF' > /home/${USERNAME}/.inputrc
set bell-style none
set editing-mode vi
set colored-stats On
set visible-stats On
set mark-symlinked-directories On
set colored-completion-prefix On
set menu-complete-display-prefix On
"\e[1;5D": backward-word
"\e[1;5C": forward-word
EOF
```

```sh
mkdir --parents "/home/${USERNAME}/.config/autorandr"
cat << 'EOF' > /home/${USERNAME}/.config/autorandr/postswitch
#!/bin/sh

screen_layout
EOF

chmod +x /home/${USERNAME}/.config/autorandr/postswitch
```

```sh
cat << 'EOF' > /home/${USERNAME}/bin/screen_layout
#!/bin/sh

if [ -f ~/.fehbg ]; then
    . ~/.fehbg
fi
EOF

chmod +x /home/${USERNAME}/bin/screen_layout
```

### Key Bindings

```sh
cat << 'EOF' > /home/${USERNAME}/.xbindkeysrc
"autorandr --cycle"
    m:0x40 + c:33
    Mod4 + p

"xscreensaver-command --lock"
    m:0x40 + c:75
    Mod4 + F9

"maim --select | xclip -selection clipboard -t image/png"
    m:0x0 + c:107
    Print
EOF
```

### Dark Theme

```sh
echo "export GTK_THEME=Adwaita:dark" >> "/home/${USERNAME}/.environment"
```

### Window Transparency

```sh
mkdir --parents "/home/${USERNAME}/.config/picom"
cp /etc/xdg/picom.conf "/home/${USERNAME}/.config/picom/picom.conf"
cat << 'EOF' >> /home/${USERNAME}/.config/picom/picom.conf

opacity-rule = [
  "80:class_g = 'URxvt' && focused",
  "70:class_g = 'URxvt' && !focused"
];
EOF
```

### Configure i3

```sh
cat << 'EOFOUTER' >> /home/${USERNAME}/bin/i3-configure
if [ -f ~/.config/i3/config ]; then
  echo "There already exists an i3 configuration!"
  exit 1
fi

i3-config-wizard --modifier win

sed --in-place '/XF86Audio/s/^/#/'  ~/.config/i3/config
sed --in-place '/# Start i3bar/,$d' ~/.config/i3/config

cat << 'EOF' >> ~/.config/i3/config
bar {
        status_command i3status
        mode hide
        hidden_state hide
        modifier Mod4
}

default_border none
floating_minimum_size 854 x 480
popup_during_fullscreen leave_fullscreen
workspace_auto_back_and_forth yes
EOF
EOFOUTER

chmod +x /home/${USERNAME}/bin/i3-configure
```

### Manual Configuration

To create a profile for a certain screen layout:

1. Use `arandr` to configure a screen layout.
2. After replacing `<NAME>` with a suitable name, run:

        autorandr --skip-options crtc --save <NAME>


## Buttons and Power Management

Setup power management:
```sh
pacman --quiet --sync --needed --noconfirm acpid tlp

systemctl enable acpid
systemctl start acpid

systemctl enable tlp
systemctl start tlp
```

Handle sleep:
```sh
mkdir -p /etc/systemd/logind.conf.d
cat << 'EOF' > /etc/systemd/logind.conf.d/logind.conf
[Login]
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend-then-hibernate
HandleLidSwitchDocked=suspend-then-hibernate
EOF
```

Handle volume and mute buttons:
```sh
mkdir -p /etc/acpi/handlers

cat << 'EOF' > /etc/acpi/events/audio
event=button/(mute|volume.*)
action=/etc/acpi/handlers/audio.sh %e
EOF

cat << 'EOF' > /etc/acpi/handlers/audio.sh
#!/bin/sh

pulseaudio_pid=$(pgrep pulseaudio)
user_name=$(ps --format user --no-headers $pulseaudio_pid)
user_id=$(id --user $user_name)

case $2 in
  MUTE)  sudo --user $user_name XDG_RUNTIME_DIR=/run/user/$user_id pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
  VOLDN) sudo --user $user_name XDG_RUNTIME_DIR=/run/user/$user_id sh -c "pactl set-sink-mute @DEFAULT_SINK@ false; pactl set-sink-volume @DEFAULT_SINK@ -5%" ;;
  VOLUP) sudo --user $user_name XDG_RUNTIME_DIR=/run/user/$user_id sh -c "pactl set-sink-mute @DEFAULT_SINK@ false; pactl set-sink-volume @DEFAULT_SINK@ +5%" ;;
esac
EOF

chmod +x /etc/acpi/handlers/audio.sh
```

Handle backlight buttons:
```sh
cat << 'EOF' > /etc/acpi/events/backlight
event=video/brightness.*
action=/etc/acpi/handlers/backlight.sh %e
EOF

cat << 'EOF' > /etc/acpi/handlers/backlight.sh
#!/bin/sh

backlight_instance=$(ls /sys/class/backlight | head -n 1)
backlight=/sys/class/backlight/$backlight_instance

step=$(expr $(< $backlight/max_brightness) / 40)

case $2 in
  BRTDN) echo $(($(< $backlight/brightness) - $step)) > $backlight/brightness;;
  BRTUP) echo $(($(< $backlight/brightness) + $step)) > $backlight/brightness;;
esac
EOF

chmod +x /etc/acpi/handlers/backlight.sh
```


## KeePassXC
```sh
pacman --quiet --sync --needed --noconfirm keepassxc
sed --in-place '/^xscreensaver/a keepassxc &' "/home/${USERNAME}/.xinitrc"
```


## Change User Home Owner and Group

```sh
chown --recursive "${USERNAME}:users" "/home/${USERNAME}"
```
