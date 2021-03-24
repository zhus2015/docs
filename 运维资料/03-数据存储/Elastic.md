## 故障处理

查看集群健康状态

```shell
curl -XGET http://localhost:9200/_cluster/health\?pretty
```

查看所有分片状态

```shell
curl -XGET http://localhost:9200/_cat/shards
```





查看故障分片

```shell
curl -XGET localhost:9200/_cluster/allocation/explain?pretty
```



强制启用不可用分片

```shell
curl -XPOST 'localhost:9200/_cluster/reroute' -d 
'{ "commands" :
      [ { "allocate" : 
          { "index" : "party-build-edu-2021", "shard" : 0, "node": "uNQzmQkZSGO5k9smDWAg5A", "allow_primary": "true" }
      }]
}'
```

