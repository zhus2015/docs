# Postgresql 日常使用

## 创建用户

```
CREATE USER testUser WITH PASSWORD '*****';
```

## 创建数据库

```sql
CREATE DATABASE dbname ENCODING='utf-8' TABLESPACE= pg_default owner user_name;
```



## 授权用户访问数据库

```sql
GRANT ALL PRIVILEGES ON DATABASE testDB TO user_name;


#如果库的所属主部署授权用户时，需要对schema进行授权
\c testDB
GRANT ALL PRIVILEGES ON all tables in schema public TO user_name;
```



## 数据库删除

```
DROP DATABASE dbname;
```



## 数据库导入导出

### 导入

```shell
psql -d db_name -U user_name -f sql_file.sql
```

注意导入的时候使用-U参数会改变表的owner，这是表非owner用户修改表结构或其他内容时可能会出现无权限问题。

### 导出

```sql

```





## 开启慢日志记录

全局设置
修改配置postgres.conf：

```shell
log_min_duration_statement=5000
```

然后加载配置：

```sql
postgres=# select pg_reload_conf();
postgres=# show log_min_duration_statement;
log_min_duration_statement
----------------------------
5s
(1 row)
```

　　

也可以针对某个用户或者某数据库进行设置

```sql
postgres=# alter database test set log_min_duration_statement=5000;
```



## 数据库空间查询

### 查询数据库空间大小

```sql
select pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname)) AS size from pg_database;
```

### 查询数据库中单个表的大小（不包含索引）

```sql
select pg_size_pretty(pg_relation_size('表名'));
```

### 查出所有表（包含索引）并排序

```sql
SELECT table_schema || '.' || table_name AS table_full_name, pg_size_pretty(pg_total_relation_size('"' || table_schema || '"."' || table_name || '"')) AS size
FROM information_schema.tables
ORDER BY
pg_total_relation_size('"' || table_schema || '"."' || table_name || '"') DESC limit 20
```

### 查出表大小按大小排序并分离data与index

```sql
SELECT
table_name,
pg_size_pretty(table_size) AS table_size,
pg_size_pretty(indexes_size) AS indexes_size,
pg_size_pretty(total_size) AS total_size
FROM (
SELECT
table_name,
pg_table_size(table_name) AS table_size,
pg_indexes_size(table_name) AS indexes_size,
pg_total_relation_size(table_name) AS total_size
FROM (
SELECT ('"' || table_schema || '"."' || table_name || '"') AS table_name
FROM information_schema.tables
) AS all_tables
ORDER BY total_size DESC
) AS pretty_sizes
```



## 查看连接数

### 查看最大连接数

```
show max_connections;
```



### 查看当前连接的

```shell
select count(*), usename from pg_stat_activity group by usename;

select usename, count(*) from pg_stat_activity group by usename order by count(*) desc;

```

### 查看当前连接信息

```
select datname,client_addr,pid,application_name,state from pg_stat_activity;
```



## 锁

### 查询锁



```
select T.PID, T.STATE, T.QUERY, T.WAIT_EVENT_TYPE, T.WAIT_EVENT,
       T.QUERY_START
  from PG_STAT_ACTIVITY T
 where T.DATNAME = 'cloud-platform-sso';
```



```
WITH trans AS
  (SELECT pid
   FROM pg_stat_activity
   WHERE now()-xact_start>interval '10 sec'
     AND query !~ '^COPY'
     AND STATE<>'idle'
   ORDER BY xact_start)
SELECT 'select pg_cancel_backend' || '(' || trans.pid || ');'AS killsql
FROM trans;
```





### 解锁

```
select T.PID, T.STATE, T.QUERY, T.WAIT_EVENT_TYPE, T.WAIT_EVENT,
       T.QUERY_START
  from PG_STAT_ACTIVITY T
 where T.DATNAME = 'cloud-platform-sso';
```



### 解锁用户

```
select user_unlock('xxxx');
```



```shell
alter user username valid until '2999-01-01';   --修改用户到期时间
alter user username set Passwordlock=off; --关闭用户密码错误次数限制
```

