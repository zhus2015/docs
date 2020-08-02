# Docker的安装配置及使用详解

## **基本概念**

Docker 包括三个基本概念

- 镜像（Image）
- 容器（容器）
- 仓库（Repository）

先理解了这三个概念，就理解了 Docker 的整个生命周期。



## **1、Docker安装与启动**

> 安装docker

配置阿里云源：

```sh
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
yum makacache fast
```

> 安装docker

```sh
yum install docker-ce 
```

> 启动docker

```sh
systemctl start docker
```



> 镜像仓库配置

```
1.Docker官方的中央仓库：这个仓库是镜像最全的，但是下载速度较慢，但是可以使用阿里云免费的镜像加速服务
https://hub.docker.com/
2.国内的镜像网站：网易蜂巢，daoCloud等，下载速度快，但是镜像相对不全。
https://c.163yun.com/hub#/home 
http://hub.daocloud.io/ （推荐使用）

#需要创建 /etc/docker/daemon.json，并添加如下内容
{
	"registry-mirrors":["https://registry.docker-cn.com"],
	"insecure-registries":["ip:port"]  #公司私服
}

#重启两个服务
systemctl daemon-reload
systemctl restart docker
```



## **2、镜像的获取与容器的使用**

### 2.1、镜像查看

> 搜索镜像 在docker index中搜索image

```
docker search <image> 
```

> 下载镜像 从docker registry server 中下拉image

```
docker pull <image>  
```

> 查看镜像

```
docker images： 
```

> 列出images 列出所有的images（包含历史）

```
docker images -a 
```

> 删除一个或多个image

```
docker rmi  <image ID>： 
```

> 使用镜像创建容器

```
docker run -i -t sauloal/ubuntu14.04
```

> 创建一个容器，让其中运行 bash 应用，退出后容器关闭

```
docker run -i -t sauloal/ubuntu14.04 /bin/bash
```

### 2.2、查看容器

> 列出当前所有正在运行的容器

```
docker ps 
```

> 列出最近一次启动的容器

```
docker ps -l
```

> 列出所有的容器（包含历史，即运行过的容器）

```
docker ps -a
```

> 列出最近一次运行的容器 ID

```
docker ps -q
```

> 开启/停止/重启

```
docker start/stop/restart 容器ID
```

> 连接一个正在运行的容器实例（即实例须为start状态，可以多个窗口同时attach 一个容器实例）

```
docker attach  容器ID
```

> 启动一个容器并进入交互模式（相当于先 start，在attach）

```
docker start -i 容器ID
```

> 使用image创建容器并进入交互模式, login shell是/bin/bash

```
docker run -i -t 镜像ID /bin/bash
```

> 映射 HOST 端口到容器，方便 外部访问容器内服务，host_port 可以省略，省略表示把 容器_port 映射到一个动态端口

```
docker run -i -t -p 主机端口:容器端口
```

注：使用start是启动已经创建过得容器，使用run则通过image开启一个新的容器。

> 删除一个或多个容器

```
docker rm 容器ID
```

> 删除所有已停止的容器，正在运行的容器需要先停止才能删除

```shell
$ docker rm `docker ps -a -q` 
$ docker ps -a -q | xargs docker rm
```



### 2.3、创建一个容器

- -d 后台运行

#### 端口映射

- **-P :**是容器内部端口**随机**映射到主机的高端口。
- **-p :** 是容器内部端口绑定到**指定**的主机端口。

> 随机将容器的端口映射

```shell
$ docker run -d -P tomcat:v8.5.51
```

> 指定端口映射

```shell
$ docker run -d -p 8080:8080 tomcat:v8.5.51
```



#### 文件挂载

-v <host>:<容器>:[rw|ro]

```shell
$ docker run -d -p 8080:8080 -v /data/tomcat_logs:/opt/tomcat/logs tomcat:v8.5.51
```



## 3、持久化容器与镜像

### 3.1、通过容器生成新的镜像

运行中的镜像称为容器。你可以修改容器（比如删除一个文件），但这些修改不会影响到镜像。不过，你使用docker commit 命令可以把一个正在运行的容器变成一个新的镜像。

将一个容器固化为一个新的image，后面的repo:tag可选。

```
docker commit <容器> [repo:tag]
```

### **3.2、持久化容器**(导出容器)

export命令用于持久化容器

```
docker export <容器 ID> > /tmp/export.tar
```

### 3.3、持久化镜像(导出镜像)

Save命令用于持久化（导出）镜像

```
docker save 镜像ID > /tmp/save.tar
```

### 3.4、导入持久化容器

> 导入export.tar文件

```
cat /tmp/export.tar | docker import - export:latest
```

### 3.5、导入持久化image

> 导入本地镜像文件

```
docker load < /tmp/save.tar
```

>  修改镜像名称

命令格式`docker tag  IMAGE_ID REPOSITORY:TAG`

```sh
docker tag daa11948e23d tomcat:8.5
```

### 3.6、export-import与save-load的区别

导出后再导入(export-import)的镜像会丢失所有的历史，而保存后再加载（save-load）的镜像没有丢失历史和层(layer)。这意味着使用导出后再导入的方式，你将无法回滚到之前的层(layer)，同时，使用保存后再加载的方式持久化整个镜像，就可以做到层回滚。（可以执行docker tag 来回滚之前的层）。

### 3.7、一些其它命令

docker logs $容器_ID #查看docker实例运行日志，确保正常运行 docker inspect $容器_ID #docker inspect <image|容器> 查看image或容器的底层信息 docker build <path> 寻找path路径下名为的Dockerfile的配置文件，使用此配置生成新的image docker build -t repo[:tag] 同上，可以指定repo和可选的tag docker build - < <dockerfile> 使用指定的dockerfile配置文件，docker以stdin方式获取内容，使用此配置生成新的image docker port <容器> <容器 port> 查看本地哪个端口映射到容器的指定端口，其实用docker ps 也可以看到

**一些使用技巧**

**docker文件存放目录**

Docker实际上把所有东西都放到/var/lib/docker路径下了。

[root@localhost docker]# ls -F

容器s/ devicemapper/ execdriver/ graph/ init/ linkgraph.db repositories-devicemapper volumes/

容器s目录当然就是存放容器（容器）了，graph目录存放镜像，文件层（file system layer）存放在graph/imageid/layer路径下，这样我们就可以看看文件层里到底有哪些东西，利用这种层级结构可以清楚的看到文件层是如何一层一层叠加起来的。