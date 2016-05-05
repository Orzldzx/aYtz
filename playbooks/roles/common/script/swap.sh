#!/bin/bash
count=$(cat /proc/swaps|wc -l)
space=$(df -h|awk '/\/$/{print $2-$3}'|awk -F\. '{print $1}')
if [[ $count -ne 2 ]]; then 
    if [[ $space -ge 3 ]]; then
        dd if=/dev/zero of=/var/swap bs=1M count=2048 
        if [[ $? -ne 0 ]]; then
            rm -rf /var/swap
            exit
        fi
    else
        echo "No space to swap!"
    fi
    mkswap /var/swap
    swapon /var/swap
    echo "/var/swap     swap    swap    defaults    0 0" >> /etc/fstab                                                                                                                                                                                                        
else
    swapon -s
fi

echo 0 > /proc/sys/vm/swappiness
