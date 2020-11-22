# Linux系统网络设置



## Centos

适用于centos7版本

配置文件：/etc/sysconfig/network-scripts/ifcfg-网卡名称

例子：

```shell
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static        #IP模式，static/dhcp
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
NAME=ens33
UUID=421f912f-c5c3-4107-9107-dcd3b3b97bcb
DEVICE=ens33
ONBOOT=yes               #开机启动 yes/no
IPADDR=10.10.10.10       #IP地址
NETMASK=255.255.255.0    #子网掩码
GATEWAY=10.10.10.2       #网关地址
DNS1=223.5.5.5           #dns1
DNS2=114.114.114.114     #dns2
```





## ubuntu

ubuntu16.04

配置文件：/etc/network/interfaces

例子：

```shell
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet static
address 10.10.10.11
netmask 255.255.255.0                                     
gateway 10.10.10.2
dns-nameserver 114.114.114.114
```

