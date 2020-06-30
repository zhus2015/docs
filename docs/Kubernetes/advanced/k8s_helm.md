# Helm安装部署



官方安装参考地址：https://helm.sh/docs/intro/install/https://helm.sh/docs/intro/install/

GitHub地址：https://github.com/helm/helm



## Helm安装

### 手动安装

```shell
$ wget https://get.helm.sh/helm-v2.16.9-linux-amd64.tar.gz
$ tar -zxvf helm-v2.16.9-linux-amd64.tar.gz
$ cp linux-amd64/heml /usr/local/bin
```



### 官方一键脚本安装

```shell
$ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
$ chmod 700 get_helm.sh
$ ./get_helm.sh
```



## Tiller安装

安装Tiller

```shell
$ helm init
```

创建 Kubernetes 的服务帐号和绑定角色

```shell
$ kubectl create serviceaccount --namespace kube-system tiller
```

给 Tiller 的 deployments 添加刚才创建的 ServiceAccount

```
$ kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
```

查看 Tiller deployments 资源是否绑定 ServiceAccount

```shell
$ kubectl get deploy -n kube-system tiller-deploy -o yaml | grep serviceAccount
```

查看 Tiller 是否安装成功

```shell
$ helm version 
```

