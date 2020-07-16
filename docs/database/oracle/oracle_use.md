# Oracle日常操作

## 表空间相关操作

查看数据库快大小(11g默认大小8192)

select value from v$parameter where name='db_block_size'

表空间数据文件容量与DB_BLOCK_SIZE有关，在初始建库时，DB_BLOCK_SIZE要根据实际需要，设置为 4K、8K、16K、32K、64K等几种大小，ORACLE的物理文件最大只允许4194304个数据块（由操作系统决定），表空间数据文件的最大值为 4194304×DB_BLOCK_SIZE/1024M

- DB_BLOCK_SIZE作为数据库的最小操作单位，是在创建数据库的时候指定的，在创建完数据库之后便不可修改。要修改DB_BLOCK_SIZE，需要重建数据库。一般可以将数据EXP出来，然后重建数据库，指定新的DB_BLOCK_SIZE，然后再将数据IMP进数据库。
- DB_BLOCK_SIZE一般设置为操作系统块的倍数，即2K,4K,8K,16K或32K，但它的大小一般受数据库用途的影响。对于联机事务，其特点是事务量大，但每个事务处理的数据量小，所以DB_BLOCK_SIZE设置小点就足够了，一般为4K或者8K，设置太大话一次读出的数据有部分是没用的，会拖慢数据库的读写时间，同时增加无必要的IO操作。而对于数据仓库和ERP方面的应用，每个事务处理的数据量很大，所以DB_BLOCK_SIZE一般设置得比较大，一般为8K，16K或者32K，此时如果DB_BLOCK_SIZE小的话，那么I/O自然就多，消耗太大。
- 大一点的DB_BLOCK_SIZE对索引的性能有一定的提高。因为DB_BLOCK_SIZE比较大的话，一个DB_BLOCK一次能够索引的行数就比较多。
- 对于行比较大的话，比如一个DB_BLOCK放不下一行，数据库在读取数据的时候就需要进行行链接，从而影响读取性能。此时DB_BLOCK_SIZE大一点的话就可以避免这种情况的发生。

在本机单个表空间文件大小超过32G时，表空间容量就达到了最大值，数据库就不能继续增加信息了，扩容方法有以下三种

1、多个数据文件叠加，即为表空间增加数据文件

2、扩大db_block_size

![img](../images/clipboard.png) 

3、创建bigfile表空间

create bigfile tablespace 

![img](../images/clipboard.png) 

需要注意的是使用bigfile表空间，它只能支持一个数据文件。也就是说这个文件的最大大小就是表空间最大大小，你不可能通过增加数据文件来扩大该表空间的大小。



### **查看表空间使用情况**

> 方法一

```sql
SELECT
	a.tablespace_name AS "表空间名",
	a.bytes / 1024 / 1024 AS "表空间大小 ( M )",
	( a.bytes - b.bytes ) / 1024 / 1024 AS "已使用空间 ( M )",
	b.bytes / 1024 / 1024 "空闲空间 ( M )",
	round((( a.bytes - b.bytes ) / a.bytes ) * 100, 2 ) "使用比" 
FROM
	( SELECT tablespace_name, sum( bytes ) bytes FROM dba_data_files GROUP BY tablespace_name ) a,
	( SELECT tablespace_name, sum( bytes ) bytes, max( bytes ) largest FROM dba_free_space GROUP BY tablespace_name ) b 
WHERE
    a.tablespace_name = b.tablespace_name 
ORDER BY
	(( a.bytes - b.bytes ) / a.bytes ) DESC;
```

> 方法二

```sql
SELECT
	a.tablespace_name "表空间名称",
	total / ( 1024 * 1024 ) "表空间大小(M)",
	free / ( 1024 * 1024 ) "表空间剩余大小(M)",
	( total - free ) / ( 1024 * 1024 ) "表空间使用大小(M)",
	total / ( 1024 * 1024 * 1024 ) "表空间大小(G)",
	free / ( 1024 * 1024 * 1024 ) "表空间剩余大小(G)",
	( total - free ) / ( 1024 * 1024 * 1024 ) "表空间使用大小(G)",
	round(( total - free ) / total, 4 ) * 100 "使用率 %" 
FROM
	( SELECT tablespace_name, SUM( bytes ) free FROM dba_free_space GROUP BY tablespace_name ) a,
	( SELECT tablespace_name, SUM( bytes ) total FROM dba_data_files GROUP BY tablespace_name ) b 
WHERE
	a.tablespace_name = b.tablespace_name
```

> 查看表空间物理文件的名称及大小

```sql
SELECT
	tablespace_name,
	file_id,
	file_name,
	round( bytes / ( 1024 * 1024 ), 0 ) total_space 
FROM
	dba_data_files 
ORDER BY
	tablespace_name;
```



### 创建表空间

```sql
create tablespace HA
datafile '/data/app/oracle/oradata/orcl/HA.pbf' 
size 2048m
autoextend on
next 50m
maxsize 20480m
extent management local; 
```



### 删除表空间和文件

```sql
DROP TABLESPACE HA INCLUDING CONTENTS AND DATAFILES; 
```



### 改变表空间状态

> 使表空间脱机

```sql
ALTER TABLESPACE HA OFFLINE;
```

> 使表空间联机

```sql
ALTER TABLESPACE HA ONLINE;
```

> 使数据文件脱机 

```sql
ALTER DATABASE DATAFILE 3 OFFLINE; 
```

> 使数据文件联机 

```sql
ALTER DATABASE DATAFILE 3 ONLINE; 
```



### 扩展表空间

查询表空间名称及其数据文件

```sql
select tablespace_name, file_id, file_name,  
round(bytes/(1024*1024),0) total_space 
from dba_data_files 
order by tablespace_name; 
```



> 增加数据文件

```sql
ALTER TABLESPACE HA ADD DATAFILE '/data/app/oracle/oradata/orcl/HA1.pbf' SIZE 1024M;
```

> 扩展源数据文件

```sql
ALTER DATABASE DATAFILE '/data/app/oracle/oradata/orcl/HA.pbf' RESIZE 4196M;
```

> 设定数据文件自动扩展  

```sql
ALTER DATABASE DATAFILE '/data/app/oracle/oradata/orcl/HA1.pbf'
AUTOEXTEND ON NEXT 100M 
MAXSIZE 10000M; 
```



## 数据导入导出

### 导出

exp 用户/密码@实例名  file=输出文件位置 log=输出日志

注意如果密码有特殊符号的情况最好手动输入密码，避免有转义造成问题。

```shell
exp test/test@ORCL file=./test.dmp log=./test.log
```



### 导入

imp 用户名/密码@实例名 file=导入的dmp文件路径 full=y

```shell
imp test/test@ORCL file=./test.dmp full=y
```

