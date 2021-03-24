# Mysql安装使用

Centos7 Yum源配置

> 5.6

```shell
vim /etc/yum.repos.d/mysql.repo
[mysql56-community]
name=MySQL 5.6 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.6-community/el/7/$basearch/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql
```

> 5.7

```shell
rpm -ivh https://repo.mysql.com//mysql57-community-release-el7-11.noarch.rpm
```

# 忘记Root密码

​    1、修改mysql配置文件

​           在my.cnf的mysqld中增加：skip-grant-tables 命令跳过认证

​      2、重启mysqld服务

3、a.登录mysql

​      b.use mysql

​      c.修改密码

 mysql 5.6之前版本：

 	update user set password=password ('password') where user='root';

​        ('password'):中的password是要修改的密码

  	mysql 5.7 : 

5.7版本user.user表中将password字段换成了authentication_string字段

update user set authentication_string=password('pasaword') where user='root';

​    看到下图说明执行成功

![img](https://gitee.com/zhus2015/images/raw/master/docimg/20210310154804.png) 

4、修改配置文件my.cnf 删除skip-grant-tables行

5、重启mysqld服务，使用新的密码即可登录mysql

注意5.7版本在使用重置后的密码登录后进行操作可能提示：

ERROR 1820 (HY000): You must reset your **password** using **ALTER** USER statement；

会提示密码过期，使用**SET** **PASSWORD** = **PASSWORD**('yourpass');重新设置密码即可