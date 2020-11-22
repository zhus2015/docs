# Centos更改hostname

## 方法一、hostname   临时有效

```sh
hostname test-7_45
```



## 方法二、hostnamectl 永久生效

```sh
hostnamectl  set-hostname TEST-7_45
```

hostnamectl 设置主机名时，大写会自动转换成小写

hostnamectl 设置主机名时会自动更新/etc/hostname配置文件，但是不会更新/etc/hosts文件



## 方法三、nmcli 永久有效

> nmcli

```sh
nmcli general hostname TEST-7_45
```

> nmtui

```
nmtui hostname HAHA
```

> nmtui-hostname

```sh
nmtui-hostname HAHA-TEST-7_45
```

此设置主机名时会自动更新/etc/hostname配置文件，但是不会更新/etc/hosts文件