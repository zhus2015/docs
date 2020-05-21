.. _header-n0:

交付Dubbo微服务到K8S
====================

本文档基于k8s二进制安装

.. _header-n3:

集群规划
--------

==================== ======================= ============
主机名               角色                    IP
==================== ======================= ============
home-10-20.host.com  k8s代理节点1，zk1       10.10.10.20
home-10-21.host.com  k8s代理节点2，zk2       10.10.10.21
home-10-30.host.com  k8s运算节点1，zk3       10.10.10.30
home-10-31.host.com  k8s运算节点2，jenkins   10.10.10.31
home-10-200.host.com k8s运维节点(docker仓库) 10.10.10.200
==================== ======================= ============

.. _header-n30:

部署zookeeper
-------------

.. _header-n31:

安装jdk1.8
~~~~~~~~~~

**此步骤在服务器10.10.10.20、10.10.10.21、10.10.10.30上同时操作**

下载软件包并上传到相关主机的/opt/src目录下

.. code:: shell

   [root@home-10-20 src]# mkdir -p /usr/java
   [root@home-10-20 src]# tar xf jdk-8u151-linux-x64.tar.gz -C /usr/java
   [root@home-10-20 src]# ln -s /usr/java/jdk1.8.0_151 /usr/java/jdk
   [root@home-10-20 src]# vim /etc/profile.d/java.sh
   JAVA_HOME=/usr/java/jdk
   JRE_HOME=$JAVA_HOME/jre
   CLASS_PATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib/rt.jar
   PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin
   export JAVA_HOME JRE_HOME CLASS_PATH PATH
   [root@home-10-20 src]# source /etc/profile
   [root@home-10-20 src]# java -version
   java version "1.8.0_151"
   Java(TM) SE Runtime Environment (build 1.8.0_151-b12)
   Java HotSpot(TM) 64-Bit Server VM (build 25.151-b12, mixed mode)

.. _header-n36:

安装zookeeper
~~~~~~~~~~~~~

**此步骤在服务器10.10.10.20、10.10.10.21、10.10.10.30上同时操作**

.. _header-n38:

解压安装
^^^^^^^^

下载软件包并上传到相关主机的/opt/src目录下

官方下载链接：https://mirror.bit.edu.cn/apache/zookeeper/zookeeper-3.4.14/zookeeper-3.4.14.tar.gz

如果使用其他版本请自行下载

官方地址：http://archive.apache.org/dist/zookeeper/

.. code:: shell

   [root@home-10-20 src]# tar xf zookeeper-3.4.14.tar.gz -C /opt
   [root@home-10-20 src]# cd /opt
   [root@home-10-20 opt]# ln -s /opt/zookeeper-3.4.14 /opt/zookeeper
   [root@home-10-20 opt]# mkdir -pv /data/zookeeper/{data,logs}
   [root@home-10-20 opt]# cat > /opt/zookeeper/conf/zoo.cfg << EOF
   tickTime=2000
   initLimit=10
   syncLimit=5
   dataDir=/data/zookeeper/data
   dataLogDir=/data/zookeeper/logs
   clientPort=2181
   server.1=zk1.od.com:2888:3888
   server.2=zk2.od.com:2888:3888
   server.3=zk3.od.com:2888:3888
   EOF

.. _header-n45:

配置DNS
^^^^^^^

**此步骤在10.10.10.20进行**

.. code:: 

   [root@home-10-20 opt]# vim /var/named/od.com.zone
   zk1                  A    10.10.10.20
   zk2                  A    10.10.10.21
   zk3                  A    10.10.10.30
   [root@home-10-20 opt]# systemctl restart named
   [root@home-10-20 opt]# dig -t A zk1.od.com @10.10.10.20 +short
   10.10.10.20

.. _header-n49:

配置机器的id
^^^^^^^^^^^^

在不同机器上执行，按照规划设置

   10.10.10.20

.. code:: 

   [root@home-10-20 opt]# vim /data/zookeeper/data/myid
   1

..

   10.10.10.21

.. code:: 

   [root@home-10-21 opt]# vim /data/zookeeper/data/myid
   2

..

   10.10.10.30

.. code:: 

   [root@home-10-30 opt]# vim /data/zookeeper/data/myid
   3

.. _header-n61:

依次启动
^^^^^^^^

.. code:: 

   [root@home-10-20 opt]# /opt/zookeeper/bin/zkServer.sh start
   ZooKeeper JMX enabled by default
   Using config: /opt/zookeeper/bin/../conf/zoo.cfg
   Starting zookeeper ... STARTED

