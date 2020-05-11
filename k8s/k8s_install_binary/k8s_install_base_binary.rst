k8s二进制安装文档-基础部件
============================
   
架构介绍
--------

环境准备
--------

在所有主机进行操作

虚拟机准备
~~~~~~~~~~

本次搭建使用5台虚拟机

配置 2c2g 40G硬盘

操作系统：Centos 7.7

主机IP及主机名如下:

+------------------------+---------------------------+----------------+
| 主机名                 | 角色                      | ip             |
+========================+===========================+================+
| home-10-20.host.com    | k8s代理节点1              | 10.10.10.20    |
+------------------------+---------------------------+----------------+
| home-10-21.host.com    | k8s代理节点2              | 10.10.10.21    |
+------------------------+---------------------------+----------------+
| home-10-30.host.com    | k8s运算节点1              | 10.10.10.30    |
+------------------------+---------------------------+----------------+
| home-10-31.host.com    | k8s运算节点2              | 10.10.10.31    |
+------------------------+---------------------------+----------------+
| home-10-200.host.com   | k8s运维节点(docker仓库)   | 10.10.10.200   |
+------------------------+---------------------------+----------------+

系统环境准备
~~~~~~~~~~~~

设置主机名
^^^^^^^^^^

按照环境介绍中的主机名对应设置

::

    # hostnamectl set-hostname home-10-20.host.com

关闭防火墙和Selinux
^^^^^^^^^^^^^^^^^^^

::

    # systemctl stop firewalld
    # systemctl disable firewalld
    # setenforce 0
    # sed -i 's/enforcing/disabled/' /etc/selinux/config

设置yum源
^^^^^^^^^

我这里使用的是阿里云的源，也可以使用其他源

::

    # curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

安装扩展包及常规软件包
^^^^^^^^^^^^^^^^^^^^^^

::

    安装epel扩展源
    # yum install epel-release -y
    安装常用软件包
    # yum install vim telnet wget net-tools nmap sysstat lrzsz dos2unix bind-utils ntpdate -y

同步时间
^^^^^^^^

::

    # ntpdate ntp.api.bz

系统优化
^^^^^^^^

::

    略过

部署DNS服务
~~~~~~~~~~~

**在10.10.10.20上进行部署**

安装bind软件
^^^^^^^^^^^^

::

    # yum install bind -y

配置bind9
^^^^^^^^^

::

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

配置区域文件
^^^^^^^^^^^^

::


    # vim /etc/named.rfc1912.zones
    在配置文件末尾添加以下内容
    zone "host.com" IN {
        type master;
        file "host.com.zone";
        allow-update { 10.10.10.20; };
    };

    zone "od.com" IN {
        type master;
        file "od.com.zone";
        allow-update { 10.10.10.20; };
    };

配置数据文件
^^^^^^^^^^^^

配置主机域数据文件
''''''''''''''''''

::

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
    HOME-10-200           A    10.10.10.200

配置业务域数据文件
''''''''''''''''''

::

    # vim /var/named/od.com.zone

    $ORIGIN od.com.
    $TTL 600  ;  10 minutes
    @         IN SOA  dns.host.com. dnsadmin.host.com. (
                      2020050401 ; serial
                      10800      ; refresh (3 hours)
                      900        ; retry (15 minutes)
                      604800     ; expire (1 week)
                      86400      ; minimum (1 day)
                      )
                  NS   dns.od.com.
    $TTL 60 ; 1 minute
    dns                  A    10.10.10.20

启动bind9
^^^^^^^^^

::

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

    检查解析是否成功

    # dig -t A home-10-200.host.com @10.10.10.20 +short
    10.10.10.200

配置DNS客户端
~~~~~~~~~~~~~

所有机器上进行操作，将所有机器的DNS地址指向刚才搭建的dns服务器

Linux客户端
^^^^^^^^^^^

::

    # vim /etc/sysconfig/network-scripts/ifcfg-ens33
    DNS1=10.10.10.20

    重启网卡服务
    # systemctl restart network

    测试网络连通性
    # ping -c 4 www.baidu.com
    # ping -c 4 home-10-200.host.com

Windows客户端
^^^^^^^^^^^^^

修改nat虚拟网卡的dns服务器为10.10.10.20

有可能设置自动跃点数为10或者20

证书签发环境部署
~~~~~~~~~~~~~~~~

**此环境部署在10.10.10.200上**

安装CFSSL
^^^^^^^^^

::

    # wget http://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -O /usr/bin/cfssl
    # wget http://pkg.cfssl.org/R1.2/cfssl-json_linux-amd64 -O /usr/bin/cfssl-json
    # wget http://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -O /usr/bin/cfssl-certinfo
    增加可执行权限
    # chmod +x /usr/bin/cfssl*

创建生成CA证书签名请求CSR
^^^^^^^^^^^^^^^^^^^^^^^^^

::

    # mkdir -p /opt/certs
    # vim /opt/certs/ca-csr.json
    {
        "CN": "OldboyEdu",
        "hosts": [
        ],
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
                "C": "CN",
                "ST": "jinan",
                "L": "jinan",
                "O": "od",
                "OU": "ops"
            }
        ],
        "ca": {
            "expiry": "175200h"
        }
    }

CN：CommonName，浏览器使用该字段验证网站是否合法，一般写的是域名。非常重要。

C：Country，国家

ST：State，洲、省

L：Locality，地区、城市

O：Organization Name，组织名称、公司名称

OU：Organization Unit Name，组织单位名称，公司部门

生成CA证书和私钥
^^^^^^^^^^^^^^^^

::

    # cd /opt/certs
    # cfssl gencert -initca ca-csr.json | cfssl-json -bare ca
    2020/05/04 23:11:53 [INFO] generating a new CA key and certificate from CSR
    2020/05/04 23:11:53 [INFO] generate received request
    2020/05/04 23:11:53 [INFO] received CSR
    2020/05/04 23:11:53 [INFO] generating key: rsa-2048
    2020/05/04 23:11:53 [INFO] encoded CSR
    2020/05/04 23:11:53 [INFO] signed certificate with serial number 323069993578295958992066261479729646946196294438

安装docker环境
~~~~~~~~~~~~~~

在10.10.10.200，10.10.10.30，10.10.10.31上部署

安装
^^^^

方法一、

::

    # curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

方法二、

::

    # 安装 Docker
    # wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo  
    # yum -y install docker-ce

配置
^^^^

::

    # mkdir -p /etc/docker
    # mkdir -p /data/docker
    # vim /etc/docker/daemon.json
    ##注意变更bip的值，第三段为机器IP最后一位
    {
      "graph": "/data/docker",
      "storage-driver": "overlay2",
      "insecure-registries": ["registry.access.redhat.com","quay.io","harbor.od.com"],
      "registry-mirrors": ["https://vprbki78.mirror.aliyuncs.com"],
      "bip": "172.10.30.1/24",
      "exec-opts": ["native.cgroupdriver=systemd"],
      "live-restore": true
    }

