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



### 数据库导入

```shell
psql -d db_name -U user_name -f sql_file.sql
```

注意导入的时候使用-U参数会改变表的owner，这是表非owner用户修改表结构或其他内容时可能会出现无权限问题。