最好将启动命令加入开机启动脚本rc.local中

.. _header-n65:

部署Jenkins
-----------

部署到k8s中

.. _header-n67:

准备镜像
~~~~~~~~

**此步骤在运维主机10.10.10.200操作**

官网地址：https://jenkins.io

我这里用的是2.222.3版本

.. code:: 

   [root@home-10-200 ~]# docker pull jenkins/jenkins:2.222.3
   [root@home-10-200 ~]# docker push harbor.od.com/public/jenkins
   [root@home-10-200 ~]# docker tag 5307ff34e221 harbor.od.com/public/jenkins:v2.222.3

.. _header-n73:

自定义Dockerfile
~~~~~~~~~~~~~~~~

**此步骤在运维主机10.10.10.200操作**

/data/dockerfile/jenkins/Dockerfile

.. code:: shell

   FROM harbor.od.com/public/jenkins:v2.222.3
   USER root
   RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
       echo 'Asia/Shanghai' > /etc/localtime
   ADD id_rsa /root/.ssh/id_rsa
   ADD config.json /root/.docker/config.json
   ADD get-docker.sh /get-docker.sh
   RUN echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
       /get-docker.sh

   生成密钥对

.. code:: 

   # ssh-keygen -t rsa -b 2048 -C "zhus8251@163.com" -N "" -f /root/.ssh/id_rsa

   config.json

.. code:: 

   {
   	"auths": {
   		"harbor.od.com": {
   			"auth": "YWRtaW46SGFyYm9yMTIzNDU="
   		}
   	},
   	"HttpHeaders": {
   		"User-Agent": "Docker-Client/19.03.8 (linux)"
   	}
   }

   get-docker.sh

.. code:: 

   [root@home-10-200 jenkins]# curl -fssL get.docker.com -o get-docker.sh
   [root@home-10-200 jenkins]# chmod +x get-docker.sh

**制作自定义镜像**

.. code:: 

   [root@home-10-200 jenkins]# docker build . -t harbor.od.com/infra/jenkins:v2.222.3

   在代码仓库增加公钥

主要是为了免密获取代码

仓库地址：https://gitee.com/zhus2015/dubbo-demo-service

.. _header-n99:

创建私有仓库
~~~~~~~~~~~~

在harbor中创建名称为infra的私有仓库

.. _header-n102:

推送镜像
~~~~~~~~

**此步骤在运维主机10.10.10.200操作**

.. code:: 

   [root@home-10-200 jenkins]# docker push harbor.od.com/infra/jenkins

测试一下是否能链接上git仓库

.. code:: 

   # docker run --rm harbor.od.com/infra/jenkins:v2.222.3 ssh -i /root/.ssh/id_rsa -T git@gitee.com

.. _header-n109:

创建kubernetes名称空间
~~~~~~~~~~~~~~~~~~~~~~

**在k8s集群任意计算节点执行即可**

.. code:: shell

   # kubectl create ns infra
   namespace/infra created

   为命名空间增加secret

.. code:: shell

   # kubectl create secret docker-registry harbor --docker-server=harbor.od.com --docker-username=admin --docker-password=Harbor12345 -n infra
   secret/harbor created

.. _header-n117:

准备共享存储
~~~~~~~~~~~~

.. _header-n118:

安装NFS
^^^^^^^

**此步骤在运维主机及k8s运算节点上执行**

.. code:: 

   # yum install -y nfs-utils 

.. _header-n122:

配置NFS
^^^^^^^

**此步骤在运维主机操作**

这里使用运维主机10.10.10.200作为server

   配置nfs

.. code:: 

   # vim /etc/exports
   /data/nfs-volume 10.10.10.0/24(rw,no_root_squash)

   创建目录

.. code:: 

   # mkdir /data/nfs-volume

.. _header-n133:

启动NFS
^^^^^^^

**此步骤在运维主机上进行**

.. code:: 

   # systemctl start nfs
   # systemctl enable nfs

.. _header-n137:

准备资源配置清单
~~~~~~~~~~~~~~~~

**此步骤在运维主机上进行**

.. code:: 

   # mkdir /data/k8s-yaml/jenkins
   # mkdir /data/nfs-volume/jenkins_home

.. _header-n140:

dp.yaml
^^^^^^^

vim /data/k8s-yaml/jenkins/dp.yaml

