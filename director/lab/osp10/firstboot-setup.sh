#!/bin/bash

# Permit root login over SSH
sed -i 's/.*ssh-rsa/ssh-rsa/' /root/.ssh/authorized_keys
sed -i 's/PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config

systemctl restart sshd

# Update the root password to something we know
echo changeme | sudo passwd root --stdin

# configure rp filter to accept packets on all links
#echo 2 > /proc/sys/net/ipv4/conf/all/rp_filter

# This script contains your procedure to wipe the non-root disks. It
# wipes all disks except for the root disk to make sure there's nothing
# left from a previous install and to have GPT labels in place.
if [[ `hostname` = *"ceph"* ]]; then
  echo "Number of disks detected: $(lsblk -no NAME,TYPE,MOUNTPOINT | grep "disk" | awk '{print $1}' | wc -l)"
  for DEVICE in `lsblk -no NAME,TYPE,MOUNTPOINT | grep "disk" | awk '{print $1}'`
  do
    ROOTFOUND=0
    echo "Checking /dev/$DEVICE..."
    echo "Number of partitions on /dev/$DEVICE: $(expr $(lsblk -n /dev/$DEVICE | awk '{print $7}' | wc -l) - 1)"
    for MOUNTS in `lsblk -n /dev/$DEVICE | awk '{print $7}'`
    do
      if [ "$MOUNTS" = "/" ]
      then
        ROOTFOUND=1
      fi
    done
    if [ $ROOTFOUND = 0 ]
    then
      echo "Root not found in /dev/${DEVICE}"
      echo "Wiping disk /dev/${DEVICE}"
      #dd if=/dev/zero of=/dev/${DEVICE} bs=1G count=1
      sgdisk -Z /dev/${DEVICE}
      sgdisk -g /dev/${DEVICE}
      #parted /dev/${DEVICE} mklabel gpt
      #sync
    else
      echo "Root found in /dev/${DEVICE}"
    fi
  done
  # partx is still broken so we replace it by a script that simulates it
  if [ ! -e /usr/sbin/partx.org ]; then
    mv /usr/sbin/partx /usr/sbin/partx.org
    cat <<"END" > /usr/sbin/partx
#!/bin/bash
[[ $1 = *"dev"* ]] && DEV="$1" || DEV="$2"
/usr/sbin/partx.org -u ${DEV}
echo "`date` partx $@" >> /tmp/partx.out
exit 0
END
    chmod 755 /usr/sbin/partx
    ln -s /bin/true /usr/sbin/partx
  fi
fi

exit 0

# old one for SSD journal that needs to have a frst partition in place
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
