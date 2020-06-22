# kubeadm安装部署k8s

官方文档：https://kubernetes.io/zh/docs/setup/independent/create-cluster-kubeadm/

**注意注意：使用kubeadm部署的k8s集群证书的有效期只有1年，一定要注意提前更换**



## 主机信息

所有机器配置位2c2g 40G硬盘

| 主机名     | ip          | 用途             |
| ---------- | ----------- | ---------------- |
| k8s-master | 10.10.10.10 | etcd、k8s-master |
| k8s-node1  | 10.10.10.11 | etcd、k8s-worker |
| k8s-node2  | 10.10.10.12 | etcd、k8s-worker |



## 环境初始化

### 设置主机名

```shell
#10.10.10.10
hostnamectl set-hostname k8s-master

#10.10.10.11
hostnamectl set-hostname k8s-node1

#10.10.10.12
hostnamectl set-hostname k8s-node2
```



### 关闭防火墙

```shell
systemctl stop firewalld
systemctl disable firewalld
```



### 关闭selinux

```shell
setenforce 0
sed -i 's/enforcing/disabled/' /etc/selinux/config
```



### 关闭swap

```
swapoff -a
vi /etc/fstab
注释关于swap挂载的信息
```



### 添加主机名和IP的对应关系

```shell
cat >> /etc/hosts << EOF 
10.10.10.10 k8s-master
10.10.10.11 k8s-node1 
10.10.10.12 k8s-node2 
EOF
```



### 调整内核参数

```shell
# cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# sysctl --system
```



### 修改yum源

```
#修改base源
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo


#增加k8s的源
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```



## 安装docker

### 修改yum源

```
#增加docker源
curl -o /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```



```
yum -y install docker-ce-18.06.1.ce-3.el7
systemctl start docker
systemctl enable docker
docker --version
```



## 安装kubernetes组件

```
yum install -y kubelet-1.15.0 kubeadm-1.15.0 kubectl-1.15.0
systemctl enable kubelet
```



## 部署kubernets Master

在master服务器10.10.10.10上执行

### 初始化master节点

```
kubeadm init \
--apiserver-advertise-address=10.10.10.10 \
--image-repository registry.aliyuncs.com/google_containers \
--kubernetes-version v1.15.10 \
--service-cidr=10.1.0.0/16 \
--pod-network-cidr=10.244.0.0/16
```



### 准备kubeclt工具使用环境

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```



### 安装网络插件

```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml
```

![image-20200605104334415](../images/image-20200605104334415.png)

## 部署node节点

在初始化master节点是会生成加入master节点集群的token，此token有效期为1小时，如果失效了需要手动生成新的token

```
kubeadm join 10.10.10.10:6443 --token 0et5h5.8qheqfbgklfmd6yj \
    --discovery-token-ca-cert-hash sha256:8e0a3a651da53442966febc2eee384767702aef9dbb5cd0976720dbc2f43e9d0
```

![image-20200605104310938](../images/image-20200605104310938.png)

## 检查集群运行状态

在master节点上执行

```
kubectl get nodes
```

![image-20200605104248555](../images/image-20200605104248555.png)

```
kubectl get pod,svc -n kube-system
```

确认所有服务都的状态都在Running状态

![image-20200605152435227](../images/image-20200605152435227.png)

到这里我们的K8S集群就基本部署完成了，接下来可以根据自己的需求进行部署dashboard、ingress等插件