启动
^^^^

::

    # systemctl start docker
    # systemctl enable docker

部署docker私有仓库habor
~~~~~~~~~~~~~~~~~~~~~~~

在10.10.10.200上部署

安装docker-compose
^^^^^^^^^^^^^^^^^^

harbor是通过docker-compose单机编排

::

    # yum install -y docker-composer

下载安装包
^^^^^^^^^^

下载地址：https://github.com/goharbor/harbor/releases

下载版本为v1.10.2

因使用虚拟机下载较慢，所以是用宿主机下载后上传到指定目录

解压移动文件
^^^^^^^^^^^^

::

    这里上传到/opt/src目录下进行解压
    # cd /opt/src
    # tar zxvf harbor-offline-installer-v1.10.2.tgz
    # mv harbor /opt/harbor-v1.10.2
    # ln -s /opt/harbor-v1.10.2 /opt/harbor

配置harbor.yml
^^^^^^^^^^^^^^

::

    # cd /opt/harbor
    # vim harbor.yml
    hostname: harbor.od.com
    port: 180  #需要安装nginx因此将默认监听端口进行修改
    #https:  # 将https相关配置进行注释，这是我们使用http
    #  # https port for harbor, default is 443
    #  port: 443
    #  # The path of cert and key files for nginx
    #  certificate: /your/certificate/path
    #  private_key: /your/private/key/path
    harbor_admin_password: Harbor12345  #密码测试环境可以不修改
    data_volume: /data/harbor    #数据目录
    location: /data/harbor/logs  #日志目录

    # mkdir -p /data/harbor/logs

执行安装脚本
^^^^^^^^^^^^

::

    # /opt/harbor/install.sh
    等待安装结束即可，看到以下信息即安装成功
    ✔ ----Harbor has been installed and started successfully.----

安装配置nginx
^^^^^^^^^^^^^

安装
''''

::

    # yum install -y nginx

配置
''''

::

    # vim /etc/nginx/conf.d/harbor.od.com.conf

    server {
        listen 80;
        server_name harbor.od.com;

        client_max_body_size 1000m;

        location / {
            proxy_pass http://127.0.0.1:180;
        }
    }

