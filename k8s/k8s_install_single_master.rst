单master部署
=========================


.. toctree::
   :maxdepth: 2
   :caption: Contents:
   
   
初始化环境
----------

..  code-block:: shell

	# 关闭防火墙
	$ systemctl stop firewalld
	$ systemctl disable firewalld

	# 关闭selinux
	$ sed -i 's/enforcing/disabled/' /etc/selinux/config
	$ setenforce 0

	# 关闭swap
	$ swapoff -a #临时
	$ vi /etc/fstab #永久

	# 添加主机名和IP的对应关系
	$ vim /etc/hosts
	10.10.10.50 k8s-01
	10.10.10.51 k8s-02
	10.10.10.52 k8s-03

	# 将桥接的IPv4流量传递到iptables的链
	$ cat > /etc/sysctl.d/k8s.conf << EOF
	net.bridge.bridge-nf-call-ip6tables = 1
	net.bridge.bridge-nf-call-iptables = 1
	net.ipv4.ip_forward = 1
	EOF
	$ sysctl –system
	
	# 安装工具包**
	$ yum install ntpdate wget vim -y

	# 同步时间
	$ ntpdate ntp.api.bz


安装 Docker
-----------

..  code-block:: shell

	$ wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
	$ yum -y install docker-ce-18.06.1.ce-3.el7
	$ systemctl enable docker && systemctl start docker
	$ docker –version
	Docker version 18.06.1-ce, build e68fc7a


安装k8s
-----------

	#添加阿里云软件源

..  code-block:: shell

	$ cat << EOF > /etc/yum.repos.d/kubernetes.repo
	[kubernetes]
	name=Kubernetes
	baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
	enabled=1
	gpgcheck=1
	repo_gpgcheck=1
	gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
	http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
	EOF

	# 安装指定版本的kubeadm，kubelet和kubectl
	$ yum install -y kubelet-1.14.0 kubeadm-1.14.0 kubectl-1.14.0
	$ systemctl enable kubelet

	# 安装k8s
	在k8s-01(10.10.10.50)节点上执行
	$ kubeadm init   –apiserver-advertise-address=10.10.10.50  
	–image-repository registry.aliyuncs.com/google_containers  
	–kubernetes-version v1.14.0   –service-cidr=10.1.0.0/16  
	–pod-network-cidr=10.244.0.0/16
	
	# 配置kubectl工具
	$ mkdir -p $HOME/.kube
	$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	$ sudo chown :math:`(id -u):`\ (id -g) $HOME/.kube/config
	$ kubectl get nodes


安装Pod网络插件
---------------
..  code-block:: shell

	$ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml

	#加入k8s node

	kubeadm join 10.10.10.50:6443 –token s3tw0x.d79fj7gw3o3fr0me
	–discovery-token-ca-cert-hash
	sha256:99c0d0bc448588a2abb02643fcc18fc8d8bb31878222cda7294ffa6b4cf2fc26

测试kubernetes集群
------------------

..  code-block:: shell

	# 在Kubernetes集群中创建一个pod，验证是否正常运行：
	$ kubectl create deployment nginx –image=nginx
	$ kubectl expose deployment nginx –port=80 –type=NodePort
	$ kubectl get pod,svc

部署Dashboard
-------------

**最好先下载下来，因为我们要修改一部分内容**

..  code-block:: shell

	# 使用下载yaml的方式部署
	$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml

	# 下载配置文件
	$ wget https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml

	修改以下内容：
	默认Dashboard只能集群内部访问，修改Service为NodePort类型，暴露到外部：不修改的话外部不能访问。
	kind: Service
	apiVersion: v1
	metadata:
	labels:
	k8s-app: kubernetes-dashboard
	name: kubernetes-dashboard
	namespace: kube-system
	spec:
	type: NodePort
	ports:
	- port: 443
	targetPort: 8443
		nodePort: 30000
		selector: