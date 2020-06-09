# 基于jre镜像制作Tomcat镜像

!!! warning "注意：这里是基于之前制作的jre镜像"

> Dockerfile

```
FROM zhus2015/jre8:8u251
ENV CATALINA_HOME /opt/tomcat
ENV LANG zh_CN.UTF-8
ADD apache-tomcat-8.5.51/ /opt/tomcat
ADD config.yml /opt/prom/config.yml
ADD jmx_javaagent-0.3.1.jar /opt/prom/jmx_javaagent-0.3.1.jar
WORKDIR /opt/tomcat
ADD entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]

```

> entrypoint.sh 

!!! note "这里有些调优的选项，可以根据自己实际情况进行调优，这里的调优不是我做的，我也不知道啥意思"

```shell
#!/bin/sh
set -x
M_OPTS="-Duser.timezone=Asia/Shanghai -javaagent:/opt/prom/jmx_javaagent-0.3.1.jar=$(hostname -i):${M_PORT:-"12346"}:/opt/prom/config.yml"
C_OPTS=${C_OPTS}
MIN_HEAP=${MIN_HEAP:-"1024m"}
MAX_HEAP=${MAX_HEAP:-"2048m"}
JAVA_OPTS=${JAVA_OPTS:-"Xmn384m -Xss256k -Duser.timezone=GMT+08 -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSParallelRemarkEnabled \
           -XX:+UseCMSCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=0 -XX:CMSClassUnloadingEnabled -XX:LargePageSizeInBytes=128m -XX:+UseFastAccessorMethods \
           -XX:UseInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=80 -XX:SoftRefLRUPolicyMSPerMB=0 -XX:+PrintClassHistogram -Dfile.encoding=UTF8 -Dsun.jnu.encoding=UTF8"}
CATALINA_OPTS="${CATALINA_OPTS}"
JAVA_OPTS="${M_OPTS} ${C_OPTS} -Xms${MIN_HEAP} -Xmx${MAX_HEAP}"
sed -i -e "1a\JAVA_OPTS=\"$JAVA_OPTS\"" -e "1a\CATALINA_OPTS=\"$CATALINA_OPTS\"" /opt/tomcat/bin/catalina.sh
cd /opt/tomcat && /opt/tomcat/bin/catalina.sh run 2>&1 >> /opt/tomcat/logs/stdout.log
```

> jmx_javaagent-0.3.1.jar  
> 主要是为了介入Prometheus监控使用，如果不使用Prometheus可以添加此jar包，注意在Dockerfile中和entrypoint.sh 脚本中删除相关信息  

下载: wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.3.1/jmx_prometheus_javaagent-0.3.1.jar -O jmx_javaagent-0.3.1.jar



> config.yml  
> jmx监控配置文件，不适用Prometheus监控时可以不添加此文件，注意在Dockerfile中和entrypoint.sh 脚本中删除相关信息  

```yml
---
rules:
  - pattern: '.*'
```