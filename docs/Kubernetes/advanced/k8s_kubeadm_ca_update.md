# Kubeadm部署集群证书更新

!!! error "注意注意，一定要在证书到期前提前更换"

!!! error "本文未在生产环境进行过使用，请严格测试后使用"

!!! error "我这里的集群是1.8.5版本，其他版本需要修改的文件可能稍有不同，请自行到官网查询相关文档"



## 重新编译kubeadm

### 配置go语言编译环境

参考官网相关文档



### 下载kubuernetes对应版本源码

GitHub地址：https://github.com/kubernetes/kubernetes



### 修改对应文件

V1.8.5版本是修改 cmd/kubeadm/app/constants/constants.go文件中49行内容

```go
- CertificateValidity = time.Hour * 24 * 365 
+ CertificateValidity = time.Hour * 24 * 365 * 10
```

-对应的是修改之前的内容

+对应的是修改之后的内容



### 重新编译文件

```shell
make WHAT=cmd/kubeadm GOFLAGS=-v
```

新生成的文件在_output/bin/目录下



### 覆盖原来的kubeadm程序

```
cp /usr/bin/kubeadm /usr/bin/kubeadm.bak
cp _output/bin/kubeadm /usr/bin/kubeadm 
```





## 证书更新

### 查看证书时间

首先查看证书的时间，可以看到我的证书还有364天才会到期，这里我只是做测试，生产使用请慎重，注意新版本的ca证书已经默认是10年了。

```shell
[root@k8s-master ~]# kubeadm alpha certs check-expiration
[check-expiration] Reading configuration from the cluster...
[check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Jul 05, 2021 03:06 UTC   364                                      no      
apiserver                  Jul 05, 2021 03:06 UTC   364              ca                      no      
apiserver-etcd-client      Jul 05, 2021 03:06 UTC   364              etcd-ca                 no      
apiserver-kubelet-client   Jul 05, 2021 03:06 UTC   364              ca                      no      
controller-manager.conf    Jul 05, 2021 03:06 UTC   364                                      no      
etcd-healthcheck-client    Jul 05, 2021 03:06 UTC   364              etcd-ca                 no      
etcd-peer                  Jul 05, 2021 03:06 UTC   364              etcd-ca                 no      
etcd-server                Jul 05, 2021 03:06 UTC   364              etcd-ca                 no      
front-proxy-client         Jul 05, 2021 03:06 UTC   364              front-proxy-ca          no      
scheduler.conf             Jul 05, 2021 03:06 UTC   364                                      no      

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      Jul 05, 2030 02:25 UTC   9y              no      
etcd-ca                 Jul 05, 2030 02:25 UTC   9y              no      
front-proxy-ca          Jul 05, 2030 02:25 UTC   9y              no      
```



### 备份证书

```shell
[root@k8s-master kubernetes]# cp -r /etc/kubernetes/pki /etc/kubernetes/pki.bak
```





### 重新生成证书

```shell
[root@k8s-master kubernetes]# kubeadm alpha certs renew all
certificate embedded in the kubeconfig file for the admin to use and for kubeadm itself renewed
certificate for serving the Kubernetes API renewed
certificate the apiserver uses to access etcd renewed
certificate for the API server to connect to kubelet renewed
certificate embedded in the kubeconfig file for the controller manager to use renewed
certificate for liveness probes to healtcheck etcd renewed
certificate for etcd nodes to communicate with each other renewed
certificate for serving etcd renewed
certificate for the front proxy client renewed
certificate embedded in the kubeconfig file for the scheduler manager to use renewed
```



### 再次查看证书时间

```shell
[root@k8s-master ~]# kubeadm alpha certs check-expiration
[check-expiration] Reading configuration from the cluster...
[check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Jul 05, 2030 03:06 UTC   9y                                      no      
apiserver                  Jul 05, 2030 03:06 UTC   9y              ca                      no      
apiserver-etcd-client      Jul 05, 2030 03:06 UTC   9y              etcd-ca                 no      
apiserver-kubelet-client   Jul 05, 2030 03:06 UTC   9y              ca                      no      
controller-manager.conf    Jul 05, 2030 03:06 UTC   9y                                      no      
etcd-healthcheck-client    Jul 05, 2030 03:06 UTC   9y              etcd-ca                 no      
etcd-peer                  Jul 05, 2030 03:06 UTC   9y              etcd-ca                 no      
etcd-server                Jul 05, 2030 03:06 UTC   9y              etcd-ca                 no      
front-proxy-client         Jul 05, 2030 03:06 UTC   9y              front-proxy-ca          no      
scheduler.conf             Jul 05, 2030 03:06 UTC   9y                                      no      

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      Jul 05, 2030 02:25 UTC   9y              no      
etcd-ca                 Jul 05, 2030 02:25 UTC   9y              no      
front-proxy-ca          Jul 05, 2030 02:25 UTC   9y              no      
[root@k8s-master ~]# 
```



### 应用证书

```shell
[root@k8s-master ~]# kubeadm upgrade apply --certificate-renewal v1.18.5
```

