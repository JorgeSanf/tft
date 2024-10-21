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

# Redirect output to a log file
exec > >(tee -i /var/log/lcd_setup.log)
exec 2>&1

# Locate config.txt
locate_config_file

# Update and install necessary packages
sudo apt-get update
sudo apt-get install cmake libraspberrypi-dev xserver-xorg-input-evdev -y

# Copy the necessary overlay for the LCD to the correct location
sudo cp ./usr/tft9341-overlay.dtb /boot/overlays/
sudo cp ./usr/tft9341-overlay.dtb /boot/overlays/tft9341.dtbo

# Backup and modify the config file
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.bak" # Backup current config.txt

# Disable vc4-kms-v3d overlay if it exists
sudo sed -i '/dtoverlay=vc4-kms-v3d/d' "$CONFIG_FILE"

# Add necessary settings to config.txt
sudo sed -i '/hdmi_force_hotplug/d' "$CONFIG_FILE"
sudo sed -i '/dtoverlay=tft9341/d' "$CONFIG_FILE"

sudo bash -c "cat <<EOL >> $CONFIG_FILE
hdmi_force_hotplug=1
dtparam=i2c_arm=on
dtparam=spi=on
enable_uart=1
dtoverlay=tft9341:rotate=90
hdmi_group=2
hdmi_mode=87
hdmi_cvt 480 360 60 6 0 0 0
hdmi_drive=2
EOL"

# Copy calibration file for touchscreen if needed
sudo cp ./usr/99-calibration.conf /etc/X11/xorg.conf.d/99-calibration.conf

# Install framebuffer copy (fbcp) if not already installed
if ! command -v fbcp &> /dev/null; then
    echo "fbcp not found, installing..."
    wget --spider -q https://github.com
    if [ $? -ne 0 ]; then
        echo "No internet connection, skipping fbcp installation"
    else
        sudo git clone https://github.com/tasanakorn/rpi-fbcp
        cd rpi-fbcp/
        mkdir build
        cd build
        cmake ..
        make
        sudo install fbcp /usr/local/bin/fbcp
        cd ../..
    fi
fi

# Enable fbcp on boot by adding it to /etc/rc.local
if ! grep -q "fbcp" /etc/rc.local; then
    sudo sed -i '$i /usr/local/bin/fbcp &' /etc/rc.local
fi

# Sync and reboot
sudo sync
echo "Rebooting now..."
sudo reboot
