.. _header-n0:

k8s核心组件安装
===============

kubernetes设计了网络模型，但却将它的实现交给了网络插件，CNI网络插件最主要的功能就是实现POD资源能够跨宿主机进行通信

.. _header-n4:

K8S的CNI网络插件-Flannel
------------------------

.. _header-n6:

集群规划
~~~~~~~~

.. _header-n8:

下载软件包
~~~~~~~~~~

   软件下载地址：

https://github.com/coreos/flannel/releases

   版本：v0.11.0

.. code:: 

   # cd /opt/src
   # wget https://github.com/coreos/flannel/releases/download/v0.11.0/flannel-v0.11.0-linux-amd64.tar.gz

.. _header-n16:

创建相关目录解压软件包
~~~~~~~~~~~~~~~~~~~~~~

.. code:: 

   # mkdir /opt/flannel-v0.11.0
   # tar xf flannel-v0.11.0-linux-amd64.tar.gz -C /opt/flannel-v0.11.0
   # ln -s /opt/flannel-v0.11.0 /opt/flannel

.. _header-n19:

拷贝证书
~~~~~~~~

   flannel需要连接etcd这里需要client证书及相关私钥

.. code:: 

   # cd /opt/flannel
   # mkdir certs
   # cd certs
   # scp  root@10.10.10.200:/opt/certs/ca.pem .
   # scp  root@10.10.10.200:/opt/certs/client.pem .
   # scp  root@10.10.10.200:/opt/certs/client-key.pem .

.. _header-n24:

创建配置文件
~~~~~~~~~~~~

   注意修改FLANNEL_SUBNET

.. code:: 

   # cd /opt/flannel
   # vim subnet.env
   FLANNEL_NETWORK=172.10.0.0/16
   FLANNEL_SUBNET=172.10.30.1/24
   FLANNEL_MTU=1500
   FLANNEL_IPMASQ=false

.. _header-n29:

创建启动脚本
~~~~~~~~~~~~

.. code:: 

   # vim flanneld.sh
   #!/bin/bash
   ./flanneld \
     --public-ip=10.10.10.30 \
     --etcd-endpoints=https://10.10.10.21:2379,https://10.10.10.30:2379,https://10.10.10.31:2379 \
     --etcd-keyfile=./certs/client-key.pem \
     --etcd-certfile=./certs/client.pem \
     --etcd-cafile=./certs/ca.pem \
     --iface=ens33 \
     --subnet-file=./subnet.env \
     --healthz-port=2401

.. _header-n32:

检查配置、权限、创建日志目录
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: 

   # chmod +x /opt/flannel/flanneld.sh
   # mkdir -p /data/logs/flanneld

.. _header-n35:

设置flannel的网络配置
~~~~~~~~~~~~~~~~~~~~~

**此步骤在任意etcd节点上执行，执行一次即可**

   host-gw模型

   .. code:: 

      # etcdctl set /coreos.com/network/config '{"Network": "172.10.0.0/16","Backend": {"Type": "host-gw"}}'

   验证

.. code:: 

   # etcdctl get /coreos.com/network/config
   {"Network": "172.10.0.0/16","Backend": {"Type": "host-gw"}}

附其他网络模型

   VxLan模型

   .. code:: 

      '{"Network": "172.10.0.0/16","Backend": {"Type": "VxLan"}}'

   直接路由模型

   .. code:: 

      '{"Network": "172.10.0.0/16","Backend": {"Type": "VxLan","Directrouting"： true}}'

.. _header-n55:

创建flannel的supervisor配置文件
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code:: 

   # cat > /etc/supervisord.d/flanneld.ini << EOF
   [program:flanneld]
   command=/opt/flannel/flanneld.sh                     
   numprocs=1
   directory=/opt/flannel
   autostart=true
   autorestart=true
   startsecs=30
   startretries=3
   exitcodes=0,2
   stopsignal=QUIT
   stopwaitsecs=10
   user=root
   redirect_stderr=true
   stdout_logfile=/data/logs/flanneld/flanneld.stdout.log
   stdout_logfile_maxbytes=64MB
   stdout_logfile_backups=4
   stdout_capture_maxbytes=1MB
   stdout_events_enabled=false
   EOF

.. _header-n58:

启动验证
~~~~~~~~

.. code:: 

   # supervisorctl update

   验证
   ping 另一个宿主机上的pod
   这里如果有ping不通的可以尝试
   iptables -P INPUT ACCEPT
   iptables -P FORWARD ACCEPT

