

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

