# 交付Dubbo微服务到K8S

本文档基于k8s二进制安装

## 集群规划

| 主机名               | 角色                    | IP           |
| :------------------- | ----------------------- | ------------ |
| home-10-20.host.com  | k8s代理节点1，zk1       | 10.10.10.20  |
| home-10-21.host.com  | k8s代理节点2，zk2       | 10.10.10.21  |
| home-10-30.host.com  | k8s运算节点1，zk3       | 10.10.10.30  |
| home-10-31.host.com  | k8s运算节点2，jenkins   | 10.10.10.31  |
| home-10-200.host.com | k8s运维节点(docker仓库) | 10.10.10.200 |



## 部署zookeeper

### 安装jdk1.8

**此步骤在服务器10.10.10.20、10.10.10.21、10.10.10.30上同时操作**

下载软件包并上传到相关主机的/opt/src目录下

```shell
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
```



### 安装zookeeper

**此步骤在服务器10.10.10.20、10.10.10.21、10.10.10.30上同时操作**

#### 解压安装

下载软件包并上传到相关主机的/opt/src目录下

官方下载链接：https://mirror.bit.edu.cn/apache/zookeeper/zookeeper-3.4.14/zookeeper-3.4.14.tar.gz

如果使用其他版本请自行下载

官方地址：http://archive.apache.org/dist/zookeeper/

```shell
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
```



#### 配置DNS

**此步骤在10.10.10.20进行**

```
[root@home-10-20 opt]# vim /var/named/od.com.zone
zk1                  A    10.10.10.20
zk2                  A    10.10.10.21
zk3                  A    10.10.10.30
[root@home-10-20 opt]# systemctl restart named
[root@home-10-20 opt]# dig -t A zk1.od.com @10.10.10.20 +short
10.10.10.20
```



#### 配置机器的id

在不同机器上执行，按照规划设置

> 10.10.10.20

```
[root@home-10-20 opt]# vim /data/zookeeper/data/myid
1
```

> 10.10.10.21

```
[root@home-10-21 opt]# vim /data/zookeeper/data/myid
2
```

> 10.10.10.30

```
[root@home-10-30 opt]# vim /data/zookeeper/data/myid
3
```



#### 依次启动

```
[root@home-10-20 opt]# /opt/zookeeper/bin/zkServer.sh start
ZooKeeper JMX enabled by default
Using config: /opt/zookeeper/bin/../conf/zoo.cfg
Starting zookeeper ... STARTED
```

最好将启动命令加入开机启动脚本rc.local中



## 部署Jenkins

部署到k8s中

### 准备镜像

**此步骤在运维主机10.10.10.200操作**

官网地址：https://jenkins.io

我这里用的是2.222.3版本

```
[root@home-10-200 ~]# docker pull jenkins/jenkins:2.222.3
[root@home-10-200 ~]# docker push harbor.od.com/public/jenkins
[root@home-10-200 ~]# docker tag 5307ff34e221 harbor.od.com/public/jenkins:v2.222.3
```



### 自定义Dockerfile

**此步骤在运维主机10.10.10.200操作**

/data/dockerfile/jenkins/Dockerfile

```shell
FROM harbor.od.com/public/jenkins:v2.222.3
USER root
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/localtime
ADD id_rsa /root/.ssh/id_rsa
ADD config.json /root/.docker/config.json
ADD get-docker.sh /get-docker.sh
RUN echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
    /get-docker.sh
```



> 生成密钥对

```
# ssh-keygen -t rsa -b 2048 -C "zhus8251@163.com" -N "" -f /root/.ssh/id_rsa
```



>  config.json

```
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
```



> get-docker.sh

```
[root@home-10-200 jenkins]# curl -fssL get.docker.com -o get-docker.sh
[root@home-10-200 jenkins]# chmod +x get-docker.sh
```



**制作自定义镜像**

```
[root@home-10-200 jenkins]# docker build . -t harbor.od.com/infra/jenkins:v2.222.3
```





> 在代码仓库增加公钥

