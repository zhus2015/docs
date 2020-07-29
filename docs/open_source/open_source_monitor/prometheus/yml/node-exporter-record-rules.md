# node-exporter-record-rules.yml

```yml
groups:
  - name: node-exporter-record
    rules:
    - expr: up{job=~"node-exporter"}
      record: node_exporter:up 
      labels: 
        desc: "节点是否在线, 在线1,不在线0"
        unit: " "
        job: "node-exporter"
    - expr: time() - node_boot_time_seconds{}
      record: node_exporter:node_uptime
      labels: 
        desc: "节点的运行时间"
        unit: "s"
        job: "node-exporter"
##############################################################################################
#                              cpu                                                           #
    - expr: (1 - avg by (environment,instance) (irate(node_cpu_seconds_total{job="node-exporter",mode="idle"}[5m])))  * 100 
      record: node_exporter:cpu:total:percent
      labels: 
        desc: "节点的cpu总消耗百分比"
        unit: "%"
        job: "node-exporter"

    - expr: (avg by (environment,instance) (irate(node_cpu_seconds_total{job="node-exporter",mode="idle"}[5m])))  * 100 
      record: node_exporter:cpu:idle:percent
      labels: 
        desc: "节点的cpu idle百分比"
        unit: "%"
        job: "node-exporter"

    - expr: (avg by (environment,instance) (irate(node_cpu_seconds_total{job="node-exporter",mode="iowait"}[5m])))  * 100 
      record: node_exporter:cpu:iowait:percent
      labels: 
        desc: "节点的cpu iowait百分比"
        unit: "%"
        job: "node-exporter"


    - expr: (avg by (environment,instance) (irate(node_cpu_seconds_total{job="node-exporter",mode="system"}[5m])))  * 100 
      record: node_exporter:cpu:system:percent
      labels: 
        desc: "节点的cpu system百分比"
        unit: "%"
        job: "node-exporter"

    - expr: (avg by (environment,instance) (irate(node_cpu_seconds_total{job="node-exporter",mode="user"}[5m])))  * 100 
      record: node_exporter:cpu:user:percent
      labels: 
        desc: "节点的cpu user百分比"
        unit: "%"
        job: "node-exporter"

    - expr: (avg by (environment,instance) (irate(node_cpu_seconds_total{job="node-exporter",mode=~"softirq|nice|irq|steal"}[5m])))  * 100 
      record: node_exporter:cpu:other:percent
      labels: 
        desc: "节点的cpu 其他的百分比"
        unit: "%"
        job: "node-exporter"
##############################################################################################


##############################################################################################
#                                    memory                                                  #
    - expr: node_memory_MemTotal_bytes{job="node-exporter"}
      record: node_exporter:memory:total
      labels: 
        desc: "节点的内存总量"
        unit: byte
        job: "node-exporter"

    - expr: node_memory_MemFree_bytes{job="node-exporter"}
      record: node_exporter:memory:free
      labels: 
        desc: "节点的剩余内存量"
        unit: byte
        job: "node-exporter"

    - expr: node_memory_MemTotal_bytes{job="node-exporter"} - node_memory_MemFree_bytes{job="node-exporter"}
      record: node_exporter:memory:used
      labels: 
        desc: "节点的已使用内存量"
        unit: byte
        job: "node-exporter"

    - expr: node_memory_MemTotal_bytes{job="node-exporter"} - node_memory_MemAvailable_bytes{job="node-exporter"}
      record: node_exporter:memory:actualused
      labels: 
        desc: "节点用户实际使用的内存量"
        unit: byte
        job: "node-exporter"

    - expr: (1-(node_memory_MemAvailable_bytes{job="node-exporter"} / (node_memory_MemTotal_bytes{job="node-exporter"})))* 100
      record: node_exporter:memory:used:percent
      labels: 
        desc: "节点的内存使用百分比"
        unit: "%"
        job: "node-exporter"

    - expr: ((node_memory_MemAvailable_bytes{job="node-exporter"} / (node_memory_MemTotal_bytes{job="node-exporter"})))* 100
      record: node_exporter:memory:free:percent
      labels: 
        desc: "节点的内存剩余百分比"
        unit: "%"
        job: "node-exporter"
##############################################################################################
#                                   load                                                     #
    - expr: sum by (instance) (node_load1{job="node-exporter"})
      record: node_exporter:load:load1
      labels: 
        desc: "系统1分钟负载"
        unit: " "
        job: "node-exporter"

    - expr: sum by (instance) (node_load5{job="node-exporter"})
      record: node_exporter:load:load5
      labels: 
        desc: "系统5分钟负载"
        unit: " "
        job: "node-exporter"

    - expr: sum by (instance) (node_load15{job="node-exporter"})
      record: node_exporter:load:load15
      labels: 
        desc: "系统15分钟负载"
        unit: " "
        job: "node-exporter"
   
##############################################################################################
#                                 disk                                                       #
    - expr: node_filesystem_size_bytes{job="node-exporter" ,fstype=~"ext4|xfs"}
      record: node_exporter:disk:usage:total
      labels: 
        desc: "节点的磁盘总量"
        unit: byte
        job: "node-exporter"

    - expr: node_filesystem_avail_bytes{job="node-exporter",fstype=~"ext4|xfs"}
      record: node_exporter:disk:usage:free
      labels: 
        desc: "节点的磁盘剩余空间"
        unit: byte
        job: "node-exporter"

    - expr: node_filesystem_size_bytes{job="node-exporter",fstype=~"ext4|xfs"} - node_filesystem_avail_bytes{job="node-exporter",fstype=~"ext4|xfs"}
      record: node_exporter:disk:usage:used
      labels: 
        desc: "节点的磁盘使用的空间"
        unit: byte
        job: "node-exporter"

    - expr:  (1 - node_filesystem_avail_bytes{job="node-exporter",fstype=~"ext4|xfs"} / node_filesystem_size_bytes{job="node-exporter",fstype=~"ext4|xfs"}) * 100 
      record: node_exporter:disk:used:percent    
      labels: 
        desc: "节点的磁盘的使用百分比"
        unit: "%"
        job: "node-exporter"

    - expr: irate(node_disk_reads_completed_total{job="node-exporter"}[1m])
      record: node_exporter:disk:read:count:rate
      labels: 
        desc: "节点的磁盘读取速率"
        unit: "次/秒"
        job: "node-exporter"

    - expr: irate(node_disk_writes_completed_total{job="node-exporter"}[1m])
      record: node_exporter:disk:write:count:rate
      labels: 
        desc: "节点的磁盘写入速率"
        unit: "次/秒"
        job: "node-exporter"

    - expr: (irate(node_disk_written_bytes_total{job="node-exporter"}[1m]))/1024/1024
      record: node_exporter:disk:read:mb:rate
      labels: 
        desc: "节点的设备读取MB速率"
        unit: "MB/s"
        job: "node-exporter"

    - expr: (irate(node_disk_read_bytes_total{job="node-exporter"}[1m]))/1024/1024
      record: node_exporter:disk:write:mb:rate
      labels: 
        desc: "节点的设备写入MB速率"
        unit: "MB/s"
        job: "node-exporter"

##############################################################################################
#                                filesystem                                                  #
    - expr:   (1 -node_filesystem_files_free{job="node-exporter",fstype=~"ext4|xfs"} / node_filesystem_files{job="node-exporter",fstype=~"ext4|xfs"}) * 100 
      record: node_exporter:filesystem:used:percent    
      labels: 
        desc: "节点的inode的剩余可用的百分比"
        unit: "%"
        job: "node-exporter"
#############################################################################################
#                                filefd                                                     #
    - expr: node_filefd_allocated{job="node-exporter"}
      record: node_exporter:filefd_allocated:count
      labels: 
        desc: "节点的文件描述符打开个数"
        unit: "%"
        job: "node-exporter"
 
    - expr: node_filefd_allocated{job="node-exporter"}/node_filefd_maximum{job="node-exporter"} * 100 
      record: node_exporter:filefd_allocated:percent
      labels: 
        desc: "节点的文件描述符打开百分比"
        unit: "%"
        job: "node-exporter"

#############################################################################################
#                                network                                                    #
    - expr: avg by (environment,instance,device) (irate(node_network_receive_bytes_total{device=~"eth0|eth1|ens33|ens37"}[1m]))
      record: node_exporter:network:netin:bit:rate
      labels: 
        desc: "节点网卡eth0每秒接收的比特数"
        unit: "bit/s"
        job: "node-exporter"

    - expr: avg by (environment,instance,device) (irate(node_network_transmit_bytes_total{device=~"eth0|eth1|ens33|ens37"}[1m]))
      record: node_exporter:network:netout:bit:rate
      labels: 
        desc: "节点网卡eth0每秒发送的比特数"
        unit: "bit/s"
        job: "node-exporter"

    - expr: avg by (environment,instance,device) (irate(node_network_receive_packets_total{device=~"eth0|eth1|ens33|ens37"}[1m]))
      record: node_exporter:network:netin:packet:rate
      labels: 
        desc: "节点网卡每秒接收的数据包个数"
        unit: "个/秒"
        job: "node-exporter"

    - expr: avg by (environment,instance,device) (irate(node_network_transmit_packets_total{device=~"eth0|eth1|ens33|ens37"}[1m]))
      record: node_exporter:network:netout:packet:rate
      labels: 
        desc: "节点网卡发送的数据包个数"
        unit: "个/秒"
        job: "node-exporter"

    - expr: avg by (environment,instance,device) (irate(node_network_receive_errs_total{device=~"eth0|eth1|ens33|ens37"}[1m]))
      record: node_exporter:network:netin:error:rate
      labels: 
        desc: "节点设备驱动器检测到的接收错误包的数量"
        unit: "个/秒"
        job: "node-exporter"

    - expr: avg by (environment,instance,device) (irate(node_network_transmit_errs_total{device=~"eth0|eth1|ens33|ens37"}[1m]))
      record: node_exporter:network:netout:error:rate
      labels: 
        desc: "节点设备驱动器检测到的发送错误包的数量"
        unit: "个/秒"
        job: "node-exporter"
      
    - expr: node_tcp_connection_states{job="node-exporter", state="established"}
      record: node_exporter:network:tcp:established:count
      labels: 
        desc: "节点当前established的个数"
        unit: "个"
        job: "node-exporter"

    - expr: node_tcp_connection_states{job="node-exporter", state="time_wait"}
      record: node_exporter:network:tcp:timewait:count
      labels: 
        desc: "节点timewait的连接数"
        unit: "个"
        job: "node-exporter"

    - expr: sum by (environment,instance) (node_tcp_connection_states{job="node-exporter"})
      record: node_exporter:network:tcp:total:count
      labels: 
        desc: "节点tcp连接总数"
        unit: "个"
        job: "node-exporter"
   
#############################################################################################
#                                process                                                    #
    - expr: node_processes_state{state="Z"}
      record: node_exporter:process:zoom:total:count
      labels: 
        desc: "节点当前状态为zoom的个数"
        unit: "个"
        job: "node-exporter"
#############################################################################################
#                                other                                                    #
    - expr: abs(node_timex_offset_seconds{job="node-exporter"})
      record: node_exporter:time:offset
      labels: 
        desc: "节点的时间偏差"
        unit: "s"
        job: "node-exporter"

#############################################################################################
   
    - expr: count by (instance) ( count by (instance,cpu) (node_cpu_seconds_total{ mode='system'}) ) 
      record: node_exporter:cpu:count
```

