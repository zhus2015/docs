# Oracle更改字符编码



```sql
# 连接数据库
SQL> conn /as sysdba

已连接。
SQL> shutdown immediate;
数据库已关闭。
已经卸载数据库。

SQL> startup mount
数据库装载完毕。

SQL> ALTER SYSTEM ENABLE RESTRICTED SESSION;
系统已更改。
SQL> ALTER SYSTEM SET JOB_QUEUE_PROCESSES=0;
系统已更改。
SQL> ALTER SYSTEM SET AQ_TM_PROCESSES=0;

系统已更改。
SQL> alter database open;

数据库已更改。
SQL> ALTER DATABASE CHARACTER SET ZHS16GBK;

第1行出现错误：
ORA-12712: new character set must be a superset of old character set
提示我们的字符集：新字符集必须为旧字符集的超集，这时我们可以跳过超集的检查做更改：
SQL> ALTER DATABASE character set INTERNAL_USE ZHS16GBK;

数据库已更改。
SQL> select * from v$nls_parameters;
RARAMETER
VALUE
NAS_LANGUAGE
SIMPLIFIED CHINESE
NLS_TERRITORY
CHINA
……

SQL> shutdown immediate;
SQL> startup

ORA-01081:???????ORACLE-???????意思是无法启动已运行的ORACLE，请首先关闭它
SQL> select * from v$nls_parameters;


至此，字符集的修改就完成了，我们可以通过输入命令验证一下，其结果已经变成了ZHS16GBK了。

SQL> select userenv(‘language’) from dual;
```

