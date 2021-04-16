## kubesphere平台上搭建es集群和skywalking apm参考教程

#### 前提条件

- 已搭建好`k8s`集群或者`kubesphere`集群
- 安装`helm`包管理工具

#### 集群配置如下

| NAME        | ROLES  | IP           | VERSION |
| :---------- | :----- | :----------- | :------ |
| master1     | master | 192.168.88.3 | v1.17.9 |
| worker-p001 | node   | 192.168.88.4 | v1.17.9 |
| worker-p002 | node   | 192.168.88.5 | v1.17.9 |

#### **es 集群搭建**

在`k8s`搭建`elasticsearch`集群的方案有很多，这里使用`helm`安装, 先添加官方`repo`

```
$ helm repo add elastic https://helm.elastic.co
$ helm repo update
```

下载定制化的安装代码：

```
$ git clone https://github.com/kubesphere/elastic-helm-charts
$ cd /elastic-helm-charts/elasticsearch/examples/kubespheretre
$ tree .
|-- Makefile
|-- README.md
|-- client.yaml
|-- data.yaml
|-- es-patch-torlence.json
|-- master.yaml
`-- test
    `-- goss.yaml
```

##### 各节点参数建议

master 节点

```
clusterName: "elasticsearch"
nodeGroup: "master"

roles:
  master: "true"
  ingest: "false"
  data: "false"
  ml: "false"
  remote_cluster_client: "false"

# 增加master不调度的容忍
# tolerations:
# - effect: NoSchedule
#  key: node-role.kubernetes.io/master
#  value: ''

replicas: 3
minimumMasterNodes: 2

esJavaOpts: "-Xmx512m -Xms512m"

resources:
  requests:
    cpu: "512m"
    memory: "512m"
  limits:
    cpu: "1"
    memory: "1Gi"

```

data 节点

```

clusterName: "elasticsearch"
nodeGroup: "data"

roles:
  master: "false"
  ingest: "true"
  data: "true"
  ml: "false"
  remote_cluster_client: "false"


# 增加master不调度的容忍
# tolerations:
# - effect: NoSchedule
#  key: node-role.kubernetes.io/master
#  value: ''

# 分片值可按需修改
replicas: 3
minimumMasterNodes: 2

# data 节点来说
# 此选项最好不要修改，高版本的es支持自动按需设置java内存堆大小
# 设置成null，java内存堆默认为设为资源上限的一半
esJavaOpts: null

# 根据数据规模实际情况按需修改limits，内存最高能调到 32Gi
resources:
  requests:
    cpu: "1"
    memory: "2Gi"
  limits:
    cpu: "2"
    memory: "4Gi"

# data节点的pv容量建议为20Gi+
volumeClaimTemplate:
  accessModes: [ "ReadWriteOnce" ]
  resources:
    requests:
      storage: 30Gi
```

##### 使用定制化`make cmdline` 

该目录下我们提供了比较好用的`make`脚本，参考如下：

```
default: test

include ../../../helpers/examples.mk

PREFIX := elasticsearch
NAMESPACE ?= default
TIMEOUT := 1200s
PATCH := $(shell cat es-patch-torlence.json)

# 安装命令，可指定namespace，通过参数-e NAMESPACE=xxx
# eg： make install -e NAMESPACE=test
install:
        helm upgrade --install  $(PREFIX)-master ../../ --values master.yaml -n $(NAMESPACE) --set imageTag="7.11.1"
        helm upgrade --install  $(PREFIX)-data ../../  --values data.yaml -n  $(NAMESPACE) --set imageTag="7.11.1"

# 当运行install后，用于兼容noschedule污点容忍调度的patch
patch:
        kubectl patch sts elasticsearch-master --patch  '$(PATCH)'
        kubectl patch sts elasticsearch-data --patch  '$(PATCH)'

# 卸载命令，如果非default的ns，卸载需要指定-e NAMESPACE=xxx
# eg: make uninstall -e NAMESPACE=test
uninstall:
        helm del $(PREFIX)-master -n  $(NAMESPACE)
        helm del $(PREFIX)-data -n  $(NAMESPACE)

```

###### install

```
make install [-e NAMESPACE=xxx]
```

###### patch

如果install后pods无异常，可跳过此步骤.

当查看pods运行状态时，发现有节点处于`pending`状态:

