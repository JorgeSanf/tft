#!/bin/bash

# Function to locate the correct config.txt file
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

# Backup current config.txt before applying changes
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.bak_tft"

# Ensure no previous conflicting configurations exist
sudo sed -i '/dtoverlay=tft9341/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_force_hotplug/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_group/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_mode/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_cvt/d' "$CONFIG_FILE"
sudo sed -i '/hdmi_drive/d' "$CONFIG_FILE"

# Add TFT screen configuration
sudo bash -c "cat <<EOL >> $CONFIG_FILE
# Force HDMI output (needed to ensure the screen is activated)
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt 480 360 60 6 0 0 0
hdmi_drive=2

# Enable SPI and I2C for TFT
dtparam=i2c_arm=on
dtparam=spi=on
enable_uart=1

# Apply TFT overlay
dtoverlay=tft9341:rotate=90
EOL"

# Verify if the overlay file exists
if [ ! -f /boot/overlays/tft9341.dtbo ]; then
    echo "Error: tft9341 overlay not found! Please ensure it is installed."
    exit 1
fi

# Sync the file system and reboot to apply the changes
sudo sync
echo "Configuration applied. Rebooting..."
sudo reboot
