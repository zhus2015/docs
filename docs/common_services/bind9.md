### 安装bind9软件

```
 # yum install bind -y
```



### 配置bind9

先备份配置文件，防止出错，建议修改配置前先进行备份。

```shell
先备份配置文件，防止出错，建议修改配置先进行备份。
# cp /etc/named.conf /etc/named.conf.bak
# vim /etc/named.conf
listen-on port 53 { 10.10.10.20; };
allow-query     { any; };
forwarders      { 10.10.10.2; };  #指向宿主机的地址，我的nat网络网关是10.1，宿主机地址是10.2
recursion yes;

检查配置
# named-checkconf
无任何输出即为没有错误，如果有输出请按照相关提示进行修改
```

 

### 配置区域文件

```shell
# vim /etc/named.rfc1912.zones
在配置文件末尾添加以下内容
zone "host.com" IN {
	type master;
	file "host.com.zone";
	allow-update { 10.10.10.20; };
};

zone "zs.com" IN {
	type master;
	file "zs.com.zone";
	allow-update { 10.10.10.20; };
};
```



### 配置数据文件

#### 配置主机域

```shell
# vim /var/named/host.com.zone

$ORIGIN host.com.
$TTL 600  ;  10 minutes
@         IN SOA  dns.host.com. dnsadmin.host.com. (
                  2020050401 ; serial
                  10800      ; refresh (3 hours)
                  900        ; retry (15 minutes)
                  604800     ; expire (1 week)
                  86400      ; minimum (1 day)
                  )
              NS   dns.host.com.
$TTL 60 ; 1 minute
dns                  A    10.10.10.20
HOME-10-20           A    10.10.10.20
HOME-10-21           A    10.10.10.21
HOME-10-30           A    10.10.10.30
HOME-10-31           A    10.10.10.31
HOME-10-200          A    10.10.10.200
```



#### 配置业务域

```shell
# vim /var/named/zs.com.zone

$ORIGIN zs.com.
$TTL 600  ;  10 minutes
@         IN SOA  dns.host.com. dnsadmin.host.com. (
                  2020050401 ; serial
                  10800      ; refresh (3 hours)
                  900        ; retry (15 minutes)
                  604800     ; expire (1 week)
                  86400      ; minimum (1 day)
                  )
              NS   dns.zs.com.
$TTL 60 ; 1 minute
dns                  A    10.10.10.20
```



### 启动bind9

```shell
检查配置文件
# named-checkconf

启动bind9
# systemctl start named

查看端口监听
# netstat -luntp |grep 53

tcp        0      0 127.0.0.1:953           0.0.0.0:*               LISTEN      12375/named         
tcp        0      0 10.10.10.20:53          0.0.0.0:*               LISTEN      12375/named         
tcp6       0      0 ::1:953                 :::*                    LISTEN      12375/named         
tcp6       0      0 ::1:53                  :::*                    LISTEN      12375/named         
udp        0      0 10.10.10.20:53          0.0.0.0:*                           12375/named         
udp6       0      0 ::1:53                  :::*                                12375/named  

设置开机启动
# systemctl enable named
```



### 检查解析设置

```shell
检查解析是否成功
# dig -t A home-10-200.host.com @10.10.10.20 +short
10.10.10.200
```

