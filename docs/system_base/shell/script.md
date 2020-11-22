# 实用脚本



## 远程密码修改脚本

remote_sh.sh

expect需要单独安装expect软件包

```sh
#!/bin/bash
##password 服务器密码
password="redhat"
for ip in `cat ip.list`
do
  echo $ip
  /usr/bin/expect << EOF
  spawn /usr/bin/ssh root@$ip

  expect {
   "yes/no" { send "yes\r"}
  }

  expect {
    "password:" { send "${password}\r" }
  }

  expect "]*"
  send "curl -sSL http://10.4.7.45/init.sh | sh\r"
  expect "]*"
  send "exit\r"
  expect eof
EOF
done
```



## 系统初始化

init.sh

```sh
#!/bin/bash
download_host=10.4.7.45

function ssh_authorized() {
  [ -d /root/.ssh ] || mkdir /root/.ssh
  curl -o /root/.ssh/authorized_keys http://$download_host/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
}

function install_zabbix() {
  rpm -ivh http://$download_host/zabbix-agent-5.0.2-1.el7.x86_64.rpm
  sed -i 's/Server=localhost/Server=10.10.10.10/g' /etc/zabbix/zabbix_agentd.conf
  systemctl enable zabbix-agent && systemctl start zabbix-agent
}

function main() {
  ssh_authorized
  #install_zabbix
}
main
```



## 写日志函数

```shell
#!/bin/bash
LOG_FILE=/tmp/${0}.log
function WriteLog()

{
  NOW_TIME='['$(date +"%Y-%m-%d %H:%M:%S")']'
  echo ${NOW_TIME} $1 | tee -a ${LOG_FILE}
}
```



## 获取主机IP函数

```shell
#!/bin/bash
NETDEVICE_NAME=`ls /sys/class/net/ | grep -v "$(ls /sys/devices/virtual/net/)"`
HOST_IP=`ifconfig ${NETDEVICE_NAME} |grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
```





## FTP上传文件脚本

```shell
#!/bin/bash
# 主要是用FTP上传文件
#set -e 
#set -x
PROJECT=jinan

#IP地址获取
NETDEVICE_NAME=`ls /sys/class/net/ | grep -v "$(ls /sys/devices/virtual/net/)"`
HOST_IP=`ifconfig ${NETDEVICE_NAME} |grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`

FTP_DIR=/data/pgsql/backup
FTP_TMP=/tmp/ftp.tmp
FTP_LOG=/tmp/ftp.log
FTP_HOST=10.4.7.131
FTP_PORT=21
FTP_USER=ftp
FPT_PASS=123456

LockProcess(){
   touch /tmp/${0}.lock
}

UlockProcess(){
   rm -rf /tmp/${0}.lock
}

function FtpUpload()
{
   FTP_TMP=/tmp/ftp.tmp
   echo "\
   open $FTP_HOST $FTP_PORT
   user $FTP_USER $FPT_PASS
   prom
   bin
   mkdir $PROJECT
   cd $PROJECT
   mkdir $HOST_IP
   cd $HOST_IP 
   "  >$FTP_TMP

   for file in `ls ${FTP_DIR}`
     do
       echo "\
       lcd $FTP_DIR
       put $file
       " >>$FTP_TMP
     done
   echo "bye" $FTP_TMP
   cat $FTP_TMP |ftp -n 2 >>$FTP_LOG
}

#删除已上传的文件
function DelFile()
{
   for line in `grep "put" $FTP_TMP |sed 's/put//g'`
   do
     rm -rf $FTP_DIR/$line
   done
}

#这里写了一个main函数来执行
Main()
{
  [ -f /tmp/${0}.lock ] || (echo "The Shell is Runing " && exit)
  LockProcess
  FtpUpload
  #DelFile
  echo ${HOST_IP}
  UlockProcess
}
Main
```



