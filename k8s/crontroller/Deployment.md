
## Deplooyment

#### examples

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-nginx
spec:
  replicas: 3
  minReadySeconds: 10
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.10-alpine
        ports:
        - containerPort: 80
          name: http
        readinessProbe:
          periodSeconds: 1
          httpGet:
            path: /
            port: http
```

#### Kind

- Deployment

#### metadata

- name
- labels

#### version

- apps/v1

#### spec

-  minReadySeconds	<integer>
  - 一个新创建的pod完成并无任何冲突的最短时间
  - default 0
- paused	<Bool>
  - 表明这个deployment处理停止状态，不会被控制器调用
- progressDeadlineSeconds	<integer>
  - 一个deployment被认为是运行失败的最大缓冲时间
- replicas	<integer>
  - 分片，需要的目标pods数量
- strategy	<Object> pod更新策略
  - Recreate 杀死所有运行的pod，创建新的pod
  - RollingUpdate 滚动更新。
    - 可以设置maxUnavailable【最大不可用百分比】
    - maxSurge【旧ReplicaSet的Pod副本数之和不超过期望副本数的100+maxSurge%】
  - 多重更新（Rollover）的情况
    - 以最终提交的版本进行过渡，不会等中间版本状态完全就绪 
- selector	<Object>
  -Label selector for pods. Existing ReplicaSets whose pods are selected by this will be the ones affected by this deployment.
- template	<Object> -required-
  - Template describes the pods that will be created.

#### Deployment的升级

- 镜像直接升级
  - kubectl set image deployment/deploy-nginx nginx=nginx:1.9.1
  - kubectl edit deployment/deploy-nginx 

- rolling-update更新RC【高版本不支持】
  - kubectl rolling-update redis-master -f redis-master-controller-v2.yaml
    - RC的名字（name）不能与旧RC的名字相同。
    - 在selector中应至少有一个Label与旧RC的Label不同，以标识其为新RC。在本例中新增了一个名为version的Label，以与旧RC进行区分
  - kubectl rolling-update redis-master --image=reids-master:2.0
  
- replace
  - kubectl get pod mypod -o yaml | sed 's/\(image: myimage\):.*$/\1:v4/' | kubectl replace -f - 【更新镜像版本(tag)到v4】


#### 暂停和恢复Deployment的部署操作

- kubectl rollout pause/resume deployment/nginx-deployment

#### 查看更新状态和查看更新历史记录

- 更新状态查看
  - kubectl rollout status deployment/deploy-nginx 
  - kubectl describe deployment/deploy-nginx
- 更新历史记录查看
  - kubectl rollout history deployment/deploy-nginx [--revision=<N> 【查看第几个版本的】]
  - kubectl rollout undo deployment/deploy-nginx [--to-revision=<N> 版本回退]

#### Pod的扩缩容

- Examples:
  - Scale a replicaset named 'foo' to 3.
    - kubectl scale --replicas=3 rs/foo
  - Scale a resource identified by type and name specified in "foo.yaml" to 3.
    - kubectl scale --replicas=3 -f foo.yaml
  - If the deployment named mysql's current size is 2, scale mysql to 3.
    - kubectl scale --current-replicas=2 --replicas=3 deployment/mysql
  - Scale multiple replication controllers.
    - kubectl scale --replicas=5 rc/foo rc/bar rc/baz
  - Scale statefulset named 'web' to 3.
    - kubectl scale --replicas=3 statefulset/web
