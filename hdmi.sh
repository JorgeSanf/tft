#!/bin/bash

# Function to check and locate the correct config.txt file
locate_config_file() {
    if [ -f /boot/config.txt ]; then
        CONFIG_FILE="/boot/config.txt"
    elif [ -f /boot/firmware/config.txt ]; then
        CONFIG_FILE="/boot/firmware/config.txt"
    else
        echo "Error: Could not locate config.txt"
        exit 1
    fi
    echo "Using config file at: $CONFIG_FILE"
}

# Locate config.txt
locate_config_file

# Backup the current config.txt before making changes
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.bak_hdmi_revert"

# Restore HDMI settings and remove LCD-specific settings from config.txt
sudo sed -i '/dtoverlay=tft9341/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_cvt/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_force_hotplug/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_group/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_mode/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_drive/d' "$CONFIG_FILE"
sudo sed -i '/dtparam=i2c_arm=on/d' "$CONFIG_FILE"
sudo sed -i '/dtparam=spi=on/d' "$CONFIG_FILE"
sudo sed -i '/enable_uart=1/d' "$CONFIG_FILE"

# Add back the default HDMI settings if they were removed
sudo bash -c "cat <<EOL >> $CONFIG_FILE
hdmi_force_hotplug=1
hdmi_group=1
hdmi_mode=16 # 1080p 60Hz
EOL"

# Remove fbcp from /etc/rc.local if it's no longer needed
if grep -q "fbcp" /etc/rc.local; then
    sudo sed -i '/fbcp/d' /etc/rc.local
fi

# Optionally remove fbcp (uncomment if desired)
# sudo rm -f /usr/local/bin/fbcp

# Sync and reboot
sudo sync
echo "Rebooting now to switch back to HDMI..."
sudo reboot