主要是为了免密获取代码

仓库地址：https://gitee.com/zhus2015/dubbo-demo-service



### 创建私有仓库

在harbor中创建名称为infra的私有仓库



### 推送镜像

**此步骤在运维主机10.10.10.200操作**

```
[root@home-10-200 jenkins]# docker push harbor.od.com/infra/jenkins
```



测试一下是否能链接上git仓库

```
# docker run --rm harbor.od.com/infra/jenkins:v2.222.3 ssh -i /root/.ssh/id_rsa -T git@gitee.com
```



### 创建kubernetes名称空间

**在k8s集群任意计算节点执行即可**

```shell
# kubectl create ns infra
namespace/infra created
```



> 为命名空间增加secret

```shell
# kubectl create secret docker-registry harbor --docker-server=harbor.od.com --docker-username=admin --docker-password=Harbor12345 -n infra
secret/harbor created
```



### 准备共享存储

#### 安装NFS

**此步骤在运维主机及k8s运算节点上执行**

```
# yum install -y nfs-utils 
```



#### 配置NFS

**此步骤在运维主机操作**

这里使用运维主机10.10.10.200作为server

> 配置nfs

```
# vim /etc/exports
/data/nfs-volume 10.10.10.0/24(rw,no_root_squash)
```



> 创建目录

```
# mkdir /data/nfs-volume
```



#### 启动NFS

**此步骤在运维主机上进行**

```
# systemctl start nfs
# systemctl enable nfs
```



### 准备资源配置清单

**此步骤在运维主机上进行**

```
# mkdir /data/k8s-yaml/jenkins
# mkdir /data/nfs-volume/jenkins_home
```

#### dp.yaml

vim /data/k8s-yaml/jenkins/dp.yaml

```yaml
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
```



#### svc.yaml

vim /data/k8s-yaml/jenkins/svc.yaml

```yaml
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
```



#### ingress.yaml

vim /data/k8s-yaml/jenkins/ingress.yaml

```yaml
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
```



### 依次创建资源

在任意计算节点上执行

```
# kubectl apply -f http://k8s-yaml.od.com/jenkins/dp.yaml
# kubectl apply -f http://k8s-yaml.od.com/jenkins/svc.yaml
# kubectl apply -f http://k8s-yaml.od.com/jenkins/ingress.yaml
```



### 域名解析

10.10.10.20  dns服务器上增加jenkins的A记录10.10.10.25



### 访问检查

dig -t A jenkins.od.com @10.10.10.20 +short

通过页面访问http://jenkins.od.com



### 安装Blue Ocean插件



## maven安装配置

**此步骤在10.10.10.200运维主机上进行操作**

### 下载二进制包

版本3.6.1



### 解压到指定目录

```shell
# mkdir -p /data/nfs-volume/jenkins_home/maven-3.6.1-8u151
# tar xfv apache-maven-3.6.1-bin.tar.gz -C /data/nfs-volume/jenkins_home/maven-3.6.1-8u151
# cd /data/nfs-volume/jenkins_home/maven-3.6.1-8u151
# mv ../apache-maven-3.6.1/* ../
```



### 修改maven源

增加阿里云源配置，提高软件包的获取速度

```shell
# cd /data/nfs-volume/jenkins_home/maven-3.6.1-8u151
# vim conf/setting.xml
    <mirror>
        <id>alimaven</id>
        <name>aliyun maven</name>
        <url>http://maven.aliyun.com/nexus/content/groups/public/</url>
        <mirrorOf>central</mirrorOf>
    </mirror>
```



## 制作dubbo微服务的底包镜像

**此步骤在10.10.10.200运维主机上进行操作**



### jre镜像准备

```
# docker pull docker.io/stanleyws/jre8:8u112
# docker tag fa3a085d6ef1 harbor.od.com/public/jre:8u112
# docker push harbor.od.com/public/jre:8u112
```





### 自定义Dockerfile

> /data/dockerfile/jre8/Dockerfile

