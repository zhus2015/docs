# K8S存储相关知识

!!! tip "部分资料参考：Kubernetes权威指南第四版"

​	PV是对底层网络共享存储的抽象，将共享存储定义为一种“资源”，比如Node也是一种容器应用可以“消费”的资源。PV由管理员创建和配置，它与共享存储的具体实现直接相关，例如GlusterFS、iSCSI、RBD或GCE或AWS公有云提供的共享存储，通过插件式的机制完成与共享存储的对接，以供应用访问和使用。 

​	PVC则是用户对存储资源的一个“申请”。就像Pod“消费”Node的资源一样，PVC能够“消费”PV资源。PVC可以申请特定的存储空间和访问模式。





## PV



```

```

