<!--
 * @Description:
 * @version:
 * @Author: zhu733756
 * @Date: 2020-09-04 16:51:37
 * @LastEditors: zhu733756
 * @LastEditTime: 2020-09-04 17:36:01
-->

## Operator 的启动

```shell 静态启动
$ etcd --name infra0 --initial-advertise-peer-urls http://10.0.1.10:2380 \
--listen-peer-urls http://10.0.1.10:2380 \
---
--initial-cluster-token etcd-cluster-1 \
--initial-cluster infra0=http://10.0.1.10:2380,infra1=http://10.0.1.11:2380,infra2=http://10.0.1.12:2380 \
--initial-cluster-state new

$ etcd --name infra1 --initial-advertise-peer-urls http://10.0.1.11:2380 \
--listen-peer-urls http://10.0.1.11:2380 \
---
--initial-cluster-token etcd-cluster-1 \
--initial-cluster infra0=http://10.0.1.10:2380,infra1=http://10.0.1.11:2380,infra2=http://10.0.1.12:2380 \
--initial-cluster-state new

$ etcd --name infra2 --initial-advertise-peer-urls http://10.0.1.12:2380 \
--listen-peer-urls http://10.0.1.12:2380 \
---
--initial-cluster-token etcd-cluster-1 \
--initial-cluster infra0=http://10.0.1.10:2380,infra1=http://10.0.1.11:2380,infra2=http://10.0.1.12:2380 \
--initial-cluster-state new
```

- 利用了 Kubernetes 的自定义 API 资源（CRD）来描述我们想要部署的有状态应用；然后在自定义控制器里，根据自定义 API 对象的变化，来完成具体的部署和运维工作。
- Etcd Operator 部署 Etcd 集群，采用的是静态集群（Static）的方式, 规定了节点启动时集群的拓扑结构，需要跟哪些节点通信来组成集群。

## 创建过程

- 虽然选择的也是静态集群，但这个集群具体的组建过程，是逐个节点动态添加的方式
  - 首先，Etcd Operator 会创建一个“种子节点”；
  - 然后，Etcd Operator 会不断创建新的 Etcd 节点，然后将它们逐一加入到这个集群当中，直到集群的节点数等于 size。

## 工作原理

- Etcd Operator 的启动流程也是围绕着 Informer 展开的

```
  func (c *Controller) Start() error {
 for {
  err := c.initResource()
  ...
  time.Sleep(initRetryWaitTime)
 }
 c.run()
}

func (c *Controller) run() {
 ...

 _, informer := cache.NewIndexerInformer(source, &api.EtcdCluster{}, 0, cache.ResourceEventHandlerFuncs{
  AddFunc:    c.onAddEtcdClus,
  UpdateFunc: c.onUpdateEtcdClus,
  DeleteFunc: c.onDeleteEtcdClus,
 }, cache.Indexers{})

 ctx := context.TODO()
 // TODO: use workqueue to avoid blocking
 informer.Run(ctx.Done())
}
```

- Etcd Operator 启动要做的第一件事（ c.initResource），是创建 EtcdCluster 对象所需要的 CRD
  - Etcd Operator 会定义一个 EtcdCluster 对象的 Informer
  - 第一个工作只在该 Cluster 对象第一次被创建的时候才会执行。
  - 每个 Cluster 对象，都会事先创建一个与该 EtcdCluster 同名的 Headless Service
- 第二个工作，则是启动该集群所对应的控制循环
  - 这个控制循环每隔一定时间，就会执行一次下面的 Diff 流程
  - 修改 size 或者 Etcd 的 version，它们对应的更新事件都会由这个 Cluster 对象的控制循环进行处理

## operator 解决了有状态部署的那些问题？

- 在 StatefulSet 里，它为 Pod 创建的名字是带编号的，用来维护拓扑关系，为啥 operator 不需要？
  - Etcd Operator 在每次添加 和删除的时候，都会更新 Etcd 内部维护的拓扑信息，所以 Etcd Operator 无需在集群外部通过编号来固定这个拓扑关系。
- 为什么我没有在 EtcdCluster 对象里声明 Persistent Volume
  - Etcd 是一个基于 Raft 协议实现的高可用 Key-Value 存储。根据 Raft 协议的设计原则，当 Etcd 集群里只有半数以下（在我们的例子里，小于等于一个）的节点失效时，当前集群依然可以正常工作
  - 使用 Etcd 本身的备份数据来对集群进行恢复操作
  - 每当你创建一个 EtcdBackup 对象（backup_cr.yaml），就相当于为它所指定的 Etcd 集群做了一次备份，在实际的环境里，我建议你把最后这个备份操作，编写成一个 Kubernetes 的 CronJob 以便定时运行。
  - 当 Etcd 集群发生了故障之后，你就可以通过创建一个 EtcdRestore 对象来完成恢复操作。当然，这就意味着你也需要事先启动 Etcd Restore Operator
