# Prometheus的安装部署

参考官网文档：   https://prometheus.io/docs/prometheus/latest/installation/



![Prometheus architecture](https://prometheus.io/assets/architecture.png)



## Prometheus server 

```shell
docker run --name=prometheus -d \
-p 9090:9090 \
-v /etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
-v /etc/prometheus/rules.yml:/etc/prometheus/rules.yml \
-v "/etc/localtime:/etc/localtime" \
prom/prometheus:v2.20.0 \
--config.file=/etc/prometheus/prometheus.yml \
--web.enable-lifecycle
```



启动时加上--web.enable-lifecycle启用远程热加载配置文件
调用指令是curl -X POST  http://localhost:9090/-/reload

!!! waring "注意挂载之前需要将配置文件的权限修改为777，否则有可能出现配置文件无法同步"



## Node exporter

用于提供metrics，通过接口进行信息的收集

```shell
docker run -d \
--name=node-exporter \
-p 9100:9100 \
-v "/etc/localtime:/etc/localtime" \
prom/node-exporter
```



# Cadvisor

cadvisor用于收集容器信息

```shell
docker run -d \
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



## Alertmanager

```
docker run -d -p 9093:9093 \
--name alertmanager \
-v /etc/prometheus/alertmanager.yml:/etc/alertmanager/alertmanager.yml \
prom/alertmanager
```





```yml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["10.10.10.103:9093"]
```

