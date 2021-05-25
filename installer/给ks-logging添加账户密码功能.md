## 给ks-logging添加账户密码功能

```
$ cd /elastic-on-k8s/deploy/eck-operator
$ helm upgrade --install elastic-operator ../eck-operator -n kubesphere-logging-system  -f values-for-kubesphere.yaml
$  helm list -n kubesphere-logging-system
NAME                            NAMESPACE                       REVISION        UPDATED                                 STATUS          CHART                           APP VERSION
elastic-operator                kubesphere-logging-system       1               2021-02-25 09:53:02.027112639 +0000 UTC deployed        eck-operator-1.5.0-SNAPSHOT     1.5.0-SNAPSHOT
$ kubectl apply -f ../kubesphere/es-cluster-with-auth.yaml
```

Access：

```
$ kubectl get secrets | grep elastic
$ password=$(kubectl -n kubesphere-logging-system get secrets kubesphere-es-cluster-es-elastic-user -o go-template="{{.data.elastic | base64decode}}")
$ kubectl create secret generic elasticsearch-credentials --from-literal="elastic" --from-literal="password=$password" --type=kubernetes.io/basic-auth -n kubesphere-logging-system
$  kubectl edit svc  kubesphere-es-cluster-es-http
$ kubectl get svc  kubesphere-es-cluster-es-http
NAME                            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubesphere-es-cluster-es-http   NodePort   10.96.221.193   <none>        9200:30149/TCP   12m
# curl -u elastic:$password <node-ip>:30149/_cluster/health?pretty
{
  "cluster_name" : "kubesphere-es-cluster",
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

集成到ks-logging, https://kubesphere.io/docs/faq/observability/logging/#how-to-change-the-log-store-to-the-external-elasticsearch-and-shut-down-the-internal-elasticsearch

```
externalElasticsearchUrl: <192.168.0.2>
externalElasticsearchPort: <9200>


```

```
$ kubectl edit output es -n kubesphere-logging-system
es:
    host: kubesphere-es-cluster-es-http.default.svc
    http:
      httpUser:
        valueFrom:
          secretKeyRef:
            key: kubesphere-es-cluster-es-elastic-user
    logstashFormat: true
    logstashPrefix: ks-cl-o3vzji61-log
    port: 9200
    timeKey: '@timestamp'
```



卸载

```
helm uninstall elastic-operator -n kubesphere-logging-system
```

