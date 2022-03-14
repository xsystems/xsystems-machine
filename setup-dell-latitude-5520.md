# setup-dell-latitude-5520.sh

## Touch Screen
```sh
cat << 'EOF' >> /home/${USER}/bin/screen_layout

xinput --map-to-output 'ELAN900C:00 04F3:2C6B' eDP-1
EOF
```

## Workspaces
```sh
cat << 'EOF' >> /home/${USER}/.config/i3/config

workspace 1  output primary
workspace 3  output primary
workspace 5  output primary
workspace 7  output primary
workspace 9  output primary
workspace 10 output primary

workspace 2  output HDMI-1 DP-1 DP-2 primary
workspace 4  output HDMI-1 DP-1 DP-2 primary
workspace 6  output HDMI-1 DP-1 DP-2 primary
workspace 8  output HDMI-1 DP-1 DP-2 primary
EOF
```