```
FROM harbor.od.com/public/jre:8u112
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &&\
    echo 'Asia/Shanghai' >/etc/timezone
ADD config.yml /opt/prom/config.yml
ADD jmx_javaagent-0.3.1.jar /opt/prom/
WORKDIR /opt/project_dir
ADD entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
```



> /data/dockerfile/jre8/config.yml

```yaml
---
rules:
  - pattern: '.*'
```



> /data/dockerfile/jre8/

```shell
# cd /data/dockerfile/jre8/
# wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.3.1/jmx_prometheus_javaagent-0.3.1.jar -O jmx_javaagent-0.3.1.jar
```



> /data/dockerfile/jre8/entrypoint.sh

```shell
#!/bin/sh
M_OPTS="-Duser.timezone=Asia/Shanghai -javaagent:/opt/prom/jmx_javaagent-0.3.1.jar=$(hostname -i):${M_PORT:-"12346"}:/opt/prom/config.yml"
C_OPTS=${C_OPTS}
JAR_BALL=${JAR_BALL}
exec java -jar ${M_OPTS} ${C_OPTS} ${JAR_BALL}
```

> chmod  u+x  /data/dockerfile/jre8/entrypoint.sh





### 创建公开仓库

在harbor中创建一个公开的bash仓库



### 构建镜像

```shell
# cd /data/dockerfile/jre8/
# docker build . -t harbor.od.com/base/jre8:8u112
```



### 推送到私有仓库

```shell
# docker push harbor.od.com/base/jre8:8u112
```



## 创建Jenkins项目

#### 创建pipeline项目

创建一个名字叫dubbo-demo的流水线项目

勾选discard old builds  参数 3 30

#### 参数化构建

选择“This project is parameterized”，增加以下参数：

1. Add Parameter -> String Parameter  

   > name：app_name 
   >
   > Description：项目的名称，例：dubbo-demo-service
   >
   > 勾选 Trim the string

    

2. Add Parameter -> String Parameter  

   > name：image_name
   >
   > Description：docker镜像名称，例：app/dubbo-demo-service
   >
   > 勾选 Trim the string

3. Add Parameter -> String Parameter  

   > name：git_repo
   >
   > Description：项目所在的git中央仓库的地址，例：https://gitee.com/stanleywang/dubbo-demo-service.git
   >
   > 勾选 Trim the string

4. Add Parameter -> String Parameter  

   > name：git_ver
   >
   > Description：项目在git中央仓库所对应的分支或者版本号，推荐使用版本号
   >
   > 勾选 Trim the string

5. Add Parameter -> String Parameter  

   > name：add_tag
   >
   > Description：docker镜像标签的一部分，日期时间戳，例：200511_1250
   >
   > 勾选 Trim the string

6. Add Parameter -> String Parameter  

   > name：mvn_dir
   >
   > Default Value：./
   >
   > Description：编译项目的目录，默认为项目的根目录
   >
   > 勾选 Trim the string

7. Add Parameter -> String Parameter  

   > name：target_dir
   >
   > Default Value：./target
   >
   > Description：项目编译完成后产生war/jar包的目录，默认为项目的根目录下target
   >
   > 勾选 Trim the string

8. Add Parameter -> String Parameter   

   > name：mvn_cmd
   >
   > Default Value：mvn clean package -Dmaven.test.skip=true
   >
   > Description：执行编译所用的命令
   >
   > 勾选 Trim the string

9. Add Parameter -> Choice Parameter

   > name：base_image
   >
   > Choices：
   >
   > - base/jre8:8u112
   > - base/jre7:7u80
   >
   > Description：项目的基础镜像名称在harbor.od.com

10. Add Parameter -> Choice Parameter

    > name：maven
    >
    > Choices：
    >
    > - 3.6.1-8u151
    >
    > - 3.2.5-7u045
    >
    > - 2.2.1-6u025 
    >
    > Description：编译使用的maven版本



#### Pipeline script

```groovy
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
```





## 交付dubbo微服务至kubernetes集群

### 通过jenkins进行一次CI

