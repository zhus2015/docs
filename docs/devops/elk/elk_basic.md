# ELK基础知识



## 文档

- elasticsearch是面向文档的，文档是所有可搜索数据的最小单位
- 文档会被序列化json格式，保存在elasticsearch中
- 每个文档都有一个UniqueID
  - ID可以自己指定
  - 这个ID也可以通过elastcisearch自动生成
- 文档的元数据，用于标注文档的相关资料
  - _index：文档所属的索引名

## 索引

type 在7.0开始，一个index只能有一个type

### 正排索引

### 倒排索引

- 单词词典
- 倒排列表
  - 倒排索引项



## RESTAPI





## 节点

生产环境建议一台机器只运行一个elasticsearch进程

### Master-eligible nodes   && Master nodes

- 每个节点启动后，默认就是一个Master eligible节点
  - 可以设置node.master.false禁止
- Master-eligible节点可以参加选主流程，成为Master节点
- 当第一个节点启动的时候，它会将自己选举为Master节点
- 每个节点上都保存了集群的状态，只有Master节点才能修改集群的状态信息
  - 集群状态，维护了一个集群中，必要的信息
    - 所有的节点信息
    - 所有的索引和其他相关的Mapping与Setting信息
    - 分片的路由信息
  - 任意节点都能修改信息会导致数据的不一致性

### Data Node && Coordinating Node

- Data Node
  - 可以保存数据的节点，叫做Data Node。负责保存分片数据。在数据扩展上起到了只管重要的作用
  - 节点启动后，默认就是数据节点，可以通过设置node.data的值为false禁止
- Coordinating Node
  - 负责接收Client的请求，将请求分发到合适的节点，最总把结果汇集到一起
  - 每个节点默认起到了Coordinating Node的职责
- 其他节点类型
  - Hot&Warm Node
    - 不同硬件配置的Data Node，用来实现Hot&Warm架构，降低集群部署成本
  - Machine Learning Node
    - 负责跑机器学习的job，用来做异常检测

### 节点类型的配置

- 开发测试环境中一个节点可以承担多种角色

- 生产环境中，应该设置单一的角色的节点

  | 节点类型          | 配置参数    | 默认值                                                  |
  | ----------------- | ----------- | ------------------------------------------------------- |
  | master eligible   | node.master | true                                                    |
  | data              | node.data   | true                                                    |
  | ingest            | node.ingest | true                                                    |
  | coordinating only | 无          | 每个节点默认都素hicoordinating节点。设置其他类型为false |
  | machine learning  | node.ml     | true（需enable x-pack）                                 |



## 分片(Primary Shard & Replica Share)

- 主分片，用以解决数据水平扩展的问题。通过主分片，可以将数据分布到集群内的所有节点上
  - 一个分片是一个运行 lucene的实例
  - 主分片数在索引创建时指定，后续不允许修改，除非Reindex
- 副本，用以解决数据高可用的问题。分片是主分片的拷贝
  - 副本分片数，可以动态调整
  - 增加副本数，还可以在一定成都上提高服务的可用性(读取的吞吐)

#### 分片的设定

- 对于生产环境中分片的设定，需要提前做好容量规划
  - 分片数设置国小
    - 导致后续无法增加节点实现水平扩展
    - 单个分派你的数据量太大，导致数据重新分配耗时较长
  - 分片数设置过大，7.0开始默认主分片为1，解决了over-sharding的问题
    - 影响搜索结果的相关性打分，影响统计结果的准确性
    - 单个节点上过多的分片，会导致资源浪费，同时也会影响性能

