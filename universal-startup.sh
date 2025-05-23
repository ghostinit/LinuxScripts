#!/bin/bash
ROLE=$1

sudo apt update && apt upgrade -y





function host_setup() 
{
	sudo apt install vim neovim gparted gimp conky git apcupsd htop net-tools curl wget build-essential unzip
	echo "Installing Brave Browser"
	curl -fsS https://dl.brave.com/install.sh | sh
	
	echo "Installing MullVAD"
	sudo curl -fsSLo /usr/share/keyrings/mullvad-keyring.asc https://repository.mullvad.net/deb/mullvad-keyring.asc
	echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=$( dpkg --print-architecture )] https://repository.mullvad.net/deb/stable stable main" | sudo tee /etc/apt/sources.list.d/mullvad.list
	#echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=$( dpkg --print-architecture )] https://repository.mullvad.net/deb/beta beta main" | sudo tee /etc/apt/sources.list.d/mullvad.list
	sudo apt update
	sudo apt install mullvad-vpn
	echo "Mullvad Installed"
	
	echo "Installing Packages"
	sudo apt install vim neovim gedit gparted -y
	
	read -p "Remove bloat? (y/n): " remove_bloat
	if [[ "$remove_bloat" =~ ^[Yy]$ ]]; then
		sudo apt remove --purge libreoffice-* thunderbird hexchat pidgin simple-scan rhythmbox xplayer -y
		sudo apt autoremove --purge -y
		sudo apt clean
	fi

	read -p "Setup KVM? (y/n): " setup_kvm
	if [[ "$setup_kvm" =~ ^[Yy]$ ]]; then
		sudo apt update && sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager -y 
		sudo usermod -aG libvirt $(whoami)
		newgrp libvirt

	fi
	
	read -p "Harden system? (y/n): " harden_system
	if [[ "$harden_system" =~ ^[Yy]$ ]]; then
		echo "Enabling firewall"
		sudo ufw default deny incoming
		sudo ufw default allow outgoing
		sudo ufw allow 22/tcp    # Or your custom SSH port
		sudo ufw enable
		
		echo "Disabling ipv6"
		echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf > /dev/null
		echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf > /dev/null
		sudo sysctl -p
		
		echo "Setting up Fail2Ban"
		sudo apt install fail2ban -y
		sudo systemctl enable fail2ban
		sudo systemctl start fail2ban
		
		echo "Setting up AppArmor"
		sudo aa-status
		sudo systemctl enable apparmor --now
		
		echo "Enabling automatic security updates"
		sudo apt install unattended-upgrades -y
		sudo dpkg-reconfigure --priority=low unattended-upgrades
		
		echo "Open a new terminal and do the following now"
		read -p "SSH Hardening

			Edit /etc/ssh/sshd_config:

			PermitRootLogin no
			PasswordAuthentication no
			AllowUsers yourusername
			# Optional: Port 2222

			Restart SSH:

			sudo systemctl restart ssh
			
			Enter when done:"
		
		
		read -p "Harden Shared Memory

			Add to /etc/fstab:
		
			tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0
		
			Enter when done:"
		
		
		read -p "Use Secure DNS

			Edit /etc/systemd/resolved.conf:

			DNS=1.1.1.1
			FallbackDNS=9.9.9.9

			Restart:

			sudo systemctl restart systemd-resolved

			Enter when done:"
			
		echo "Installing AIDE"
		sudo apt install aide -y
		sudo aideinit

		dpkg --get-selections > ~/packages_installed.txt

	fi
	
}

do_reboot() {
	read -p "Reboot now? (y/n): " do_reboot
	if [[ "$do_reboot" =~ ^[Yy]$ ]]; then
		sudo reboot now
	fi

}

if [ "$ROLE" == "host" ] || [ "$ROLE" == "HOST" ]; then
	echo "Running Host Setup"
	#curl -fsSL https://raw.githubusercontent.com/ghostinit/LinuxScripts/main/modules/host_setup.sh -o /tmp/host_setup.sh
	#chmod +x /tmp/host_setup.sh
	#/tmp/host_setup.sh
	host_setup
	do_reboot
else
	echo "Unknown setup role"
fi