填写相关参数，进行构建，第一次编译时间较长，需要稍微等待

app_name：dubbo-name-service

images_name：app/dubbo-name-service

git_repo：https://gitee.com/stanleywang/dubbo-demo-service.git

git_ver：master

add_tag：200511_1250

mvn_dir：./

target_dir：./dubbo-server/target

mvn_cmd：mvn clean package -Dmaven.test.skip=true

base_image：base/jre8:8u112

maven：3.6.1-8u151



### 检查Harbor仓库中的镜像



### 准备K8S资源配置清单

**此步骤在10.10.10.200运维主机上进行操作**

/data/k8s-yaml/dubbo-demo-service/dp.yaml

注意资源清单中的镜像名称要保持一致

```yaml
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
```



### 应用K8S资源配置清单

**在任意计算节点执行**

#### 创建app名称空间

```
kubectl create ns app
```



#### 创建secret资源

为了能够访问harbor仓库的私有项目

```
kubectl create secret docker-registry harbor --docker-server=harbor.od.com --docker-username=admin --docker-password=Harbor12345 -n app
```



#### 应用资源配置文件

```
# kubectl apply -f http://k8s-yaml.od.com/dubbo-demo-service/dp.yaml
```



### 到zookeeper中检查服务

**在任意zookeeper节点执行**

```
# sh /opt/zookeeper/bin/zkCli.sh
# [zk: localhost:2181(CONNECTED) 2] ls 
```



## 交付dubbo微服务consume到k8s集群

### 通过jenkins进行一次CI

填写相关参数，进行构建

app_name：dubbo-name-consumer

images_name：app/dubbo-name-consumer

git_repo：https://gitee.com/zhus2015/dubbo-demo-service.git

git_ver：master

add_tag：200512_1150

mvn_dir：./

target_dir：./dubbo-client/target

mvn_cmd：mvn clean package -Dmaven.test.skip=true

base_image：base/jre8:8u112

maven：3.6.1-8u151



### 准备资源清单

```
# mkdir /data/k8s-yaml/dubbo-consumer
# cd /data/k8s-yaml/dubbo-consumer
```



#### dp.yaml

> /data/k8s-yaml/dubbo-consumer/dp.yaml

```yaml
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: dubbo-demo-consumer
  namespace: app
  labels: 
    name: dubbo-demo-consumer
spec:
  replicas: 1
  selector:
    matchLabels: 
      name: dubbo-demo-consumer
  template:
    metadata:
      labels: 
        app: dubbo-demo-consumer
        name: dubbo-demo-consumer
    spec:
      containers:
      - name: dubbo-demo-consumer
        image: harbor.od.com/app/dubbo-demo-consumer:master_200512_1150
        ports:
        - containerPort: 8080
          protocol: TCP
        - containerPort: 20880
          protocol: TCP
        env:
        - name: JAR_BALL
          value: dubbo-client.jar
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
```



#### svc.yaml

> /data/k8s-yaml/dubbo-consumer/svc.yaml

```yaml
kind: Service
apiVersion: v1
metadata: 
  name: dubbo-demo-consumer
  namespace: app
spec:
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
  selector: 
    app: dubbo-demo-consumer
```



#### ingress.yaml

>  /data/k8s-yaml/dubbo-consumer/ingress.yaml

```yaml
kind: Ingress
apiVersion: extensions/v1beta1
metadata: 
  name: dubbo-demo-consumer
  namespace: app
spec:
  rules:
  - host: demo.od.com
    http:
      paths:
      - path: /
        backend: 
          serviceName: dubbo-demo-consumer
          servicePort: 8080
```



### 应用资源清单

```yaml
# kubectl apply -f http://k8s-yaml.od.com/dubbo-consumer/dp.yaml
# kubectl apply -f http://k8s-yaml.od.com/dubbo-consumer/svc.yaml
# kubectl apply -f http://k8s-yaml.od.com/dubbo-consumer/ingress.yaml
```



### 增加DNS解析

将demo解析到10.10.10.25上



### 访问验证

访问http://demo.od.com