启动
''''

::

    # systemctl start nginx
    # systemctl enable nginx

配置域名解析
^^^^^^^^^^^^

在我们的DNS服务器10.10.10.20上进行配置，生产到时候使用云服务商的DNS服务即可

::

    # vim /var/named/od.name.zone
    将序列号增加，同时在末尾增加一条A记录
    2020050402 ; serial
    harbor               A    10.10.10.200

    重启DNS服务
    # systemctl restart named

验证
^^^^

::

    任意机器都行
    # curl harbor.od.com

或者使用宿主机通过浏览器进行访问harbor.od.com

在harbor中创建项目
^^^^^^^^^^^^^^^^^^

新建一个公开项目

下载镜像并推送到harbor中
^^^^^^^^^^^^^^^^^^^^^^^^

::

    通过公网下载一个镜像
    # docker pull nginx:1.7.9

    为镜像打上tag
    # docker tag 84581e99d807 harbor.od.com/public/nginx:v1.7.9

    登录harbor，如果这里不登陆会提示没有权限推送
    # docker login harbor.od.com
    Username: admin
    Password:
    WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
    Configure a credential helper to remove this warning. See
    https://docs.docker.com/engine/reference/commandline/login/#credentials-store

    Login Succeeded

    推送镜像到harbor
    # docker push harbor.od.com/public/nginx:v1.7.9
    The push refers to repository [harbor.od.com/public/nginx]
    5f70bf18a086: Pushed 
    4b26ab29a475: Pushed 
    ccb1d68e3fb7: Pushed 
    e387107e2065: Pushed 
    63bf84221cce: Pushed 
    e02dce553481: Pushed 
    dea2e4984e29: Pushed 
    v1.7.9: digest: sha256:b1f5935eb2e9e2ae89c0b3e2e148c19068d91ca502e857052f14db230443e4c2 size: 3012

    看到以上信息或者在harbor.od.com的public项目中看到有相关镜像即为成功

部署master节点服务
------------------

部署etcd集群
~~~~~~~~~~~~

集群规划
^^^^^^^^

+-----------------------+---------------+---------------+
| 主机名                | 角色          | ip            |
+=======================+===============+===============+
| home-10-21.host.com   | etcd lead     | 10.10.10.21   |
+-----------------------+---------------+---------------+
| home-10-30.host.com   | etcd follow   | 10.10.10.30   |
+-----------------------+---------------+---------------+
| home-10-31.host.com   | etcd follow   | 10.10.10.31   |
+-----------------------+---------------+---------------+

签发证书
^^^^^^^^

在10.10.10.200上操作

创建证书配置文件
^^^^^^^^^^^^^^^^

::

    # cd /opt/cert
    # vim ca-config.json
    {
        "signing": {
            "default": {
                "expiry": "175200h"
            },
            "profiles": {
                "server": {
                    "expiry": "175200h",
                    "usages": [
                        "signing",
                        "key encipherment",
                        "server auth"
                    ]
                },
                "client": {
                    "expiry": "175200h",
                    "usages": [
                        "signing",
                        "key encipherment",
                        "client auth"
                    ]
                },
                "peer": {
                    "expiry": "175200h",
                    "usages": [
                        "signing",
                        "key encipherment",
                        "server auth",
                        "client auth"
                    ]
                }
            }
        }
    }

创建自签证书签名请求配置文件
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

::

    # vim etcd-peer-csr.json
    {
        "CN": "k8s-etcd",
        "hosts": [
            "10.10.10.20",
            "10.10.10.21",
            "10.10.10.30",
            "10.10.10.31"
        ],
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
                "C": "CN",
                "ST": "beijing",
                "L": "beijing",
                "O": "od",
                "OU": "ops"
            }
        ]
    }

创建证书和私钥
^^^^^^^^^^^^^^

::

    # cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer etcd-peer-csr.json | cfssl-json -bare etcd-peer
    2020/05/04 19:10:21 [INFO] generate received request
    2020/05/04 19:10:21 [INFO] received CSR
    2020/05/04 19:10:21 [INFO] generating key: rsa-2048
    2020/05/04 19:10:22 [INFO] encoded CSR
    2020/05/04 19:10:22 [INFO] signed certificate with serial number 702497363108855472557923927932108042074638540577
    2020/05/04 19:10:22 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
    websites. For more information see the Baseline Requirements for the Issuance and Management
    of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
    specifically, section 10.2.3 ("Information Requirements").

下载解压etcd
^^^^^^^^^^^^

使用GitHub下载慢或者无法下载的可以选择使用国内的地址进行下载

github地址：https://github.com/etcd-io/etcd/releases

华为云地址：https://mirrors.huaweicloud.com/etcd/

下载版本：3.1.20

版本连接：https://mirrors.huaweicloud.com/etcd/v3.1.20/etcd-v3.1.20-linux-amd64.tar.gz

::

    # mkdir -p /opt/src
    # cd /opt/src
    # wget https://mirrors.huaweicloud.com/etcd/v3.1.20/etcd-v3.1.20-linux-amd64.tar.gz
    # tar zxvf etcd-v3.1.20-linux-amd64.tar.gz
    # mv etcd-v3.1.20-linux-amd64 /opt/etcd-v3.1.20
    # ln -s /opt/etcd-v3.1.20 /opt/etcd

创建用户及相关目录
^^^^^^^^^^^^^^^^^^

::

    # useradd -s /sbin/nologin -M etcd
    # mkdir -p /opt/etcd/certs /data/etcd /data/logs/etcd-server

拷贝相关证书
^^^^^^^^^^^^

::

    # cd /opt/etcd/certs
    # scp 10.10.10.200:/opt/certs/ca.pem .
    # scp 10.10.10.200:/opt/certs/etcd-peer.pem .
    # scp 10.10.10.200:/opt/certs/etcd-peer-key.pem .

创建启动脚本
^^^^^^^^^^^^

注意不同机器修改相关配置项

::

    # cd /opt/etcd
    # vim etcd-server-startup.sh
    #!/bin/bash
    ./etcd --name etcd-server-10-21 \
           --data-dir /data/etcd/etcd-server \
           --listen-peer-urls https://10.10.10.21:2380 \
           --listen-client-urls https://10.10.10.21:2379,http://127.0.0.1:2379 \
           --quota-backend-bytes 800000000 \
           --initial-advertise-peer-urls https://10.10.10.21:2380 \
           --advertise-client-urls https://10.10.10.21:2379,http://127.0.0.1:2379 \
           --initial-cluster etcd-server-10-21=https://10.10.10.21:2380,etcd-server-10-30=https://10.10.10.30:2380,etcd-server-10-31=https://10.10.10.31:2380 \
           --ca-file ./certs/ca.pem \
           --cert-file ./certs/etcd-peer.pem \
           --key-file ./certs/etcd-peer-key.pem \
           --client-cert-auth \
           --trusted-ca-file ./certs/ca.pem \
           --peer-ca-file ./certs/ca.pem \
           --peer-cert-file ./certs/etcd-peer.pem \
           --peer-key-file ./certs/etcd-peer-key.pem \
           --peer-client-cert-auth \
           --peer-trusted-ca-file ./certs/ca.pem \
           --log-output stdout

修改相关文件权限及目录所属
^^^^^^^^^^^^^^^^^^^^^^^^^^

::

    # chmod +x /opt/etcd/etcd-server-startup.sh
    # chown -R etcd.etcd /opt/etcd-v3.1.20
    # chown -R etcd.etcd /data/etcd
    # chown -R etcd.etcd /data/logs/etcd-server

安装配置supervisor
^^^^^^^^^^^^^^^^^^

supervisor是一种进程管理工具，可以使程序在后台运行并且自动守护进程

安装supervisor
''''''''''''''

::

    # yum install -y supervisor
    # systemctl start supervisord
    # systemctl enable supervisord

配置etcd配置
''''''''''''

::

    # vim /etc/supervisord.d/etcd-server.ini
    [program:etcd-server]
    command=/opt/etcd/etcd-server-startup.sh
    numprocs=1
    directory=/opt/etcd
    autostart=true
    autorestart=true
    startsecs=30
    startretries=3
    exetcodes=0,2
    stopsignal=QUIT
    stopwaitsecs=10
    user=etcd
    rediect_stderr=true
    stdout_logfile=/data/logs/etcd-server/etcd.stdout.log
    stdout_logfile_maxbytes=64MB
    stdout_logfile_backups=4
    stdout_captyre_maxbytes=1MB
    stdout_events_enabled=false

启动etcd程序
''''''''''''

::

    # supervisorctl update

检查启动情况
^^^^^^^^^^^^

::

    # netstat -luntp |grep etcd
    tcp        0      0 10.10.10.21:2379        0.0.0.0:*               LISTEN      12945/./etcd        
    tcp        0      0 127.0.0.1:2379          0.0.0.0:*               LISTEN      12945/./etcd        
    tcp        0      0 10.10.10.21:2380        0.0.0.0:*               LISTEN      12945/./etcd

    # /opt/etcd/etcdctl cluster-health
    member a01381d0afc19e9 is healthy: got healthy result from http://127.0.0.1:2379
    member 3b366b27a21256dd is healthy: got healthy result from http://127.0.0.1:2379
    member f3a29751bf654569 is healthy: got healthy result from http://127.0.0.1:2379
    cluster is healthy
    显示如上信息即为正常情况

部署kube-apiserver集群
~~~~~~~~~~~~~~~~~~~~~~

集群规划
^^^^^^^^

+--------------+------------------+---------------+
| 主机名       | 角色             | IP            |
+==============+==================+===============+
| HOME-10-30   | kube-apiserver   | 10.10.10.30   |
+--------------+------------------+---------------+
| HOME-10-31   | kube-apiserver   | 10.10.10.31   |
+--------------+------------------+---------------+
| HOME-10-20   | 4层负载均衡      | 10.10.10.20   |
+--------------+------------------+---------------+
| HOME-10-21   | 4层负载均衡      | 10.10.10.21   |
+--------------+------------------+---------------+

10.10.10.20和10.10.10.21使用nginx做4层的负载均衡，用keepalived跑一个vip：10.10.10.25代理两个kube-apiserver，实现考可用

安装软件
^^^^^^^^

此操作在10.10.10.30和10.10.10.31上，这里已10.10.10.30为例

软件下载
''''''''

这里由于下载较慢，我这里选择使用宿主机进行下载，然后进行上传到虚拟机的/opt/src目录下，或者直接使用wget的方式下载

::

    # cd /opt/src/
    # wget https://storage.googleapis.com/kubernetes-release/release/v1.15.10/kubernetes-server-linux-amd64.tar.gz

下载地址(全版本)：https://github.com/kubernetes/kubernetes/releases

下载版本：v1.5.10

版本下载链接：https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.15.md#downloads-for-v11510

软件包链接：https://storage.googleapis.com/kubernetes-release/release/v1.15.10/kubernetes-server-linux-amd64.tar.gz

可以下载其他版本，下载方式在release版本中点击连接CHANGELOG-1.15.md.，在新页面中找到Server
Binaries项，下载相关平台版本包即可

解压包、做软连接
''''''''''''''''

