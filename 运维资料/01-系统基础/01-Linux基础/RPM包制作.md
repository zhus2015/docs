# 制作Node-export的RPM安装包

## 基础环境准备

安装rpm包打包使用工具

```
[root@localhost ~]# yum install rpm-build rpm-dev rpmdevtools –y
```

 

## 创建RPM打包环境

```
[root@localhost ~]# rpmdev-setuptree
```

执行此命令后会在当前用户的家目录下生成rpmbuild目录

 

## 创建打包相关脚本

```sh
Name:           node_exporter
Version:        1.0.1
Release:        0
Summary:        node_exporter build for fosung

Group:          System Environment/Daemons
License:        GPL
Vendor:         loding.top
Packager:       zs

%description
This RPM package is based on the node_export 1.0.1 package

%prep

#安装前
%pre
grep prometheus /etc/passwd > /dev/null
if [ $? != 0 ]
then 
  useradd prometheus -M -s /sbin/nologin
fi
#ss -lntp |grep ":9100" >/dev/null
#if [ $? == 0 ]
#then
#  sed -i 's#ExecStart.*#ExecStart=/usr/bin/node_exporter --web.listen-address=:1900#g' /usr/lib/systemd/system/node_exporter.service
#  systemctl daemon-reload
#fi

%post
chmod +x /usr/bin/node_exporter
systemctl enable node_exporter
systemctl start node_exporter

#卸载前
%preun 
if [ $1 == 0 ];then
  systemctl stop node_exporter
  systemctl disable node_exporter
fi

#卸载后
%postun
[ -L /etc/systemd/system/multi-user.target.wants/node_exporter.service ] && unlink /etc/systemd/system/multi-user.target.wants/node_exporter.service
rm -rf /usr/bin/node_exporter

%clean 
#rm -rf %{buildroot}

%files
%defattr (-,root,root,0777)
/usr/bin/node_exporter
/usr/lib/systemd/system/node_exporter.service
```





## 创建项目目录并上传文件

文件目录和打包脚本中的Version、Name等参数有关系，注意修改

```sh
# mkdir –p /root/rpmbuild/BUILDROOT/node_exporter-1.0.1-0.x86_64/usr/bin
# mkdir –p /root/rpmbuild/BUILDROOT/node_exporter-1.0.1-0.x86_64/usr/lib/systemd/system
```

 

将执行文件node_exporter文件上传到/root/rpmbuild/BUILDROOT/node_exporter-1.0.1-0.x86_64/usr/bin目录下

将启动文件node_exporter.service上传到/root/rpmbuild/BUILDROOT/node_exporter-1.0.1-0.x86_64/usr/lib/systemd/system目录下

 

## 执行打包命令

```
[root@localhost SPECS]# rpmbuild -ba node_exporter.spec
```

对应的RPM包会在目录/root/rpmbuild/RPMS/x86_64目录下