.. _header-n62:

优化
~~~~

安装iptables-services

.. code:: 

   # yum install -y iptables-services
   # systemctl start iptables
   # systemctl enable iptables

优化iptables规则

   主要优化postrouting -s 172.10.31.0？24 ! -o docker0 -j
   MASQUERADE这条规则

.. code:: 

   # iptables-save |grep -i postrouting
   删除此条规则
   # iptables -t nat -D +规则名称

   插入一条规则
   # iptables -t nat -I POSTROUTING -s 172.10.31.0/24 ! -d 172.10.0.0/16 ! -o docker0 -j MASQUERADE

   保存
   # iptables-save > /etc/sysconfig/iptables

   注意要删除两台机器上的reject规则，否则会出现

.. _header-n71:

K8S的服务发现插件-CoreDNS
-------------------------

k8s里的dns只负责自动维护“服务名”->“集群网络IP”之前的关系

.. _header-n74:

部署k8s的内网资源配置清单http服务
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   在10.10.10.200运维主机上，配置一个nginx虚拟主机，用以提供统一的资源配置清单访问入口

此步骤在10.10.10.200机器上执行

.. _header-n78:

配置nginx
^^^^^^^^^

.. code:: 

   # cat > /etc/nginx/conf.d/k8s-yaml.od.com.conf << EOF
   server {
       listen 80;
       server_name k8s-yaml.od.com;
       
       location / {
           autoindex on;
           default_type text/plain;
           root /data/k8s-yaml;
       }

   }
   EOF

.. _header-n81:

重启nginx
^^^^^^^^^

.. code:: 

   # nginx -s reload

.. _header-n84:

配置内网域名解析
~~~~~~~~~~~~~~~~

此步骤在10.10.10.20 服务器上进行操作

.. code:: 

   # vim /var/named/od.com.zone
   增加以下配置
   10.10.10.200 k8s-yaml.od.com
   保存退出

   # systemctl restart named

.. _header-n88:

部署CoreDNS
~~~~~~~~~~~

.. _header-n89:

准备镜像
^^^^^^^^

此步骤在10.10.10.200上执行

.. _header-n91:

获取镜像
''''''''

.. code:: 

   # docker pull docker.io/coredns/coredns:1.6.1

.. _header-n94:

镜像打包
''''''''

.. code:: 

   # docker tag c0f6e815079e harbor.od.com/public/coredns:v1.6.1

.. _header-n97:

推送镜像到私有仓库
''''''''''''''''''

.. code:: shell

   # docker push harbor.od.com/public/coredns:v1.6.1

.. _header-n100:

准备资源配置清单
^^^^^^^^^^^^^^^^

在10.10.10.200上操作

官方参考地址：https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/dns/coredns

.. _header-n103:

rbac
''''

/data/k8s-yaml/coredns/rbac.yaml

.. code:: yaml

   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: coredns
     namespace: kube-system
     labels:
       kubernetes.io/cluster-service: "ture"
       addonmanager.kubernetes.io/mode: Reconcile
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     labels:
       kubernetes.io/bootstrapping: rbac-defaults
       addonmanager.kubernetes.io/mode: Reconcile
     name: system:coredns
   rules:
   - apiGroups:
     - ""
     resources:
     - endpoints
     - services
     - pods
     - namespaces
     verbs:
     - list
     - watch
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
     annotations:
       rbac.authorization.kubernetes.io/autoupdate: "true"
     labels:
       kubernetes.io/bootstrapping: rbac-defaults
       addonmanager.kubernetes.io/mode: EnsureExists
     name: system:coredns
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: ClusterRole
     name: system:coredns
   subjects:
   - kind: ServiceAccount
     name: coredns
     namespace: kube-system

.. _header-n108:

configMap
'''''''''

/data/k8s-yaml/coredns/cm.yaml

.. code:: yaml

   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: coredns
     namespace: kube-system
   data:
     Corefile: |
       .:53 {
           errors
           health
           ready
           kubernetes cluster.local 192.168.0.0/16
           forward . 10.10.10.20
           cache 30
           loop
           reload
           loadbalance
         }

.. _header-n113:

Deployment
''''''''''

/data/k8s-yaml/coredns/dp.yaml

.. code:: yaml

   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: coredns
     namespace: kube-system
     labels:
       k8s-app: coredns
       kubernetes.io/cluster-service: "true"
       kubernetes.io/name: "CoreDNS"
   spec:
     replicas: 1
     selector:
       matchLabels:
         k8s-app: coredns
     template:
       metadata:
         labels:
           k8s-app: coredns
       spec:
         priorityClassName: system-cluster-critical
         serviceAccountName: coredns
         containers:
         - name: coredns
           image: harbor.od.com/public/coredns:v1.6.1
           args:
           - "-conf"
           - "/etc/coredns/Corefile"
           volumeMounts:
           - name: config-volume
             mountPath: /etc/coredns
           ports:
           - containerPort: 53
             name: dns
             protocol: UDP
           - containerPort: 53
             name: dns-tcp
             protocol: TCP
           - containerPort: 9153
             name: mecrics
             protocol: TCP
           livenessProbe:
             httpGet:
               path: /healtk
               port: 8080
               scheme: HTTP
             initialDelaySeconds: 60
             timeoutSeconds: 5
             successThreshold: 1
             failureThreshold: 5
         dnsPolicy: Default
         volumes:
           - name: config-volume
             configMap:
               name: coredns
               items:
               - key: Corefile
                 path: Corefile

.. _header-n118:

Service
'''''''

/data/k8s-yaml/coredns/svc.yaml

.. code:: yaml

   apiVersion: v1
   kind: Service
   metadata:
     name: coredns
     namespace: kube-system
     labels:
       k8s-app: coredns
       kubernetes.io/cluster-service: "true"
       kunernetes.io/name: "CoreDNS"
   spec:
     selector:
       k8s-app: coredns
     clusterIP: 192.168.0.2
     ports:
     - name: dns
       port: 53
       protocol: UDP
     - name: dns-tcp
       port: 53
       protocol: TCP
     - name: metrics
       port: 9153
       protocol: TCP

.. _header-n123:

依次创建相关资源
^^^^^^^^^^^^^^^^

   在任意运算节点执行

.. code:: shell

   # kubectl apply -f http://k8s-yaml.od.com/coredns/rbac.yaml
   # kubectl apply -f http://k8s-yaml.od.com/coredns/cm.yaml
   # kubectl apply -f http://k8s-yaml.od.com/coredns/dp.yaml
   # kubectl apply -f http://k8s-yaml.od.com/coredns/svc.yaml

.. _header-n128:

检查验证
^^^^^^^^

   在任意运算节点执行

.. code:: shell

   # kubectl get all -n kube-system
   NAME                           READY   STATUS    RESTARTS   AGE
   pod/coredns-69798d5bc8-4g5bt   1/1     Running   2          4m7s


   NAME              TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                  AGE
   service/coredns   ClusterIP   192.168.0.2   <none>        53/UDP,53/TCP,9153/TCP   51s


   NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
   deployment.apps/coredns   1/1     1            1           4m7s

   NAME                                 DESIRED   CURRENT   READY   AGE
   replicaset.apps/coredns-69798d5bc8   1         1         1       4m7s

   # kubelctl expose deployment nginx-dp --port=80 -n kube-public
   service/nginx-dp exposed
   # kubelctl get svc -n kube-public
   NAME       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
   nginx-dp   ClusterIP   192.168.122.94   <none>        80/TCP    17s
   # dig -t A nginx-dp.kube-public.svc.cluster.local. @192.168.0.2 +short
   192.168.122.94

.. _header-n133:

K8S服务暴露插件-traefik
-----------------------

官方地址：https://github.com/containous/traefik

.. _header-n136:

部署traefik
~~~~~~~~~~~

.. _header-n137:

准备镜像
^^^^^^^^

   此步骤在10.10.10.200运维服务器上操作

.. code:: 

   下载镜像
   # docker pull traefik:v1.7.2-alpine
   打包镜像
   # docker tag add5fac61ae5 harbor.od.com/public/traefik:v1.7.2
   推送镜像到私有仓库
   # docker push harbor.od.com/public/traefik:v1.7.2

.. _header-n143:

准备资源配置清单
^^^^^^^^^^^^^^^^

   此步骤在10.10.10.200运维服务器上操作

   参考地址：https://github.com/containous/traefik/blob/v1.7.2/examples/k8s

.. _header-n148:

RABC
''''

/data/k8s-yaml/traefik/rbac.yaml

