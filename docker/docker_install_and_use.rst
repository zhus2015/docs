Docker的安装配置及使用详解
==========================


**基本概念**
------------

Docker 包括三个基本概念

-  镜像（Image）

-  容器（Container）

-  仓库（Repository）

先理解了这三个概念，就理解了 Docker 的整个生命周期。


**docker安装与启动**
-----------------------

安装docker

配置阿里云源：

.. code:: shell

   wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo

..

安装docker

.. code:: shell

   yum install docker-ce 

..

启动docker

.. code:: 

   systemctl start docker



**镜像的获取与容器的使用**
-----------------------------

搜索镜像 在docker index中搜索image

.. code:: 

   docker search <image> 

..

下载镜像 从docker registry server 中下拉image

.. code:: 

   docker pull <image>  

..

查看镜像

.. code:: 

   docker images： 

..

列出images 列出所有的images（包含历史）

.. code:: 

   docker images -a 

..

删除一个或多个image

.. code:: 

     docker rmi  <image ID>： 

..

使用镜像创建容器

.. code:: 

   docker run -i -t sauloal/ubuntu14.04

..

创建一个容器，让其中运行 bash 应用，退出后容器关闭

.. code:: 

    docker run -i -t sauloal/ubuntu14.04 /bin/bash #   

查看容器

列出当前所有正在运行的container

.. code:: 

   docker ps 

..

列出最近一次启动的container

.. code:: 

   docker ps -l

..

列出所有的container（包含历史，即运行过的container）

.. code:: 

   docker ps -a

..

列出最近一次运行的container ID

.. code:: 

   docker ps -q

开启/停止/重启

.. code:: 

   docker start/stop/restart <container>

..


连接一个正在运行的container实例（即实例须为start状态，可以多个窗口同时attach一个container实例）

.. code:: 

   docker attach [container_id] 

..

启动一个container并进入交互模式（相当于先 start，在attach）

.. code:: 

   docker start -i <container>

..

使用image创建container并进入交互模式, login shell是/bin/bash

.. code:: 

   docker run -i -t <image> /bin/bash

..

映射 HOST 端口到容器，方便 外部访问容器内服务，host\ *port可以省略，省略表示把 container*\ port 映射到一个动态端口

.. code:: 

   docker run -i -t -p <host_port:contain_port> 

注：使用start是启动已经创建过得container，使用run则通过image开启一个新的container。

删除一个或多个container

.. code:: 

   docker rm <container...>

删除所有的container

.. code:: 

   docker rm `docker ps -a -q` 
   docker ps -a -q | xargs docker rm


持久化容器与镜像
-------------------

通过容器生成新的镜像
~~~~~~~~~~~~~~~~~~~~~~~~~

运行中的镜像称为容器。你可以修改容器（比如删除一个文件），但这些修改不会影响到镜像。不过，你使用docker
commit 命令可以把一个正在运行的容器变成一个新的镜像。

将一个container固化为一个新的image，后面的repo:tag可选。

.. code:: 

   docker commit <container> [repo:tag]



持久化容器**
~~~~~~~~~~~~~~~~~~~

export命令用于持久化容器

.. code:: 

   docker export <CONTAINER ID> > /tmp/export.tar


持久化镜像
~~~~~~~~~~~~~~~

Save命令用于持久化镜像

.. code:: 

   docker save 镜像ID > /tmp/save.tar


导入持久化container
~~~~~~~~~~~~~~~~~~~~~~~~

删除container 2161509ff65e

.. code:: 

   docker rm 2161509ff65e

导入export.tar文件

.. code:: 

   cat /tmp/export.tar | docker import - export:latest


导入持久化image
~~~~~~~~~~~~~~~~~~~~

删除image daa11948e23d

.. code:: 

   docker rmi daa11948e23d

导入save.tar文件

.. code:: 

   docker load < /tmp/save.tar

对image打tag

.. code:: 

   docker tag daa11948e23d load:tag


export-import与save-load的区别
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

导出后再导入(export-import)的镜像会丢失所有的历史，而保存后再加载（save-load）的镜像没有丢失历史和层(layer)。这意味着使用导出后再导入的方式，你将无法回滚到之前的层(layer)，同时，使用保存后再加载的方式持久化整个镜像，就可以做到层回滚。（可以执行docker
tag 来回滚之前的层）。


一些其它命令
~~~~~~~~~~~~~~~~~

docker logs $CONTAINER\ *ID #查看docker实例运行日志，确保正常运行 docker
inspect $CONTAINER*\ ID #docker inspect <image|container>
查看image或container的底层信息 docker build
寻找path路径下名为的Dockerfile的配置文件，使用此配置生成新的image docker
build -t repo[:tag] 同上，可以指定repo和可选的tag docker build - <
使用指定的dockerfile配置文件，docker以stdin方式获取内容，使用此配置生成新的image
docker port 查看本地哪个端口映射到container的指定端口，其实用docker ps
也可以看到

**一些使用技巧**

**docker文件存放目录**

Docker实际上把所有东西都放到/var/lib/docker路径下了。

[root@localhost docker]# ls -F

containers/ devicemapper/ execdriver/ graph/ init/ linkgraph.db
repositories-devicemapper volumes/

containers目录当然就是存放容器（container）了，graph目录存放镜像，文件层（file
system
layer）存放在graph/imageid/layer路径下，这样我们就可以看看文件层里到底有哪些东西，利用这种层级结构可以清楚的看到文件层是如何一层一层叠加起来的。
