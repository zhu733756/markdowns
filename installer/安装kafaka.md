#### install java

https://linuxize.com/post/install-java-on-ubuntu-18-04/

```
sudo apt update && sudo apt install default-jdk -y && java -version
```

#### install kfaka

https://kafka.apache.org/quickstart

```
bin/zookeeper-server-start.sh config/zookeeper.properties

bin/kafka-server-start.sh config/server.properties
```



```java

./bin/kafka-run-class.sh kafka.tools.GetOffsetShell  --broker-list 192.168.88.4:9092  --topic kubesphere-logging-system --time -1 --offsets 1
 
 ./bin/zookeeper-shell.sh localhost:2181
ls /consumers
     
 bin/kafka-run-class.sh kafka.admin.ConsumerGroupCommand \
    --group metadata \
    --bootstrap-server localhost:9092 \
    --describe
        
 bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --group kls-consumer --topic kubesphere-logging-system --from-beginning
     
bin/kafka-run-class.sh kafka.admin.ConsumerGroupCommand     --group kls-consumer     --bootstrap-server localhost:9092     --describe
    
    
 bin/kafka-console-consumer.sh --topic kubesphere-logging-system --from-beginning --bootstrap-server 192.168.88.6:9092
```

