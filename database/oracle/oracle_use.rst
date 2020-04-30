Oracle常用操作
================

查看表空间使用情况
-------------------

**方法一**

..  code-block:: shell

	SQL> SELECT
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
	

**方法二**

..  code-block:: shell

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


查看表空间物理文件的名称及大小
-------------------------------

..  code-block:: shell

	SELECT
		tablespace_name,
		file_id,
		file_name,
		round( bytes / ( 1024 * 1024 ), 0 ) total_space 
	FROM
		dba_data_files 
	ORDER BY
		tablespace_name;

创建表空间
---------------

..  code-block:: shell

	create tablespace HA
	datafile '/data/app/oracle/oradata/orcl/HA.pbf' 
	size 2048m
	autoextend on
	next 50m
	maxsize 20480m
	extent management local; 

删除表空间和文件
------------------

..  code-block:: shell

	DROP TABLESPACE HA INCLUDING CONTENTS AND DATAFILES; 

改变表空间状态
------------------


**1、使表空间脱机**

..  code-block:: shell

	ALTER TABLESPACE HA OFFLINE;


**2、使表空间联机**

..  code-block:: shell

	ALTER TABLESPACE HA ONLINE;


**3.使数据文件脱机**

..  code-block:: shell

	ALTER DATABASE DATAFILE 3 OFFLINE; 
 
**4.使数据文件联机**

..  code-block:: shell

	ALTER DATABASE DATAFILE 3 ONLINE; 

扩展表空间
---------------

**查询表空间名称及其数据文件**

..  code-block:: shell

	select tablespace_name, file_id, file_name,  
	round(bytes/(1024*1024),0) total_space 
	from dba_data_files 
	order by tablespace_name; 

**1.增加数据文件**

..  code-block:: shell

	ALTER TABLESPACE HA ADD DATAFILE '/data/app/oracle/oradata/orcl/HA1.pbf' SIZE 1024M;

**2.扩展源数据文件**

..  code-block:: shell

	ALTER DATABASE DATAFILE '/data/app/oracle/oradata/orcl/HA.pbf' RESIZE 4196M;

**3.设定数据文件自动扩展**
  
..  code-block:: shell

	ALTER DATABASE DATAFILE '/data/app/oracle/oradata/orcl/HA1.pbf'
	AUTOEXTEND ON NEXT 100M 
	MAXSIZE 10000M; 