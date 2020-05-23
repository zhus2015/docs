

交付Dubbo-monitor监控到k8s
=============================



准备docker镜像
--------------

**在运维主机10.10.10.200上执行**



下载镜像
~~~~~~~~

.. code:: shell

   # cd /opt/src
   # wget https://github.com/Jeromefromcn/dubbo-monitor/archive/master.zip



解压、修改配置
~~~~~~~~~~~~~~

.. code:: shell

   # unzip master.zip
   # vim /opt/src/dubbo-monitor/dubbo-monitor-simple/conf/dubbo_origin.properties
   修改以下对应参数
   dubbo.registry.address=zookeeper://zk1.od.com:2181?backup=zk2.od.com:2181,zk3.od.com:2181
   dubbo.protocol.port=20880
   dubbo.jetty.port=8080
   dubbo.jetty.directory=/dubbo-monitor-simple/monitor
   dubbo.statistics.directory=/dubbo-monitor-simple/statistics
   dubbo.charts.directory=/dubbo-monitor-simple/charts
   dubbo.log4j.file=logs/dubbo-monitor.log



优化Docker镜像
~~~~~~~~~~~~~~

.. code:: shell

   # sed -r -i -e '/^nohup/{p;:a;N;$!ba;d}'  ./dubbo-monitor-simple/bin/start.sh && sed  -r -i -e "s%^nohup(.*)%exec \1%"  ./dubbo-monitor-simple/bin/start.sh



制作镜像
~~~~~~~~

.. code:: shell

   # cp -a dubbo-monitor/ /data/dockerfile/
   # cd /data/dockerfile/dubbo-monitor
   # docker build . -t harbor.od.com/infra/dubbo-monitor:latest
   # docker push harbor.od.com/infra/dubbo-monitor:latest



准备资源配置清单
----------------

**在运维主机10.10.10.200上执行**

.. code:: shell

   # mkdir /data/k8s-yaml/dubbo-monitor
   # cd /data/k8s-yaml/dubbo-monitor



dp.yaml
~~~~~~~

   /data/k8s-yaml/dubbo-monitor/dp.yaml

.. code:: yaml

   kind: Deployment
   apiVersion: extensions/v1beta1
   metadata:
     name: dubbo-monitor
     namespace: infra
     labels: 
       name: dubbo-monitor
   spec:
     replicas: 1
     selector:
       matchLabels: 
         name: dubbo-monitor
     template:
       metadata:
         labels: 
           app: dubbo-monitor
           name: dubbo-monitor
       spec:
         containers:
         - name: dubbo-monitor
           image: harbor.od.com/infra/dubbo-monitor:latest
           ports:
           - containerPort: 8080
             protocol: TCP
           - containerPort: 20880
             protocol: TCP
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



svc.yaml
~~~~~~~~

   /data/k8s-yaml/dubbo-monitor/svc.yaml

.. code:: yaml

   kind: Service
   apiVersion: v1
   metadata: 
     name: dubbo-monitor
     namespace: infra
   spec:
     ports:
     - protocol: TCP
       port: 8080
       targetPort: 8080
     selector: 
       app: dubbo-monitor



ingress.yaml
~~~~~~~~~~~~

   /data/k8s-yaml/dubbo-monitor/ingress.yaml

.. code:: yaml

   kind: Ingress
   apiVersion: extensions/v1beta1
   metadata: 
     name: dubbo-monitor
     namespace: infra
   spec:
     rules:
     - host: dubbo-monitor.od.com
       http:
         paths:
         - path: /
           backend: 
             serviceName: dubbo-monitor
             servicePort: 8080



应用资源清单
------------

**在任意计算节点执行**

.. code:: shell

   # kubectl apply -f http://k8s-yaml.od.com/dubbo-monitor/dp.yaml
   # kubectl apply -f http://k8s-yaml.od.com/dubbo-monitor/svc.yaml
   # kubectl apply -f http://k8s-yaml.od.com/dubbo-monitor/ingress.yaml



配置域名解析
------------

**此步骤在DNS服务器上操作**

增加一条dubbo-monitor的A记录解析到VIP：10.10.10.25

测试解析

.. code:: shell

   # dig -t A dubbo-monitor.od.com @10.10.10.20 +short



页面访问
--------

浏览器访问: http://dubbo-monitor.od.com