::

    # cd /opt/src
    # tar zxvf kubernetes-server-linux-amd64.tar.gz
    # mv kubernetes /opt/kubernetes-v1.5.10
    # ln -s /opt/kubernetes-v1.5.10 /opt/kubernetes
    删除用不到的源码包、docker镜像及tag文件，可以不删除
    # rm -rf /opt/kubernetes/kubernetes-src.tar.gz
    # rm -rf /opt/kubernetes/server/bin/*.tar
    # rm -rf /opt/kubernetes/server/bin/*_tag

签发client证书
^^^^^^^^^^^^^^

此证书是apiserver与etcd集群通信使用的证书

此步骤在10.10.10.200上进行操作

创建生成证书签名请求
''''''''''''''''''''

::

    # vim /opt/certs/client-csr.json
    {
        "CN": "k8s-node",
        "hosts": [
        ],
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
                "C": "CN",
                "ST": "jinan",
                "L": "jinan",
                "O": "od",
                "OU": "ops"
            }
        ]
    }

生成client证书和私钥
''''''''''''''''''''

::

    # cd /opt/certs
    # cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client-csr.json | cfssl-json -bare client
    2020/05/05 08:16:17 [INFO] generate received request
    2020/05/05 08:16:17 [INFO] received CSR
    2020/05/05 08:16:17 [INFO] generating key: rsa-2048
    2020/05/05 08:16:18 [INFO] encoded CSR
    2020/05/05 08:16:18 [INFO] signed certificate with serial number 101952592807466276860144810634052081539740463310
    2020/05/05 08:16:18 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
    websites. For more information see the Baseline Requirements for the Issuance and Management
    of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
    specifically, section 10.2.3 ("Information Requirements").

检查生成的证书和私钥
''''''''''''''''''''

::

    # ls -al /opt/certs | grep client
    -rw-r--r--. 1 root root  989 May  5 08:16 client.csr
    -rw-r--r--. 1 root root  276 May  5 08:12 client-csr.json
    -rw-------. 1 root root 1679 May  5 08:16 client-key.pem
    -rw-r--r--. 1 root root 1354 May  5 08:16 client.pem

签发kube-apiserver证书
^^^^^^^^^^^^^^^^^^^^^^

此步骤在10.10.10.200上进行操作

创建生成证书签名请求
''''''''''''''''''''

我这里多写了很多的hosts为了方便后续扩展使用，注意10.10.10.25这个VIP，这是反向代理的vip

::

    # vim /opt/certs/apiserver-csr.json
    {
        "CN": "k8s-apiserver",
        "hosts": [
            "127.0.0.1",
            "192.168.0.1",
            "kubernetes.default",
            "kubernetes.default.svc",
            "kubernetes.default.svc.cluster",
            "kubernetes.default.svc.cluster.local",
            "10.10.10.25",
            "10.10.10.21",
            "10.10.10.30",
            "10.10.10.31",
            "10.10.10.32",
            "10.10.10.40",
            "10.10.10.41",
            "10.10.10.42",
            "10.10.10.43"
        ],
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
                "C": "CN",
                "ST": "jinan",
                "L": "jinan",
                "O": "od",
                "OU": "ops"
            }
        ]
    }

生成apiserver证书
'''''''''''''''''

::

    # cd /opt/certs
    # cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server apiserver-csr.json | cfssl-json -bare server
    2020/05/05 08:18:29 [INFO] generate received request
    2020/05/05 08:18:29 [INFO] received CSR
    2020/05/05 08:18:29 [INFO] generating key: rsa-2048
    2020/05/05 08:18:30 [INFO] encoded CSR
    2020/05/05 08:18:30 [INFO] signed certificate with serial number 29607801833592764615600392359035638695037506966
    2020/05/05 08:18:30 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
    websites. For more information see the Baseline Requirements for the Issuance and Management
    of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
    specifically, section 10.2.3 ("Information Requirements").

检查生成的证书和私钥
''''''''''''''''''''

::

    # ls -al /opt/certs | grep apiserver
    -rw-r--r--. 1 root root 1285 May  5 08:28 apiserver.csr
    -rw-r--r--. 1 root root  672 May  5 08:28 apiserver-csr.json
    -rw-------. 1 root root 1675 May  5 08:28 apiserver-key.pem
    -rw-r--r--. 1 root root 1627 May  5 08:28 apiserver.pem

拷贝证书
^^^^^^^^

::

    # cd /opt/kubernetes/server/bin
    # mkdir certs
    # cd certs
    # scp root@10.10.10.200:/opt/certs/apiserver-key.pem .
    # scp root@10.10.10.200:/opt/certs/apiserver.pem .
    # scp root@10.10.10.200:/opt/certs/ca-key.pem .
    # scp root@10.10.10.200:/opt/certs/ca.pem .
    # scp root@10.10.10.200:/opt/certs/client-key.pem .
    # scp root@10.10.10.200:/opt/certs/client.pem .

    如果感觉上面的scp较麻烦，可以将所有的pem证书都拷贝过来,然后删除不用的证书
    # scp root@10.10.10.200:/opt/certs/*.pem .
    # rm -rf etcd*.pem

创建启动配置文件
^^^^^^^^^^^^^^^^

创建audit.yaml审计文件
''''''''''''''''''''''

::

    # cd /opt/kubernetes/server/bin
    # mkdir conf
    # cd conf
    日志审计规则
    # vim audit.yaml
    apiVersion: audit.k8s.io/v1 # This is required.
    kind: Policy
    # Don't generate audit events for all requests in RequestReceived stage.
    omitStages:
      - "RequestReceived"
    rules:
      # Log pod changes at RequestResponse level
      - level: RequestResponse
        resources:
        - group: ""
          # Resource "pods" doesn't match requests to any subresource of pods,
          # which is consistent with the RBAC policy.
          resources: ["pods"]
      # Log "pods/log", "pods/status" at Metadata level
      - level: Metadata
        resources:
        - group: ""
          resources: ["pods/log", "pods/status"]

      # Don't log requests to a configmap called "controller-leader"
      - level: None
        resources:
        - group: ""
          resources: ["configmaps"]
          resourceNames: ["controller-leader"]

      # Don't log watch requests by the "system:kube-proxy" on endpoints or services
      - level: None
        users: ["system:kube-proxy"]
        verbs: ["watch"]
        resources:
        - group: "" # core API group
          resources: ["endpoints", "services"]

      # Don't log authenticated requests to certain non-resource URL paths.
      - level: None
        userGroups: ["system:authenticated"]
        nonResourceURLs:
        - "/api*" # Wildcard matching.
        - "/version"

      # Log the request body of configmap changes in kube-system.
      - level: Request
        resources:
        - group: "" # core API group
          resources: ["configmaps"]
        # This rule only applies to resources in the "kube-system" namespace.
        # The empty string "" can be used to select non-namespaced resources.
        namespaces: ["kube-system"]

      # Log configmap and secret changes in all other namespaces at the Metadata level.
      - level: Metadata
        resources:
        - group: "" # core API group
          resources: ["secrets", "configmaps"]

      # Log all other resources in core and extensions at the Request level.
      - level: Request
        resources:
        - group: "" # core API group
        - group: "extensions" # Version of group should NOT be included.

      # A catch-all rule to log all other requests at the Metadata level.
      - level: Metadata
        # Long-running requests like watches that fall under this rule will not
        # generate an audit event in RequestReceived.
        omitStages:
          - "RequestReceived"