```
$ kubectl get pods
NAME                     READY   STATUS     RESTARTS   AGE
busybox-sleep            1/1     Running    1          23h
elasticsearch-data-0     0/1     Init:0/1   0          14s
elasticsearch-data-1     0/1     Init:0/1   0          14s
elasticsearch-data-2     0/1     Pending    0          14s
elasticsearch-master-0   0/1     Init:0/1   0          15s
elasticsearch-master-1   0/1     Init:0/1   0          15s
elasticsearch-master-2   0/1     Pending    0          15s
```

这里以我在实际部署中发现污点`kubernetes.io/master=:noschedule`导致`master`不耐受为例：

```
$ kubectl describe pod -l  app=elasticsearch-master
.. 1 node(s) had taints that the pod didn't tolerate, 2 node(s) didn't match pod affinity/anti-affinity...
```

首先，将需要添加容忍的脚本放在`es-patch-torlence.json`:

```
{"spec":{"template":{"spec":{"tolerations":[{"effect":"NoSchedule","key":"node-role.kubernetes.io/master","value":""}]}}}}
```

其次，运行`make patch`:

```
make patch [-e NAMESPACE=xxx]
```

如果有需要，可删除pods重启

```
kubectl delete pod -l  app=elasticsearch-master [-n xxx]
kubectl delete pod -l  app=elasticsearch-data [-n xxx]
```

###### uninstall

卸载集群极为方便，只需要运行以下命令即可：

```
make uninstall [-e NAMESPACE=xxx]
```

##### 访问集群

如果上述集群搭建正常，想要访问es集群，为了方便起见，这里使用`nodeport`方式访问`svc`:

```
$ kubectl edit svc elasticsearch-data # type:NodePort
$ kubectl get svc elasticsearch-data
NAME                            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                         AGE
elasticsearch-data              NodePort    10.96.125.133   <none>        9200:30057/TCP,9300:31075/TCP   165m
```

访问测试:

```
$ curl http://<your node ip>:30057/_cluster/health?pretty
{
  "cluster_name" : "elasticsearch",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 6,
  "number_of_data_nodes" : 3,
  "active_primary_shards" : 0,
  "active_shards" : 0,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
```

#### 安装Skywalking apm

克隆仓库, `add repo`

```
$ git clone https://github.com/apache/skywalking-kubernetes
$ cd skywalking-kubernetes/chart
$ helm repo add elastic https://helm.elastic.co
$ helm dep up skywalking
```

编辑`skywalking/values-my-es.yaml`:

```yaml
oap:
  image:
    tag: 8.3.0-es7 
  storageType: elasticsearch7

ui:
  image:
    tag: 8.3.0

elasticsearch:
  enabled: false
  config:               
    host: elasticsearch-master.default # elasticsarch cluter's ip 
    port:
      http: 9200
    #user: "xxx"         # [optional]
    #password: "xxx"     # [optional]
```

创建一个`ns`并在该`ns`下安装`skywalking`:

```
$ kubectl create ns skywalking
$ helm install skywalking skywalking -n skywalking -f ./skywalking/values-my-es.yaml 
```

验证`pods`:

```
$kubectl get pods -n skywalking
```

为了方便调试，这里直接将`skywalking`的`svc`类型修改为`nodeport`：

```
$ kubectl edit svc skywalking-ui -n skywalking
----
spec:
  clusterIP: 10.96.219.21
  externalTrafficPolicy: Cluster
  ports:
  - nodePort: 30283
    port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: skywalking
    component: ui
    release: skywalking
  sessionAffinity: None
  type: NodePort # 修改这里
----
$ kubectl get svc skywalking-ui -n skywalking
NAME            TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
skywalking-ui   NodePort   10.96.89.148   <none>        80:30283/TCP   1m11s
```

或者编辑配置`skywalking/values-my-es.yaml`，使用`helm upgrade `更新服务：

```
oap:
  image:
    tag: 8.3.0-es7
  storageType: elasticsearch7

ui:
  image:
    tag: 8.3.0
  service:
    type: NodePort #添加配置

elasticsearch:
  enabled: false
  config:    
    host: elasticsearch-master.default
    port:
      http: 9200
```

