# VSFTP安装部署

## 环境说明

操作系统：CentOS Linux release 7.7.1908 (Core)

VSFTP版本： 3.0.2

关闭防火墙、selinux、优化内核等操作略



## 安装服务

```
yum install vsftpd libdb-utils -y
```

vsftpd是我们这次实验的主要软件

libdb-utils：是用来做用户加密的

## 创建用户

```
useradd -M -s /sbin/nologin vsftpd
```

## 修改配置文件

### 修改vsftpd.conf

```
vim /etc/vsftpd/vsftpd.conf
```

> 修改内容：

```
anonymous_enable=YES修改为  anonymous_enable=NO
#anon_upload_enable=YES修改为anon_upload_enable=NO
#anon_mkdir_write_enable=YES修改为anon_mkdir_write_enable=NO
#chroot_local_user=YES修改为chroot_local_user=YES
```



> 添加配置：

```
guest_enable=YES
##映射虚拟用户名称
guest_username=vsftpd  
virtual_use_local_privs=YES
#虚拟用户配置文件
user_config_dir=/etc/vsftpd/vuser_conf
#allow_writeable_chroot=YES
#开启被动模式
pasv_enable=YES
#被动模式安全检查
pasv_promiscuous=YES
#被动模式开放最小端口
pasv_min_port=14000
#被动模式开放最大端口
pasv_max_port=15000
```



### 修改认证文件

```
vim /etc/pam.d/vsftpd
```

只保留以下信息即可

> 64位系统

```
auth     sufficient  /lib64/security/pam_userdb.so db=/etc/vsftpd/vuser
account  sufficient  /lib64/security/pam_userdb.so db=/etc/vsftpd/vuser
```

> 32位系统

```
auth     sufficient  /lib/security/pam_userdb.so db=/etc/vsftpd/vuser
account  sufficient  /lib/security/pam_userdb.so db=/etc/vsftpd/vuser
```



## 创建相关文件及目录

> 创建目录

```
mkdir -p /etc/vsftpd/vuser_conf
```

> 创建用户文件

```
vim /etc/vsftpd/vuser
```

增加一个测试用户，格式如下：第一行为用户名，第二行为密码，再增加用户，依次顺延增加即可

test

test123

> 生成用户存储库

```
db_load -T -t hash -f /etc/vsftpd/vuser /etc/vsftpd/vuser.db
```

> 创建用户配置文件
>
> vim /etc/vsftpd/vuser_conf/test

```
local_root=/data/ftpdir/test
anonymous_enable=NO
write_enable=YES
local_umask=022
anon_upload_enable=NO
anon_mkdir_write_enable=NO
idle_session_timeout=600
data_connection_timeout=120
max_clients=10
max_per_ip=5
local_max_rate=50000
allow_writeable_chroot=YES
```

!!! warning "注意"

allow_writeable_chroot=YES  ##在2.3.5版本之后如果不写此条，ftp文件夹的所属主必须是root，否则连接的时候会报错



> 创建FTP文件夹

```
mkdir -p /data/ftpdir/test
chown -R vsftpd.vsftpd /data/ftpdir/test
```



## 启动服务测试

```
systemctl start vsftpd
```



可以使用FTP图形化工具进行测试例如：FileZilla、xftp之类的

也可以通过命令行进行操作

![image-20200616171352684](https://gitee.com/zhus2015/images/raw/master/docimg/20210317160608.png) 



## 附录：FTP命令

```
get filename：下载文件
mget *.txt：批量下载文件
put filename：上传文件
mput *.txt：批量上传文件
cd  dirname：切换目录
lcd dirname：切换本地目录
ls:显示远程文件列表
delete filename：删除远程文件
```







```
#关闭匿名登入
max_clients=10000
max_per_ip=10000
anonymous_enable=NO
anon_other_write_enable=YES
local_enable=YES
#开启日志
xferlog_file=/var/log/xferlog
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
#限制用户家目录
chroot_list_enable=YES
#限制用户家目录的用户
chroot_list_file=/etc/vsftpd/chroot_list
allow_writeable_chroot=YES
listen=YES
pam_service_name=vsftpd
userlist_enable=YES
#tcp_wrappers=YES
tcp_wrappers=NO
#不查找DNS，提高响应速度
reverse_lookup_enable=NO
pasv_promiscuous=yes
```



# FTP相关脚本

!!! warning "请自行测试过后使用"

!!! node "部分脚本是搬运而来，如有侵权请联系删除"

## 安装脚本

```shell
#!/bin/bash
#centos 7
yum install -y vsftpd libdb4-utils
useradd -d /home/vsftpd -s /bin/false vsftpd
sed  -i "s/anonymous_enable=YES/anonymous_enable=NO/g" /etc/vsftpd/vsftpd.conf
sed  -i "s/#ascii_upload_enable=YES/ascii_upload_enable=YES/g" /etc/vsftpd/vsftpd.conf
sed  -i "s/#ascii_download_enable=YES/ascii_download_enable=YES/g" /etc/vsftpd/vsftpd.conf
sed  -i "s/#chroot_local_user=YES/chroot_local_user=YES/g" /etc/vsftpd/vsftpd.conf

cat >> /etc/vsftpd/vsftpd.conf << EOF
guest_enable=YES
guest_username=vsftpd
user_config_dir=/etc/vsftpd/vuser_conf
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=4000
pasv_max_port=5000
EOF

touch /etc/vsftpd/vuser
echo "input you vsftpd username: $a"
read a
echo "input you vsftpd password: $b"
read b
echo $a >> /etc/vsftpd/vuser
echo $b >> /etc/vsftpd/vuser
db_load -T -t hash -f /etc/vsftpd/vuser /etc/vsftpd/vuser.db
chmod 600 /etc/vsftpd/vuser.db

cat > /etc/pam.d/vsftpd << EOF
auth required pam_userdb.so db=/etc/vsftpd/vuser
account required pam_userdb.so db=/etc/vsftpd/vuser
EOF

mkdir -p /etc/vsftpd/vuser_conf
touch /etc/vsftpd/vuser_conf/`cat /etc/vsftpd/vuser | awk 'NR==1'`
echo "ftp path:"
read c
mkdir -p $c

cat > /etc/vsftpd/vuser_conf/`cat /etc/vsftpd/vuser | awk 'NR==1'` << EOF
local_root=${c}
anon_umask=022
anon_world_readable_only=NO
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
EOF

chmod -R 777 $c
systemctl restart vsftpd
echo "vsftpd config finsh"
```



## 上传脚本

```shell
#!/bin/bash
# 主要是用FTP上传文件
set -e 
#set -x

FTP_DIR=/data/ftpfile
FTP_TMP=/tmp/ftp.tmp
FTP_LOG=/tmp/ftp.log
FTP_HOST=10.10.10.10
FTP_PORT=21
FTP_USER="test"
FPT_PASS="test"

function FtpUpload()
{   
   FTP_TMP=/tmp/ftp.tmp
   echo "\
   open $FTP_HOST $FTP_PORT
   user $FTP_USER $FPT_PASS
   prom
   bin
   "  >$FTP_TMP

   for file in `ls $FTP_DIR`
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
  FtpUpload
  DelFile
}
Main
```

