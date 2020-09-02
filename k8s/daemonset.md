<!--
 * @Description: 
 * @version: 
 * @Author: zhu733756
 * @Date: 2020-09-02 15:22:01
 * @LastEditors: zhu733756
 * @LastEditTime: 2020-09-02 15:51:21
-->
## 应用场景

- 各种网络插件的 Agent 组件，都必须运行在每一个节点上，用来处理这个节点上的容器网络；
- 各种存储插件的 Agent 组件，也必须运行在每一个节点上，用来在这个节点上挂载远程存储目录，操作容器的 Volume 目录；
- 各种监控组件和日志组件，也必须运行在每一个节点上，负责这个节点上的监控信息和日志搜集。

## 作用

- 这个 Pod 运行在 Kubernetes 集群里的每一个节点（Node）上；
- 每个节点上只有一个这样的 Pod 实例；
- 当有新的节点加入 Kubernetes 集群后，该 Pod 会自动地在新节点上被创建出来；而当旧节点被删除后，它上面的 Pod 也相应地会被回收掉。

## 如何实现在每个node上部署一个daemonset

- nodeSelector选择器
- nodeAffinity 【更好的选择】
  - requiredDuringSchedulingIgnoredDuringExecution：它的意思是说，这个 nodeAffinity 必须在每次调度的时候予以考虑。同时，这也意味着你可以设置在某些情况下不考虑这个 nodeAffinity
  - 这个 Pod，将来只允许运行在“metadata.name”是“node-geektime”的节点上。
  - tolerations
    - 下面的例子中不允许用户在 Master 节点部署 Pod
      - 因为，Master 节点默认携带了一个叫作node-role.kubernetes.io/master的污点
  
```
nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: metadata.name
            operator: In
            values:
            - node-geektime
-----
tolerations:
- key: node-role.kubernetes.io/master
  effect: NoSchedule
```

## cmds

- 查看
  - kubectl get ds -n kube-system fluentd-elasticsearch

- 镜像升级
  - kubectl set image ds/fluentd-elasticsearch fluentd-elasticsearch=k8s.gcr.io/fluentd-elasticsearch:v2.2.0 --record -n=kube-system

- 滚动更新过程查看
  - kubectl rollout status ds/fluentd-elasticsearch -n kube-system

- 历史版本
  - kubectl rollout history daemonset fluentd-elasticsearch -n kube-system

- 版本回退
  - kubectl rollout undo daemonset fluentd-elasticsearch --to-revision=1 -n kube-system
