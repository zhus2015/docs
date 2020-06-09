# ELK部署安装

官方文档地址：https://www.elastic.co/cn/what-is/elasticsearch



## 关于

“ELK”是三个开源项目的首字母缩写，这三个项目分别是：Elasticsearch、Logstash 和 Kibana。Elasticsearch 是一个搜索和分析引擎。Logstash 是服务器端数据处理管道，能够同时从多个来源采集数据，转换数据，然后将数据发送到诸如 Elasticsearch 等“存储库”中。Kibana 则可以让用户在 Elasticsearch 中使用图形和图表对数据进行可视化。



## 环境

> 虚拟机

操作系统：centos7.7

配置：

​	- CPU：4C 

​	- MEM：8G  

​	- DISK：40G



> 软件版本

elasticearch：7.7.1

logstasch：7.7.1

kibana：7.7.1

采集软件filebeat：7.7.1



## 安装

!!! warning "这里跳过了环境初始化的步骤，例如关闭防火墙、优化内核参数、升级软件包等等"

!!! warning "注意这里需要1.8及以上版本的jdk环境，请提前安装"

!!! note "为了方便这里全部使用yum安装"



### 配置yum源

> vim /etc/yum.repos.d/elasticsearch.repo

````
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

```
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```



### 安装

```
yum install elasticsearch-7.7.1 logstash-7.7.1 kibana-7.7.1 -y
```

??? note "如果安装较慢，可以将rpm包先下载下来然后安装"

    ```
    wegt https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.7.1-x86_64.rpm
    wget https://artifacts.elastic.co/downloads/logstash/logstash-7.7.1.rpm
    wget https://artifacts.elastic.co/downloads/kibana/kibana-7.7.1-x86_64.rpm
    yum localinstall -y elasticsearch-7.7.1-x86_64.rpm logstash-7.7.1.rpm kibana-7.7.1-x86_64.rpm
    ```


## 修改配置

### 修改elasticsearch配置

> vim /etc/elasticsearch/elasticsearch.yml

```
cluster.name: myelk
node.name: elk
path.data: /data/elasticsearch
path.logs: /data/logs/elasticsearch
network.host: 0.0.0.0
http.port: 9200
discovery.seed_hosts: ["elk"]
```

??? tip "配置说明"

	```
	cluster.name: myelk                 #集群名称
	node.name: elk                      #节点名称，我这里是用的我的主机名
	path.data: /data/elasticsearch      #数据目录
	path.logs: /data/logs/elasticsearch #日志目录
	network.host: 0.0.0.0               #监听地址
	http.port: 9200                     #监听端口
	discovery.seed_hosts: ["elk"]       #启动节点默认节点，这里可以填写主机名称或者IP
	cluster.initial_master_nodes: ["elk"] #初始化集群的节点，这里可以填写主机名称或者IP
	```

  

### 修改logstash配置

> vim /etc/logstash/logstash.yml

```
node.name: elk
path.data: /data/logstash
path.logs: /data/logs/logstash
```



> vim /etc/logstash/conf.d/logstash.conf

```
input {
  beats {
    port => 5044
    codec => plain {
      charset => "UTF-8"
    }
  }
}

output {
  elasticsearch {
    hosts => "127.0.0.1:9200"
    manage_template => false
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    document_type => "%{[@metadata][type]}"
  }
}
```



### 修改kinbana配置

> vim /etc/kibana/kibana.yml

```
server.port: 5601
server.host: "10.10.10.110"
elasticsearch.hosts: ["http://10.10.10.110:9200"]
```




### 创建相关目录

```
mkdir -p /data/{elasticsearch,logstash}
mkdir -p /data/logs/{elasticsearch,logstash}
chown -R elasticsearch.elasticsearch /data/elasticsearch
chown -R elasticsearch.elasticsearch /data/logs/elasticsearch
chown -R logstash.logstash /data/logstash
chown -R logstash.logstash /data/logs/logstash
```





## 启动相关程序

```
systemctl daemon-reload
systemctl start elasticsearch 
systemctl start logstash 
systemctl start kibana 
```





## 验证

![image-20200609171205322](images/image-20200609171205322.png)