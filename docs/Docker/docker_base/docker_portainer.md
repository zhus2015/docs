# 容器管理工具Portainer

Portainer是一个可视化的容器镜像的图形管理工具，利用Portainer可以轻松构建，管理和维护Docker环境。 而且完全免费，基于容器化的安装方式，方便高效部署。

官网：https://www.portainer.io/



## 实验环境

| IP         | 角色             | 备注 |
| ---------- | ---------------- | ---- |
| 10.4.7.131 | portainer-server |      |
| 10.4.7.132 | portainer-agent  |      |



## Portainer服务端部署

### Server安装部署

```shell
 # mkdir -p /data/portainer_data
 # docker run -dit -p 8000:8000 -p 9000:9000 --name=portainer --restart=always  \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v /data/portainer_data:/data \
            portainer/portainer:1.24.1
```

### Agent安装部署

```shell
# docker run -d -p 9001:9001 --name portainer_agent --restart=always \
             -v /var/run/docker.sock:/var/run/docker.sock \
             -v /var/lib/docker/volumes:/var/lib/docker/volumes \
             portainer/agent:2.0.0
```



### Edge_agent安装

边缘代理节点，一般用来管理swarm集群使用

Edge_agent的命令是添加endpoint节点的时候自动生成，拷贝出来使用即可

```
docker run -d --restart always -p 8000:80 --name portainer_edge_agent\
            -v /data/portainer_agent_data:/data \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v /var/lib/docker/volumes:/var/lib/docker/volumes \
            -v /:/host  -e EDGE=1 \
            -e EDGE_ID=6ad0f1ff-6fea-4710-97e2-513ef1066fd8 \
            -e CAP_HOST_MANAGEMENT=1 \
            portainer/agent:2.0.0
```



### 配置管理员用户

直接使用浏览器访问http://ip:9000端口即可

![image-20201112211626962](../../images/image-20201112211626962.png)

### 选择管理的类型

portainer-ce版本可以选择管理“本机Docker”、Kuberneter集群、和安装了portainer-agent客户端的机器

![image-20201112211838073](../../images/image-20201112211838073.png)



而普通版本的portainer支持通过Docker API管理其他服务器上的容器，以及支持Azure服务器

![image-20201112212327727](../../images/image-20201112212327727.png)



### 添加Agent客户端

![image-20201112213133448](../../images/image-20201112213133448.png)

添加后可以看到一台Agent客户端在线，这时我们就可以开始对这台机器上的容器进行远程管理

![image-20201112213202998](../../images/image-20201112213202998.png)





## Portainer管理swarm集群



```
# docker service create --name portainer --publish 9000:9000 \
         --constraint 'node.role == manager' \
         --mount type=bind,src=//var/run/docker.sock,dst=/var/run/docker.sock \
         portainer/portainer:1.24.1 -H unix:///var/run/docker.sock

```



```
# docker service create --name portainer_agent \
         --network portainer_agent_network \
         --mode global \
         --constraint 'node.platform.os == linux' \
         --mount type=bind,src=//var/run/docker.sock,dst=/var/run/docker.sock \
         --mount type=bind,src=//var/lib/docker/volumes,dst=/var/lib/docker/volumes \
         portainer/agent:2.0.0
```