创建启动脚本
''''''''''''

::

    # cd /opt/kubernetes/server/bin
    # vim kube-apiserver.sh
    #!/bin/bash
    ./kube-apiserver \
      --apiserver-count=2 \
      --audit-log-path=/data/logs/kubernetes/kube-apiserver/audit.log \
      --audit-policy-file ./conf/audit.yaml \
      --authorization-mode RBAC \
      --client-ca-file ./certs/ca.pem \
      --enable-admission-plugins NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota \
      --etcd-cafile ./certs/ca.pem \
      --etcd-certfile ./certs/client.pem \
      --etcd-keyfile ./certs/client-key.pem \
      --etcd-servers=https://10.10.10.21:2379,https://10.10.10.30:2379,https://10.10.10.31:2379 \
      --service-account-key-file ./certs/ca-key.pem \
      --service-cluster-ip-range 192.168.0.0/16 \
      --service-node-port-range 3000-29999 \
      --target-ram-mb=1024 \
      --kubelet-client-certificate ./certs/client.pem \
      --kubelet-client-key ./certs/client-key.pem \
      --log-dir=/data/logs/kubernetes/kube-apiserver \
      --tls-cert-file ./certs/apiserver.pem \
      --tls-private-key-file ./certs/apiserver-key.pem \
      --v 2

调整权限和目录
^^^^^^^^^^^^^^

::

    增加启动权限
    [root@home-10-30 bin]# chmod +x kube-apiserver.sh
    创建相关目录
    [root@home-10-30 bin]# mkdir -p /data/logs/kubernetes/kube-apiserver

创建supervisor管理配置
^^^^^^^^^^^^^^^^^^^^^^

::

    # vim /etc/supervisord.d/kube-apiserver.ini
    [program:kube-apiserver]
    command=/opt/kubernetes/server/bin/kube-apiserver.sh
    numprocs=1
    directory=/opt/kubernetes/server/bin
    autostart=true
    autorestart=true
    startsecs=30
    startretries=3
    exetcodes=0,2
    stopsignal=QUIT
    stopwaitsecs=10
    user=root
    rediect_stderr=true
    stdout_logfile=/data/logs/kubernetes/kube-apiserver/apiserver.stdout.log
    stdout_logfile_maxbytes=64MB
    stdout_logfile_backups=4
    stdout_captyre_maxbytes=1MB
    stdout_events_enabled=false

启动服务并检查
^^^^^^^^^^^^^^

::

    # supervisorctl update

安装部署启动检查所有集群状态

安装配置4层反向代理
^^^^^^^^^^^^^^^^^^^

此步骤在10.10.10.20和10.10.10.21上执行

安装nginx和keepalived
'''''''''''''''''''''

::

    # yum install -y nginx keepalived

nginx配置
'''''''''

::

    # vim /etc/nginx/nginx.conf
    在最后增加以下配置
    stream {
        upstream kube-apiserver {
            server 10.10.10.30:6443 max_fails=3 fail_timeout=30s;
            server 10.10.10.31:6443 max_fails=3 fail_timeout=30s;
        }

        server {
            listen 7443;
            proxy_connect_timeout 2s;
            proxy_timeout 900s;
            proxy_pass kube-apiserver;
        }
    }

keepalived配置
''''''''''''''

check\_port.sh
              

::

    # vim /etc/keepalived/check_port.sh
    #!/bin/bash
    #keepalived 监控端口脚本
    #使用方法：
    #vrrp_script check_port {#创建一个vrrp_script甲苯。检查配置
    #    script "/etc/keepalived/check_port.sh 6379" #配置监听的端口
    #    interval 2 #检查脚本的频率
    #}
    CHK_PORT=$1
    if [ -n "${CHK_PORT}" ]
    then
        PORT_PROCESS=`ss -lnt |grep ${CHK_PORT} | wc -l`
        if [ ${PORT_PROCESS} -eq 0 ]
        then
            echo "Port ${CHK_PORT} Is Not Used,End."
            exit 1
        fi
    else
         echo "Check Port Cant Be Empty!"
    fi

    # chmod +x /etc/keepalived/check_port.sh

keepalived主
            

::

    # vim /etc/keepalived/keepalived.conf
    global_defs {
       router_id 10.10.10.20
    }

    vrrp_script chk_nginx {
        script "/etc/keepalived/check_port.sh 7443"
        interval 2
        weight -20
    }
    vrrp_instance VI_1 {
        state MASTER
        interface ens33
        virtual_router_id 251
        priority 100
        advert_int 1
        mcast_src_ip 10.10.10.20
        nopreempt

        authentication {
            auth_type PASS
            auth_pass 1111
        }
        track_script {
            chk_nginx
        }
        virtual_ipaddress {
            10.10.10.25
        }
    }

keepalived备
            

::

    # vim /etc/keepalived/keepalived.conf
    global_defs {
       router_id 10.10.10.21
    }

    vrrp_script chk_nginx {
        script "/etc/keepalived/check_port.sh 7443"
        interval 2
        weight -20
    }
    vrrp_instance VI_1 {
        state BACKUP
        interface ens33
        virtual_router_id 251
        priority 90
        advert_int 1
        mcast_src_ip 10.10.10.21

        authentication {
            auth_type PASS
            auth_pass 1111
        }
        track_script {
            chk_nginx
        }
        virtual_ipaddress {
            10.10.10.25
        }
    }

启动代理并检查
''''''''''''''

::

    # systemctl start nginx
    # systemctl enable nginx
    # systemctl start keepalived
    # systemctl enbale keepalived
    # ip addr 
    可以看到我的vip起来了即为成功

    可以通过停止主节点上的nginx来测试vip是否漂移，这里有一个问题，就是systemctl stop keepalived时会出现子进程无法停止的问题，可以将 /usr/lib/systemd/system/keepalived.service 中的KillMode=process注释掉

部署controller-manager
~~~~~~~~~~~~~~~~~~~~~~

