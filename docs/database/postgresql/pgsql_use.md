# Postgresql 日常使用



## 创建数据库

```sql
CREATE DATABASE dbname;
```



## 创建用户

```
CREATE USER testUser WITH PASSWORD '*****';
```



## 授权用户访问数据库

```sql
GRANT ALL PRIVILEGES ON DATABASE testDB TO user_name;
\c testDB
GRANT ALL PRIVILEGES ON all tables in schema public TO user_name;
```



## 数据库删除

```
DROP DATABASE dbname;
```



### 数据库导入

```shell
psql -d db_name -U user_name -f sql_file.sql
```

