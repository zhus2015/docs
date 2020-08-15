# Redis集群

!!! Tip “文档内容来源 https://blog.csdn.net/miss1181248983/article/details/90056960，如有侵权请联系删除”

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



## Sentinel模式

> Sentine模式特点

- sentinel模式是建立在主从模式的基础上，如果只有一个Redis节点，sentinel就没有任何意义 
- 当master挂了以后，sentinel会在slave中选择一个做为master，并修改它们的配置文件，其他slave的配置文件也会被修改，比如slaveof属性会指向新的master 
-  当master重新启动后，它将不再是master而是做为slave接收新的master的同步数据
- sentinel因为也是一个进程有挂掉的可能，所以sentinel也会启动多个形成一个sentinel集群 
- 多sentinel配置的时候，sentinel之间也会自动监控
- 当主从模式配置密码时，sentinel也会同步将配置信息修改到配置文件中，不需要担心 
- 一个sentinel或sentinel集群可以管理多个主从Redis，多个sentinel也可以监控同一个redis 
- sentinel最好不要和Redis部署在同一台机器，不然Redis的服务器挂了以后，sentinel也挂了



>  Sentinel工作模式机制

- 每个sentinel以每秒钟一次的频率向它所知的master，slave以及其他sentinel实例发送一个 PING 命令  
- 如果一个实例距离最后一次有效回复 PING 命令的时间超过 down-after-milliseconds 选项所指定的值， 则这个实例会被sentinel标记为主观下线。
- 如果一个master被标记为主观下线，则正在监视这个master的所有sentinel要以每秒一次的频率确认master的确进入了主观下线状态 
- 当有足够数量的sentinel（大于等于配置文件指定的值）在指定的时间范围内确认master的确进入了主观下线状态， 则master会被标记为客观下线
- 在一般情况下， 每个sentinel会以每 10 秒一次的频率向它已知的所有master，slave发送 INFO 命令 
-  当master被sentinel标记为客观下线时，sentinel向下线的master的所有slave发送 INFO 命令的频率会从 10 秒一次改为 1 秒一次
-  若没有足够数量的sentinel同意master已经下线，master的客观下线状态就会被移除；  若master重新向sentinel的 PING 命令返回有效回复，master的主观下线状态就会被移除

> Cluster模式

cluster集群特点：

* 多个redis节点网络互联，数据共享

* 所有的节点都是一主一从（也可以是一主多从），其中从不提供服务，仅作为备用

* 不支持同时处理多个key（如MSET/MGET），因为redis需要把key均匀分布在各个节点上，
  并发量很高的情况下同时创建key-value会降低性能并导致不可预测的行为
  
* 支持在线增加、删除节点

* 客户端可以连接任何一个主节点进行读写