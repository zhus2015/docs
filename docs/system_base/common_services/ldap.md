# Centos7安装配置LDAP



## 简述



## 安装

环境初始化跳过

> 安装

```sh
[root@localhost ~]# yum install -y openldap openldap-*
```

> 启动服务并设置开机启动

```sh
[root@localhost ~]# systemctl start slapd
[root@localhost ~]# systemctl enable slapd
```

> 查看服务启动状况

LDAP默认监听端口389

```sh
[root@localhost ~]# netstat -lntp |grep 389
tcp        0      0 0.0.0.0:389             0.0.0.0:*               LISTEN      2104/slapd    
tcp6       0      0 :::389                  :::*                    LISTEN      2104/slapd
```



## 配置LDAP

> 配置数据库

```sh
[root@localhost ~]# cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
[root@localhost ~]# chown ldap:ldap -R /var/lib/ldap
[root@localhost ~]# chmod 700 -R /var/lib/ldap
```



> 生成openldap管理员密码

```sh
[root@localhost ~]# slappasswd 
New password: 
Re-enter new password: 
{SSHA}73cdmp0gcTqH0/fsUntTl51OnYIX3S88
```

我这里仅仅是进行测试，因此设置的密码是123456，注意，设置密码时是不回显的，注意保存加密的字符



> 编辑配置文件chrootpw.ldif

```
[root@localhost ~]# mkdir -p /data/ldap
[root@localhost ~]# cd /data/ldap
[root@localhost openldap] vi chrootpw.ldif
dn: olcDatabase={0}config,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: {SSHA}73cdmp0gcTqH0/fsUntTl51OnYIX3S88 #上一步设置的管理员密码
```



> 导入chrootpw.ldif文件

```sh
[root@localhost ldap]# ldapadd -Y EXTERNAL -H ldapi:/// -f chrootpw.ldif
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "olcDatabase={0}config,cn=config"
```



> 导入基本模式

```sh
[root@localhost ldap]# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
adding new entry "cn=cosine,cn=schema,cn=config"

[root@localhost ldap]# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
adding new entry "cn=nis,cn=schema,cn=config"

[root@localhost ldap]# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
adding new entry "cn=inetorgperson,cn=schema,cn=config"

```



> 配置ldap服务的域名

```sh
[root@localhost ldap]# vi chdomain.ldif
# replace to your own domain name for "dc=***,dc=***" section
# specify the password generated above for "olcRootPW" section
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth"
  read by dn.base="cn=Manager,c=cn" read by * none

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: c=cn

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=Manager,c=cn

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
#上面生成的密码密钥
olcRootPW: {SSHA}73cdmp0gcTqH0/fsUntTl51OnYIX3S88

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by
  dn="cn=Manager,c=cn" write by anonymous auth by self write by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by dn="cn=Manager,c=cn" write by * read
```



> 导入管理员数据

```sh
[root@localhost ldap]# vi rootdn.ldif
dn: c=cn
objectclass: country
c: cn

dn: cn=Manager,c=cn
objectclass: organizationalRole
cn: Manager

[root@localhost ldap]# ldapadd -x -D cn=Manager,c=cn -W -f rootdn.ldif
#输入管理员密码即可
Enter LDAP Password: 
adding new entry "c=cn"

adding new entry "cn=Manager,c=cn"

```





使用ldapadmin进行测试

ldapadmin：http://www.ldapadmin.org/download/ldapadmin.html



![image-20200921222606766](../image/image-20200921222606766.png) 





### ldap安装web管理服务



yum install httpd -y



vi /etc/httpd/conf/httpd.conf

AllowOverride all

systemctl start httpd

systemctl enable httpd

yum install phpldapadmin -y

vi /etc/phpldapadmin/config.php

$servers->setValue('server','host','127.0.0.1');

$servers->setValue('login','attr','dn');
//$servers->setValue('login','attr','uid');



vim /etc/httpd/conf.d/phpldapadmin.conf 

取消Order Deny,Allow的注释

systemctl restart httpd

http://10.4.7.110/phpldapadmin