.. code:: yaml

   kind: Deployment
   apiVersion: extensions/v1beta1
   metadata:
     name: jeknins
     namespace: infra
     labels:
       name: jenkins
   spec:
     replicas: 1
     selector:
       matchLabels:
         name: jenkins
     template:
       metadata:
         labels:
           app: jenkins
           name: jenkins
       spec:
         volumes:
         - name: data
           nfs:
             server: home-10-200
             path: /data/nfs-volume/jenkins_home
         - name: docker
           hostPath: 
             path: /run/docker.sock
             type: ''
         containers:
         - name: jenkins
           image: harbor.od.com/infra/jenkins:v2.222.3
           imagePullPolicy: IfNotPresent
           ports:
           - containerPort: 8080
             protocol: TCP
           env:
           - name: JAVA_OPTS
             value: -Xmx512m -Xms512m
           volumeMounts:
           - name: data
             mountPath: /var/jenkins_home
           - name: docker
             mountPath: /run/docker.sock
         imagePullSecrets:
         - name: harbor
         securityContext:
           runAsUser: 0
     strategy:
       type: RollingUpdate
       rollingUpdate:
         maxUnavailable: 1
         maxSurge: 1
     revisionHistoryLimit: 7
     progressDeadlineSeconds: 600          

.. _header-n144:

svc.yaml
^^^^^^^^

vim /data/k8s-yaml/jenkins/svc.yaml

.. code:: yaml

   kind: Service
   apiVersion: v1
   metadata:
     name: jenkins
     namespace: infra
   spec:
     ports:
     - protocol: TCP
       port: 80
       targetPort: 8080
     selector:
       app: jenkins

.. _header-n148:

ingress.yaml
^^^^^^^^^^^^

vim /data/k8s-yaml/jenkins/ingress.yaml

.. code:: yaml

   kind: Ingress
   apiVersion: extensions/v1beta1
   metadata:
     name: jenkins
     namespace: infra
   spec:
     rules:
     - host: jenkins.od.com
       http:
         paths: /
         backend:
           serviceName: jenkins
           servicePort: 80

.. _header-n152:

依次创建资源
~~~~~~~~~~~~

在任意计算节点上执行

.. code:: 

   # kubectl apply -f http://k8s-yaml.od.com/jenkins/dp.yaml
   # kubectl apply -f http://k8s-yaml.od.com/jenkins/svc.yaml
   # kubectl apply -f http://k8s-yaml.od.com/jenkins/ingress.yaml

.. _header-n156:

域名解析
~~~~~~~~

10.10.10.20 dns服务器上增加jenkins的A记录10.10.10.25

.. _header-n159:

访问检查
~~~~~~~~

dig -t A jenkins.od.com @10.10.10.20 +short

通过页面访问http://jenkins.od.com

.. _header-n163:

安装Blue Ocean插件
~~~~~~~~~~~~~~~~~~

.. _header-n165:

maven安装配置
-------------

**此步骤在10.10.10.200运维主机上进行操作**

.. _header-n167:

下载二进制包
~~~~~~~~~~~~

版本3.6.1

.. _header-n170:

解压到指定目录
~~~~~~~~~~~~~~

.. code:: shell

   # mkdir -p /data/nfs-volume/jenkins_home/maven-3.6.1-8u151
   # tar xfv apache-maven-3.6.1-bin.tar.gz -C /data/nfs-volume/jenkins_home/maven-3.6.1-8u151
   # cd /data/nfs-volume/jenkins_home/maven-3.6.1-8u151
   # mv ../apache-maven-3.6.1/* ../

.. _header-n173:

修改maven源
~~~~~~~~~~~

增加阿里云源配置，提高软件包的获取速度

.. code:: shell

   # cd /data/nfs-volume/jenkins_home/maven-3.6.1-8u151
   # vim conf/setting.xml
       <mirror>
           <id>alimaven</id>
           <name>aliyun maven</name>
           <url>http://maven.aliyun.com/nexus/content/groups/public/</url>
           <mirrorOf>central</mirrorOf>
       </mirror>

.. _header-n177:

制作dubbo微服务的底包镜像
-------------------------

**此步骤在10.10.10.200运维主机上进行操作**

.. _header-n180:

jre镜像准备
~~~~~~~~~~~

.. code:: 

   # docker pull docker.io/stanleyws/jre8:8u112
   # docker tag fa3a085d6ef1 harbor.od.com/public/jre:8u112
   # docker push harbor.od.com/public/jre:8u112

