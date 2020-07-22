# Harbor忘记管理用户密码

## 登陆Harobor数据库容器

```
$ docker exec -it harbor-db /bin/bash
```



## 登陆数据库

```shell
postgres [ / ]$ psql -h postgresql -d postgres -U postgres  #这种方法需要数据库密码，如果未修改密码默认为root123
postgres [ / ]$ psql -U postgres -d postgres -h 127.0.0.1 -p 5432  #或者用这个可以不输入密码
```



## 切换数据库

```plsql
postgres=# \c registry
```



## 修改密码

修改密码为默认密码Harbor12345

```plsql
postgres=# update harbor_user set password='a71a7d0df981a61cbb53a97ed8d78f3e', salt='ah3fdh5b7yxepalg9z45bu8zb36sszmr'  where username='admin';
```

