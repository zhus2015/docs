# 基于jre镜像制作运行jar包的程序的镜像

!!! warning "注意：这里我基于之前制作的jre镜像"



>  Dockerfile

```shell
FROM zhus2015/jre8:8u251
MAINTAINER ZHUSHUAI "zhushuai@iald.cn"
ADD config.yml /opt/prom/config.yml
ADD jmx_javaagent-0.3.1.jar /opt/prom/
WORKDIR /opt/project_dir
ADD entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
```

> entrypoint.sh 

```shell
#!/bin/sh
M_OPTS="-Duser.timezone=Asia/Shanghai -javaagent:/opt/prom/jmx_javaagent-0.3.1.jar=$(hostname -i):${M_PORT:-"12346"}:/opt/prom/config.yml"
C_OPTS=${C_OPTS}
JAR_BALL=${JAR_BALL}
exec java -jar ${M_OPTS} ${C_OPTS} ${JAR_BALL}
```

> jmx_javaagent-0.3.1.jar  
> 主要是为了介入Prometheus监控使用，如果不使用Prometheus可以添加此jar包，注意在Dockerfile中和entrypoint.sh 脚本中删除相关信息  
>
> 下载: wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.3.1/jmx_prometheus_javaagent-0.3.1.jar -O jmx_javaagent-0.3.1.jar

> config.yml  
> jmx监控配置文件，不适用Prometheus监控时可以不添加此文件，注意在Dockerfile中和entrypoint.sh 脚本中删除相关信息  

```yml
---
rules:
  - pattern: '.*'
```



制作镜像

```
 docker build -t zhus2015/jre:jre1.8 .
```



如果是想要运行jar包时可以在启动是指定参数进行运行即可，这里写了一个小例子

Dockerfile如下：   jar包是我找的一个公司的eureka注册中心程序，没有什么依赖，直接启动即可使用，而且有页面可以验证，自己可以去网上找相关资料

```shell
FROM zhus2015/base/jre8:8u251
ADD eureka.jar /opt/project_dir
```



制作镜像

```
docker build -t 10.10.10.103/police/eureka:v0.1 .
```



运行镜像

```
docker run -d -it -p 9001:9001 -e JAR_BALL=eureka.jar 10.10.10.103/police/eureka:v0.1
```

这里给脚本传了一个参数JAR_BALL，就是jar包的名字，也可以传入指定的运行参数比方说指定内存大小之类的