# K8S基础概述

!!! tip "部分资料参考：Kubernetes权威指南第四版"



## k8s的组成

Master：集群控制节点，提供HTTP REST服务

Kuber-apiserver：集群控制入口

Kube-controller-manager：资源对象自动化控制中心。

Kube-scheduler：pod调度

Node：工作节点，主要是运行容器应用

kubelet：负责Pod的创建、启动、监控、重启、销毁等工作，与master节点协作，实现集群管理	的基本功能

kube-proxy：负责kubernetes service的通信和负载均衡

Pod：Pod是kubernetes最基本的部署调度单元，每个pod可以有一个或多个业务容器和一个根容器(Pause容器)组成。一个Pod表示某一个应用的一个实例

ReplicaSet：是Pod副本的抽象，用于解决Pod的扩容和伸缩

Deployment：Deployment表示部署，在内部使用ReplicaSet来实现。可以通过Deployment来生成相对应的ReplicaSet完成Pod副本的创建

Service：Service是Kubernetes最重要的资源对象。Kubernetes中的Service对象可以对应微服务架构中的微服务。Service定义了服务的访问入口，服务的调用者通过这个地址访问Service后端的Pod副本实例。Service通过Label Selector同后台端的Pod副本建立关系，Deployment保证后端Pod副本的数量，也就是保证服务的伸缩性。

Kubernetes主要以下几个核心组件组成：

- etcd  保存了整个集群的状态，就是一个数据库
- apiserver  提供了资源操作的唯一入口，并提供认证、授权、访问控制、API注册和发现等机制；
- controller manager 负责维护集群的状态，比如故障检测、自动扩展、滚动更新等；
- scheduler 负责资源的调度，按照预定的调度策略将Pod调度到相应的机器上；
- kubelet 负责维护容器的声明周期，同时也负责Volume(CSI)和网络(CNI)的管理；
- Container runtime 负责镜像管理以及Pod和容器的真正运行（CRI）；
- kube-proy 负责为Service提供cluster内部的服务发现和负载均衡；

 还有一些推荐插件

- kube-dns 负责为整个集群提供DNS服务
- Ingress Controller 为服务提供外网入口
- Heapster 提供资源监控
- Dashboard提供GUI



## Master

​	Kubernetes里的Master指的是集群控制节点，在每个kubernetes集群里都需要有一个Master来负责整个集群的管理和控制，基本上kubernetes的所有控制命令都发给它，它负责具体的执行过程。Master通常会占据一个独立的服务器（高可用部署建议使用3台服务器），主要原因是它太重要了，是整个集群的”首脑“，如果它宕机或者不可用，那么对集群内容器应用的管理都将失效

​	在master上一般运行着以下关键进程。

- Kubernetes API Server（kube-apiserver）：提供了HTTP Rest接口的关键服务进程，是Kubernetes里所有资源的增、删、改、查等操作的唯一入口，也是集群控制的入口进程。

- Kubernetes Controller Manager（kube-controller-manager）：Kunernetes里所有资源对象的自动化控制中心，可以将其理解为资源对象的”大总管“。

- Kubernetes Scheduler（Kube-scheduler）：负责资源调度（Pod调度）的进程，相当于公交公司的”调度室“。

  另外，在Master节点上还需要部署etcd服务，因为Kubernetes里的所有资源对象的数据都被保存在etcd中。



## Node

​	除了Master，Kubernetes集群中的其他机器被称为Node，在较早的 版本中也被称为Minion。与Master一样，Node可以是一台物理主机，也 可以是一台虚拟机。Node是Kubernetes集群中的工作负载节点，每个 Node都会被Master分配一些工作负载（Docker容器），当某个Node宕机时，其上的工作负载会被Master自动转移到其他节点上。

​	在每个Node上都运行着以下关键进程。 

- kubelet：负责Pod对应的容器的创建、启停等任务，同时与Master密切协作，实现集群管理的基本功能。 

-  kube-proxy：实现Kubernetes Service的通信与负载均衡机制的重要组件。 

