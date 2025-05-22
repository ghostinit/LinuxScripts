#!/bin/bash

# Update and upgrade system
sudo apt update && sudo apt upgrade -y

# Remove all Snap packages
if command -v snap >/dev/null 2>&1; then
  echo "Removing all Snap packages..."
  for pkg in $(snap list | awk 'NR>1 {print $1}'); do
    sudo snap remove --purge "$pkg"
  done

  # Remove snapd
  echo "Purging snapd..."
  sudo apt purge -y snapd
  sudo rm -rf /var/cache/snapd
  rm -rf ~/snap

  # Prevent snapd from being reinstalled
  echo -e "Package: snapd\nPin: release a=*\nPin-Priority: -10" | sudo tee /etc/apt/preferences.d/no-snap

  echo "Snap successfully nuked from orbit."
else
  echo "Snap not installed, skipping..."
fi

# Done
echo "System is prepped and snap-free."

sudo apt install postgresql postgresql-contrib openssh-server postgresql-client vim -y