集群规划
^^^^^^^^

+--------------+----------------------+---------------+
| 主机名       | 角色                 | ip            |
+==============+======================+===============+
| HOME-10-30   | controller-manager   | 10.10.10.30   |
+--------------+----------------------+---------------+
| HOME-10-31   | controller-manager   | 10.10.10.31   |
+--------------+----------------------+---------------+

创建启动脚本
^^^^^^^^^^^^

::

    # vim /opt/kubernetes/server/bin/kube-controller-manager.sh
    #!/bin/sh
    ./kube-controller-manager \
      --cluster-cidr 10.10.0.0/16 \
      --leader-elect true \
      --log-dir /data/logs/kubernetes/kube-controller-manager \
      --master http://127.0.0.1:8080 \
      --service-account-private-key-file ./certs/ca-key.pem \
      --service-cluster-ip-range 192.168.0.0/16 \
      --root-ca-file ./certs/ca.pem \
      --v 2

调整文件权限和创建目录
^^^^^^^^^^^^^^^^^^^^^^

::

    # chmod +x /opt/kubernetes/server/bin/kube-controller-manager.sh
    # mkdir -p /data/logs/kubernetes/kube-controller-manager

为controller-manager创建supervisor配置
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

::

    # cat > /etc/supervisord.d/kube-conntroller-manager.ini << EOF
    [program:kube-controller-manager]
    command=/opt/kubernetes/server/bin/kube-controller-manager.sh                     
    numprocs=1
    directory=/opt/kubernetes/server/bin
    autostart=true
    autorestart=true
    startsecs=30
    startretries=3
    exitcodes=0,2
    stopsignal=QUIT
    stopwaitsecs=10
    user=root
    redirect_stderr=false
    stdout_logfile=/data/logs/kubernetes/kube-controller-manager/controll.stdout.log
    stdout_logfile_maxbytes=64MB
    stdout_logfile_backups=4
    stdout_capture_maxbytes=1MB
    stdout_events_enabled=false
    stderr_logfile=/data/logs/kubernetes/kube-controller-manager/controll.stderr.log
    stderr_logfile_maxbytes=64MB
    stderr_logfile_backups=4
    stderr_capture_maxbytes=1MB
    stderr_events_enabled=false
    EOF

启动服务并检查
^^^^^^^^^^^^^^

::

    # supervisorctl update 
    # supervisorctl status

部署kube-scheduler
~~~~~~~~~~~~~~~~~~

集群规划
^^^^^^^^

+--------------+----------------------+---------------+
| 主机名       | 角色                 | ip            |
+==============+======================+===============+
| HOME-10-30   |     scheduler        | 10.10.10.30   |
+--------------+----------------------+---------------+
| HOME-10-31   |     scheduler        | 10.10.10.31   |
+--------------+----------------------+---------------+

创建启动脚本
^^^^^^^^^^^^

::

    # cat > /opt/kubernetes/server/bin/kube-scheduler.sh << EOF
    #!/bin/sh
    ./kube-scheduler \
      --leader-elect  \
      --log-dir /data/logs/kubernetes/kube-scheduler \
      --master http://127.0.0.1:8080 \
      --v 2
    EOF

调整文件权限，创建目录
^^^^^^^^^^^^^^^^^^^^^^

::

    # chmod +x /opt/kubernetes/server/bin/kube-scheduler.sh
    # mkdir -p /data/logs/kubernetes/kube-scheduler

为kube-scheduler创建supervisor配置文件
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

::

    # cat > /etc/supervisord.d/kube-scheduler.ini << EOF
    [program:kube-controller-scheduler]
    command=/opt/kubernetes/server/bin/kube-scheduler.sh                     
    numprocs=1
    directory=/opt/kubernetes/server/bin
    autostart=true
    autorestart=true
    startsecs=30
    startretries=3
    exitcodes=0,2
    stopsignal=QUIT
    stopwaitsecs=10
    user=root
    redirect_stderr=false
    stdout_logfile=/data/logs/kubernetes/kube-scheduler/scheduler.stdout.log
    stdout_logfile_maxbytes=64MB
    stdout_logfile_backups=4
    stdout_capture_maxbytes=1MB
    stdout_events_enabled=false
    stderr_logfile=/data/logs/kubernetes/kube-scheduler/scheduler.stderr.log
    stderr_logfile_maxbytes=64MB
    stderr_logfile_backups=4
    stderr_capture_maxbytes=1MB
    stderr_events_enabled=false
    EOF

启动服务并检查
^^^^^^^^^^^^^^

::

    # supervisorctl update 
    # supervisorctl status

检查主控节点
~~~~~~~~~~~~

两台机器都要执行

::

    为kubectl创建链接并查看集群健康
    # ln -s /opt/kubernetes/server/bin/kubectl /usr/bin/kubectl
    # kubectl get cs
    NAME                 STATUS    MESSAGE              ERROR
    controller-manager   Healthy   ok                   
    scheduler            Healthy   ok                   
    etcd-2               Healthy   {"health": "true"}   
    etcd-0               Healthy   {"health": "true"}   
    etcd-1               Healthy   {"health": "true"}  

部署node节点
------------

部署kubelet服务
~~~~~~~~~~~~~~~

集群规划
^^^^^^^^

+--------------+-----------+---------------+
| 主机名       | 角色      | ip            |
+==============+===========+===============+
| HOME-10-30   | kubelet   | 10.10.10.30   |
+--------------+-----------+---------------+
| HOME-10-31   | kubelet   | 10.10.10.31   |
+--------------+-----------+---------------+

签发证书
^^^^^^^^

此步骤在10.10.10.200上进行

创建生成证书签名请求
''''''''''''''''''''

::

    # vim /opt/certs/kubelet-csr.json
    {
        "CN": "kubelet-node",
        "hosts": [
            "127.0.0.1",
            "10.10.10.25",
            "10.10.10.21",
            "10.10.10.30",
            "10.10.10.31",
            "10.10.10.32",
            "10.10.10.40",
            "10.10.10.41",
            "10.10.10.42",
            "10.10.10.43"
        ],
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
                "C": "CN",
                "ST": "jinan",
                "L": "jinan",
                "O": "od",
                "OU": "ops"
            }
        ]
    }

生成证书
''''''''

::

    # cd /opt/certs 
    # cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kubelet-csr.json | cfssl-json -bare kubelet
    2020/05/05 13:46:00 [INFO] generate received request
    2020/05/05 13:46:00 [INFO] received CSR
    2020/05/05 13:46:00 [INFO] generating key: rsa-2048
    2020/05/05 13:46:00 [INFO] encoded CSR
    2020/05/05 13:46:00 [INFO] signed certificate with serial number 234664240374568418840884293192201025984384515932
    2020/05/05 13:46:00 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
    websites. For more information see the Baseline Requirements for the Issuance and Management
    of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
    specifically, section 10.2.3 ("Information Requirements").