.. code:: yaml

   ---
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: traefik-ingress-controller
     namespace: kube-system
   ---
   kind: ClusterRole
   apiVersion: rbac.authorization.k8s.io/v1beta1
   metadata:
     name: traefik-ingress-controller
   rules:
     - apiGroups:
         - ""
       resources:
         - services
         - endpoints
         - secrets
       verbs:
         - get
         - list
         - watch
     - apiGroups:
         - extensions
       resources:
         - ingresses
       verbs:
         - get
         - list
         - watch
   ---
   kind: ClusterRoleBinding
   apiVersion: rbac.authorization.k8s.io/v1beta1
   metadata:
     name: traefik-ingress-controller
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: ClusterRole
     name: traefik-ingress-controller
   subjects:
   - kind: ServiceAccount
     name: traefik-ingress-controller
     namespace: kube-system

.. _header-n153:

DemonSet
''''''''

/data/k8s-yaml/traefik/ds.yaml

.. code:: yaml

   ---
   kind: DaemonSet
   apiVersion: extensions/v1beta1
   metadata:
     name: traefik-ingress
     namespace: kube-system
     labels:
       k8s-app: traefik-ingress
   spec:
     template:
       metadata:
         labels:
           k8s-app: traefik-ingress
           name: traefik-ingress
       spec:
         serviceAccountName: traefik-ingress-controller
         terminationGracePeriodSeconds: 60
         containers:
         - image: harbor.od.com/public/traefik:v1.7.2
           name: traefik-ingress
           ports:
           - name: http
             containerPort: 80
             hostPort: 81
           - name: admin-web
             containerPort: 8080
           securityContext:
             capabilities:
               drop:
               - ALL
               add:
               - NET_BIND_SERVICE
           args:
           - --api
           - --kubernetes
           - --logLevel=INFO
           - --insecureskipverify=true
           - --kubernetes.endpoint=https://10.10.10.25:7443
           - --accesslog
           - --accesslog.filepath=/var/log/traefik_access.log
           - --traefiklog
           - --traefiklog.filepath=/var/log/traefik.log
           - --metrics.prometheus

.. _header-n158:

Service
'''''''

/data/k8s-yaml/traefik/svc.yaml

.. code:: yaml

   ---
   kind: Service
   apiVersion: v1
   metadata:
     name: traefik-ingress-service
     namespace: kube-system
   spec:
     selector:
       k8s-app: traefik-ingress
     ports:
       - protocol: TCP
         port: 80
         name: ingress-controller
       - protocol: TCP
         port: 8080
         name: admin-web

.. _header-n163:

Ingress
'''''''

/data/k8s-yaml/traefik/ingress.yaml

.. code:: yaml

   ---
   apiVersion: extensions/v1beta1
   kind: Ingress
   metadata:
     name: traefik-web-ui
     namespace: kube-system
     annotations:
       kubernetes.io/ingress.class: traefik
   spec:
     rules:
     - host: traefik.od.com
       http:
         paths:
         - path: /
           backend:
             serviceName: traefik-ingress-service
             servicePort: 8080

.. _header-n168:

依次创建相关资源
^^^^^^^^^^^^^^^^

   在任意运算节点执行

.. code:: 

   # kubectl apply -f http://k8s-yaml.od.com/traefik/rbac.yaml
   # kubectl apply -f http://k8s-yaml.od.com/traefik/ds.yaml
   # kubectl apply -f http://k8s-yaml.od.com/traefik/svc.yaml
   # kubectl apply -f http://k8s-yaml.od.com/traefik/ingress.yaml

.. _header-n173:

创建反向代理
~~~~~~~~~~~~

   在lvs服务器上操作，两台机器的nginx都要配置

.. code:: 

   # vim /etc/nginx/conf.d/od.com.conf
   upstream default_backend_traefik {
       server 10.10.10.30:81   max_fails=3 fail_timeout=10s;
       server 10.10.10.31:81   max_fails=3 fail_timeout=10s;
   }

   server {
       server_name *.od.com;

       location / {
           proxy_pass http://default_backend_traefik;
           proxy_set_header Host    $http_host;
           proxy_set_header x-forwarded-for $proxy_add_x_forwarded_for;
       }
   }

   检查配置
   # nginx -t
   nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
   nginx: configuration file /etc/nginx/nginx.conf test is successful

   重启nginx
   # nginx -s reload

.. _header-n178:

内部域名解析
~~~~~~~~~~~~

在DNS服务器上配置traefik的A的记录指向lvs的vip

.. _header-n181:

验证
~~~~

浏览器访问 http://traefik.od.com
