

```yml
version: '2.2'
services:
  cerebro:
    image: lmenezes/cerebro:0.8.3
    container_name: cerebro
    ports:
      - "9000:9000"
    command:
      - -Dhosts.0.host=http://elasticsearch:9200
    networks:
      - es72net
  kibana:
    image: docker.elastic.co/kibana/kibana:7.2.0
    container_name: kibana72
    environment:
      #- I18N_LOCALE=zh-CN
      - XPACK_GRAPH_ENABLED=true
      - TIMELION_ENABLED=true
      - XPACK_MONITORING_COLLECTION_ENABLED="true"
      - elasticsearch.hosts=es72_01:9200,es72_02:9200,es72_03:9200
    ports:
      - "5601:5601"
    networks:
      - es72net
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.2.0
    container_name: es72_01
    environment:
      - cluster.name=geektime
      - node.name=es72_01
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - discovery.seed_hosts=es72_01,es72_02,es72_03
      - network.publish_host=es72_01
      - cluster.initial_master_nodes=es72_01,es72_02,es72_03
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es72data1:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
    networks:
      - es72net
  elasticsearch2:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.2.0
    container_name: es72_02
    environment:
      - cluster.name=geektime
      - node.name=es72_02
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - discovery.seed_hosts=es72_01,es72_02,es72_03
      - network.publish_host=es72_02
      - cluster.initial_master_nodes=es72_01,es72_02,es72_03
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es72data2:/usr/share/elasticsearch/data
    networks:
      - es72net
  elasticsearch3:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.2.0
    container_name: es72_03
    environment:
      - cluster.name=geektime
      - node.name=es72_03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - discovery.seed_hosts=es72_01,es72_02,es72_03
      - network.publish_host=es72_03
      - cluster.initial_master_nodes=es72_01,es72_02,es72_03
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es72data3:/usr/share/elasticsearch/data
    networks:
      - es72net


volumes:
  es72data1:
    driver: local
  es72data2:
    driver: local
  es72data3:
    driver: local

networks:
  es72net:
    driver: bridge

```





```yml
version: '2.2'
services:
  logstash:
    image: logstash:7.3.0
    container_name: logstash73
    restart: always
    ulimits:
      memlock:
        soft: -1
        hard: -1
    environment:
      TZ: Asia/Shanghai
    volumes:
      - /data/es-logstash/logstash.conf:/usr/share/logstash/config/logstash.conf
      - /data/movielens:/data/movielens

networks:
  default:
    external:
      name: es72_es72net

```

