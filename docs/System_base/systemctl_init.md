#防火墙及Selinux配置

	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
	setenforce 0 >/dev/null 2>&1
	systemctl stop firewalld.service
	systemctl disable firewalld.service


#更改yum源

```
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo

curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
sed -i 's|^#baseurl=https://download.fedoraproject.org/pub|baseurl=https://mirrors.aliyun.com|' /etc/yum.repos.d/epel*
sed -i 's|^metalink|#metalink|' /etc/yum.repos.d/epel*

yum clean all
yum makecache
```



#时间同步软件安装

```
yum install chronyd
systemctl start chronyd
systemctl enable chronyd
```





#tengine安装

```

./configure --with-debug --with-stream \
--prefix=/data/nginx \
--add-module=./modules/ngx_http_upstream_check_module \
--add-module=./modules/ngx_http_reqstat_module \
--add-module=./modules/nginx-module-vts \
--add-module=./modules/echo-nginx-module \
--add-module=./modules/ngx_image_thumb \
--with-http_image_filter_module
```

