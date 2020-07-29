# node-exporter-alert-rules.yml



```yml
groups:
  - name: node-exporter-alert
    rules:
    - alert: node-exporter-down
      expr: node_exporter:up == 0 
      for: 1m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} 宕机了"  
        description: "instance: {{ $labels.instance }} \n- job: {{ $labels.job }} 关机了， 时间已经1分钟了。" 
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"



    - alert: node-exporter-cpu-high 
      expr:  node_exporter:cpu:total:percent > 80
      for: 3m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} cpu 使用率高于 {{ $value }}"  
        description: ""    
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"

    - alert: node-exporter-cpu-iowait-high 
      expr:  node_exporter:cpu:iowait:percent >= 12
      for: 3m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} cpu iowait 使用率高于 {{ $value }}"  
        description: ""    
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"

    - alert: node-exporter-load-load1-high 
      expr:  (node_exporter:load:load1) > (node_exporter:cpu:count) * 1.2
      for: 3m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} load1 使用率高于 {{ $value }}"  
        description: ""    
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"

    - alert: node-exporter-memory-high
      expr:  node_exporter:memory:used:percent > 85
      for: 3m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} memory 使用率高于 {{ $value }}"  
        description: ""    
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"

    - alert: node-exporter-disk-high
      expr:  node_exporter:disk:used:percent > 88
      for: 10m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} disk 使用率高于 {{ $value }}"  
        description: ""    
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"

    - alert: node-exporter-disk-read:count-high
      expr:  node_exporter:disk:read:count:rate > 3000
      for: 2m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} iops read 使用率高于 {{ $value }}"  
        description: ""    
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"

    - alert: node-exporter-disk-write-count-high
      expr:  node_exporter:disk:write:count:rate > 3000
      for: 2m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} iops write 使用率高于 {{ $value }}"  
        description: ""    
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"




    - alert: node-exporter-disk-read-mb-high
      expr:  node_exporter:disk:read:mb:rate > 60 
      for: 2m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} 读取字节数 高于 {{ $value }}"  
        description: ""    
        instance: "{{ $labels.instance }}"
        value: "{{ $value }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"

    - alert: node-exporter-disk-write-mb-high
      expr:  node_exporter:disk:write:mb:rate > 60
      for: 2m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} 写入字节数 高于 {{ $value }}"  
        description: ""    
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"

    - alert: node-exporter-filefd-allocated-percent-high 
      expr:  node_exporter:filefd_allocated:percent > 80
      for: 10m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} 打开文件描述符 高于 {{ $value }}"  
        description: ""    
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"

    - alert: node-exporter-network-netin-error-rate-high
      expr:  node_exporter:network:netin:error:rate > 4
      for: 1m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} 包进入的错误速率 高于 {{ $value }}"  
        description: ""    
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"
    - alert: node-exporter-network-netin-packet-rate-high
      expr:  node_exporter:network:netin:packet:rate > 35000
      for: 1m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} 包进入速率 高于 {{ $value }}"  
        description: ""    
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"

    - alert: node-exporter-network-netout-packet-rate-high
      expr:  node_exporter:network:netout:packet:rate > 35000
      for: 1m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} 包流出速率 高于 {{ $value }}"  
        description: ""    
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"

    - alert: node-exporter-network-tcp-total-count-high
      expr:  node_exporter:network:tcp:total:count > 40000
      for: 1m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} tcp连接数量 高于 {{ $value }}"  
        description: ""    
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"

    - alert: node-exporter-process-zoom-total-count-high 
      expr:  node_exporter:process:zoom:total:count > 10
      for: 10m
      labels: 
        severity: info
      annotations: 
        summary: "instance: {{ $labels.instance }} 僵死进程数量 高于 {{ $value }}"  
        description: ""    
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"

    - alert: node-exporter-time-offset-high
      expr:  node_exporter:time:offset > 0.03
      for: 2m
      labels: 
        severity: info
      annotations:
        summary: "instance: {{ $labels.instance }} {{ $labels.desc }}  {{ $value }} {{ $labels.unit }}"  
        description: ""    
        value: "{{ $value }}"
        instance: "{{ $labels.instance }}"
        grafana: "http://xxxxxxxx.com/d/node-exporter/node-exporter?orgId=1&var-instance={{ $labels.instance }} "
        console: "https://ecs.console.aliyun.com/#/server/{{ $labels.instanceid }}/detail?regionId=cn-beijing"
        cloudmonitor: "https://cloudmonitor.console.aliyun.com/#/hostDetail/chart/instanceId={{ $labels.instanceid }}&system=&region=cn-beijing&aliyunhost=true"
        id: "{{ $labels.instanceid }}"
        type: "aliyun_meta_ecs_info"
```

