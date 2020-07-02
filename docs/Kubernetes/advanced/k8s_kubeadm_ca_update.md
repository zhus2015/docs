# Kubeadm部署集群证书更新

!!! warning "注意注意，一定要在证书到期前提前更换"

!!! warning "本文未在生产环境进行过使用，请严格测试后使用"



### 查看证书时间

首先查看证书的时间，可以看到我的证书还有364天才会到期，这里我只是做测试，生产使用请慎重

```shell
[root@k8s-master kubernetes]# kubeadm alpha certs check-expiration
CERTIFICATE                EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
admin.conf                 Jul 01, 2021 08:13 UTC   364d            no      
apiserver                  Jul 01, 2021 08:13 UTC   364d            no      
apiserver-etcd-client      Jul 01, 2021 08:13 UTC   364d            no      
apiserver-kubelet-client   Jul 01, 2021 08:13 UTC   364d            no      
controller-manager.conf    Jul 01, 2021 08:13 UTC   364d            no      
etcd-healthcheck-client    Jul 01, 2021 08:13 UTC   364d            no      
etcd-peer                  Jul 01, 2021 08:13 UTC   364d            no      
etcd-server                Jul 01, 2021 08:13 UTC   364d            no      
front-proxy-client         Jul 01, 2021 08:13 UTC   364d            no      
scheduler.conf             Jul 01, 2021 08:13 UTC   364d            no      
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
[root@k8s-master kubernetes]# kubeadm alpha certs check-expiration
CERTIFICATE                EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
admin.conf                 Jul 02, 2021 06:29 UTC   364d            no      
apiserver                  Jul 02, 2021 06:29 UTC   364d            no      
apiserver-etcd-client      Jul 02, 2021 06:29 UTC   364d            no      
apiserver-kubelet-client   Jul 02, 2021 06:29 UTC   364d            no      
controller-manager.conf    Jul 02, 2021 06:29 UTC   364d            no      
etcd-healthcheck-client    Jul 02, 2021 06:29 UTC   364d            no      
etcd-peer                  Jul 02, 2021 06:29 UTC   364d            no      
etcd-server                Jul 02, 2021 06:29 UTC   364d            no      
front-proxy-client         Jul 02, 2021 06:29 UTC   364d            no      
scheduler.conf             Jul 02, 2021 06:29 UTC   364d            no   
```



### 应用证书

```shell
[root@k8s-master ~]# kubeadm upgrade apply --certificate-renewal v1.15.11
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[preflight] Running pre-flight checks.
[upgrade] Making sure the cluster is healthy:
[upgrade/version] You have chosen to change the cluster version to "v1.15.11"
[upgrade/versions] Cluster version: v1.15.11
[upgrade/versions] kubeadm version: v1.15.11
[upgrade/confirm] Are you sure you want to proceed with the upgrade? [y/N]: y
[upgrade/prepull] Will prepull images for components [kube-apiserver kube-controller-manager kube-scheduler etcd]
[upgrade/prepull] Prepulling image for component etcd.
[upgrade/prepull] Prepulling image for component kube-apiserver.
[upgrade/prepull] Prepulling image for component kube-controller-manager.
[upgrade/prepull] Prepulling image for component kube-scheduler.
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-kube-scheduler
[apiclient] Found 0 Pods for label selector k8s-app=upgrade-prepull-etcd
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-kube-apiserver
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-kube-controller-manager
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-etcd
[apiclient] Found 1 Pods for label selector k8s-app=upgrade-prepull-kube-scheduler
[upgrade/prepull] Prepulled image for component kube-scheduler.
[upgrade/prepull] Prepulled image for component kube-apiserver.
[upgrade/prepull] Prepulled image for component kube-controller-manager.
[upgrade/prepull] Prepulled image for component etcd.
[upgrade/prepull] Successfully prepulled the images for all the control plane components
[upgrade/apply] Upgrading your Static Pod-hosted control plane to version "v1.15.11"...
Static pod: kube-apiserver-k8s-master hash: cdce0479785511903e1c5c69ef57a938
Static pod: kube-controller-manager-k8s-master hash: a6ec9ef765edb475611dfa2288b9741c
Static pod: kube-scheduler-k8s-master hash: 3f5741cf13258502241439acc82697ad
[upgrade/etcd] Upgrading to TLS for etcd
[upgrade/staticpods] Writing new Static Pod manifests to "/etc/kubernetes/tmp/kubeadm-upgraded-manifests465586650"
[upgrade/staticpods] Preparing for "kube-apiserver" upgrade
[upgrade/staticpods] Current and new manifests of kube-apiserver are equal, skipping upgrade
[upgrade/staticpods] Preparing for "kube-controller-manager" upgrade
[upgrade/staticpods] Current and new manifests of kube-controller-manager are equal, skipping upgrade
[upgrade/staticpods] Preparing for "kube-scheduler" upgrade
[upgrade/staticpods] Current and new manifests of kube-scheduler are equal, skipping upgrade
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.15" in namespace kube-system with the configuration for the kubelets in the cluster
[kubelet-start] Downloading configuration for the kubelet from the "kubelet-config-1.15" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.15.11". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
```

