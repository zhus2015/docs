# systemctl进程管理工具

本文内容参考：[Centos7 自定义systemctl服务脚本]( https://blog.csdn.net/yyy987456123/article/details/9820044 )

Linux 服务管理两种方式service和systemctl

systemd是Linux系统最新的初始化系统(init),作用是提高系统的启动速度，尽可能启动较少的进程，尽可能更多进程并发启动。

systemd对应的进程管理命令是systemctl



## 编写自定义服务脚本

文件位置：

/usr/lib/systemd/system #系统服务，开机不需要登录就能运行的程序（可以用于开机自启）

/usr/lib/systemd/user #用户服务，需要登录后才能运行程序

服务脚本一般以.service命名，脚本中分为三部分：[Unit]、[Service]、[Install]

这里借用jumpserver的启动脚本进行说明

```shell
[Unit]
Description=Jumpserver Core Server
Documentation=https://github.com/jumpserver/jumpserver.git
After=network.target mariadb.service redis.service docker.service
Wants=mariadb.service redis.service docker.service

[Service]
Type=forking
TimeoutStartSec=0
WorkingDirectory=/opt/jumpserver
PIDFile=/opt/jumpserver/tmp/jms.pid
Environment="PATH=/opt/py3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin"
ExecStart=/opt/jumpserver/jms start -d
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/opt/jumpserver/jms stop

[Install]
WantedBy=multi-user.target
```



[Unit]区块字段描述

```
Description：简单描述
Documentation：文档地址
Requires：当前 Unit 依赖的其他 Unit，如果它们没有运行，当前 Unit 会启动失败
Wants：与当前 Unit 配合的其他 Unit，如果它们没有运行，当前 Unit 不会启动失败
BindsTo：与Requires类似，它指定的 Unit 如果退出，会导致当前 Unit 停止运行
Before：如果该字段指定的 Unit 也要启动，那么必须在当前 Unit 之后启动
After：如果该字段指定的 Unit 也要启动，那么必须在当前 Unit 之前启动
Conflicts：这里指定的 Unit 不能与当前 Unit 同时运行
Condition...：当前 Unit 运行必须满足的条件，否则不会运行
Assert...：当前 Unit 运行必须满足的条件，否则会报启动失败
```



[Service]区块字段描述

```
Type：定义启动时的进程行为。它有以下几种值。
Type=simple：默认值，执行ExecStart指定的命令，启动主进程
Type=forking：以 fork 方式从父进程创建子进程，创建后父进程会立即退出
Type=oneshot：一次性进程，Systemd 会等当前服务退出，再继续往下执行
Type=dbus：当前服务通过D-Bus启动
Type=notify：当前服务启动完毕，会通知Systemd，再继续往下执行
Type=idle：若有其他任务执行完毕，当前服务才会运行
ExecStart：启动当前服务的命令
ExecStartPre：启动当前服务之前执行的命令
ExecStartPost：启动当前服务之后执行的命令
ExecReload：重启当前服务时执行的命令
ExecStop：停止当前服务时执行的命令
ExecStopPost：停止当其服务之后执行的命令
RestartSec：自动重启当前服务间隔的秒数
Restart：定义何种情况 Systemd 会自动重启当前服务 
    no(默认值)： # 退出后无操作
    on-success:  # 只有正常退出时（退出状态码为0）,才会重启
    on-failure:  # 非正常退出时，重启，包括被信号终止和超时等
    on-abnormal: # 只有被信号终止或超时，才会重启
    on-abort:    # 只有在收到没有捕捉到的信号终止时，才会重启
    on-watchdog: # 超时退出时，才会重启
    always:      # 不管什么退出原因，都会重启
    # 对于守护进程，推荐用on-failure
KillMode的类型：
    control-group(默认)：# 当前控制组里的所有子进程，都会被杀掉
    process: # 只杀主进程
    mixed:   # 主进程将收到SIGTERM信号，子进程收到SIGKILL信号
    none:    # 没有进程会被杀掉，只是执行服务的stop命令
TimeoutSec：定义 Systemd 停止当前服务之前等待的秒数
Environment：指定环境变量
```



[Install]字段描述

```
WantedBy：它的值是一个或多个 Target，当前 Unit 激活时（enable）符号链接会放入/etc/systemd/system目录下面以 Target 名 + .wants后缀构成的子目录中
    multi-user.target: # 表示多用户命令行状态，这个设置很重要
    graphical.target:  # 表示图形用户状体，它依赖于multi-user.target
RequiredBy：它的值是一个或多个 Target，当前 Unit 激活时，符号链接会放入/etc/systemd/system目录下面以 Target 名 + .required后缀构成的子目录中
Alias：当前 Unit 可用于启动的别名
Also：当前 Unit 激活（enable）时，会被同时激活的其他 Unit
```