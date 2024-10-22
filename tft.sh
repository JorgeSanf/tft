#!/bin/bash

# Backup current configuration
sudo ./system_backup.sh

# Clean up any existing libinput configuration
if [ -f /etc/X11/xorg.conf.d/40-libinput.conf ]; then
    sudo rm -rf /etc/X11/xorg.conf.d/40-libinput.conf
fi

# Ensure the xorg.conf.d directory exists
if [ ! -d /etc/X11/xorg.conf.d ]; then
    sudo mkdir -p /etc/X11/xorg.conf.d
fi

# Copy the TFT overlay files
sudo cp ./usr/tft9341-overlay.dtb /boot/overlays/
sudo cp ./usr/tft9341-overlay.dtb /boot/overlays/tft9341.dtbo

# Set up the configuration for TFT
sudo touch /boot/config.txt.bak
{
    echo "hdmi_force_hotplug=1"
    echo "dtparam=i2c_arm=on"
    echo "dtparam=spi=on"
    echo "enable_uart=1"
    echo "dtoverlay=tft9341:rotate=90"
    echo "hdmi_group=2"
    echo "hdmi_mode=1"
    echo "hdmi_mode=87"
    echo "hdmi_cvt 480 360 60 6 0 0 0"
    echo "hdmi_drive=2"
} | sudo tee -a /boot/config.txt.bak > /dev/null

sudo cp -rf /boot/config.txt.bak /boot/config.txt

# Copy calibration configuration
sudo cp -rf ./usr/99-calibration.conf-32-90 /etc/X11/xorg.conf.d/99-calibration.conf

# Update and install necessary packages
sudo apt-get update
if wget --spider -q -o /dev/null --tries=1 -T 10 https://cmake.org/; then
    sudo apt-get install cmake libraspberrypi-dev -y
    if type cmake > /dev/null 2>&1; then
        # Install fbcp
        sudo git clone https://github.com/tasanakorn/rpi-fbcp
        cd rpi-fbcp || exit
        mkdir build
        cd build || exit
        sudo cmake ..
        sudo make
        sudo install fbcp /usr/local/bin/fbcp
        cd - > /dev/null
    else
        echo "cmake installation failed."
    fi
else
    echo "Network error, can't install cmake."
fi

# Install evdev input driver
if ! dpkg -l | grep -q xserver-xorg-input-evdev; then
    sudo apt-get install xserver-xorg-input-evdev -y
fi

# Copy evdev configuration
sudo cp -rf /usr/share/X11/xorg.conf.d/10-evdev.conf /usr/share/X11/xorg.conf.d/45-evdev.conf

# Sync and reboot
sudo sync
sleep 1
echo "Rebooting now..."
sudo reboot
