# ELK生产集群运维



## 集群规划

### 单一角色：职责分离

- Dedicated master eligible nodes：负责集群状态(cluster state)的管理
  - 使用低配置的CPU、RAM和磁盘
  - 从高可用&避免脑裂的角度出发(单独部署)
    - 一般生产环境中配置3台master节点
    - 一个集群只有一台活跃的主节点
      - 负责分片管理、索引创建、集群管理等操作
- Dedicated data nodes：负责数据存储及处理客户端请求
  - 使用高配置的CPU、RAM和磁盘
- Dedicated ingest nodes：负责数据处理
  - 使用高配置CPU；中等配置的RAM；低配置的磁盘
- Dedicated Coording Only Node(Client Node)
  - 配置：将Master、Data、ingest都配置成False
    - 中高配置的CPU；中高配置的RAM和低配置的磁盘
  - 生产环境中，建议为一些大的集群配置Coording Only Nodes
    - 扮演Load Balancers，降低Master和Data Nodes的负载
    - 负责搜索结果的Gather/Reduce



### Hot & Warm 架构

Hot节点使用高配置高性能磁盘

Warm节点使用低配置大容量磁盘

#### 配置Hot & Warm Architecture

- 使用Share Filtering，步骤分为以下几步
  - 标记节点（Tagging）
  - 配置索引到Hot Node
  - 配置索引到Warm节点



### 如何设计分片数

- 当分片数 > 节点数时
  - 一旦集群中有新的数据节点加入，分片就可以自动进行分配
  - 分片在重新分配时，系统就不会有downtime
- 多分片的好处：一个索引如何分布在不同的节点，多个节点可以并行执行
  - 查询可以并行执行
  - 数据写入可以分散到多个机器
- 分片数过多带来的副作用
  - Shard是Elasticsearch实现集群水平扩展的最小单位
  - 过的设置分片数会带来一些潜在的问题
    - 每个分派你是一个lucene的索引，会使用机器的资源。过多的分派你会导致额外的性能开销
      - Lucene Indices/File descriptors /RAM/CPU
      - 每次搜索的请求，需要从每个分片上获取数据
      - 分片的Meta信息由Master节点维护。过多，会增加管理的负担。经验值，控制分片总数在10W以内

### 如何确定分片数

- 从存储的物理角度看

  - 日志类应用，单个分片不要大于50G
  - 搜索类应用，单个分片不要超过20G

  > 为什么控制分片存储的大小

  - 提高update的性能
  - merge时减少所需要的资源
  - 丢失节点后，更快的恢复速度

### 如何确定副本分片数

- 副本是主分片的拷贝
  - 提高系统可用性:相应查询请求，避免数据丢失
  - 需要占用系统资源
- 对性能的影响
  - 副本会降低数据的索引速度：有几分副本就会有几倍的CPU资源消耗在索引上
  - 会减缓对主分片的查询压力，但是会消耗同样的内存资源
    - 如果机器资源充足，提高副本数量，可以提高整体查询的QPS
- 调整分片总数的设定，避免分配不均衡



### 集群容量规划



#### 硬件配置

- 合理的硬件，数据节点尽可能的使用SSD
- 搜索等性能要求高的场景，建议SSD
  - 按照1：10的比例配置内存和硬盘
- 日志类和查询并发低的场景，可以考虑使用机械硬盘存储
  - 按照1：50的比例配置内存和硬盘
- 单节点数据建议控制在2TB以内，最大不建议超过5TB
- JVM配置机器内存的一半，JVM内存配置不建议超过32G



## 集群部署最佳实践

### 网络

- 单个集群不要跨数据中心进行部署（不要使用wan）
- 节点之间hops越少越好
- 如果有多块网卡，最好将transport和http绑定到不同的网卡，并设置不同的防火墙Rules
- 按需为Coordinating Node 或 Ingrest Node配置负载均衡

### 内存

需要保留50%的内存作为全文检索使用

- 内存大小要根据Node需要存储的数据来进行估算
  - 搜索类的比例建议：1:16
  - 日志类：1:48-1:96之间
- 总数据量1T，设置一个副本=2T总数据量
  - 如果搜索类的项目，每个节点31*16=496G，加上预留空间。所以每个节点最多400G数据，至少需要5个数据节点
  - 如果是日志类项目，每个节点31*50=1550G，2个数据节点即可

### 存储

- 推荐使用SSD，使用本地存储，避免使用SAN NFS/AWS/Azure filesystem
- 可以在本地指定多个“path.data”，以支持多块磁盘
- ES本身提供了很好的HA机制，无需使用RAID1/5/10
- 可以在Warm节点上使用Spinning Disk，但是需要关闭Concurrent Merges
  - index.merge.scheduler.max_thread_count: 1
- Trim你的SSD
  - https://www.elastic.co/blog/is-your-elasticsearch-trimmed

### 服务器硬件

- 建议使用中等配置的机器，不建议使用过于强劲的硬件配置
  - Medium machine over large machine
- 不建议在一台机器上运行多个节点

### 集群设置: Throttles 限流

- 对Relocation和Recovery设置限流，避免过多任务对集群产生性能影响
- Recovery
  - Cluster.routing.allocation.node_concurrent_recoveries: 2
- Relocation
  - Cluster.routing.allocation.node_concurrent_rebalance: 2

### 集群设置：关闭Dynamic Indexes

- 可以考虑关闭动态索引创建功能
- 或者通过模板设置白名单



