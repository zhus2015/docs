k8s常用命令
===========

陈述式资源管理
--------------

管理名称空间资源
>>>>>>>>>>>>>>>>>>>

查询名称空间
:::::::::::::
 
::

    完整命令
    # kubectl get namespace
    NAME              STATUS   AGE
    default           Active   41h
    kube-node-lease   Active   41h
    kube-public       Active   41h
    kube-system       Active   41h



::

    简写命令
    # kubectl get ns
    NAME              STATUS   AGE
    default           Active   41h
    kube-node-lease   Active   41h
    kube-public       Active   41h
    kube-system       Active   41h

创建名称空间
::::::::::::::

::

    创建一个名字叫app的空间
    # kubectl create ns app
    namespace/app created

删除名称空间
:::::::::::::

::

    # kubectl delete ns app
    namespace "app" deleted

管理Deployment资源
>>>>>>>>>>>>>>>>>>>

创建deplyment
::::::::::::::



::

    Deployment是一种pod节点控制器
    # kubectl create deployment nginx-dp --image=harbor.od.com/public/nginx:v1.7.9 -n kube-public
    deployment.apps/nginx-dp created

查看pods
::::::::::::

::

    # kubectl get pods -n kube-public
    NAME                        READY   STATUS    RESTARTS   AGE
    nginx-dp-5dfc689474-7wbp7   1/1     Running   0          4m52s

    这里还可以加上参数-o wide 扩展参数来查看到pod的ip、镜像之类的信息
    # kubectl get pods -n kube-public -o wide
    NAME                        READY   STATUS    RESTARTS   AGE     IP            NODE                  NOMINATED NODE   READINESS GATES
    nginx-dp-5dfc689474-7wbp7   1/1     Running   0          4m48s   172.10.31.3   home-10-31.host.com   <none>           <none>

查看pod详细信息
:::::::::::::::::::::

::

    # kubectl describe deployment nginx-dp -n kube-public

删除pod
::::::::::

::

    # kubectl delete pod nginx-dp-5dfc689474-7wbp7 -n kube-public

    只删除pod不删除pod控制器可以看做是重启

删除pod控制器
::::::::::::::::

::

    # kubectl delete depoly nginx-dp -n kube-public

管理Service资源
>>>>>>>>>>>>>>>>>>>

创建Service
^^^^^^^^^^^

::

    # kubectl create depolyment nginx-dp -image=harbor.od.com/public/nginx:v1.7.9 -n kubectl-public
    deployment.apps/nginx-dp created

    # kubectl expose deployment nginx-dp --port=80 -n kube-public
    server/nginx-dp exposed

    # kubectl get all -n kube-publice

    # kubectl scale deployment nginx-dp --replicas=2 -n kube-public
    可以将pod节点数量扩容为2个

声明式资源管理
------------------

获取资源清单
>>>>>>>>>>>>>>

::

    # kubectl get svc nginx-dp -o yaml -n kube-public

解释资源清单
>>>>>>>>>>>>>>>

::

    # kubectl explain service.metdata
    # kubectl explain service.spec

创建
:::::

::

    # kubectl create -f nginx-ds-svc.yaml

修改
:::::


::

    离线修改
    # kubectl apply -f nginx-ds-svc.yaml
	
    在线修改
    # kubectl edit svc nginx-ds

删除
:::::

::

    # kubectl delete -f nginx-ds-svc.yaml

资源配合清单说明
^^^^^^^^^^^^^^^^

::

    # vim nginx-ds-svc.yaml
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: nginx-ds
      name: nginx-ds
      namespace: default
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 80
      selector:
        app: nginx-ds
      sessionAffinity: None
      type: ClusterIP

查询资源
>>>>>>>>>>>

完整命令 kubectl get all [-n default]

默认default空间是可以不写 "[ ]" 内的内容
