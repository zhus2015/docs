# Prometheus的安装部署

参考官网文档：   https://prometheus.io/docs/prometheus/latest/installation/



![Prometheus architecture](https://prometheus.io/assets/architecture.png)





## Node exporter

用于提供metrics，通过接口进行信息的收集

```shell
docker run -d --restart=always \
           --name=node-exporter \
           -p 9100:9100 \
           -v "/etc/localtime:/etc/localtime" \
           prom/node-exporter
```



# Cadvisor

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



## Prometheus server 

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
docker run --user=root --name=prometheus -itd \
           --restart=always -p 9090:9090 \
           -v /data/docker/prometheus/data:/prometheus/data \
           -v /data/docker/prometheus/conf/prometheus.yml:/etc/prometheus/prometheus.yml \
           -v "/etc/localtime:/etc/localtime" \
           prom/prometheus:v2.20.0 \
           --config.file=/etc/prometheus/prometheus.yml \
           --web.enable-lifecycle
```



启动时加上--web.enable-lifecycle启用远程热加载配置文件
调用指令是curl -X POST  http://localhost:9090/-/reload

!!! waring "注意挂载之前需要将配置文件的权限修改为777，否则有可能出现配置文件无法同步"



## Alertmanager

```
docker run -d -p 9093:9093 \
--name alertmanager \
-v "/etc/localtime:/etc/localtime" \
-v /etc/prometheus/alertmanager.yml:/etc/alertmanager/alertmanager.yml \
prom/alertmanager
```





```yml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["10.10.10.103:9093"]
```



## Grafana

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

