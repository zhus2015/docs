# redis数据迁移

## Aof

```
# 源实例开启 aof 功能，将在 dir 目录下生成 appendonly.aof 文件
redis-cli -h 源RedisIP -a password config ``set` `appendonly ``yes

```



```
# 将 appendonly.aof 文件放在当前路径下
redis-cli -h 目标RedisIp -a password --pipe < appendonly.aof
# 源实例关闭 aof 功能
redis-cli -h 源RedisIp -a password config ``set` `appendonly no
```

AOF 的缺点：速度慢，并且如果内容多的话，文件也比较大。而且开启 AOF 后，QPS 会比 RDB 模式写的 QPS 低。还有就是 AOF 是一个定时任务，可能会出现数据丢失的情况。



## redis-dump和redis-load



```shell
yum -y install ruby ruby-devel rubygems
# 验证
ruby -v

#升级ruby
wget https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.4.tar.gz

tar xf ruby-2.6.4.tar.gz -C /server

cd ruby-2.6.4
./configure
make
make install

#配置国内源
gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/

#安装
gem install redis-dump -V
```



## RedisShake

阿里云官方产品

开源地址：https://github.com/alibaba/RedisShake

官方文档地址：https://help.aliyun.com/document_detail/97027.html?spm=a2c4g.11186623.6.641.449e5d4aUu1ZSY



## reids同步数据到Codis集群

使用官方提供的工具redis-port

官方工具地址：https://github.com/CodisLabs/redis-port

GITHUP下载地址：https://github.com/CodisLabs/redis-port/releases/download/v1.2.1/redis-port-v1.2.1-go1.7.5-linux.tar.gz

