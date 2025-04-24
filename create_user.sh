#!/bin/bash

# Set variables for the new user
USERNAME="sid"
PASSWORD="tryitjesus01"

snap install amass 
snap install go --classic
apt install -y vim sudo nmap figlet parallel libpcap-dev python3 iputils-ping nodejs npm dirsearch dirb
pip3 install arjun

#Clone the repo and install shrewdeye
git clone https://github.com/tess-ss/shrewdeye-bash.git
cd shrewdeye-bash
chmod +x shrewdeye.sh
cp shrewdeye.sh /bin

# Create the user
adduser --gecos "" --disabled-password $USERNAME

# Set the password for the user
echo "$USERNAME:$PASSWORD" | chpasswd

# Add the user to the sudoers list
usermod -aG sudo $USERNAME

# Add the alias for the user
echo "alias home='cd /home/$USERNAME'" >> /home/$USERNAME/.bashrc

# Copying ssh key and fixing permission
rsync --archive --chown=sid:sid ~/.ssh /home/sid
chown -R sid: /home/sid

# Install necessary tools as the new user
sudo -u $USERNAME bash <<EOF
cd /home/$USERNAME
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/lc/gau/v2/cmd/gau@latest
go install -v github.com/hakluke/hakrawler@latest
go install -v github.com/Emoe/kxss@latest
go install -v github.com/tomnomnom/waybackurls@latest
CGO_ENABLED=1 go install github.com/projectdiscovery/katana/cmd/katana@latest

# Copy Go binaries to /bin
sudo cp /home/$USERNAME/go/bin/* /bin
EOF

echo "System updated, tools installed, user $USERNAME created with password $PASSWORD, added to the sudoers list, and alias 'home' added. Go binaries copied to /bin. Knock installed."