- Docker Engine（docker）：Docker引擎，负责本机的容器创建 和管理工作。 

  Node可以在运行期间动态增加到Kubernetes集群中，前提是在这个 节点上已经正确安装、配置和启动了上述关键进程，在默认情况下kubelet会向Master注册自己，这也是Kubernetes推荐的Node管理方式。 一旦Node被纳入集群管理范围，kubelet进程就会定时Master汇报自身的情报，例如操作系统、Docker版本、机器的CPU和内存情况，以及当 前有哪些Pod在运行等，这样Master就可以获知每个Node的资源使用情况，并实现高效均衡的资源调度策略。而某个Node在超过指定时间不上 报信息时，会被Master判定为“失联”，Node的状态被标记为不可用（Not Ready），随后Master会触发“工作负载大转移”的自动流程。 

  

## Label





## Replication Controller

简称RC,RC是Kubernetes系统中的核心概念之一，简单来说，它其实定义了 

一个期望的场景，即声明某种Pod的副本数量在任意时刻都符合某个预期值，所以RC的定义包括如下几个部分。 

- Pod期待的副本数量。 

- 用于筛选目标Pod的Label Selector。 

- 当Pod的副本数量小于预期数量时，用于创建新Pod的Pod模板（template）

下面是一个完整的RC定义的例子，即确保拥有tier=frontend标签的这个Pod（运行Tomcat容器）在整个Kubernetes集群中始终只有一个副本：

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: frontend
spec:
  replicas: 1
  selector:
    tier: frontend
  template:
    metadata:
      labels:
        app: app-demo
        tier: frontend
    spec:
      containers:
      - name: tomcat-demo
        image: tomcat
        imagePullPolicy: IfNotPresent
        env:
        - name: GET_HOSTS_FROM
          value: dns
        ports:
        - containerPort: 80
```

在我们定义了一个RC并将其提交到Kubernetes集群中后，Master上的Controller Manager组件就得到通知，定期巡检系统中当前存活的目标Pod，并确保目标Pod实例的数量刚好等于此RC的期望值，如果有过多的Pod副本在运行，系统就会停掉一些Pod，否则系统会再自动创建一些 Pod。可以说，通过RC，Kubernetes实现了用户应用集群的高可用性，并且大大减少了系统管理员在传统IT环境中需要完成的许多手工运维工作（如主机监控脚本、应用监控脚本、故障恢复脚本等）。

需要注意的是，删除RC并不会影响通过该RC已创建好的Pod。为了删除所有Pod，可以设置replicas的值为0，然后更新该RC。另外，kubectl提供了stop和delete命令来一次性删除RC和RC控制的全部Pod。



## Deployment

Deployment是Kubernetes在1.2版本中引入的新概念，用于更好地解 决Pod的编排问题。为此，Deployment在内部使用了Replica Set来实现目的，无论从Deployment的作用与目的、YAML定义，还是从它的具体命令行操作来看，我们都可以把它看作RC的一次升级，两者的相似度超 过90%。

Deployment相对于RC的一个最大升级是我们可以随时知道当前Pod“部署”的进度。实际上由于一个Pod的创建、调度、绑定节点及在目 标Node上启动对应的容器这一完整过程需要一定的时间，所以我们期待系统启动N个Pod副本的目标状态，实际上是一个连续变化的“部署过 程”导致的最终状态。 

Deployment的典型使用场景有以下几个。 

- 创建一个Deployment对象来生成对应的Replica Set并完成Pod副本的创建。 

- 检查Deployment的状态来看部署动作是否完成（Pod副本数量是否达到预期的值）。 

- 更新Deployment以创建新的Pod（比如镜像升级）。◎ 如果当前Deployment不稳定，则回滚到一个早先的Deployment版本。

- 暂停Deployment以便于一次性修改多个PodTemplateSpec的配置项，之后再恢复Deployment，进行新的发布。 

- 扩展Deployment以应对高负载。 

- 查看Deployment的状态，以此作为发布是否成功的指标。 

- 清理不再需要的旧版本ReplicaSets。 