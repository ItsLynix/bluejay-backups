#!/bin/bash

# Function to install ADB and set up udev rules
install_adb() {
    # Check the Linux distribution
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        distro=$ID
    elif [[ -f /etc/redhat-release ]]; then
        distro="centos"
    elif [[ -f /etc/arch-release ]]; then
        distro="arch"
    else
        echo "Unsupported Linux distribution."
        exit 1
    fi

    echo "Detected distribution: $distro"

    # Check if ADB is installed
    if command -v adb >/dev/null 2>&1; then
        echo "ADB is already installed."
	bash ./linux/manager.sh
        return
    fi

    # Install ADB based on the Linux distribution
    case $distro in
        ubuntu|debian)
            sudo_cmd="sudo"
            if ! command -v sudo >/dev/null 2>&1; then
                echo "Please install 'sudo' to continue."
                exit 1
            fi
            sudo_cmd+=" apt update && $sudo_cmd apt install -y android-tools-adb android-tools-fastboot"
            ;;
        arch)
            sudo_cmd="sudo"
            if ! command -v sudo >/dev/null 2>&1; then
                echo "Please install 'sudo' to continue."
                exit 1
            fi
            sudo_cmd+=" pacman -Sy --noconfirm android-tools"
            ;;
        centos|rhel)
            sudo_cmd="sudo"
            if ! command -v sudo >/dev/null 2>&1; then
                echo "Please install 'sudo' to continue."
                exit 1
            fi
            sudo_cmd+=" yum install -y android-tools"
            ;;
        *)
            echo "Unsupported Linux distribution."
            exit 1
            ;;
    esac

    # Set up udev rules if necessary
    if [[ ! -f /etc/udev/rules.d/51-android.rules ]]; then
        case $distro in
            ubuntu|debian|centos|rhel|arch)
                sudo_cmd+=" && echo SUBSYSTEM==\"usb\", ATTR{idVendor}==\"0bb4\", MODE=\"0666\", GROUP=\"plugdev\" | $sudo_cmd tee /etc/udev/rules.d/51-android.rules > /dev/null"
                sudo_cmd+=" && $sudo_cmd udevadm control --reload-rules && $sudo_cmd udevadm trigger"
                ;;
            *)
                echo "Cannot automatically set up udev rules for this distribution. Please set up udev rules manually."
                exit 0
                ;;
        esac

        echo "ADB and udev rules have been installed and set up successfully."
    else
        echo "ADB is installed, but udev rules already exist."
    fi

    # Execute installation command with sudo privileges if necessary
    if [[ $EUID -ne 0 ]]; then
        echo "This script needs to be run with sudo privileges to install ADB and set up udev rules."
        echo "Please enter your sudo password to continue."
        eval "$sudo_cmd"
    else
        eval "$sudo_cmd"
    fi
}

# Check if ADB and udev rules are already installed
if command -v adb >/dev/null 2>&1 && [[ -f /etc/udev/rules.d/51-android.rules ]]; then
    echo "ADB and udev rules are already installed."
    # Execute the manager.sh script
    current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    manager_script="$current_dir/linux/manager.sh"

    if [[ -f "$manager_script" ]]; then
        chmod +x "$manager_script"
        "$manager_script"
    else
        echo "manager.sh script not found in the 'linux' folder."
        exit 1
    fi
else
    # Install ADB and set up udev rules
    install_adb
fi
