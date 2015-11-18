#!/bin/bash
# 1un
# 创建:2015-09-08 修改:2015-10-29
# 初始化脚本
# 增加zabbix-agent:mysql监控项下发,调整用户环境变量

[ $UID -ne 0 ] && { echo "Usage: sudo su -" ; exit 1 ; }

_print(){    #打印信息
    printf "\n    *************************************\n"
    printf "  ****** \033[1;7;5;40;32m%-s\033[0m \n" $*
    printf "*************************************\n"
    sleep 3
}

#----------------------------------------------------------------------

_print 初始化数据盘

wget -q http://ks.cfgximi.com/automount_data_block.sh -O /tmp/automount_data_block.sh
/bin/bash /tmp/automount_data_block.sh

#----------------------------------------------------------------------

_print 获取外网信息

echo "$(curl members.3322.org/dyndns/getip 2>/dev/null)" > /etc/wan

#----------------------------------------------------------------------

_print 创建只读用户

rm -rf /bin/sh && ln -s /bin/bash /bin/sh
useradd ximi
useradd nobody
mkdir /home/ximi
[ -f "/home/ximi/.bashrc" ] && cp /home/ximi/.bashrc /home/ximi/.bashrc.bak
wget -q http://ks.cfgximi.com/ximi.bashrc -O /home/ximi/.bashrc
sed -i '/ximi\:/ s#/bin/sh#/bin/bash#g' /etc/passwd
## ↑ /bin/sh ---> /bin/bash ##  修改只读用户shell环境

#----------------------------------------------------------------------

_print 修改主机名

read -p "Enter Hostname:" hn
hostname $hn
sed -i -e "/ubuntu/d" -i -e "s/$hn//g" -i -e "/127.0.0.1/ s/^127.0.0.1.*/127.0.0.1 $hn $hn.ximigame.net localhost/g" /etc/hosts
echo "$hn" > /etc/hostname
sed -i -e "/zabbix.ximiidc.com/d" /etc/hosts
echo "ks.cfgximi.com zabbix.ximiidc.com" >> /etc/hosts
#wget -q http://ks.cfgximi.com/lzqieximi -O /tmp/hosts                             #最新hosts
#wget -q http://ks.cfgximi.com/authorized_keys -O /home/ximi/.ssh/authorized_keys  #ssh key

#----------------------------------------------------------------------

_print 准备工作目录

mkdir -p /data/svndata 
ln -s /data/svndata /svndata
# ddz迁移 软链??
ln -s /data /alidata1
mkdir /monitor
mkdir /fw
mkdir -p /data/corefile
[ ! -d /root/.ssh/ ] && mkdir -p /root/.ssh
# 只读用户家目录
mkdir /home/ximi/.ssh/
chmod  755 /home/ximi/.ssh/

#----------------------------------------------------------------------

_print 配置管理员环境变量

cp /root/.bashrc /root/.bashrc.bak
wget -q http://ks.cfgximi.com/root.bashrc -O /root/.bashrc

#----------------------------------------------------------------------

_print 修改欢迎界面

wget -q http://ks.cfgximi.com/motd.tail -O /etc/motd.tail

#----------------------------------------------------------------------

_print 安装必要软件

apt-get update >/dev/null
apt-get install -y htop >/dev/null
apt-get install -y iotop >/dev/null
apt-get install -y nload >/dev/null
apt-get install -y bmon >/dev/null
apt-get install -y vim >/dev/null
apt-get install -y gdb >/dev/null
apt-get install -y unzip >/dev/null
apt-get install -y screen >/dev/null
apt-get install -y lrzsz >/dev/null
apt-get install -y liblua5.1-dev >/dev/null
apt-get install -y liblua5.1-curl0 >/dev/null
apt-get install -y libssl-dev >/dev/null
apt-get install -y apt-show-versions >/dev/null
apt-get install -y git >/dev/null
apt-get install -y curl >/dev/null
apt-get install -y dos2unix >/dev/null
apt-get install -y liblua5.1-0-dev >/dev/null
apt-get install -y gcc >/dev/null
apt-get install -y g++ >/dev/null
apt-get install -y make >/dev/null
apt-get install -y subversion >/dev/null
apt-get install -y zlib1g-dev >/dev/null
apt-get install -y libssl-dev >/dev/null
apt-get install -y openssl >/dev/null
apt-get install -y tree >/dev/null
apt-get install -y iftop >/dev/null
apt-get install -y bc >/dev/null
apt-get install -y acl >/dev/null
apt-get install -y sysstat >/dev/null
apt-get upgrade -y glibc >/dev/null

