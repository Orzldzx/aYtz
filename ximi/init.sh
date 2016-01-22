#!/bin/bash
# 1un
# 创建:2015-09-08 修改:2016-01-06
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
mkdir -p /etc/zabbix/zabbix_agentd.d
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
pkill rsync
/usr/bin/rsync --daemon


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
cp -r /opt/zabbix-2.4.6/etc/* /etc/zabbix/
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

wget -q http://10.140.34.28/xyj/Initialize/sshd-for-key.sh -O /tmp/sshd-for-key.sh
/bin/bash /tmp/sshd-for-key.sh
sed -i '/ AAAAB3NzaC1yc2EAAAABIwAAAQEAyCNnRVphssiEsQ/d' /root/.ssh/authorized_keys
sed -i '/ AAAAB3NzaC1yc2EAAAADAQABAAABAQCoF72GzH/d' /root/.ssh/authorized_keys

# 管理员key (跳板机)
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAnUcYtcyWpzWaIW5clD/LqjcprYl0AkQPnioEpm3J9NTT6UOUbR/FPnXBRj+2SdKcydNv/ryo10Z90W6isiS2JlkpyuFjVJp2SkGFMh8gbONaQ3w3XYxiOX6xk8lxyPx5BGydrKa4NwNuset0KmZWDUo8LoyHacNLbohtd4bKc5LvqQGfpj/TcRh+kW70ssOBPlNyD3JV2hPcJ/dqMJyZY1Vf3KM9IyBG4ko39hKXS/RDfp6e1PWI+Ky0j7mMOow4rsu24Jz35PcKCPV5uIFfIfB1MfdwD3pzEGlcXFzX63Eg+VOuqujAuPBqSXROvYUyCK1QAG+/XwiSdpoSzKVhPw== root@vm10-140-34-28.ksc.com' >> /root/.ssh/authorized_keys

# auto-push
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWlA7AnRLWMWc1Hiz870DpkH43hzFFuspVXiLDwYfpH2kRR7BNQKFbD7EhCKC5sORGrhTSqw2/bxRjR0WdHLTvB6e+7cSBoQJD/nq9j3Ht2g22l+xvkJ8nufHZI8aB+APSdkIproZfi9eTKC6tbRqQiNEn8V2Pjf0SEEZIX6hJjOv36qbPVjqU/UE05AzvWJ5X6ppgyrt6PM3O6gzOuyhUqDNqk/jgc38t4Hhr1THCcA1MmlxCyZ4REsUhUf/Q83T75m243i72nXkaWBnWUCHjlpuLlEiSWJ1t4V27yJ+XiuAF89hBoFybMKYeTOYNlapo8QGZyyYgqapBle/Ic9w5 root@rundeck' >> /root/.ssh/authorized_keys

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

_print 优化系统配置
# 启动时不清除/tmp目录
sed -i 's/^TMPTIME=0/TMPTIME=-1/' /etc/default/rcS
# 禁止CTRL+ALT+DEL关机
sed -i "s/ca::ctrlaltdel:\/sbin\/shutdown -t3 -r now/#ca::ctrlaltdel:\/sbin\/shutdown -t3 -r now/" /etc/inittab

#----------------------------------------------------------------------

# 优化内核参数
cp /etc/sysctl.conf /etc/sysctl.conf-$(date +%F).bak
cat > /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 1                          # 开启ipv4路由转发
net.ipv4.conf.default.rp_filter = 1              # 开启多网卡下接受多播过滤(发给a网卡,b接受到了就被丢弃掉)
net.ipv4.conf.default.accept_source_route = 0    # 不接受源路由
kernel.sysrq = 0                                 # 禁用sysrq(键盘上截图键)
kernel.core_uses_pid = 1                         # 给生成的core文件加上pid
net.ipv4.tcp_syncookies = 1                      # 开启SYN Cookies(出现SYN等待队列溢出时可防范少量SYN攻击)
kernel.msgmnb = 65536                            # 每个消息队列的最大字节限制
kernel.msgmax = 65536                            # 每个消息的最大size
kernel.shmmax = 68719476736                      # 定义单个共享内存段的最大值
kernel.shmall = 4294967296                       # 控制共享内存页数
net.ipv4.tcp_max_tw_buckets = 6000               # 系统同时保持TIME_WAIT套接字的最大数量(如果超过这个数字,TIME_WAIT套接字将立刻被清除并打印警告信息)
net.ipv4.tcp_sack = 1                            # 开启Selective ACK,用来查找特定丢失数据包,有助于快速恢复状态
net.ipv4.tcp_window_scaling = 1                  # 设置tcp/ip会话的华东窗口大小为可变

net.ipv4.tcp_rmem = 4096 87380 4194304           # 预留接收socket缓冲内存大小
# min: 为TCP socket, 预留用于接收缓冲的内存数量, 即使在内存出现紧张情况下tcp socket都至少会有这么多数量的内存用于接收缓冲, 默认值为8K
# default: 为TCP socket预留用于接收缓冲的内存数量, 默认情况下该值影响其它协议使用的net.core.wmem_default 值. 该值决定了在tcp_adv_win_scale, tcp_app_win和tcp_app_win=0默认值情况下, TCP窗口大小为65535. 默认值为87380
# max: 用于TCP socket接收缓冲的内存最大值. 该值不会影响 net.core.wmem_max, "静态"选择参数 SO_SNDBUF则不受该值影响. 默认值为 128K. 默认值为87380*2 bytes.

net.ipv4.tcp_wmem = 4096 16384 4194304           # 发送(同上)
net.core.wmem_default = 8388608                  # 表示发送套接字缓冲区大小的缺省值(以字节为单位)
net.core.rmem_default = 8388608                  # 表示接收套接字缓冲区大小的缺省值(以字节为单位)
net.core.rmem_max = 16777216                     # 最大socket读buffer, 可参考的优化值:873200
net.core.wmem_max = 16777216                     # 最大socket写buffer, 可参考的优化值:873200
net.core.netdev_max_backlog = 262144             # 每个网络接口接收数据包的速率比内核处理这些包的速率快时, 允许送到队列的数据包的最大数目.

net.core.somaxconn = 262144                      
# web应用中listen函数的backlog默认会给我们内核参数的net.core.somaxconn限制到128, 而nginx定义的NGX_LISTEN_BACKLOG默认为511, 所以有必要调整这个值

net.ipv4.tcp_max_orphans = 3276800               # 系统能创建的不属于任何进程的socket数量.快速建立大量连接时,需要关注这个值

net.ipv4.tcp_max_syn_backlog = 262144            # 记录的那些尚未收到客户端确认信息的连接请求的最大值(syn队列,默认1024)
net.ipv4.tcp_timestamps = 0                      # 关闭TCP连接中TIME-WAIT sockets的快速回收
net.ipv4.tcp_synack_retries = 1                  # syn-ack握手状态重试次数
net.ipv4.tcp_syn_retries = 1                     # 外向syn握手重试次数
net.ipv4.tcp_tw_recycle = 1                      # 开启TCP连接中TIME-WAIT sockets的快速回收
net.ipv4.tcp_tw_reuse = 1                        # 表示开启重用. 允许将TIME-WAIT sockets重新用于新的TCP连接

net.ipv4.tcp_mem = 94500000 915000000 927000000
# net.ipv4.tcp_mem[0]:低于此值, TCP没有内存压力
# net.ipv4.tcp_mem[1]:在此值下, 进入内存压力阶段
# net.ipv4.tcp_mem[2]:高于此值, TCP拒绝分配socket
# 上述内存单位是页, 而不是字节. 可参考的优化值是:786432 1048576 1572864

net.ipv4.tcp_fin_timeout = 1                     # 修改系統默认的 TIMEOUT 时间
net.ipv4.tcp_keepalive_time = 1200               # 主动探测socket是否可用的时间间隔
net.ipv4.ip_local_port_range = 1024 65535        # 用于向外连接的端口范围
EOF
/sbin/sysctl -p

#----------------------------------------------------------------------

_print 设置时间同步
sed -i 's/ntpupdate/ntpdate/' /var/spool/cron/crontabs/root

#----------------------------------------------------------------------

_print 清理临时文件
cd /tmp
rm -rf automount_data_block.sh sshd-for-key.sh zabbix.deb 6379.conf *.iptables oldhistory redis-3.0.4.tar.gz $0

#----------------------------------------------------------------------

_print 初始化完成
