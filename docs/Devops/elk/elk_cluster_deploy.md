# ELK集群部署

## 环境

> 虚拟机

| IP         | 操作系统   | 配置 | 部署服务                        |
| ---------- | ---------- | ---- | ------------------------------- |
| 10.4.7.131 | Centos 7.7 | 4C8G | elasticsearch、logstash、kibana |
| 10.4.7.132 | Centos 7.7 | 2C4G | elasticsearch                   |
| 10.4.7.133 | Centos 7.7 | 2C4G | elasticsearch、filebeat、nginx  |



> 软件版本

elasticearch：7.7.1

logstasch：7.7.1

kibana：7.7.1

采集软件filebeat：7.7.1



## Elasticsearch安装

### 配置yum源

> [root@10-4-7-131 ~]# vim /etc/yum.repos.d/elasticsearch.repo

````shell
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md

[logstash-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md

[kibana-7.x]
name=Kibana repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
````

> 导入PGP密钥

```shell
[root@10-4-7-131 ~]# rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```



### 安装

> 10.4.7.131安装三个包，其他节点安装elasticsearch即可

```shell
[root@10-4-7-131 ~]# yum install elasticsearch-7.7.1 -y
```

??? note "如果安装较慢，可以将rpm包先下载下来然后安装"

~~~shell
```
wegt https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.7.1-x86_64.rpm
yum localinstall elasticsearch-7.7.1-x86_64.rpm -y
```
~~~

### 创建目录



### 修改配置

