# Redis集群

!!! Tip “文档内容来源 https://blog.csdn.net/miss1181248983/article/details/90056960，如有侵权请联系删除”

Redis官网：https://redis.io/

Redis集群有三种模式：

- 主从模式
- Sentinel模式
- Cluster模式

## 主从模式

主从模式数据库分两类：主数据和(master)从数据库(slave)

主从模式有一下特点：

-  主数据库可以进行读写操作，当读写操作导致数据变化时会自动将数据同步给从数据库
-  从数据库一般都是只读的，并且接收主数据库同步过来的数据
-  一个master可以拥有多个slave，但是一个slave只能对应一个master
- slave挂了不影响其他slave的读和master的读和写，重新启动后会将数据从master同步过来
-  master挂了以后，不影响slave的读，但redis不再提供写服务，master重启后redis将重新对外提供写服务
- master挂了以后，不会在slave节点中重新选一个master



## Cluster模式



### Cluster模式搭建

#### 环境准备

操作系统：Centos 7.7

Redis：5.0.9

| IP        | 端口        | 作用                 |
| --------- | ----------- | -------------------- |
| 10.4.7.41 | 6341，16341 | 每台机器启动两个实例 |
| 10.4.7.42 | 6342，16342 | 每台机器启动两个实例 |
| 10.4.7.43 | 6343，16343 | 每台机器启动两个实例 |



#### 安装redis

> 所有redis使用二进制的方式部署，这里仅用一台机器的操作为例
>
> 这里我提前将redis的二进制软件包放到了/usr/local/src目录下

```sh
[root@localhost src]# cd /usr/loca/src
[root@localhost src]# tar zxvf redis-5.0.9.tar.gz
[root@localhost src]# yum install -y gcc jemalloc jemalloc-devel tcl
[root@localhost src]# cd redis-5.0.9/deps
[root@localhost deps]# make hiredis jemalloc linenoise lua
[root@localhost deps]# cd ..
[root@localhost redis-5.0.9]# make PREFIX=/usr/local/redis install
[root@localhost src]# mv redis-5.0.9 /usr/local/redis
```



#### 修改配置文件

> 10.4.7.41

```sh
[root@localhost src]# cd /usr/local/redis
[root@localhost redis]# mkdir cluster
[root@localhost redis]# cp redis.conf cluster/redis_6341.conf
[root@localhost redis]# cp redis.conf cluster/redis_16341.conf
[root@localhost redis]# mkdir -p /data/redis/cluster/{redis_6341,redis_16341}
[root@localhost redis]# vi cluster/redis_6341.conf
bind 10.4.7.41
port 6341
daemonize yes
pidfile "/var/run/redis_6341.pid"
logfile "/usr/local/redis/cluster/redis_6341.log"
dir "/data/redis/cluster/redis_6341"
masterauth 123456
requirepass 123456
appendonly yes
cluster-enabled yes
cluster-config-file nodes_6341.conf

[root@localhost redis]# vi cluster/redis_16341.conf
bind 10.4.7.41
port 16341
daemonize yes
pidfile "/var/run/redis_16341.pid"
logfile "/usr/local/redis/cluster/redis_16341.log"
dir "/data/redis/cluster/redis_16341"
masterauth 123456
requirepass 123456
appendonly yes
cluster-enabled yes
cluster-config-file nodes_16341.conf
```



> 10.4.7.42

```
[root@localhost src]# cd /usr/local/redis
[root@localhost redis]# mkdir cluster
[root@localhost redis]# cp redis.conf cluster/redis_6342.conf
[root@localhost redis]# cp redis.conf cluster/redis_16342.conf
[root@localhost redis]# mkdir -p /data/redis/cluster/{redis_6342,redis_16342}
[root@localhost redis]# vi cluster/redis_6341.conf
bind 10.4.7.42
port 6342
daemonize yes
pidfile "/var/run/redis_6342.pid"
logfile "/usr/local/redis/cluster/redis_6342.log"
dir "/data/redis/cluster/redis_6342"
masterauth 123456
requirepass 123456
appendonly yes
cluster-enabled yes
cluster-config-file nodes_6342.conf

[root@localhost redis]# vi cluster/redis_16342.conf
bind 10.4.7.42
port 16342
daemonize yes
pidfile "/var/run/redis_16342.pid"
logfile "/usr/local/redis/cluster/redis_16342.log"
dir "/data/redis/cluster/redis_16342"
masterauth 123456
requirepass 123456
appendonly yes
cluster-enabled yes
cluster-config-file nodes_16342.conf
```

> 10.4.7.43

```
[root@localhost src]# cd /usr/local/redis
[root@localhost redis]# mkdir cluster
[root@localhost redis]# cp redis.conf cluster/redis_6343.conf
[root@localhost redis]# cp redis.conf cluster/redis_16343.conf
[root@localhost redis]# mkdir -p /data/redis/cluster/{redis_6342,redis_16343}
[root@localhost redis]# vi cluster/redis_6343.conf
bind 10.4.7.43
port 6343
daemonize yes
pidfile "/var/run/redis_6343.pid"
logfile "/usr/local/redis/cluster/redis_6343.log"
dir "/data/redis/cluster/redis_6343"
masterauth 123456
requirepass 123456
appendonly yes
cluster-enabled yes
cluster-config-file nodes_6343.conf

[root@localhost redis]# vi cluster/redis_16343.conf
bind 10.4.7.43
port 16343
daemonize yes
pidfile "/var/run/redis_16343.pid"
logfile "/usr/local/redis/cluster/redis_16343.log"
dir "/data/redis/cluster/redis_16343"
masterauth 123456
requirepass 123456
appendonly yes
cluster-enabled yes
cluster-config-file nodes_16343.conf
```

#### 启动redis

