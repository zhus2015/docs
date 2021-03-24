# Prometheus安装部署

## Prometheus简介

参考官网文档：   https://prometheus.io/docs/prometheus/latest/installation/



![Prometheus architecture](https://prometheus.io/assets/architecture.png)

## Prometheus server服务

```yml
# my global config
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
#alerting:
#  alertmanagers:
#  - static_configs:
#    - targets:
#       - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
#rule_files:
#  - "/etc/prometheus/*rules.yml"
  #- "/etc/prometheus/rules.yml"
  #- "/etc/prometheus/node-exporter-alert-rules.yml"
  #- "/etc/prometheus/node-exporter-record-rules.yml"
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 10s
    static_configs:
      - targets: ['localhost:9090']
        labels:
          instance: prometheus
  - job_name: 'linux_hosts'
    static_configs:
      - targets: ['10.10.10.103:9100','10.10.10.10:9100']
        labels:
          group: 'client-node-exporter'
      - targets: ['10.10.10.103:8080','10.10.10.10:8080']
        labels:
          group: 'cadvisor'
      - targets: ['10.10.10.103:9091']
        labels:
          group: 'pushgateway'

```

注意先创建相关目录

```shell
#! /bin/bash

docker stop prometheus
docker rm prometheus
docker run --name prometheus -d -p 9090:9090  --restart=always \
	-v /data/prometheus/conf/prometheus.yml:/etc/prometheus/prometheus.yml \
	-v /data/prometheus/conf/rules:/etc/prometheus/rules \
	-v /data/prometheus/data:/prometheus \
	-v /data/prometheus/conf/yml:/etc/prometheus/conf \
        -v "/etc/localtime:/etc/localtime" \
	prom/prometheus:v2.25.2 \
        --config.file=/etc/prometheus/prometheus.yml \
        --storage.tsdb.retention.time=180d \
        --web.enable-admin-api \
        --web.enable-lifecycle

docker logs -f prometheus
```

- --web.enable-lifecycle：启用热加载配置文件
  可以通过 curl -X POST  http://localhost:9090/-/reload 命令不重启加载新的配置项目
- --storage.tsdb.retention=90d：配置数据存储时间，Prometheus默认保留数据时间为15天
- --config.file：指定配置文件

!!! waring "注意挂载之前需要将配置文件的权限修改为777，否则有可能出现配置文件无法同步"



## Grafana--数据展示平台

```shell
$ mkdir -p /data/grafana 
$ docker run -itd -p 3000:3000 \
           --restart=always --user=root --name=grafana \
           -v "/etc/localtime:/etc/localtime" \
           -v /data/docker/grafana/data:/var/lib/grafana \
           grafana/grafana
```

这里不使用--network=host 可能grafana会出现无法联网的情况

 -v /data/grafana:/var/lib/grafana 是为了持久化数据

```
cat <<EOF | curl --data-binary @- http://10.10.10.103:9091/metrics/job/cqh/instance/test
muscle_metric{label="gym"} 8800
bench_press 100
dead_lift 180
deep_squal 160
EOF
```



## Alertmanager--告警插件

> 启动命令

```shell
docker run -d -p 9093:9093 \
           --restart=always \
           --name alertmanager \
           -v "/etc/localtime:/etc/localtime" \
           -v /etc/prometheus/alertmanager.yml:/etc/alertmanager/alertmanager.yml \
           prom/alertmanager
```

> alertmanager.yml

```yml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'dingtalk'
receivers:
- name: 'dingtalk'
  webhook_configs:
  - url: 'http://10.10.10.103:8060/dingtalk/webhookhaha/send'  #钉钉web-hook地址
    send_resolved: true

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
```

> 需要在Prometheus中添加相关配置

```yml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["10.10.10.103:9093"]
```

## DingDing通知

### 编辑启动文件

> vim /data/prometheus/cmd/run-dingtalk.sh

```shell
#! /bin/bash

docker stop dingtalk
docker rm dingtalk
docker run --name dingtalk --restart always  \
	-d -p 8060:8060 \
	-v /data/prometheus/conf/dingtalk.yml:/etc/dingtalk.yml \
    -v /data/prometheus/conf/dingding.tmpl:/etc/dingding.tmpl \
    docker.io/zhus2015/prometheus-webhook-dingtalk:v1.0.0 \
	--config.file=/etc/dingtalk.yml

	#timonwong/prometheus-webhook-dingtalk:v1.4.0 \
docker logs -f dingtalk
```

这里的镜像是我重新进行了环境字符集的定义，其他内容未作修改

### 编辑Dingtalk配置文件

```yml
timeout: 5s
templates:
  - /etc/dingding.tmpl
targets:
  webhookedu:
    url: https://oapi.dingtalk.com/robot/send?access_token=xxxxx
    secret: xxxxx
    message:
      title: '{{ template "ding.link.title" . }}'
      text: '{{ template "ding.link.content" . }}'
  webhook_mention_all:
    url: https://oapi.dingtalk.com/robot/send?access_token=xxxxxxxxxxxx
    mention:
      all: true
  webhook_mention_users:
    url: https://oapi.dingtalk.com/robot/send?access_token=xxxxxxxxxxxx
    mention:
      mobiles: ['156xxxx8827', '189xxxx8325']
```

注意将xxxxx内容替换为自己机器人的相关配置

### 编辑自定义模板文件

> vim /data/prometheus/conf/dingding.tmpl

```
{{ define "__subject" }}[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] {{ .GroupLabels.SortedPairs.Values | join " " }} {{ if gt (len .CommonLabels) (
len .GroupLabels) }}({{ with .CommonLabels.Remove .GroupLabels.Names }}{{ .Values | join " " }}{{ end }}){{ end }}{{ end }}
{{ define "__alertmanagerURL" }}{{ .ExternalURL }}/#/alerts?receiver={{ .Receiver }}{{ end }}

{{ define "__text_alert_list" }}{{ range . }}
**Labels**
{{ range .Labels.SortedPairs }}> - {{ .Name }}: {{ .Value | markdown | html }}
{{ end }}
**Annotations**
{{ range .Annotations.SortedPairs }}> - {{ .Name }}: {{ .Value | markdown | html }}
{{ end }}
**Source:** [{{ .GeneratorURL }}]({{ .GeneratorURL }})
{{ end }}{{ end }}

{{ define "default.__text_alert_list" }}{{ range . }}
---
**告警级别:** {{ .Labels.severity | upper }}

**触发时间:** {{ dateInZone "2006.01.02 15:04:05" (.StartsAt) "Asia/Shanghai" }}

**事件信息:** 
{{ range .Annotations.SortedPairs }}> - {{ .Name }}: {{ .Value | markdown | html }}


{{ end }}

**事件标签:**
{{ range .Labels.SortedPairs }}{{ if and (ne (.Name) "severity") (ne (.Name) "summary") (ne (.Name) "team") }}> - {{ .Name }}: {{ .Value | markdown | html }}
{{ end }}{{ end }}
{{ end }}
{{ end }}
{{ define "default.__text_alertresovle_list" }}{{ range . }}
---
**告警级别:** {{ .Labels.severity | upper }}

**触发时间:** {{ dateInZone "2006.01.02 15:04:05" (.StartsAt) "Asia/Shanghai" }}

**结束时间:** {{ dateInZone "2006.01.02 15:04:05" (.EndsAt) "Asia/Shanghai" }}

**事件信息:**
{{ range .Annotations.SortedPairs }}> - {{ .Name }}: {{ .Value | markdown | html }}


{{ end }}

**事件标签:**
{{ range .Labels.SortedPairs }}{{ if and (ne (.Name) "severity") (ne (.Name) "summary") (ne (.Name) "team") }}> - {{ .Name }}: {{ .Value | markdown | html }}
{{ end }}{{ end }}
{{ end }}
{{ end }}

{{/* Default */}}
{{ define "default.title" }}{{ template "__subject" . }}{{ end }}
{{ define "default.content" }}#### \[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}\] **[{{ index .GroupLabels "alertname" }}]({{ template "__alertmanag
erURL" . }})**
{{ if gt (len .Alerts.Firing) 0 -}}

**====侦测到故障====**
{{ template "default.__text_alert_list" .Alerts.Firing }}


{{- end }}

{{ if gt (len .Alerts.Resolved) 0 -}}
**====故障恢复====**
{{ template "default.__text_alertresovle_list" .Alerts.Resolved }}


{{- end }}
{{- end }}

{{/* Legacy */}}
{{ define "legacy.title" }}{{ template "__subject" . }}{{ end }}
{{ define "legacy.content" }}#### \[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}\] **[{{ index .GroupLabels "alertname" }}]({{ template "__alertmanage
rURL" . }})**
{{ template "__text_alert_list" .Alerts.Firing }}
{{- end }}

{{/* Following names for compatibility */}}
{{ define "ding.link.title" }}{{ template "default.title" . }}{{ end }}
{{ define "ding.link.content" }}{{ template "default.content" . }}{{ end }}
```

### 启动脚本进行相关测试通知即可



## Consul自动注册服务

### 部署安装

Consul有多种安装部署方式，这里使用Docker进行部署

```shell
docker run --name consul --restart=always -d -p 8500:8500 \
           -v /data/docker/prometheus/consul/data:/consul/data \
           consul
```

启动后可以通过浏览器看到一下页面

![image-20201212103840334](https://gitee.com/zhus2015/images/raw/master/docimg/image-20201212103840334.png)

### 注册服务

这里通过官方提供的API接口添加服务

```shell
curl -X PUT -d '{"id": "node-exporter","name": "node-exporter-10.4.7.131","address": "10.4.7.131","port": 9100,"tags": ["test"],"checks": [{"http": "http://10.4.7.131:9100/metrics", "interval": "5s"}]}'  http://10.4.7.101:8500/v1/agent/service/register
```

可以看到我们新注册的测试服务已经添加到Consul中了

![image-20201212103854040](https://gitee.com/zhus2015/images/raw/master/docimg/image-20201212103854040.png)



### 注销服务

```shell
curl -X PUT http://10.4.7.101:8500/v1/agent/service/deregister/node-exporter 
```



## Node exporter--节点监控工具

用于提供metrics，通过接口进行信息的收集，主要用来收集服务器的相关数据

```shell
docker run -d --restart=always \
           --name=node-exporter \
           -p 9100:9100 \
           -v "/etc/localtime:/etc/localtime" \
           prom/node-exporter
```



## Cadvisor--容器监控插件

cadvisor用于收集容器信息

```shell
docker run -d --restart=always \
           -v "/etc/localtime:/etc/localtime" \
           --volume=/:/rootfs:ro \
           --volume=/var/run:/var/run:ro \
           --volume=/sys:/sys:ro \
           --volume=/var/lib/docker/:/var/lib/docker:ro \
           --volume=/dev/disk/:/dev/disk:ro \
           --publish=8080:8080 \
           --detach=true \
           --name=cadvisor \
           google/cadvisor
```



## Blackbox_exporter

### 部署启动

>启动脚本  runblackbox.sh

```shell
#! /bin/bash
comtainer_name=blackbox-exporter
docker stop $comtainer_name
docker rm $comtainer_name
docker run --name $comtainer_name -d -p 9115:9115 \
           --restart=always \ 
	       -v /data/docker/prometheus/blackbox.yml:/etc/blackbox_exporter/config.yml \
           -v "/etc/localtime:/etc/localtime" \
	       prom/blackbox-exporter \
```

> 配置文件blackbox.yml

```yml
modules:
  http_2xx:
    prober: http
    timeout: 10s
    http:
      preferred_ip_protocol: "ip4"  #IPv4,如果不写很多网站会有问题
  http_post_2xx:
    prober: http
    timeout: 10s
    http:
      method: POST
      preferred_ip_protocol: "ip4"
      headers:
        Content-Type: application/json
  tcp_connect:
    prober: tcp
  pop3s_banner:
    prober: tcp
    tcp:
      query_response:
      - expect: "^+OK"
      tls: true
      tls_config:
        insecure_skip_verify: false
  ssh_banner:
    prober: tcp
    tcp:
      query_response:
      - expect: "^SSH-2.0-"
  irc_banner:
    prober: tcp
    tcp:
      query_response:
      - send: "NICK prober"
      - send: "USER prober prober prober :prober"
      - expect: "PING :([^ ]+)"
        send: "PONG ${1}"  
      - expect: "^:[^ ]+ 001"
  icmp:
    prober: icmp
    timeout: 5s
```

### 服务测试

可以通过浏览器访问ip:9115的方法查看服务启动状态

![image-20201204093309851](../../images/image-20201204093309851.png)

### 应用场景

- HTTP 测试
  定义 Request Header 信息
  判断 Http status / Http Respones Header / Http Body 内容
- TCP 测试
  业务组件端口状态监听
  应用层协议定义与监听
- ICMP 测试
  主机探活机制
- POST 测试
  接口联通性
- SSL 证书过期时间

#### HTTP测试

- 相关配置内容添加到 Prometheus 配置文件内
- 对应 blackbox.yml文件的 http_2xx 模块

```shell
###WEB-TEST##
- job_name: 'blackbox'
  metrics_path: /probe
  params:
    module: [http_2xx]  # Look for a HTTP 200 response.
  static_configs:
    - targets:
      - http://www.baidu.com    # Target to probe with http.
      - https://aliyun.com      # Target to probe with https.
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: 10.7.201.98:9115  # The blackbox exporter's real hostname:port.
```

重启Prometheus加载新的配置项目，我们就能在Prometheus的监控中看到相关监控项目

![image-20201204093645365](../../images/image-20201204093645365.png)

#### TCP测试

```yml
- job_name: "blackbox_telnet_port]"
  scrape_interval: 10s
  metrics_path: /probe
  params:
    module: [tcp_connect]
  static_configs:
      - targets: [ '10.7.202.202:80' ]
        labels:
          group: 'download'
  relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 10.7.201.98:9115
```

#### ICMP测试

```yml
- job_name: 'blackbox_ping_idc_ip'
  scrape_interval: 10s
  metrics_path: /probe
  params:
    module: [icmp]  #ping
  static_configs:
      - targets: [ '10.7.202.202' ]
        labels:
          group: 'download'
  relabel_configs:
      - source_labels: [__address__]
        regex: (.*)(:80)?
        target_label: __param_target
        replacement: ${1}
      - source_labels: [__param_target]
        regex: (.*)
        target_label: ping
        replacement: ${1}
      - source_labels: []
        regex: .*
        target_label: __address__
        replacement: 10.7.201.98:9115
```

#### POST测试

> Prometheus配置文件修改

```yml
- job_name: 'blackbox_http_post'
  metrics_path: /probe
  params:
    module: [http_post_2xx]
  
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: 10.7.201.98:9115
```



#### HTTP、TCP、ICMP告警

> blackbox-alert.yml

```yml
groups:
- name: blackbox_network_stats
  rules:
  - alert: blackbox_network_stats
    expr: probe_success == 0
    for: 45s
    labels:
      severity: warning
    annotations:
      summary: "Instance {{ $labels.instance }}  is down"
      description: "This requires immediate action!"
```



```
- resolve：DNS解析持续时间
- connect：TCP连接建立的持续时间
- tls：    TLS连接协商持续时间（我认为这包括TCP连接建立持续时间）
- processing：建立连接与接收响应的第一个字节之间的持续时间
- transfer：转移响应的持续时间
```



## Redis_exporter

!!! waring "这个项目并不是官方项目"

项目地址：https://github.com/oliver006/redis_exporter/releases

下载相对应平台的软件包，也可以使用docker运行

Docker仓库地址：https://hub.docker.com/r/oliver006/redis_exporter

### Redis_exporter安装配置

这里我们将其可执行文件解压放置到/usr/bin目录下

```shell
# 下载redis_exporter
wget https://github.com/oliver006/redis_exporter/releases/download/v1.3.4/redis_exporter-v1.3.4.linux-amd64.tar.gz
# 解压
tar xzf redis_exporter-v1.3.4.linux-amd64.tar.gz 
# 安装redis_exporter
cp redis_exporter-v1.3.4.linux-amd64/redis_exporter /usr/bin/
```

### Redis_exporter启动

#### 创建Prometheus用户(存在则跳过)

```shell
useradd -g prometheus -M -s /sbin/nologin prometheus
```

#### 调整文件权限

```shell
chown prometheus.prometheus /usr/bin/redis_exporter
```



配置redis_exporter为系统服务方式启动

> vim  /usr/lib/systemd/system/redis_exporter.service

```shell
[Unit]
Description=Node exporter
After=network.target

[Service]
User=prometheus
PIDFile=/var/run/redis_exporter.pid
ExecStart=/usr/bin/redis_exporter -web.listen-address :1910 -redis.addr 127.0.0.1:6379 -redis.password password  #password为自己集群的密码
ExecReload=/bin/kill -s HUP $MAINPID
#Restart=on-failure

[Install]
WantedBy=default.target
```

- -web.listen-address  :1910  服务监听端口，默认0.0.0.0:9121
- -redis.addr  redis节点地址，默认为 redis://localhost:6379(如果有多个redis实例，建议启动多个redis_exporter进行监控)
- -redis.password  redis的密码
- -redis.file  包含一个或多个redis 节点的文件路径，每行一个节点，此选项与 -redis.addr 冲突

> 重新加载配置并配置开机启动

```shell
chown prometheus:prometheus /usr/lib/systemd/system/redis_exporter.service
systemctl daemon-reload
systemctl enable redis_exporter
systemctl start redis_exporter
systemctl status redis_exporter
```

### 添加Prometheus配置

```shell
- job_name: 'redis'
  scrape_interval: 5s
  #evaluation_interval: 15s
  metrics_path: '/metrics'
  static_configs:
    - targets: ['10.10.10.2:1910']
```

重启Prometheus加载新的配置文件

### 配置Grafana展示

导入监控模板https://grafana.com/grafana/dashboards/763



## Rocketmq-exporter

Rocketmq-exporter是对Rocket进行监控的一个工具

项目地址：https://github.com/apache/rocketmq-exporter

Grafana地址：https://grafana.com/grafana/dashboards/10477

Apache官方并没有给出打包好的二进制文件以及封装好的Docker镜像，因此需要我们自己该项目插件进行打包

### 获取代码

```shell
git clone https://github.com/apache/rocketmq-exporter.git
```

### 修改配置文件

这一步可以略过，通过启动参数执行也可以

This image is configurable using different properties, see `application.properties` for a configuration example.

| name                               | Default        | Description                                          |
| ---------------------------------- | -------------- | ---------------------------------------------------- |
| `rocketmq.config.namesrvAddr`      | 127.0.0.1:9876 | name server address for broker cluster               |
| `rocketmq.config.webTelemetryPath` | /metrics       | Path under which to expose metrics                   |
| `server.port`                      | 5557           | Address to listen on for web interface and telemetry |
| `rocketmq.config.rocketmqVersion`  | V4_3_2         | rocketmq broker version                              |

### 构建

#### 二进制打包

```shell
cd rocketmq-exporter
mvn clean install
```

#### Docker镜像打包

> 修改Dockerfile文件(src/main/docker/Dockerfile)

```
FROM java:8
MAINTAINER breeze
ADD rocketmq-exporter-0.0.2-SNAPSHOT.jar quickstart.jar
EXPOSE 5557
ENTRYPOINT ["java","-jar","quickstart.jar"]
```

主要就是`rocketmq-exporter-0.0.2-SNAPSHOT.jar`包名称，要和自己生成的包一致

> 打包并推送到个人仓库

```shell
#打包Docker镜像
mvn package -Dmaven.test.skip=true docker:build
#修改tag
docker tag e9179c2f01de zhus2015/rocketmq-exporter:0.0.2
#推送到个人仓库
docker push zhus2015/rocketmq-exporter:0.0.2
```

### 运行

#### 二进制包运行

```shell
java -jar rocketmq-exporter-0.0.2-SNAPSHOT.jar --rocketmq.config.namesrvAddr=10.1.1.20:9876
```

如果打包的时候配置了`rocketmq.config.namesrvAddr`参数，启动的时候就不需要再进行配置，程序默认端口5557，可以通过浏览器访问http://ip:5557/metrics看到监控获取到的参数

#### Docker运行

````shell
docker run -d --name rmq-export -p 5557:5557 zhus2015/rocketmq-exporter:0.0.2 \
           --restart=always \
           --rocketmq.config.namesrvAddr=10.1.1.10:9876 \
           -rocketmq.config.rocketmqVersion=V4_7_1
````

启动参数根据自己的需求进行修改，启动后可以通过浏览器访问http://ip:5557/metrics查看是否已经获取到了相关监控参数

### 修改Prometheus配置

```yml
- job_name: 'test-rocketmq'
  scrape_interval: 5s
  metrics_path: '/metrics'
  static_configs:
    - targets: ['10.7.202.202:5557']
```

重启Prometheus使配置生效

### 添加Grafana图表

官方提供了一个展示页面，需要根据自己的需求进行相关的修改即可

官方地址：https://grafana.com/grafana/dashboards/10477



### 告警规则

```yml
###
# Sample prometheus rules/alerts for rocketmq.
#
###
# Galera Alerts
 
groups:
- name: GaleraAlerts
  rules:
  - alert: RocketMQClusterProduceHigh
    expr: sum(rocketmq_producer_tps) by (cluster) >= 10
    for: 3m
    labels:
      severity: warning
    annotations:
      description: '{{$labels.cluster}} Sending tps too high.'
      summary: cluster send tps too high
  - alert: RocketMQClusterProduceLow
    expr: sum(rocketmq_producer_tps) by (cluster) < 1
    for: 3m
    labels:
      severity: warning
    annotations:
      description: '{{$labels.cluster}} Sending tps too low.'
      summary: cluster send tps too low
  - alert: RocketMQClusterConsumeHigh
    expr: sum(rocketmq_consumer_tps) by (cluster) >= 10
    for: 3m
    labels:
      severity: warning
    annotations:
      description: '{{$labels.cluster}} consuming tps too high.'
      summary: cluster consume tps too high
  - alert: RocketMQClusterConsumeLow
    expr: sum(rocketmq_consumer_tps) by (cluster) < 1
    for: 3m
    labels:
      severity: warning
    annotations:
      description: '{{$labels.cluster}} consuming tps too low.'
      summary: cluster consume tps too low
  - alert: ConsumerFallingBehind
    expr: (sum(rocketmq_producer_offset) by (topic) - on(topic)  group_right  sum(rocketmq_consumer_offset) by (group,topic)) - ignoring(group) group_left sum (avg_over_time(rocketmq_producer_tps[5m])) by (topic)*5*60 > 0
    for: 3m
    labels:
      severity: warning
    annotations:
      description: 'consumer {{$labels.group}} on {{$labels.topic}} lag behind
        and is falling behind (behind value {{$value}}).'
      summary: consumer lag behind
  - alert: GroupGetLatencyByStoretime
    expr: rocketmq_group_get_latency_by_storetime > 1000
    for: 3m
    labels:
      severity: warning
    annotations:
      description: 'consumer {{$labels.group}} on {{$labels.broker}}, {{$labels.topic}} consume time lag behind message store time
        and (behind value is {{$value}}).'
      summary: message consumes time lag behind message store time too much 
```