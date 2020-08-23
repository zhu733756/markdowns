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
- strategy	<Object>
       The deployment strategy to use to replace existing pods with new ones.
- selector	<Object>
       Label selector for pods. Existing ReplicaSets whose pods are selected by
       this will be the ones affected by this deployment.
- template	<Object> -required-
       Template describes the pods that will be created.
