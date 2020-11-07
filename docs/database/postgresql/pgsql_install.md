

# Centos7安装Postgresql11



## 配置Yum源

```shell
yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
```

## 安装相关软件包

```shell
yum install postgresql11 postgresql11-server postgresql11-libs postgresql11-contrib postgresql11-devel
```



## 初始化数据库

```
mkdir -p /data/pgsql
chown -R postgres.postgres /data/pgsql
su postgres
/usr/pgsql-11/bin/initdb -D /data/pgsql/11/data
```

## 修改启动脚本

```
vi /usr/lib/systemd/system/postgresql-11.service
Environment=PGDATA=/data/pgsql/11/data
```

## 修改配置文件

```
vi /data/pgsql/11/data/pg_hba.conf
host    all             all             0.0.0.0/0               md5

vi /data/pgsql/11/data/postgresql.conf
listen_addresses = '*'
```



## 启动pgsql服务

```
systemctl start postgresql-11
systemctl enable postgresql-11
```



## 修改用户密码及创建用户

```shell
su - postgres
psql -c "alter user postgres with password 'password'"
psql
postgres=# create user user_name with login password 'password';
```

