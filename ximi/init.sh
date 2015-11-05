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

apt-get update
apt-get install -y -qq htop
apt-get install -y -qq iotop
apt-get install -y -qq nload
apt-get install -y -qq bmon
apt-get install -y -qq vim
apt-get install -y -qq gdb
apt-get install -y -qq unzip
apt-get install -y -qq screen
apt-get install -y -qq lrzsz
apt-get install -y -qq liblua5.1-dev
apt-get install -y -qq liblua5.1-curl0
apt-get install -y -qq libssl-dev
apt-get install -y -qq apt-show-versions
apt-get install -y -qq git
apt-get install -y -qq curl
apt-get install -y -qq dos2unix
apt-get install -y -qq liblua5.1-0-dev
apt-get install -y -qq gcc
apt-get install -y -qq g++
apt-get install -y -qq make
apt-get install -y -qq subversion
apt-get install -y -qq zlib1g-dev
apt-get install -y -qq libssl-dev
apt-get install -y -qq openssl
apt-get install -y -qq tree
apt-get install -y -qq iftop
apt-get install -y -qq bc
apt-get install -y -qq acl
apt-get install -y -qq sysstat
apt-get upgrade -y -qq glibc > /dev/null

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
while [ ! -f /etc/zabbix/zabbix_agentd.conf ]
do
    sleep 5
   # wget -q http://ks.cfgximi.com/zabbix-release_2.4-1+trusty_all.deb -P /tmp/
    wget -q http://repo.zabbix.com/zabbix/2.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_2.0-1lucid_all.deb -O /tmp/zabbix.deb
   # dpkg -i zabbix-release_2.4-1+trusty_all.deb
    dpkg -i /tmp/zabbix.deb
    apt-get -qq update
    apt-get install -y -qq zabbix-agent
done
wget -q http://10.140.34.28/xyj/config-file/zabbix_agentd.conf -O /etc/zabbix/zabbix_agentd.conf
wget -q http://10.140.34.28/xyj/config-file/userparameter_mysql.conf -O /etc/zabbix/zabbix_agentd.d/userparameter_mysql.conf
#wget -r -np -nd -q http://10.140.34.28/xyj/monitor/ -P /monitor/
wget -r -np -q http://10.140.34.28/xyj/monitor/ -P /monitor/
find . -name "index*" -exec rm -f {} \;
chmod -R +x /monitor
mv /monitor/10.140.34.28/xyj/monitor/* /monitor
rm -rf /monitor/10.140.34.28
service zabbix-agent restart

#----------------------------------------------------------------------

## >>>>>>>>>>>>>>>>>>>>>>>>> mongo3.0.6 <<<<<<<<<<<<<<<<<<<<<<<<<
#_print 安装配置mongo-3.0.6
##  准备
#mkdir -p /data/mongodb
#mkdir -p /var/log/mongodb
##  下载
#wget http://10.140.34.28/xyj/app-file/mongodb-3.0.6.tgz -P /tmp/
#tar xf /tmp/mongodb-3.0.6.tgz -C /tmp/
##  安装
#mv /tmp/mongodb-linux-x86_64-ubuntu1204-3.0.6 /opt/mongodb
#echo 'export PATH=/opt/mongodb/bin:$PATH' >> /root/.bashrc
##  初始化
#echo "rs.slaveOk();" > /root/.mongorc.js
#wget http://10.140.34.28/xyj/config-file/mongod.conf -O /etc/mongod.conf
#rm -rf /tmp/mongodb-3.0.6.tgz


## >>>>>>>>>>>>>>>>>>>>>>>>> redis3.0.4 <<<<<<<<<<<<<<<<<<<<<<<<<
#_print 安装配置redis-3.0.4
##  准备/下载
#ln -s /usr/lib/insserv/insserv /sbin/insserv
#cd /tmp
#wget -q http://10.140.34.28/redis-3.0.4.tar.gz -P /tmp/
##  安装
#tar xf /tmp/redis-3.0.4.tar.gz -C /opt/
#cd /opt/redis-3.0.4/src
#make && make install
#cd /opt/redis-3.0.4/utils
##  初始化
#sh install_server.sh
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

# history record
#/bin/cp /root/.bash_history /tmp/oldhistory

# 实用别名
#alias ..='cd ..'
#alias ...='cd ../..'
#alias ....='cd ../../..'
#mkcd(){ mkdir -p \$1 ; cd \$1 ; }

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

#----------------------------------------------------------------------

_print 设置时间同步
sed -i 's/ntpupdate/ntpdate/' /var/spool/cron/crontabs/root

_print 清理临时文件
cd /tmp
rm -rf automount_data_block.sh sshd-for-key.sh zabbix.deb 6379.conf *.iptables oldhistory redis-3.0.4.tar.gz $0

_print 初始化完成