# git clone git://github.com/kongjian/tsar.git          #使用sysstat
# cd tsar/
# make
# make install

# 安装rsync
_print 安装配置rsync
apt-get install -y rsync
wget -q http://10.140.34.28/xyj/config-file/rsyncd.conf -O /etc/rsyncd.conf
pkill rsync && /usr/bin/rsync --daemon


# 安装zabbix-agent
_print 安装配置zabbix-agent
# 下载
groupadd zabbix && useradd -g zabbix zabbix -s /bin/false
wget -q http://10.140.34.28/xyj/app-file/zabbix/zabbix-2.4.6.tar.gz -P /tmp/
tar xf /tmp/zabbix-2.4.6.tar.gz -C /tmp/
cd /tmp/zabbix-2.4.6
# 安装
./configure --prefix=/opt/zabbix-2.4.6 --enable-agent
make install
# 配置
cp -r /opt/zabbix-2.4.6/etc /etc/zabbix
wget -q http://10.140.34.28/xyj/config-file/zabbix_agentd.conf -O /etc/zabbix/zabbix_agentd.conf
wget -q http://10.140.34.28/xyj/config-file/userparameter_mysql.conf -O /etc/zabbix/zabbix_agentd.d/userparameter_mysql.conf
wget -r -np -q http://10.140.34.28/xyj/monitor/ -P /monitor/
find /monitor -name "index*" -exec rm -f {} \;
chmod -R +x /monitor
mv /monitor/10.140.34.28/xyj/monitor/* /monitor
rm -rf /monitor/10.140.34.28
echo 'PATH=${PATH}:/opt/zabbix-2.4.6/sbin' >> /root/.bashrc
mkdir -p /etc/zabbix/zabbix_agentd.d && chown zabbix:zabbix /etc/zabbix/zabbix_agentd.d
mkdir -p /var/log/zabbix && chown zabbix:zabbix /var/log/zabbix
mkdir -p /var/run/zabbix && chown zabbix:zabbix /var/run/zabbix
# 启动
cd /opt/zabbix-2.4.6/sbin && ./zabbix_agentd -c /etc/zabbix/zabbix_agentd.conf
# 清理
rm -rf /tmp/zabbix*

#----------------------------------------------------------------------

## >>>>>>>>>>>>>>>>>>>>>>>>> mongo3.0.6 <<<<<<<<<<<<<<<<<<<<<<<<<
#_print 安装配置mongo-3.0.6
## 准备
#mkdir -p /data/mongodb
#mkdir -p /var/log/mongodb
## 下载
#wget -q http://10.140.34.28/xyj/app-file/mongodb-3.0.6.tgz -P /tmp/
#tar xf /tmp/mongodb-3.0.6.tgz -C /tmp/
## 安装
#mv /tmp/mongodb-linux-x86_64-ubuntu1204-3.0.6 /opt/mongodb
#echo 'export PATH=/opt/mongodb/bin:$PATH' >> /root/.bashrc
## 初始化
#echo "rs.slaveOk();" > /root/.mongorc.js
#wget -q http://10.140.34.28/xyj/config-file/mongod.conf -O /etc/mongod.conf
## 启动
#cd /opt/mongodb/bin && ./mongod --config /etc/mongod.conf
## 清理
#rm -rf /tmp/mongodb-3.0.6.tgz


## >>>>>>>>>>>>>>>>>>>>>>>>> redis3.0.4 <<<<<<<<<<<<<<<<<<<<<<<<<
#_print 安装配置redis-3.0.4
## 准备/下载
#ln -s /usr/lib/insserv/insserv /sbin/insserv
#cd /tmp
#wget -q http://10.140.34.28/xyj/app-file/redis-3.0.4.tar.gz -P /tmp/
## 安装
#tar xf /tmp/redis-3.0.4.tar.gz -C /opt/
#cd /opt/redis-3.0.4/src
#make && make install
#cd /opt/redis-3.0.4/utils
## 初始化
#sh install_server.sh
## 清理
#rm -rf /tmp/redis-3.0.4.tar.gz


## >>>>>>>>>>>>>>>>>>>>>>>>> mysql5.6.26 <<<<<<<<<<<<<<<<<<<<<<<<<
#_print 安装配置mysql-5.6.26
## 下载
#wget -r -np -nd -q -A deb,pass http://10.140.34.28/xyj/app-file/mysql/ -P /tmp/
## 安装
#debconf-set-selections /tmp/mysql.pass
#dpkg-preconfigure /tmp/mysql-*
#dpkg -i /tmp/libaio1* /tmp/mysql-*
#service mysql stop
## 配置
#mkdir -p /data/mysql/{db,binlog}
#chown -R mysql:mysql /data/mysql
#mv /etc/mysql/my.cnf{,.bak}
#wget -q http://10.140.34.28/xyj/config-file/my.cnf -O /etc/mysql/my.cnf
#wget -q http://10.140.34.28/xyj/config-file/usr.sbin.mysqld -O /etc/apparmor.d/usr.sbin.mysqld
#service apparmor restart
## 初始化
#mysql_install_db --defaults-extra-file=/etc/mysql/my.cnf
## 启动
#service mysql start
## 清理
#rm -rf /tmp/mysql* /tmp/index* /tmp/libaio1*

#----------------------------------------------------------------------

## >>>>>>>>>>>>>>>>>>>>>>>>> jdk 1.7.0_80 <<<<<<<<<<<<<<<<<<<<<<<<<
#_print 安装配置JDK-1.7.0_80
## 下载
#wget -q http://10.140.34.28/xyj/app-file/jdk.tar.bz2 -P /tmp/
## 安装
#tar xf /tmp/jdk.tar.bz2 -C /opt/
## 配置
#cat << EOF >> /etc/profile
#
##------------------------------------------------------
#
#
#PATH=\$PATH:\$HOME/bin
#
#export PATH
#
#export JAVA_HOME=/opt/jdk1.7.0_80
#export PATH=\$JAVA_HOME/bin:\$PATH
#export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
#
#EOF


#----------------------------------------------------------------------



_print 配置防火墙

wget -q http://10.140.34.28/xyj/config-file/iptables -O /fw/iptables
chmod +x -R /fw
/bin/bash /fw/iptables start

#----------------------------------------------------------------------

_print 简单安全设置

chmod 4755 /usr/bin/strace
chmod 4755 /usr/bin/lsof
chmod 4755 /bin/netstat
chmod 4755 /usr/sbin/tcpdump
chmod 4755 /usr/bin/gdb
#no shutdown
sed -i "s/^exec/#exec/g" /etc/init/control-alt-delete.conf

#----------------------------------------------------------------------

_print 配置系统启动项

sed -i "/rsync/d" /etc/rc.local
sed -i "/iptables/d" /etc/rc.local
sed -i "/exit/d" /etc/rc.local

echo "/usr/bin/rsync --daemon" >>/etc/rc.local
echo "/fw/iptables start" >>/etc/rc.local
echo "/etc/init.d/zabbix-agent start" >>/etc/rc.local
echo "exit 0" >>/etc/rc.local

#----------------------------------------------------------------------

_print 配置DNS

echo "nameserver 10.140.34.28" >/etc/resolv.conf

#----------------------------------------------------------------------

_print 配置ssh

wget -q http://10.140.34.28/sshd-for-key.sh -O /tmp/sshd-for-key.sh
/bin/bash /tmp/sshd-for-key.sh
sed -i '/ AAAAB3NzaC1yc2EAAAABIwAAAQEAyCNnRVphssiEsQ/d' /root/.ssh/authorized_keys
sed -i '/ AAAAB3NzaC1yc2EAAAADAQABAAABAQCoF72GzH/d' /root/.ssh/authorized_keys

# 管理员key
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAnUcYtcyWpzWaIW5clD/LqjcprYl0AkQPnioEpm3J9NTT6UOUbR/FPnXBRj+2SdKcydNv/ryo10Z90W6isiS2JlkpyuFjVJp2SkGFMh8gbONaQ3w3XYxiOX6xk8lxyPx5BGydrKa4NwNuset0KmZWDUo8LoyHacNLbohtd4bKc5LvqQGfpj/TcRh+kW70ssOBPlNyD3JV2hPcJ/dqMJyZY1Vf3KM9IyBG4ko39hKXS/RDfp6e1PWI+Ky0j7mMOow4rsu24Jz35PcKCPV5uIFfIfB1MfdwD3pzEGlcXFzX63Eg+VOuqujAuPBqSXROvYUyCK1QAG+/XwiSdpoSzKVhPw== root@vm10-140-34-28.ksc.com' >> /root/.ssh/authorized_keys
#echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCoF72GzH/qxyIPvbkKpiNQz6ZDNqIpLYeiSbfq+/dvlwuw8bFa8DYYLc0hBh2lx1dDkR23TTfeT1T0CwqY6QiZB7BaF7CuEs57IfFq8g+leRhxOCVDtI1czMfG3wXLKOOQ3MhZiNsmNvEIE7OOYgfxuBF4g4igKQKBXil3PmS1dT4YnDSFeXbonOAuSTeq+A+l/tW/Lg/LqhFu1rKpPQh9uedH6Nwpof4HoYRCFeCz6EZkaWnqRhL8qEXqovbp/eS3jmLNOSuoXtPpc5CQCOO6KfeTCLlppUL3N6f1Yum6GMrycnFd/PL7Kq0Y7qVpZ4IF3jN+B4dNIY3eZRnjmg/3 root@market' >> /root/.ssh/authorized_keys

# 只读用户key
echo  'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUOHXuGRx3Bf0/CVRQeo4cRtszPWwcgKKEcWbvOJo1Oth2C0Cy5lj61SP6NPTgoncyirFf4Vjb1ghn5tVOEOOXsNbiBJyiVGoOQXi8ZLDQvGWoUduKO8nOqPxUPLLX93kFiWBaSNGbBNtdkSg0dxUEMkvlEuTS2SxsQ5TpRIA9xnhbeRz8Lz/vMuWcaE5W1L/JRTcaEhN3FzEtsp/fb42WdlZW4+6k3IY8GpLMue9DCvE/Bmcr6nudLcdAuAZ7cG4HqPHHgtoem3SN8YHQpFj9pVX3bhNRBvYGB+QFmvhNJVieK+me+wkYbhxZ71buGzbHN6LZVLmefbYdtVwD9pYV root@kickseed' > /home/ximi/.ssh/authorized_keys

#----------------------------------------------------------------------

_print 配置全局环境变量

wget -q http://120.92.226.38/xyj/Initialize/profile -O /etc/profile

# core file
echo "/data/corefile/core-%e-%p-%t" > /proc/sys/kernel/core_pattern
setfacl -R -m d:u:ximi:rwx /data/corefile
setfacl -R -m u:ximi:rwx /data/corefile

#----------------------------------------------------------------------

_print 添加swap
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

#----------------------------------------------------------------------

_print 设置时间同步
sed -i 's/ntpupdate/ntpdate/' /var/spool/cron/crontabs/root

_print 清理临时文件
cd /tmp
rm -rf automount_data_block.sh sshd-for-key.sh zabbix.deb 6379.conf *.iptables oldhistory redis-3.0.4.tar.gz $0

_print 初始化完成
