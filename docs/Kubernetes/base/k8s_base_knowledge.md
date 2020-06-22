# K8S基础知识

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

  

## kubernetes集群中三种IP地址区别

Kubernetes集群里有三种IP地址，分别如下：

Node IP：Node节点的IP地址，即物理网卡的IP地址。

Pod IP：Pod的IP地址，即docker容器的IP地址，此为虚拟IP地址。

Cluster IP：Service的IP地址，此为虚拟IP地址。



### Node IP

可以是物理机的IP（也可能是虚拟机IP）。每个Service都会在Node节点上开通一个端口，外部可以通过NodeIP:NodePort即可访问Service里的Pod,和我们访问服务器部署的项目一样，IP:端口/项目名

在kubernetes查询Node IP

1.kubectl get nodes

2.kubectl describe node nodeName

3.显示出来的InternalIP就是NodeIP

![image-20200605151757780](../images/image-20200605151757780.png)



### Pod IP

Pod IP是每个Pod的IP地址，他是Docker Engine根据docker网桥的IP地址段进行分配的，通常是一个虚拟的二层网络

同Service下的pod可以直接根据PodIP相互通信

不同Service下的pod在集群间pod通信要借助于 cluster ip

pod和集群外通信，要借助于node ip

在kubernetes查询Pod IP

1.kubectl get pods

![image-20200605151909999](../images/image-20200605151909999.png)

2.kubectl describe pod podName



### Cluster IP

Service的IP地址，此为虚拟IP地址。外部网络无法ping通，只有kubernetes集群内部访问使用。

在kubernetes查询Cluster IP

kubectl -n 命名空间 get Service即可看到ClusterIP

![image-20200605151716542](../images/image-20200605151716542.png)

Cluster IP是一个虚拟的IP，但更像是一个伪造的IP网络，原因有以下几点

Cluster IP仅仅作用于Kubernetes Service这个对象，并由Kubernetes管理和分配P地址

Cluster IP无法被ping，他没有一个“实体网络对象”来响应

Cluster IP只能结合Service Port组成一个具体的通信端口，单独的Cluster IP不具备通信的基础，并且他们属于Kubernetes集群这样一个封闭的空间。

在不同Service下的pod节点在集群间相互访问可以通过Cluster IP

三种IP网络间的通信

service地址和pod地址在不同网段，service地址为虚拟地址，不配在pod上或主机上，外部访问时，先到Node节点网络，再转到service网络，最后代理给pod网络。