复制证书到计算节点
^^^^^^^^^^^^^^^^^^

::

    # cd /opt/kubernetes/server/bin/certs
    # scp -r root@10.10.10.200:/opt/certs/kubelet.pem
    # scp -r root@10.10.10.200:/opt/certs/kubelet-key.pem

创建配置文件
^^^^^^^^^^^^

在10.10.10.30、10.10.10.31其中一台主机上执行即可

设置set-cluster
'''''''''''''''

创建需要连接的集群信息，可以创建多个k8s集群信息

::

    # mkdir -p /opt/kubernetes/server/conf
    # cd /opt/kubernetes/server/conf/
    # kubectl config set-cluster myk8s \
      --certificate-authority=/opt/kubernetes/server/bin/certs/ca.pem \
      --embed-certs=true \
      --server=https://10.10.10.25:7443 \
      --kubeconfig=kubelet.kubeconfig

设置set-credentials
'''''''''''''''''''

创建用户账号，即用户登陆使用的客户端私有和证书，可以创建多个证书

::

    # kubectl config set-credentials k8s-node \
    --client-certificate=/opt/kubernetes/server/bin/certs/client.pem \
    --client-key=/opt/kubernetes/server/bin/certs/client-key.pem \
    --embed-certs=true --kubeconfig=kubelet.kubeconfig 

设置set-context
'''''''''''''''

确定账号和集群对应关系

::

    # kubectl config set-context myk8s-context \
      --cluster=myk8s \
      --user=k8s-node \
      --kubeconfig=kubelet.kubeconfig

设置use-context
'''''''''''''''

设置当前使用哪个context

::

    # kubectl config use-context myk8s-context \
      --kubeconfig=kubelet.kubeconfig

创建资源配置文件k8s-node.yaml
'''''''''''''''''''''''''''''

::

    # cat > /opt/kubernetes/server/bin/conf/k8s-node.yaml << EOF
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: k8s-node
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: system:node
    subjects:
    - apiGroup: rbac.authorization.k8s.io
      kind: User
      name: k8s-node
    EOF

应用资源文件
''''''''''''

::

    # cd /opt/kubernetes/server/bin/conf/
    # kubectl create -f k8s-node.yaml

检查
''''

::

    # kubectl get clusterrolebinding k8s-node
    NAME       AGE
    k8s-node   13s

复制kubelet.kubeconfig
''''''''''''''''''''''

将生成的kubelet.kubeconfig文件复制到另一台主机的/opt/kubernetes/server/bin/conf/目录下

创建基础镜像pause
^^^^^^^^^^^^^^^^^

此步骤在10.10.10.200(运维机器)上执行

下载镜像
''''''''

::

    # docker pull kubernetes/pause
    # docker images | grep pause

给pause镜像打tag
''''''''''''''''

::

    # docker tag kubernetes/pause:latest harbor.od.com/public/pause:latest

将镜像push到harbor仓库
''''''''''''''''''''''

::

    # docker login harbor.od.com
    # docker push harbor.od.com/public/pause:latest

验证是否推送成功
''''''''''''''''

通过网页登录到harbor中，确认镜像推送成功

创建kubelet启动脚本
^^^^^^^^^^^^^^^^^^^

注意修改hostname-override对应的主机名称

::

    # cat > /opt/kubernetes/server/bin/kubelet.sh << EOF
    #!/bin/sh
    ./kubelet \
      --anonymous-auth=false \
      --cgroup-driver systemd \
      --cluster-dns 192.168.0.2 \
      --cluster-domain cluster.local \
      --runtime-cgroups=/systemd/system.slice --kubelet-cgroups=/systemd/system.slice \
      --fail-swap-on="false" \
      --client-ca-file ./certs/ca.pem \
      --tls-cert-file ./certs/kubelet.pem \
      --tls-private-key-file ./certs/kubelet-key.pem \
      --hostname-override home-10-30.host.com \
      --image-gc-high-threshold 20 \
      --image-gc-low-threshold 10 \
      --kubeconfig /opt/kubernetes/server/conf/kubelet.kubeconfig \
      --log-dir /data/logs/kubernetes/kube-kubelet \
      --pod-infra-container-image harbor.od.com/public/pause:latest \
      --root-dir /data/kubelet
    EOF

调整文件权限和创建目录
^^^^^^^^^^^^^^^^^^^^^^

::

    # chmod +x /opt/kubernetes/server/bin/kubelet.sh
    # mkdir -p /data/logs/kubernetes/kube-kubelet /data/kubelet

为kubelet创建supervisor配置文件
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

::

    # cat > /etc/supervisord.d/kube-kubelet.ini << EOF
    [program:kube-kubelet]
    command=/opt/kubernetes/server/bin/kubelet.sh                     
    numprocs=1
    directory=/opt/kubernetes/server/bin
    autostart=true
    autorestart=true
    startsecs=30
    startretries=3
    exitcodes=0,2
    stopsignal=QUIT
    stopwaitsecs=10
    user=root
    redirect_stderr=false
    stdout_logfile=/data/logs/kubernetes/kube-kubelet/kubelet.stdout.log
    stdout_logfile_maxbytes=64MB
    stdout_logfile_backups=4
    stdout_capture_maxbytes=1MB
    stdout_events_enabled=false
    stderr_logfile=/data/logs/kubernetes/kube-kubelet/kubelet.stderr.log
    stderr_logfile_maxbytes=64MB
    stderr_logfile_backups=4
    stderr_capture_maxbytes=1MB
    stderr_events_enabled=false
    EOF

启动服务并检查
^^^^^^^^^^^^^^

::

    # supervisorctl update
    # supervisorctl status
    etcd-server                      RUNNING   pid 15208, uptime 15:35:57
    kube-apiserver                   RUNNING   pid 17652, uptime 4:00:02
    kube-controller-manager          RUNNING   pid 17971, uptime 1:05:38
    kube-controller-scheduler        RUNNING   pid 17989, uptime 0:58:33
    kube-kubelet                     RUNNING   pid 18156, uptime 0:00:45

检查计算节点
^^^^^^^^^^^^

::

    # kubectl get nodes
    NAME                  STATUS   ROLES    AGE     VERSION
    home-10-30.host.com   Ready    <none>   2m53s   v1.15.10
    home-10-31.host.com   Ready    <none>   17s     v1.15.10

部署kube-proxy
~~~~~~~~~~~~~~

集群规划
^^^^^^^^

+--------------+--------------+---------------+
| 主机名       | 角色         | ip            |
+==============+==============+===============+
| HOME-10-30   | kube-proxy   | 10.10.10.30   |
+--------------+--------------+---------------+
| HOME-10-31   | kube-proxy   | 10.10.10.31   |
+--------------+--------------+---------------+

签发证书
^^^^^^^^

此步骤在10.10.10.200上进行

创建生成证书签名请求
''''''''''''''''''''

::

    # vim /opt/certs/kube-proxy.json
    {
        "CN": "system:kube-proxy",
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
                "C": "CN",
                "ST": "jinan",
                "L": "jinan",
                "O": "od",
                "OU": "ops"
            }
        ]
    }

生成证书
''''''''

::

    # cd /opt/certs
    # cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client kube-proxy.json | cfssl-json -bare kube-proxy-client
    2020/05/05 14:42:21 [INFO] generate received request
    2020/05/05 14:42:21 [INFO] received CSR
    2020/05/05 14:42:21 [INFO] generating key: rsa-2048
    2020/05/05 14:42:21 [INFO] encoded CSR
    2020/05/05 14:42:21 [INFO] signed certificate with serial number 394389928025425806393225554827978999345325703514
    2020/05/05 14:42:21 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
    websites. For more information see the Baseline Requirements for the Issuance and Management
    of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
    specifically, section 10.2.3 ("Information Requirements")

复制证书到计算节点
^^^^^^^^^^^^^^^^^^

::

    # cd /opt/kubernetes/server/bin/certs
    # scp -r root@10.10.10.200:/opt/certs/kube-proxy-client-key.pem
    # scp -r root@10.10.10.200:/opt/certs/kube-proxy-client.pem

创建配置文件
^^^^^^^^^^^^

在任意一台机器上执行

set-cluster
'''''''''''

