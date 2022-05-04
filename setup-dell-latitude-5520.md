# setup-dell-latitude-5520.sh

## Read User Input
```sh
read -p "Username: " USERNAME
```

## Verify prerequisites

Verify that there is an i3 configuration:
```sh
if [ -f "/home/${USERNAME}/.config/i3/config" ]; then
  echo "[  OK  ] There is an i3 configuration"
else
  echo "[FAILED] There is an i3 configuration"
  HAS_UNMET_PREREQUISITE=true
fi
```

Verify that there is an autorandr postswitch configuration:
```sh
if [ -f "/home/${USERNAME}/.config/autorandr/postswitch" ]; then
  echo "[  OK  ] There is an autorandr postswitch configuration"
else
  echo "[FAILED] There is an autorandr postswitch configuration"
  HAS_UNMET_PREREQUISITE=true
fi
```

Continue ONLY when ALL the prerequisites are met:
```sh
if [ "${HAS_UNMET_PREREQUISITE}" = true ]; then
  exit 1
fi
```

## Touch Screen
```sh
pacman --quiet --sync --needed --noconfirm xorg-xinput

cat << 'EOF' >> /home/${USERNAME}/bin/screen_layout

xinput --map-to-output 'ELAN900C:00 04F3:2C6B' eDP-1
EOF
```

## Workspaces
```sh
cat << 'EOF' >> /home/${USERNAME}/.config/i3/config

workspace 1  output primary
workspace 2  output primary
workspace 3  output primary
workspace 4  output primary

workspace 5  output HDMI-1 DP-1 DP-2 DP-1-2 primary
workspace 6  output HDMI-1 DP-1 DP-2 DP-1-2 primary
workspace 7  output HDMI-1 DP-1 DP-2 DP-1-2 primary

workspace 8  output HDMI-1 DP-1 DP-1-2 DP-2 primary
workspace 9  output HDMI-1 DP-1 DP-1-2 DP-2 primary
workspace 0  output HDMI-1 DP-1 DP-1-2 DP-2 primary
EOF
```
