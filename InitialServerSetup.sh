#!/bin/bash
# A long way from everything, but enough to get started
# originally wrote for Ramnode VPS Ubuntu 16.04

# packages to be installed
packagesVar="fail2ban ufw nginx htop"

echo
echo Please disconnect from your FTP client now to avoid fail2ban banning you for 18 hours
read -n 1 -s -p "Press any key to continue"

# get user variables, and confirm password
echo
read -p "New User: " userVar
read -sp "Password: " passVar
echo
read -sp "Confirm Password: " passConfirmVar
echo

if [ "$passVar" != "$passConfirmVar" ]; then
	echo Passwords do not match, aborting...
	echo
	exit 1
fi

# Ramnode has bad locals for some reason
echo Fixing locale issues
locale-gen en_US.UTF-8
update-locale

# add user
groupadd $userVar
useradd $userVar -s /bin/bash -p $(openssl passwd -1 $passVar) -m -g $userVar -G sudo

# get rid of default things
apt-get remove --purge -y apache2 rpcbind postfix
rm /var/www/html/index.html

# update
apt update
apt full-upgrade -y
apt install -y $packagesVar

# disable root login (lets hope that create user thing worked)
sed -i -e 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
systemctl reload sshd

ufw allow 22
ufw allow 80
ufw allow 443
ufw enable

# setup harsh fail2ban limits
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
# 18 hours bantime
bantime	 = 64800

# [maxretry] bad passwords in this time
findtime  = 1800

maxretry = 3
EOF

# start fail2ban
systemctl restart fail2ban

# reboot the server to make sure everything restarts fresh
reboot
