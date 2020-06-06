# 实时文件同步

sersync依赖于rsync需要先安装rsync

环境说明

10.10.10.91   作为客户端

10.10.10.92   作为服务端



## 安装rsync

```
yum install rsync -y
```



## 配置rysnc

> /etc/rsyncd.conf

```
uid = root
gid = root
use chroot = no
secrets file = /etc/rsync.pass
max connections = 100
strict modes = yes  #检查口令文件的权限
pid file = /var/run/rsyncd.pid
lock file = /var/run/rsync.lock
log file = /var/log/rsyncd.log
hosts allow= 10.10.10.0/24

[nginxrsync]
path = /etc/nginx
uid = root
gid = root
comment = nginxrsync
read only = false
ayth users = nginxrsync
hosts allow = 10.10.10.91
```



> /etc/rsync.pass

```
nginxrsync:tongbu@123
```

注意这里创建文件后要修改文件的权限为600



## 安装配置sersync

[sersync]: files/sersync2.5.4_64bit_binary_stable_final.tar.gz



#### 解压文件

```
cd /opt
tar xf sersync2.5.4_64bit_binary_stable_final.tar.gz -C sersync
```

#### 修改配置文件

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<head version="2.5">
    <host hostip="localhost" port="8008"></host>
    <debug start="false"/>
    <fileSystem xfs="false"/>
    <filter start="false">
	<exclude expression="(.*)\.svn"></exclude>
	<exclude expression="(.*)\.gz"></exclude>
	<exclude expression="^info/*"></exclude>
	<exclude expression="^static/*"></exclude>
    </filter>
    <inotify>
	<delete start="true"/>
	<createFolder start="true"/>
	<createFile start="false"/>
	<closeWrite start="true"/>
	<moveFrom start="true"/>
	<moveTo start="true"/>
	<attrib start="false"/>
	<modify start="false"/>
    </inotify>

    <sersync>
	<localpath watch="/etc/nginx">
	    <remote ip="10.10.10.91" name="nginxrsync"/>
	    <!--<remote ip="192.168.8.39" name="tongbu"/>-->
	    <!--<remote ip="192.168.8.40" name="tongbu"/>-->
	</localpath>
	<rsync>
	    <commonParams params="-artuz"/>
	    <auth start="false" users="nginxrsync" passwordfile="/etc/rsync.passwd"/>
	    <userDefinedPort start="false" port="874"/><!-- port=874 -->
	    <timeout start="false" time="100"/><!-- timeout=100 -->
	    <ssh start="false"/>
	</rsync>
	<failLog path="/tmp/rsync_fail_log.sh" timeToExecute="60"/><!--default every 60mins execute once-->
	<crontab start="false" schedule="600"><!--600mins-->
	    <crontabfilter start="false">
		<exclude expression="*.php"></exclude>
		<exclude expression="info/*"></exclude>
	    </crontabfilter>
	</crontab>
	<plugin start="false" name="command"/>
    </sersync>

    <plugin name="command">
	<param prefix="/bin/sh" suffix="" ignoreError="true"/>	<!--prefix /opt/tongbu/mmm.sh suffix-->
	<filter start="false">
	    <include expression="(.*)\.php"/>
	    <include expression="(.*)\.sh"/>
	</filter>
    </plugin>

    <plugin name="socket">
	<localpath watch="/opt/tongbu">
	    <deshost ip="192.168.138.20" port="8009"/>
	</localpath>
    </plugin>
    <plugin name="refreshCDN">
	<localpath watch="/data0/htdocs/cms.xoyo.com/site/">
	    <cdninfo domainname="ccms.chinacache.com" port="80" username="xxxx" passwd="xxxx"/>
	    <sendurl base="http://pic.xoyo.com/cms"/>
	    <regexurl regex="false" match="cms.xoyo.com/site([/a-zA-Z0-9]*).xoyo.com/images"/>
	</localpath>
    </plugin>
</head>

```



#### 启动

```
/opt/sersync/sersync2 -n 10 -d -o /opt/sersync/confxml.xml
```