## 集群优化

### 监控Elasticsearch集群

### 诊断集群的潜在问题

### 解决集群Yellow和Red的问题



#### 分片没有被分配的一些原因

- INDEX_CREATE：创建索引导致，在索引的全部分片分配完成之前，会有短暂的Red，不一定代表有问题
- CLUSTER_RECOVER：集群重启阶段，会有这个问题
- INDEX_REOPEN：Open一个之前Close的索引
- DANGLING_INDEX_IMPORTED：一个节点离开集群期间，有索引删除。这个节点重新返回时，会导致Dangling的问题，重新执行删除操作即可解决



#### 常见集群问题与解决方法

- 集群变红，需要检查是否有节点离线。如果有，通常通过重启离线的节点可以解决问题
- 由于配置导致的问题，需要修复相关配置
  - 如果是测试索引，可以直接 删除
- 因为磁盘空间限制，分片规则引发的，需要调整规则或者增加节点
- 对于节点返回集群，导致的dangling变红，可直接删除dangling索引



> 集群Red & Yellow 问题总结

- Red & Yellow是集群运维中常见的问题
- 除了集群故障，一些创建，增加副本等操作，都会导致集群短暂Red和Yellow，所以监控和报警时需要设置一定的延时
- 通过检查节点数，使用ES提供的相关API，找到真正的原因
- 可以指定Move或者Reallocate分片

### 提升集群写性能

> 提高写性能优化的目标：增大写吞吐量，越高越好

#### 客户端

- 多线程，批量写
  - 可以通过性能测试，确定最佳文档数量
  - 多线程：需要观察是否有HTTP429返回，实现Retry以及线程数量的自动调节

#### 服务端

- 单个性能问题，往往时多个因素造成的。需要先分解问题，在单个节点上进行调整并且结合测试，尽可能压榨硬件资源，以达到最高吞吐量

  - 使用更好的硬件，观察CPU/IO Block
  - 线程切换/堆栈状况

- 减低IO操作

  - 使用ES自动生成的文档ID/一些相关的ES配置，如：Refresh intreval

- 降低CPU和存储的开销

  - 减少不必要的分词/避免不需要的dec_values/文档的字段尽量保证相同的顺序，可以提高文档的压缩率

- 尽可能做到写入和分片的均衡负载，实现水平扩展

  - Shard Filtering/Write Load Balancer

- 调整Bulk线程池和队列

  

> 文档建模的最佳实践

- 只需要聚合不需要搜索，index设置成false
- 不需要算分，Norms设置成false
- 不要对字符串使用默认的dynamic mapping。字段数量过多，会对性能产生比较大的影响
- Index_options控制在创建倒排索引时，那些内容会被添加到倒排索引中。优化这些设置，一定程度可以节约CPU
- 关闭_source，减少IO操作；（适合指标性数据）



### 提升集群读性能

#### 尽量使用Denormalize数据

- Elasticsearch !=关系型数据库
- 尽可能Denormalize数据，从而获取最佳的性能
  - 使用Nested类性的数据。查询速度会慢几倍
  - 使用Parent/Child关系。查询速度会慢几百倍

#### 数据建模

- 尽量将数据先行计算，然后保存到Elasticsearch中。尽量避免查询时的Script计算
- 尽量使用Fileter Context，利用缓存机制，减少不必要的算分
- 结合profile，explain API分析慢查询的问题，持续优化数据模型
  - 严谨使用*开头通配符Terms查询



### 集群压力测试

#### 测试方法及步骤

- 测试方法步骤
  - 测试计划
  - 脚本开发
  - 测试环境搭建
  - 分析比较结果

#### 测试目标&测试数据

- 测试目标
  - 测试集群的读写性能/做集群容量的规划
  - 对ES配置参数进行修改，评估优化效果
  - 修改Mapping和Setting，对数据建模进行优化，并测试评估性能改进
  - 测试ES新版本，结合实际场景和老版本进行比较，评估是否进行升级
- 测试数据
  - 数据量/数据分布

#### 测试脚本

- ES本身提供了REST API，所以，可以通过很多传统的性能测试工具

  - Load Runner(商业软件，支持录制+重放+DSL)
  - JMeter(Apache开源，Record&Play)
  - Gatling(开源，支持Scala代码+DSL)

- 专门为Elasticsearch设计的工具

  - ES Pref & Elasticsearch-stress-test
  - Elastic Rally
    - 官方开源，https://github.com/elastic/rally

  



## 运维建议

### 集群的生命周期管理

- 预上线
  - 评估用户的需求及使用场景/数据建模/容量规划/选择合适的部署架构/性能测试
- 上线
  - 监控流量/定期检查潜在问题（防患于未然，发现错误的使用方式，及时增加机器）
  - 对索引进行优化，检测是否存在不均衡而导致有部分节点过热
  - 定期数据备份/滚动升级
- 下架前监控流量，实现Stage Decomminssion



### 部署建议

- 根据实际场景，选择合适的部署方式，选择合理的硬件配置
  - 搜索类
  - 日志/指标
- 部署要考虑，反亲和性
  - 尽量将机器分散在不同的机架上，例如，3台master节点必须分散在不同的机架上
  - 善用Shard Filtering进行配置

- 设置Slowlogs，发现一些性能不好，甚至是错误使用的Pattern
- 集群备份，定期对集群数据进行备份
- 定期更新ES版本