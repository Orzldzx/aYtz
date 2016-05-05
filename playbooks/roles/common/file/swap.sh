#!/bin/bash
count=$(cat /proc/swaps|wc -l)
space=$(df -h|awk '/\/$/{print $2-$3}'|awk -F\. '{print $1}')
if [ $count -ne 3 ]; then
    if [ $space -ge 10 ]; then
        dd if=/dev/zero of=/var/swap bs=1M count=1000
        if [ $? -ne 0 ]; then
         #   rm -rf /var/swap
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

sed -i "/rsync/d" /etc/rc.local && sed -i "/iptables/d" /etc/rc.local && sed -i "/exit/d" /etc/rc.local && echo "/usr/bin/rsync --daemon" >>/etc/rc.local && echo "/fw/iptables start" >>/etc/rc.local && echo "/etc/init.d/zabbix-agent start" >>/etc/rc.local && echo "exit 0" >>/etc/rc.local


echo "nameserver 10.140.34.28" >/etc/resolv.conf

sed -i 's/^TMPTIME=0/TMPTIME=-1/' /etc/default/rcS

sed -i 's$ca::ctrlaltdel:/sbin/shutdown -t3 -r now$#ca::ctrlaltdel:/sbin/shutdown -t3 -r now$' /etc/inittab

sed -i 's/ntpupdate/ntpdate/' /var/spool/cron/crontabs/root

/sbin/sysctl -p

#/bin/bash /fw/iptables start

cd /opt && tar xf jdk.tar.bz2 && echo "export JAVA_HOME=/opt/jdk1.7.0_80" >> /etc/profile && echo "export PATH=\$JAVA_HOME/bin:\$PATH" >>/etc/profile && echo "export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >>/etc/profile

echo "HELLO WORD!" >> /tmp/initializefinish.txt

