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

![image-20200616171352684](../images/image-20200616171352684.png) 



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