::

    # cd /opt/kubernetes/server/bin/conf
    # kubectl config set-cluster myk8s \
      --certificate-authority=/opt/kubernetes/server/bin/certs/ca.pem \
      --embed-certs=true \
      --server=https://10.10.10.25:7443 \
      --kubeconfig=kube-proxy.kubeconfig

set-credentials
'''''''''''''''

::

    # kubectl config set-credentials kube-proxy \
      --client-certificate=/opt/kubernetes/server/bin/certs/kube-proxy-client.pem \
      --client-key=/opt/kubernetes/server/bin/certs/kube-proxy-client-key.pem \
      --embed-certs=true \
      --kubeconfig=kube-proxy.kubeconfig

set-context
'''''''''''

::

    # kubectl config set-context myk8s-context \
      --cluster=myk8s \
      --user=kube-proxy \
      --kubeconfig=kube-proxy.kubeconfig

use-context
'''''''''''

::

    # kubectl config use-context myk8s-context --kubeconfig=kube-proxy.kubeconfig

将kube-proxy.kubeconfig复制到另一台机器的相同目录，后面会用到

开启IPVS模块
^^^^^^^^^^^^

10.10.10.30和10.10.10.31都操作

查看是否已经加载了ipvs模块

::

    lsmod | grep ip_vs

如果没有开启，使用下面的脚本开启

::

    # cat > /root/ipvs.sh << EOF
    #!/bin/bash
    ipvs_mods_dir="/usr/lib/modules/$(uname -r)/kernel/net/netfilter/ipvs"
    for i in $(ls $ipvs_mods_dir|grep -o "^[^.]*")
    do
      /sbin/modinfo -F filename $i &>/dev/null
      if [ $? -eq 0 ];then
        /sbin/modprobe $i
      fi
    done
    EOF

执行添加ipvs模块脚本

::

    # cd /root
    # chmod +x ipvs.sh
    # ./ipvs.sh
    # lsmod | grep ip_vs

添加kube-proxy启动脚本
^^^^^^^^^^^^^^^^^^^^^^

::

    # cat > /opt/kubernetes/server/bin/kube-proxy.sh << EOF
    #!/bin/sh
    ./kube-proxy \
      --cluster-cidr 10.10.0.0/16 \
      --hostname-override home-10-30.host.com \
      --proxy-mode=ipvs  \
      --ipvs-scheduler=nq \
      --kubeconfig ./conf/kube-proxy.kubeconfig

调整文件权限和创建目录
^^^^^^^^^^^^^^^^^^^^^^

::

    # chmod +x /opt/kubernetes/server/bin/kube-proxy.sh
    # mkdir -p /data/logs/kubernetes/kube-proxy

为kube-proxy创建supervisor的开机自启配置文件
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

::

    # cat > /etc/supervisord.d/kube-proxy.ini << EOF
    [program:kube-proxy]
    command=/opt/kubernetes/server/bin/kube-proxy.sh                     
    numprocs=1
    directory=/opt/kubernetes/server/bin
    autostart=true
    autorestart=true
    startsecs=30
    startretries=3
    exitcodes=0,2
    stopsignal=QUIT
    stopwaitsecs=10
    user=root
    redirect_stderr=false
    stdout_logfile=/data/logs/kubernetes/kube-proxy/proxy.stdout.log
    stdout_logfile_maxbytes=64MB
    stdout_logfile_backups=4
    stdout_capture_maxbytes=1MB
    stdout_events_enabled=false
    stderr_logfile=/data/logs/kubernetes/kube-proxy/proxy.stderr.log
    stderr_logfile_maxbytes=64MB
    stderr_logfile_backups=4
    stderr_capture_maxbytes=1MB
    stderr_events_enabled=false
    EOF

启动服务并检查
^^^^^^^^^^^^^^

::

    # supervisorctl update
    # supervisorctl status

ipvsadm
^^^^^^^

::

    # yum install ipvsadm -y
    # ipvsadm -Ln
    IP Virtual Server version 1.2.1 (size=4096)
    Prot LocalAddress:Port Scheduler Flags
      -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
    TCP  192.168.0.1:443 nq
      -> 10.10.10.30:6443             Masq    1      0          0         
      -> 10.10.10.31:6443             Masq    1      0          0  

验证集群
--------

::

    # cat > /root/daemon.yaml <<EOF
    apiVersion: extensions/v1beta1
    kind: DaemonSet
    metadata:
      name: nginx-ds
      labels:
        addonmanager.kubernetes.io/mode: Reconcile
    spec:
      template:
        metadata:
          labels:
            app: nginx-ds
        spec:
          containers:
          - name: my-nginx
            image: harbor.od.com/public/nginx:v1.7.9
            ports:
            - containerPort: 80
    EOF

    # kubectl get pods -o wide
    nginx-ds-74qq8   1/1     Running   0          4m10s   172.10.31.2   home-10-31.host.com   <none>           <none>
    nginx-ds-jhxnt   1/1     Running   0          4m10s   172.10.30.2   home-10-30.host.com   <none>           <none>


    由于还没有安装网络插件 因此跨node节点的pod无法通信

