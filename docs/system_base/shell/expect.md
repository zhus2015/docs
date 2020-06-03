首先要安装expect

1、expect远程登录脚本

```shell
#!/usr/bin/expect
set host "xxx.xxx.xxx.xxx"
set passwd "passwd"
spawn ssh [root@host](mailto:root@host)
expect{
    "yes/no"{send "yes\r";exp_continue}
    "password:" {send "$passwd\r" }
}
interact
```



2、远程登陆，执行命令然后退出

```shell
#!/usr/bin/expect
set user "root"
set passwd "123456"
spawn ssh $user@192.168.11.18
expect {
    "yes/no" { send "yes\r"; exp_continue}
    "password:" { send "$passwd\r" }
}
expect "]*"
	send "touch /tmp/12.txt\r"
expect "]*"
	send "echo 1212 &gt; /tmp/12.txt\r"
expect "]*"
	send "exit\r"
```



3、传递参数

```shell
#!/usr/bin/expect

set user [lindex $argv 0]
set host [lindex $argv 1]
set passwd "123456"
set cm [lindex $argv 2]
spawn ssh $user@$host
expect {
    "yes/no" { send "yes\r"}
    "password:" { send "$passwd\r" }	
}

expect "]*"
    send "$cm\r"
expect "]*"
    send "exit\r"
```

4、自动同步文件

```shell
#!/usr/bin/expect
set passwd "123456"
spawn rsync -av root@192.168.11.18:/tmp/12.txt /tmp/
expect {
    "yes/no" { send "yes\r"}
    "password:" { send "$passwd\r" }
}
expect eof
# eof结束符
```



5、构建简单的文件分发系统

分为两部分

一部分是rsync.expect

```shell
#!/usr/bin/expect
set passwd "123456"
set host [lindex $argv 0]
set file [lindex $argv 1]
spawn rsync -av --files-from=$file / root@$host:/
expect {
    "yes/no" { send "yes\r"}
    "password:" { send "$passwd\r" }
}
expect eof
```



另一个是rsync.sh

```shell
#!/bin/bash
for ip in `cat ip.list`   ##ip.lis是需要同步的机器IP列表
do
  echo $ip
  ./rsync.expect $ip list.txt ##list.txt是同步文件列表
done
```



5、命令批量执行脚本

exe.expct

```shell
#!/usr/bin/expect
set host [lindex $argv 0]
set passwd "123456"
set cm [lindex $argv 1]
spawn ssh root@$host
expect {
    "yes/no" { send "yes\r"}
    "password:" { send "$passwd\r" }
}

expect "]*"
    send "$cm\r"
expect "]*"
    send "exit\r"
```



exe.sh

```shell
#!/bin/bash
for ip in `cat ip.list`
do
  echo $ip
  ./exe.expect $ip "w;free -m;ls /tmp"
done
```

