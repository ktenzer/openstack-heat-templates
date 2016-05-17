#!/bin/bash
 
# Permit root login over SSH
sed -i 's/.*ssh-rsa/ssh-rsa/' /root/.ssh/authorized_keys
sed -i 's/PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
 
systemctl restart sshd
 
# Update the root password to something we know
echo test1234 | sudo passwd root --stdin
 
# configure rp filter to accept packets on all links
echo 2 > /proc/sys/net/ipv4/conf/all/rp_filter

# wipe ceph disks to make sure there's nothing left from a previous install
if hostname|grep overcloud-ceph > /dev/null; then
	for i in {b,c,d,e}; do
		if [ -b /dev/sd${i} ]; then
			echo "Wiping disk /dev/sd${i} and creating journal partition..."
			sgdisk -Z /dev/sd${i}
			sgdisk -g /dev/sd${i}
			sgdisk -n 1:2048:10487808 -t 1:FFFF -c 1:"ceph journal" -g /dev/sd${i};
		fi
	done
	for i in {h,i,j,k}; do
		if [ -b /dev/sd${i} ]; then
			echo "Wiping disk /dev/sd${i}..."
			sgdisk -Z /dev/sd${i}
			sgdisk -g /dev/sd${i}
		fi
	done
fi

