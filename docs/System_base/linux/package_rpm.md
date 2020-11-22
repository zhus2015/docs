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
# cd /root/rpmbuild/SPECS
# vim node_exporter.spec
Name:      node_exporter

Version:    1.0.1

Release:    0

Summary:    node_exporter

 

Group:     System Environment/Daemons

License:    GPL

Vendor:     MySelf.com 

%description

%pre  

%preun 

%postun  

%clean 

%files

%defattr (-,root,root,0777)
/usr/bin/node_exporter
/usr/lib/systemd/system/node_exporter.service


%post
chmod +x /usr/bin/node_exporter
systemctl enable node_exporter
systemctl start node_exporter
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