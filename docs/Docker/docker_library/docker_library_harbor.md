# Docker私有仓库--Harbor

## 简介

Harbor是一个开源的容器映像仓库，它使用基于角色的访问控制来保护映像，扫描映像中的漏洞，并将映像标记为受信任的。作为一个CNCF孵化项目，Harbor提供了遵从性、性能和互操作性，帮助您在Kubernetes和Docker等云本地计算平台上一致且安全地管理映像。

官网地址：https://goharbor.io/

Github地址：https://github.com/goharbor/harbor



### 硬件配置

官方建议如下：

| Resource | Minimum | Recommended |
| :------- | :------ | :---------- |
| CPU      | 2 CPU   | 4 CPU       |
| Mem      | 4 GB    | 8 GB        |
| Disk     | 40 GB   | 160 GB      |

### 软件配置

官方建议如下：

| Software       | Version                       | Description                                                  |
| :------------- | :---------------------------- | :----------------------------------------------------------- |
| Docker engine  | Version 17.06.0-ce+ or higher | For installation instructions, see [Docker Engine documentation](https://docs.docker.com/engine/installation/) |
| Docker Compose | Version 1.18.0 or higher      | For installation instructions, see [Docker Compose documentation](https://docs.docker.com/compose/install/) |
| Openssl        | Latest is preferred           | Used to generate certificate and keys for Harbor             |



## 安装部署

下载二进制软件包，建议使用离线安装包，因为某些不可抗力的因素在线安装下载镜像可能会失败或者十分缓慢

### 解压安装包

这里是提前将下载好的软件包上传到/data/soft目录下

```shell
# cd /data/soft
# tar xf harbor-offline-installer-v1.9.3.tgz
```

### 修改安装配置

```shell
# cd harbor
# vim harbor.yml
```

修改以下配置项目：

hostname：可以改成自己的域名或者主机ip

http:

​     port: 80    监听端口，是指映射到宿主机上的端口

harbor_admin_password: 默认管理密码

data_volume:  数据存储路径

### 执行安装脚本

需要稍微等待一会

```
# ./install.sh
```

看到下图就说明安装成功了

![](../images/image-20200603140521435.png) 



这时就可以通过页面访问了

![image-20200603140559161](../images/image-20200603140559161-1591173077539.png) 





## 小坑

因为是使用虚拟机进行的测试，有时候重启虚拟机后，登陆提示密码错误，明明没有修改过密码就是提示密码错误问题，这时候可以去看看容器是否都启动起来了。这种情况大部分情况都是因为数据库容器未启动造成的，重启数据库容器即可。