如果一切配置正常，现在使用`node-ip:30283`即可访问`skywalking `服务，由于没有接入`agent`以及部署应用服务，所以暂时还没有数据展示。

#### 部署 SpringCloud 示例应用

在本文中，我们准备了一个简单的 SpringCloud 示例应用，使用` Apache SkyWalking `官方的镜像（`apache/skywalking-base:8.3.0-es7`），为 `SpringCloud` 微服务以` initContainer` 的方式注入 `Agent `到容器中。这也正是 SkyWalking Agent 巧妙之处，无需侵入代码或对原有的业务镜像改造，就能快速接入` APM`。

首先，通过 Git 将 SpringCloud 示例应用的代码拉取到本地。

```bash
git clone https://github.com/kubesphere/tutorial.git
```

然后进入 `tutorial/tutorial 6 → skywalking/6.5.0/apm-springcloud-demo/` 目录，分别将 **apm-eureka.yml** 与 **apm-item.yml** 文件中的 Agent Collector 的后端服务地址，修改为 `skywalking-oap` 服务的 DNS 地址与端口。

```text
env:
···
  - name: SW_AGENT_COLLECTOR_BACKEND_SERVICES
    value: skywalking-oap.skywalking.svc.cluster.local:11800 # skywalking oap 后端服务地址
```

`DNS` 地址与服务端口，可以通过 `KubeSphere Console `地址获取，也就是`grpc`端口`11800`。

```
root@master1:# kubectl get svc -n skywalking
NAME             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)               AGE
skywalking-oap   ClusterIP   10.96.148.77   <none>        12800/TCP,11800/TCP   11h
skywalking-ui    NodePort    10.96.219.21   <none>        80:30283/TCP          11h
```

然后，我们可以通过 kubectl 对上述克隆过的仓库 **apm-springcloud-demo** 目录下，通过 kubectl 快速部署应用，指定 namespace 为 KubeSphere 上的 demo 项目。

```text
$ kubectl apply -f apm-springcloud-demo -n demo
deployment.apps/apm-eureka created
deployment.apps/apm-item created
service/apm-eureka created
service/apm-item created
```

此时在 KubeSphere 可以看到，示例应用的工作负载 **apm-eureka** 与 **apm-item** 都已经成功运行。

接下来，只需要对其中一个服务 **apm-item** 发送一些测试请求模拟用户访问流量，就可以访问 SkyWalking 查看数据效果的展示了。

#### 压测与结果展示

首先获取一下后端服务的`svc`端口:

```
root@master1# kubectl get svc -n demo 
NAME         TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                         AGE
apm-eureka   NodePort   10.96.127.84   <none>        8761:30761/TCP,8080:30080/TCP   10h
apm-item     NodePort   10.96.100.44   <none>        8082:30082/TCP                  10h
```

安装压测工具:

```
# apt install -y apache2-utils 【Ubuntu】
# yum install -y httpd-tools 【centos】
```

先并发200同时请求测试,超时时间为10s：

```
root@master1:# ab -t 10 -c 200 http://192.168.88.2:30082/eureka/apps/delta
This is ApacheBench, Version 2.3 <$Revision: 1807734 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 192.168.88.2 (be patient)
Completed 5000 requests
Completed 10000 requests
Finished 12352 requests


Server Software:        
Server Hostname:        192.168.88.2
Server Port:            30082

Document Path:          /eureka/apps/delta
Document Length:        138 bytes

Concurrency Level:      200
Time taken for tests:   10.000 seconds
Complete requests:      12352
Failed requests:        0
Non-2xx responses:      12352
Total transferred:      3174464 bytes
HTML transferred:       1704576 bytes
Requests per second:    1235.17 [#/sec] (mean)
Time per request:       161.921 [ms] (mean)
Time per request:       0.810 [ms] (mean, across all concurrent requests)
Transfer rate:          310.00 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0   15 114.7      0    1036
Processing:     2  144 135.5     96    1201
Waiting:        2  136 131.5     87    1034
Total:          2  159 177.2    100    1715

Percentage of the requests served within a certain time (ms)
  50%    100
  66%    147
  75%    202
  80%    242
  90%    346
  95%    468
  98%    676
  99%   1058
 100%   1715 (longest request)
```

结果显示：

![](https://raw.githubusercontent.com/zhu733756/bedpic/main/imagesimage-20210121110212915.png)



