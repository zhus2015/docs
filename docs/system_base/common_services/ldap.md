# Centos7安装配置LDAP



## 简述

| **关键字** | **英文全称**       | **含义**                                                     |
| ---------- | ------------------ | :----------------------------------------------------------- |
| **dc**     | Domain Component   | 域名的部分，其格式是将完整的域名分成几部分，如域名为example.com变成dc=example,dc=com（一条记录的所属位置） |
| **uid**    | User Id            | 用户ID songtao.xu（一条记录的ID）                            |
| **ou**     | Organization Unit  | 组织单位，组织单位可以包含其他各种对象（包括其他组织单元），如“oa组”（一条记录的所属组织） |
| **cn**     | Common Name        | 公共名称，如“Thomas Johansson”（一条记录的名称）             |
| **sn**     | Surname            | 姓，如“许”                                                   |
| **dn**     | Distinguished Name | “uid=songtao.xu,ou=oa组,dc=example,dc=com”，一条记录的位置（唯一） |
| **rdn**    | Relative dn        | 相对辨别名，类似于文件系统中的相对路径，它是与目录树结构无关的部分，如“uid=tom”或“cn= Thomas Johansson” |

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

### 配置数据库

> 配置数据库

```sh
[root@localhost ~]# cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
[root@localhost ~]# chown ldap:ldap -R /var/lib/ldap
[root@localhost ~]# chmod 700 -R /var/lib/ldap
```

### 配置管理员密码

> 生成openldap管理员密码

```sh
[root@localhost ~]# slappasswd 
New password: 
Re-enter new password: 
{SSHA}XiHlMVe4GERXPft2VSmpoysX5dNU0boM
```

我这里仅仅是进行测试，因此设置的密码是123456，注意，设置密码时是不回显的，注意保存加密的字符



> 编辑配置文件chrootpw.ldif

```sh
[root@localhost ~]# mkdir -p /data/ldap
[root@localhost ~]# cd /data/ldap
[root@localhost ldap]# vi chrootpw.ldif
# specify the password generated above for "olcRootPW" section
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
#上步骤生成的密码
olcRootPW: {SSHA}XiHlMVe4GERXPft2VSmpoysX5dNU0boM
```



> 导入chrootpw.ldif文件

```sh
[root@localhost ldap]# ldapadd -Y EXTERNAL -H ldapi:/// -f chrootpw.ldif
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "olcDatabase={0}config,cn=config"
```

### 导入基础的Schemas

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

### 设置默认域

> 配置chdomain.ldif文件

```sh
[root@localhost ldap]# vi chdomain.ldif
# replace to your own domain name for "dc=***,dc=***" section
# specify the password generated above for "olcRootPW" section
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth"
  read by dn.base="cn=admin,dc=loding,dc=com" read by * none

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=loding,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=admin,dc=loding,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcRootPW
olcRootPW: {SSHA}XiHlMVe4GERXPft2VSmpoysX5dNU0boM

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by
  dn="cn=admin,dc=loding,dc=com" write by anonymous auth by self write by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by dn="cn=admin,dc=loding,dc=com" write by * read
```

> 导入chdomain.ldif文件

```sh
[root@localhost ldap]# ldapadd -Y EXTERNAL -H ldapi:/// -f chdomain.ldif
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "olcDatabase={1}monitor,cn=config"

modifying entry "olcDatabase={2}hdb,cn=config"

modifying entry "olcDatabase={2}hdb,cn=config"

modifying entry "olcDatabase={2}hdb,cn=config"

modifying entry "olcDatabase={2}hdb,cn=config"


```



> 生成根项目

```sh
[root@localhost ldap]# vi basedomain.ldif
# replace to your own domain name for "dc=***,dc=***" section
dn: dc=loding,dc=com
objectClass: top
objectClass: dcObject
objectclass: organization
o: Server World
dc: loding

dn: cn=Admin,dc=loding,dc=com
objectClass: organizationalRole
cn: admin
description: Directory Manager

dn: ou=People,dc=loding,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Group,dc=loding,dc=com
objectClass: organizationalUnit
ou: Group
```



> 导入根项目数据

```sh
[root@localhost ldap]# ldapadd -x -D cn=admin,dc=loding,dc=com -W -f rootdn.ldif
#输入管理员密码即可,这里我们没有再单独生成管理员的密码,还是第一步生成的密码
Enter LDAP Password: 
adding new entry "dc=loding,dc=com"

adding new entry "cn=Manager,dc=loding,dc=com"

adding new entry "ou=People,dc=loding,dc=com"

adding new entry "ou=Group,dc=loding,dc=com"
```



### 配置日志

```
mkdir -p /var/log/slapd

chown ldap:ldap /var/log/slapd/

touch /var/log/slapd/slapd.log

chown ldap . /var/log/slapd/slapd.log

echo "local4.* /var/log/slapd/slapd.log" >> /etc/rsyslog.conf
```





## 使用ldapadmin进行测试

ldapadmin：http://www.ldapadmin.org/download/ldapadmin.html

配置按照自己的配置进行修改即可

![image-20200924211913731](../image/image-20200924211913731.png) 





## ldap安装web管理服务

### 安装Apache服务

```sh
[root@localhost ~]# yum install httpd -y
```

### 配置httpd服务

```sh
[root@localhost ~]# vi /etc/httpd/conf/httpd.conf
AllowOverride all
```

### 启动httpd服务

```sh
[root@localhost ~]# systemctl start httpd
[root@localhost ~]# systemctl enable httpd
Created symlink from /etc/systemd/system/multi-user.target.wants/httpd.service to /usr/lib/systemd/system/httpd.service.

```

### 安装配置phpldapadmin

```sh
[root@localhost ~]# yum install phpldapadmin -y
[root@localhost ~]# vi /etc/phpldapadmin/config.php
#取消下面配置的注释
$servers->setValue('server','host','127.0.0.1');  #298行
$servers->setValue('login','attr','dn'); #397行
#注释下面的配置
//$servers->setValue('login','attr','uid'); #398行
```



### 配置http相关访问权限

```sh
[root@localhost ~]# vi /etc/httpd/conf.d/phpldapadmin.conf
#生产环境请根据自己的需求进行修改
2.4版本配置为
Require all granted
2.2版本配置为
Order allow,deny 
Allow from all
```

> 重启httpd服务

```sh
[root@localhost ~]# systemctl restart httpd
```



### 通过页面访问测试

http://10.4.7.110/phpldapadmin

![image-20200924213107941](../image/image-20200924213107941.png)

点击登录即可进行认证登录，注意用户是全路径

![image-20200924213218023](../image/image-20200924213218023.png)



登录后即可看到我们的域

![image-20200924213243128](../image/image-20200924213243128.png) 