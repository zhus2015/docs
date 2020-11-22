# Gitlab找回管理员密码



## 1、链接到gitlab安装服务器

连接到gitlab服务器后需要切换到git用户

```sh
root@localhost gitlab]# su - git
Last login: Tue Aug 11 04:05:00 CST 2020 on pts/0
-sh-4.2$ ls
```



## 2、进入gitlab控制台

```sh
-sh-4.2$ gitlab-rails console -e production
--------------------------------------------------------------------------------
 GitLab:       13.2.2-ee (618883a1f9d) EE
 GitLab Shell: 13.3.0
 PostgreSQL:   11.7
--------------------------------------------------------------------------------
Loading production environment (Rails 6.0.3.1)
```

有些资料上写的进入的命令中没有-e选项，可能是新版本程序增加的改选项



## 3、查询超级管理员信息

输入user = User.where(id:1).first查询id为1的用户对象，因为超级管理员用户默认都是1，也可以使用username来查询用户

```sh
irb(main):001:0> user = User.where(id:1).first
=> #<User id:1 @root>
```



## 4、重置密码

输入user.password='密码'，密码位置填写您新的密码即可。然后再输入user.save!保存用户，注意新版本的gitlab对密码强度有要求，我开始使用了6位密码，系统提示密码强度不够，后面使用了8位密码就好了

```sh
irb(main):002:0> user.password='123456'
=> "123456"
irb(main):003:0> user.save!
Traceback (most recent call last):
        1: from (irb):3
ActiveRecord::RecordInvalid (Validation failed: Password is too short (minimum is 8 characters))
irb(main):004:0> user = User.where(id:1).first
=> #<User id:1 @root>
irb(main):005:0> user.password='12345678'
=> "12345678"
irb(main):006:0> user.save!
Enqueued ActionMailer::MailDeliveryJob (Job ID: 8552e2fa-7c04-482a-a96c-0a24b9c43569) to Sidekiq(mailers) with arguments: "DeviseMailer", "password_change", "deliver_now", {:args=>[#<GlobalID:0x00007fe5d52679e8 @uri=#<URI::GID gid://gitlab/User/1>>]}
=> true
```



## 5、重启gitlab服务

这里做个说明，查到的资料很多都说直接去登录页面进行登录即可，这里我测试好几次都不行，然后抱着试试的态度重启了gitlab的服务，没想到居然好了

```sh
[root@localhost gitlab]# gitlab-ctl restart all
[root@localhost gitlab]#  gitlab-ctl status
run: alertmanager: (pid 1625) 2266s; run: log: (pid 1624) 2266s
run: gitaly: (pid 1586) 2266s; run: log: (pid 1585) 2266s
run: gitlab-exporter: (pid 1610) 2266s; run: log: (pid 1609) 2266s
run: gitlab-workhorse: (pid 1601) 2266s; run: log: (pid 1600) 2266s
run: grafana: (pid 1614) 2266s; run: log: (pid 1613) 2266s
run: logrotate: (pid 1603) 2266s; run: log: (pid 1602) 2266s
run: nginx: (pid 1608) 2266s; run: log: (pid 1607) 2266s
run: node-exporter: (pid 1622) 2266s; run: log: (pid 1621) 2266s
run: postgres-exporter: (pid 1627) 2266s; run: log: (pid 1626) 2266s
run: postgresql: (pid 1588) 2266s; run: log: (pid 1587) 2266s
run: prometheus: (pid 1629) 2266s; run: log: (pid 1623) 2266s
run: puma: (pid 1590) 2266s; run: log: (pid 1589) 2266s
run: redis: (pid 1584) 2266s; run: log: (pid 1581) 2266s
run: redis-exporter: (pid 1628) 2266s; run: log: (pid 1620) 2266s
run: sidekiq: (pid 1595) 2266s; run: log: (pid 1594) 2266s
```

