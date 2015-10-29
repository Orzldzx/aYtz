#!/bin/bash
# 1un
# 2015-10-09
# for ubuntu

wanip=$(cat /etc/wan)
SSHD_CONFIG_FILE=/etc/ssh/sshd_config
# Func
# Func 1
RETURN_CODE=0
#*号用的好，0个或者无限个，匹配的很全面
#REURNCODE 定义在函数之外，稍有变动都会迭代的影响
#他是用来判断是否执行顺利！
#
#注意 sed -i 后面是双引号！ 引入的$1 和 $* 两大位置变量
#sed 的作用是，不管有没有#注释掉这个参数，都把其置为$*后的参数
#这中写法需要参数全带
sshd_config() {
    # Syntax: sshd_config <option> <value>
    egrep "^ *$1" ${SSHD_CONFIG_FILE} > /dev/null
    if [ $? -eq 0 ];then
        sed -i "/^ *$1.*/s#.*#$*#" ${SSHD_CONFIG_FILE}
        #let RETURN_CODE=${RETURN_CODE}+$?
    else
        sed -i "/^# *$1.*/s#.*#$*#" ${SSHD_CONFIG_FILE}
        #let RETURN_CODE=${RETURN_CODE}+$?
    fi
}

#修改配置项
sshd_config Port 13021
sshd_config Protocol 2
sshd_config UseDNS no
sshd_config PubkeyAuthentication yes
sshd_config AuthorizedKeysFile .ssh/authorized_keys
#允许密码认证登入，调试完后关闭
sshd_config PasswordAuthentication no
#sshd_config PasswordAuthentication yes
sshd_config MaxAuthTries 60
#sshd_config PermitRootLogin no

[ ${RETURN_CODE} -eq 0 ] && echo “Change sshd is ok!!!” || exit 1

/etc/init.d/ssh restart

#生成key
. /etc/profile
#这里ethx 要对应资产表里面的内网地址
#LOCALIP=$(/sbin/ifconfig eth0 | awk '/inet addr/ {print $2}' | awk -F':' '{print $NF}')
LOCALIP=$(/sbin/ifconfig eth0 | awk '/inet addr/ {print $2}' | awk -F':' '{print $NF}')
COMMENT="($(id -un)@${wanip}:$(hostname))   $(date +%F\ %T)"
PASSPHRASE=""
KEY_TYPE=rsa
KEY_BITS=1024
KEY_NAME=/root/.ssh/${LOCALIP}.id_dsa

#创建/root/.ssh文件夹，先是判断是否有，无则创建，有则清空文件夹后面的数据
[ ! -d ${KEY_NAME%/*} ] && mkdir ${KEY_NAME%/*} || rm -rf ${KEY_NAME%/*}/*
chmod 700 ${KEY_NAME%/*}

ssh-keygen -q -t ${KEY_TYPE} -b "${KEY_BITS}" -f "${KEY_NAME}" -N "${PASSPHRASE}" -C "${COMMENT}"
# -q                安静模式。用于在 /etc/rc 中创建新密钥的时候。
# -t type           指定要创建的密钥类型。可以使用："rsa1"(SSH-1) "rsa"(SSH-2) "dsa"(SSH-2)
# -b bits           指定密钥长度。对于RSA密钥，最小要求768位，默认是2048位。DSA密钥必须恰好是1024位(FIPS 186-2 标准的要求)。
# -f filename       指定密钥文件名。
# -N new_passphrase 提供一个新的密语。
# -C comment        提供一个新注释
chmod 600 ${KEY_NAME}
chmod 644 ${KEY_NAME}.pub
#chown nobody:nobody ${KEY_NAME}
#chown nobody:nobody ${KEY_NAME}.pub
#[ -x /sbin/restorecon ] && /sbin/restorecon ${KEY_NAME}.pub

#回传到批量发布服务器
[ ! -e /usr/bin/rsync ] && apt-get install -y rsync
rsync -av --port=1888 ${KEY_NAME}* 10.140.34.28::key
if [ $? != 0 ]; then
    echo "Failed: rsync -av ${KEY_NAME}* 192.168.0.103::rsarsync"
else
    rm -f ${KEY_NAME}
    # chown root:root ${KEY_NAME}.pub 
    mv ${KEY_NAME}.pub ${KEY_NAME%/*}/authorized_keys
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAm1SY/g0RqFTCWC5gLfgk8oC0TCeohHiWH5Di4EJeJfkOlb1KvugUSd/55mbpr96qKXM+fyZq0oCFEEphViZCLM0v2r/9FhuO5PIa6sw26bi3wcucNeADh4K94CHSm0f28mX0L6dFVMIYAKzcadwh8yv0Q5o281bL10+GxEYTc8prNBl4ZeiQwgwzCql7SfTTttw8XsXDAZMsFRkpKNGRmH03aFTKykKTiv6GHPQe1dUiIxg++bXYueiwlrhHv0gdtixyJRwma92XmzQIJIOsqQcIYwaiz/bhZ7iAX6mTF5OBmAN0lt09D5MWr8ZoB5u0Eadxs9UlYfpX0XIVekbwLw==" >>${KEY_NAME%/*}/authorized_keys
fi

    #     修改权限；pub改为authorized方便ssh使用
    #     chown nobody:nobody ${KEY_NAME}*
    #     /bin/cp  ${KEY_NAME}.pub ${KEY_NAME%/*}/authorized_keys
    #     chown root.root ${KEY_NAME%/*}/authorized_keys

    #修改完成后需要做
    #1.删除两个 dsa
    #2.关闭 password 登陆
    #3.单网卡改动eth1