.. _header-n184:

自定义Dockerfile
~~~~~~~~~~~~~~~~

   /data/dockerfile/jre8/Dockerfile

.. code:: 

   FROM harbor.od.com/public/jre:8u112
   RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &&\
       echo 'Asia/Shanghai' >/etc/timezone
   ADD config.yml /opt/prom/config.yml
   ADD jmx_javaagent-0.3.1.jar /opt/prom/
   WORKDIR /opt/project_dir
   ADD entrypoint.sh /entrypoint.sh
   CMD ["/entrypoint.sh"]

   /data/dockerfile/jre8/config.yml

.. code:: yaml

   ---
   rules:
     - pattern: '.*'

   /data/dockerfile/jre8/

.. code:: shell

   # cd /data/dockerfile/jre8/
   # wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.3.1/jmx_prometheus_javaagent-0.3.1.jar -O jmx_javaagent-0.3.1.jar

   /data/dockerfile/jre8/entrypoint.sh

.. code:: shell

   #!/bin/sh
   M_OPTS="-Duser.timezone=Asia/Shanghai -javaagent:/opt/prom/jmx_javaagent-0.3.1.jar=$(hostname -i):${M_PORT:-"12346"}:/opt/prom/config.yml"
   C_OPTS=${C_OPTS}
   JAR_BALL=${JAR_BALL}
   exec java -jar ${M_OPTS} ${C_OPTS} ${JAR_BALL}

..

   chmod u+x /data/dockerfile/jre8/entrypoint.sh

.. _header-n204:

创建公开仓库
~~~~~~~~~~~~

在harbor中创建一个公开的bash仓库

.. _header-n207:

构建镜像
~~~~~~~~

.. code:: shell

   # cd /data/dockerfile/jre8/
   # docker build . -t harbor.od.com/base/jre8:8u112

.. _header-n210:

推送到私有仓库
~~~~~~~~~~~~~~

.. code:: shell

   # docker push harbor.od.com/base/jre8:8u112

.. _header-n213:

创建Jenkins项目
---------------

.. _header-n214:

创建pipeline项目
~~~~~~~~~~~~~~~~

创建一个名字叫dubbo-demo的流水线项目

勾选discard old builds 参数 3 30

.. _header-n217:

参数化构建
~~~~~~~~~~

选择“This project is parameterized”，增加以下参数：

1.  Add Parameter -> String Parameter

       name：app_name

       Description：项目的名称，例：dubbo-demo-service

       勾选 Trim the string

2.  Add Parameter -> String Parameter

       name：image_name

       Description：docker镜像名称，例：app/dubbo-demo-service

       勾选 Trim the string

3.  Add Parameter -> String Parameter

       name：git_repo

       Description：项目所在的git中央仓库的地址，例：https://gitee.com/stanleywang/dubbo-demo-service.git

       勾选 Trim the string

4.  Add Parameter -> String Parameter

       name：git_ver

       Description：项目在git中央仓库所对应的分支或者版本号，推荐使用版本号

       勾选 Trim the string

5.  Add Parameter -> String Parameter

       name：add_tag

       Description：docker镜像标签的一部分，日期时间戳，例：200511_1250

       勾选 Trim the string

6.  Add Parameter -> String Parameter

       name：mvn_dir

       Default Value：./

       Description：编译项目的目录，默认为项目的根目录

       勾选 Trim the string

7.  Add Parameter -> String Parameter

       name：target_dir

       Default Value：./target

       Description：项目编译完成后产生war/jar包的目录，默认为项目的根目录下target

       勾选 Trim the string

8.  Add Parameter -> String Parameter

       name：mvn_cmd

       Default Value：mvn clean package -Dmaven.test.skip=true

       Description：执行编译所用的命令

       勾选 Trim the string

9.  Add Parameter -> Choice Parameter

       name：base_image

       Choices：

       -  base/jre8:8u112

       -  base/jre7:7u80

       Description：项目的基础镜像名称在harbor.od.com

10. Add Parameter -> Choice Parameter

       name：maven

       Choices：

       -  3.6.1-8u151

       -  3.2.5-7u045

       -  2.2.1-6u025

       Description：编译使用的maven版本

.. _header-n297:

Pipeline script
~~~~~~~~~~~~~~~

.. code:: groovy

   pipeline {
     agent any 
       stages {
         stage('pull') { //get project code from repo 
           steps {
             sh "git clone ${params.git_repo} ${params.app_name}/${env.BUILD_NUMBER} && cd ${params.app_name}/${env.BUILD_NUMBER} && git checkout ${params.git_ver}"
           }
         }
         stage('build') { //exec mvn cmd
           steps {
             sh "cd ${params.app_name}/${env.BUILD_NUMBER}  && /var/jenkins_home/maven-${params.maven}/bin/${params.mvn_cmd}"
           }
         }
         stage('package') { //move jar file into project_dir
           steps {
             sh "cd ${params.app_name}/${env.BUILD_NUMBER} && cd ${params.target_dir} && mkdir project_dir && mv *.jar ./project_dir"
           }
         }
         stage('image') { //build image and push to registry
           steps {
             writeFile file: "${params.app_name}/${env.BUILD_NUMBER}/Dockerfile", text: """FROM harbor.od.com/${params.base_image}
   ADD ${params.target_dir}/project_dir /opt/project_dir"""
             sh "cd  ${params.app_name}/${env.BUILD_NUMBER} && docker build -t harbor.od.com/${params.image_name}:${params.git_ver}_${params.add_tag} . && docker push harbor.od.com/${params.image_name}:${params.git_ver}_${params.add_tag}"
           }
         }
       }
   }

.. _header-n301:

交付dubbo为服务至kubernetes集群
-------------------------------

.. _header-n302:

通过jenkins进行一次CI
~~~~~~~~~~~~~~~~~~~~~

填写相关参数，进行构建，第一次编译时间较长，需要稍微等待

app_name：dubbo-name-service

images_name：app/dubbo-name-service

git_repo：https://gitee.com/stanleywang/dubbo-demo-service.git

git_ver：master

add\ *tag：200511*\ 1250

mvn_dir：./

target_dir：./dubbo-server/target

mvn_cmd：mvn clean package -Dmaven.test.skip=true

base_image：base/jre8:8u112

maven：3.6.1-8u151

.. _header-n315:

检查Harbor仓库中的镜像
~~~~~~~~~~~~~~~~~~~~~~

.. _header-n317:

准备K8S资源配置清单
~~~~~~~~~~~~~~~~~~~

**此步骤在10.10.10.200运维主机上进行操作**

/data/k8s-yaml/dubbo-demo-service/dp.yaml

注意资源清单中的镜像名称要保持一致

.. code:: yaml

   kind: Deployment
   apiVersion: extensions/v1beta1
   metadata:
     name: dubbo-demo-service
     namespace: app
     labels: 
       name: dubbo-demo-service
   spec:
     replicas: 1
     selector:
       matchLabels: 
         name: dubbo-demo-service
     template:
       metadata:
         labels: 
           app: dubbo-demo-service
           name: dubbo-demo-service
       spec:
         containers:
         - name: dubbo-demo-service
           image: harbor.od.com/app/dubbo-demo-service:master_200511_1250
           ports:
           - containerPort: 20880
             protocol: TCP
           env:
           - name: JAR_BALL
             value: dubbo-server.jar
           imagePullPolicy: IfNotPresent
         imagePullSecrets:
         - name: harbor
         restartPolicy: Always
         terminationGracePeriodSeconds: 30
         securityContext: 
           runAsUser: 0
         schedulerName: default-scheduler
     strategy:
       type: RollingUpdate
       rollingUpdate: 
         maxUnavailable: 1
         maxSurge: 1
     revisionHistoryLimit: 7
     progressDeadlineSeconds: 600

.. _header-n323:

应用K8S资源配置清单
~~~~~~~~~~~~~~~~~~~

**在任意计算节点执行**

.. _header-n325:

创建app名称空间
^^^^^^^^^^^^^^^

.. code:: 

   kubectl create ns app

.. _header-n328:

创建secret资源
^^^^^^^^^^^^^^

为了能够访问harbor仓库的私有项目

.. code:: 

   kubectl create secret docker-registry harbor --docker-server=harbor.od.com --docker-username=admin --docker-password=Harbor12345 -n app

.. _header-n332:

应用资源配置文件
^^^^^^^^^^^^^^^^

.. code:: 

   # kubectl apply -f http://k8s-yaml.od.com/dubbo-demo-service/dp.yaml

.. _header-n335:

到zookeeper中检查服务
~~~~~~~~~~~~~~~~~~~~~

**在任意zookeeper节点执行**

.. code:: 

   sh /opt/zookeeper/bin/zkCli.sh
