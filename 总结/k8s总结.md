## 名词解释

#### **容器**

- 定义：
  - 可重复的、可运行的、集成了应用的运行时环境
- 本质
  - 一种特殊的单进程
  - 拥有独立的名称空间、控制组以及rootfs
    - 名称空间实现了容器隔离 
      - Pid、Mount、UTS、IPC、Network 和 User等
    - 控制组`Linux Cgroups`实现了容器的运行资源控制
      -  CPU、内存、磁盘、网络带宽
    - rootfs实现了容器的文件系统隔离
      - 切换并挂载根目录
      - Docker 在镜像的设计中，引入了层（layer）的概念，实现了增量rootfs
- 容器引申的问题
  - `docker exec`是如何进入容器执行命令的？
    - 通过`inspect`获取容器在主机中的实际进程号
    - 将`/proc/{进程id}/ns/{ns}`这个fd以及要执行的命令`cmd`传递给`setns`
    - `setns`执行成功后，当前进程和运行的容器其实共享了名称空间，说明该进程就加入到容器中去了
  - `docker volumes`是如何实现的？
    - 容器挂载的本质类似于做了inode的“重定向”，将容器中的目录对应的`dentry`指针指向了被挂载的`inode`

#### **Pod**

- 定义	

  - 在k8s中创建和管理的最小的可部署的计算单元

- 本质

  - 包含一组共享了名称空间、共享存储卷等资源的进程组的抽象集合
    - 调度、网络、存储，以及安全
    - 没有共享pid名称空间，pod中的容器间相互独立
    - 可以通过参数设置共享pid

- 原理

  - `infra`容器最先创建
    - `infra`容器就是一个占用资源极少的永远处于“暂停”状态的容器
    - `infra`容器决定了`pod`的生命周期，跟用户容器无关
  - 用户容器加入`infra`容器的`ns`中

- 应用

  - 代码发布运行
    - 利用`initContainers`容器先顺序的机制发布代码包【发布到挂载点】
    - `volumes`共享特性【从容器内的挂载点取出代码进行运行】
  - 日志收集
    - `sidecar`收集日志发布给日志处理中间件

- 重要字段

  - ` ImagePullPolicy`
    - `Always`
      - 每次创建 Pod 都重新拉取一次镜像
    -  `Never` 或者 `IfNotPresent`
      - 不主动拉取，只有在宿主机不存在时才去拉取
    - `OnFailure`
      - 当容器终止运行且退出码不为0时，由kubelet自动重启该容器
  - [`LifeStyle`](https://www.qikqiak.com/k8strain/basic/pod-life/)
    -  `postStart`
      -  容器启动后立即执行一个操作
    - `livenessProbe`
      - 可以配置存活探测的频率、以及存活探测的接口【执行命令或者请求api】
    - readinessProbe
      - 可读性探针
    - `preStop `
      - 同步进行容器被杀死后的执行的一个操作
  - resources
    - `pod`运行资源限制

- 预写入容器配置【通过volumes挂载】

  - `Secret`

    - 写入`etcd`，适合保存非明文账号密码，作为环境变量或者挂载文本传递

  - `ConfigMap`

    - 写入配置信息，挂载在一个目录或者设置成环境变量【获取cm的全部或者某个key】

  - `Downward API`

    ```yaml
    1. 使用 fieldRef 可以声明使用:
    
    spec.nodeName - 宿主机名字
    status.hostIP - 宿主机IP
    metadata.name - Pod的名字
    metadata.namespace - Pod的Namespace
    status.podIP - Pod的IP
    spec.serviceAccountName - Pod的Service Account的名字
    metadata.uid - Pod的UID
    metadata.labels['<KEY>'] - 指定<KEY>的Label值
    metadata.annotations['<KEY>'] - 指定<KEY>的Annotation值
    metadata.labels - Pod的所有Label
    metadata.annotations - Pod的所有Annotation
    
    2. 使用 resourceFieldRef 可以声明使用:
    
    容器的 CPU limit
    容器的 CPU request
    容器的 memory limit
    容器的 memory request
    ```

  - ` PodPreset` 对象

    -  定义的`pod`通过`label`选择器继承该定义
    - 适合做一些`pod`的重复性定义

#### SideCar

- 日志代理/转发，例如 fluentd；
- Service Mesh，比如 Istio，Linkerd；
- 代理，比如 Docker Ambassador；
- 探活：检查某些组件是不是正常工作；
- 其他辅助性的工作，比如拷贝文件，下载文件等；

#### [**IPtables**](https://wangchujiang.com/linux-command/c/iptables.html)

- `Linux`上常用的防火墙软件，是`netfilter`项目的一部分。可以直接配置，也可以通过许多前端和图形界面配置。
- 四表
  - **raw** ：高级功能，如：网址过滤。
  - **mangle** ：数据包修改（QOS），用于实现服务质量。
  - **nat** ：地址转换，用于网关路由器。
  - **filter** ：包过滤，用于防火墙规则。
- 五链
  - **INPUT链** ：处理输入数据包。
  - **OUTPUT链** ：处理输出数据包。
  - **FORWARD链** ：处理转发数据包。
  - **PREROUTING链** ：用于目标地址转换（DNAT）。
  - **POSTOUTING链** ：用于源地址转换（SNAT）。
- 命令行
  - ```iptables -t 表名 <-A/I/D/R> 规则链名 [规则号] <-i/o 网卡名> -p 协议名 <-s 源IP/源子网> --sport 源端口 <-d 目标IP/目标子网> --dport 目标端口 -j 动作```

#### [**IPVS**](https://www.jianshu.com/p/36880b085265)

- **LVS**

  - Linux虚拟服务器, 是一个由章文嵩博士发起的自由软件项目，基于TCP/IP的负载均衡技术，转发效率极高

- **IPVS**

  - IPVS模块是LVS集群的核心软件模块，它安装在LVS集群作为负载均衡的主节点上，虚拟出一个IP地址和端口对外提供服务

- **IPVS**三种转发模式

  - ###### DR模式

    - 改写请求包的MAC地址为后端RS的MAC地址
    - 响应包直接回给客户端
    - LB【负载均衡器】和RS【后端】须位于同一个子网，以便能够查询到RS的MAC

    - 转发效率是最高的

  - **NAT**模式

    - LB会修改数据包的地址
      - 对于请求包，会进行DNAT；对于响应包，会进行SNAT
    - LB会透传客户端IP到RS
      - 虽然做了nat转发，RS还是可以看到客户端IP
    - LB和RS须位于同一个子网，并且客户端不能和LB/RS位于同一子网
      - 为了保证响应包在返回时能走到LB上面
      - 如果客户端的IP是固定的，也可以在RS上添加明细路由指向LB的虚拟服务IP
      - LB和RS须位于同一个子网，并且客户端不能和LB/RS位于同一子网
        - 因为需要将RS的默认网关配置为LB的虚拟服务IP地址

  - ######  FULLNAT模式

    - LB会对请求包和响应包都做SNAT+DNAT
    - LB和RS对于组网结构没有要求

- 调度算法

  - 轮询
  - 加权轮询
  - 最小连接数
  - 加权最小连接数
  - 地址哈希

#### **Service**

- 定义
  - 一组 Pod 的逻辑集合和一个用于访问它们的策略，有两种实现方式`iptables`和`ipvs`
  - 由 Label Selector 来决定访问的Pod集合【重点】
  - 暴露endpoints的接口，对集群内外提供服务，实现了服务发现
- 访问逻辑
  - 普通的Service：DNS服务解析ClusterIP，再由代理转发给PodIP
  - headless Service:  利用的是 Service 的 DNS 方式，DNS服务解析到的是PodIP

#### **Ingress**

- service的代理，对外暴露集群服务

#### **Kube-Proxy**

- 转发ServiceIP给PodIP
- 监控Service和Endpoints的变化，实时刷新转发规则
- 负载均衡

#### **kubectl**

- k8s命令行集成工具

#### **kubeadm**

- 一种k8s部署工具

#### **kubelete**

- 说明
  - 在每个node节点上启用
  - 处理master节点下发给本节点的请求，管理Pod和其中的容器
  - 在api server上注册节点信息，定期汇报节点资源使用情况
- 启动配置
  - `/etc/kubernetes/kubelet`
- pod管理
  - 为pod创建一个数据目录
  - 从apiserver读取pod清单
  - 为pod挂载外部卷
  - 下载Secret
  - 检查运行的pod，执行pod中未完成的任务
  - 创建infra容器，接管Pod网络，附加用户容器
- 容器健康检查
- 资源监控

#### **API Server**

- 作用
  - 资源的唯一操作入口，保证了集群访问的安全性、可靠性，建立于存储技术之上的状态访问，不会因为存储组件的变化而变化
  - 封装了资源对象的增删改查，以RESTFUL接口提供给外部客户和内部组件调用
- 声明式API
  - 只需要提交一个定义好的 API 对象来“声明”期望的状态是什么样子
  - “声明式 API”允许有多个 API 写端，以 PATCH 的方式对 API 对象进行修改，而无需关心本地原始 YAML 文件的内容
  - 有了上述两个能力，基于对 API 对象的增、删、改、查，在完全无需外界干预的情况下，完成调谐过程
- Istio项目原理： Admission()
  - 根据k8s的api范式定义CRD【自定义资源】，指明资源属于哪个Api组，Api版本，资源类型【istio的资源是pod】
  - 将需要加入的pod的定义写入configmap通过挂载卷共享
  - 控制器模式：定义期望的状态，获取pod携带的annotation字段进行判断，读取配置，以patch的方式合成新的pod
    - 备注：此阶段在pod创建之前

#### **PV、PVC、 StorageClass**

- pvc和pv实际上类似于“接口”和“实现”的思想
- 在pod中申明volumeClaimTemplates属性后，会创建pvc对象，与pv【PersistentVolume】对象关联
-  PVC，都以“<PVC 名字 >-<StatefulSet 名字 >-< 编号 >”的方式命名
- StorageClass是自动地为集群里存在的每一个 PVC，调用存储插件（Rook）创建对应的 PV

#### CRD

- `Custom Resource Define` 简称 CRD，是 Kubernetes为提高可扩展性让开发者去自定义资源的一种方式
- `CRD `资源可以动态注册到集群中

#### [Operator](https://github.com/operator-framework/operator-sdk/blob/master/README.md)

- 结合了特定领域知识并通过 CRD 机制扩展了 资源，使用户管理内置资源（Pod、Deployment等）一样创建、配置和管理应用程序

- `Operator` 就可以看成是 CRD 和 Controller 的一种组合特例
  - 资源模型定义
  - 控制器
- [example](https://www.qikqiak.com/k8strain/operator/operator/)

#### **控制器**

- 控制器管理器
  
  - 实现集群故障的检查和恢复，负责管理各种控制器
  
- 控制器设计模式 - 调谐循环`Reconcile Loop` 

  - 保证资源对象的实际状态与 资源清单中定义的状态保持一致。

    ```go
    for {
      desired := getDesiredState()  // 期望的状态：拿rc举例的话就是yaml文件中的replica数量
      current := getCurrentState()  // 当前实际状态：拿rc举例的话就是通过label选择器筛选出来的pod数量
      if current == desired {  // 如果状态一致则什么都不做
        // nothing to do
      } else {  // 如果状态不一致则调整编排，到一致为止
        // change current to desired status
      }
    }
    ```

- 控制器管理器的几种控制器类型

    - `endpoint-controller` ：定期关联service到pod的映射关系

    - `Node Controller`: 实现管理和监控集群中的各个Node节点的相关控制功能

    - ` ReplicaSet  Controller`: 简称RS
      - 维持一组pod的运行，保证一定数量的Pod在集群中运行
      - 持续监听Pod的运行状态，在故障后数量减少或者增加时触发调谐过程

    - `replication Controller`: 简称RC
      - RS和RC功能几乎一致
      - 唯一的区别是RC只支持等式label选择器，但RS还支持集合选择器

    - `Deployment controller`

      - `Deployment `控制 `ReplicaSet`（版本），`ReplicaSet` 控制 `Pod`（副本数）
      - `restartPolicy=Always`保证`RS`处于`Running`状态【 当有容器退出时进行重启】
      - 水平扩展/收缩【rs的replica数量】
      - 滚动更新【rs的属性】

    - `statefulset controller`

      - 无状态服务
        - 服务运行的实例不会在本地存储需要持久化的数据
        - token是无状态的
        
      - 有状态服务
        - 服务运行的实例需要在本地存储持久化数据
        - session是有状态的
        
      - `statefulset`特性：维持拓扑先后关系，有状态的控制器

        - StatefulSet 的控制器直接管理的是 Pod，分配给每个 Pod 的唯一顺序索引
          - `<pod-name>`的形式为`<statefulset name>-<ordinal index>`，与 StatefulSet 的每个 Pod 实例一一对应
          -  Pod 的创建，也是严格按照编号顺序**升序**进行的，当前一个ready后才会创建后一个
          - Pod 副本的更新和删除，会按照序列号**降序**处理。
        - Kubernetes 通过 Headless Service，为这些有编号的 Pod，在 DNS 服务器中生成带有同样编号的 DNS 记录
          - `headless Service`的`dns`记录：`<pod-name>.<svc-name>.<namespace>.svc.cluster.local`
          - `headless Service`可以让DNS服务解析到的是PodIP

        - StatefulSet 还为每一个 Pod 分配并创建一个同样编号的 PVC
          - `PVC`都以`<PVC 名字 >-<StatefulSet 名字 >-< 编号 >`的方式命名
          - 删除pod的时候对应的pvc并不会删除，会重新绑定

    - `DaemonSet`

      - 定义

        - 保证每个节点上有且只有一个 Pod，类似守护进程
      - 应用

        - 各种网络插件的 Agent 组件，都必须运行在每一个节点上，用来处理这个节点上的容器网络；
        - 各种存储插件的 Agent 组件，也必须运行在每一个节点上，用来在这个节点上挂载远程存储目录，操作容器的 Volume 目录；
        - 各种监控组件和日志组件，也必须运行在每一个节点上，负责这个节点上的监控信息和日志搜集。
      - 实现

        - 遍历node以及nodeAffinity 【相当于node选择器】和 Toleration属性控制
        - 使用 ControllerRevision管理版本

    - `Job`和`CrontabJob`

      - 关键字段

        - spec.parallelism，它定义的是一个 Job 在任意时间最多可以启动多少个 Pod 同时运行
        - spec.completions，它定义的是 Job 至少要完成的 Pod 数目，即 Job 的最小完成数
      - 三种调度方式

        - 模板管理法

          - 外部管理器 +Job 模板：用脚本批量生成yaml文件
        - 拥有固定任务数目的并行 Job

          - spec.completions和spec.parallelism
          - 可以用来消费任务，只达到固定数据的任务完成量即可，每个job从生产队列去一个任务
        - 指定并行度（parallelism），但不设置固定的 completions 的值

          - 只指定spec.parallelism并发数
          - 可以用来消费任务，直到任务队列为空才退出

- 自定义控制器

  - Informer【通知器】作为资源client，与apiserver建立联系
    - 所谓 Informer，其实就是一个带有本地缓存和索引机制的、可以注册 EventHandler 的 client
  - informer作用【ListAndWatch】
    - 从队列中取出事件，同步【创建或者更新】本地缓存
    - 根据事件类型触发资源事件回调函数
  - 除了控制循环之外的所有代码，实际上都是 Kubernetes 自动生成的

####  **调度器**

- 功能
  - 负责接收`Controller Manager`创建的新的`Pod`，为其选择一个合适的`Node`，并将信息写入`etcd`中
  - `Node`上的kubelet通过API Server监听到调度器产生的`Pod`绑定信息，获取`Pod`清单，下载`image`，并启动容器
- 调度流程
  - 预选调度：遍历所有目标Node，筛选出符合要求的候选节点
  - 优选策略：采用优选策略确定最优节点

## 架构原理

#### 分层架构

- 核心层：Kubernetes 最核心的功能，对外提供 API 构建高层的应用，对内提供插件式应用执行环境
- 应用层：部署（无状态应用、有状态应用、批处理任务、集群应用等）和路由（服务发现、DNS 解析等）
- 管理层：系统度量（如基础设施、容器和网络的度量），自动化（如自动扩展、动态 Provision 等）以及策略管理（RBAC、Quota、PSP、NetworkPolicy 等）
- 接口层：kubectl 命令行工具、客户端 SDK 以及集群联邦
- 生态系统：在接口层之上的庞大容器集群管理调度的生态系统，可以划分为两个范畴
  - Kubernetes 外部：日志、监控、配置管理、CI、CD、Workflow、FaaS、OTS 应用、ChatOps 等
  - Kubernetes 内部：CRI、CNI、CVI、镜像仓库、Cloud Provider、集群自身的配置和管理等

## 安全

## 网络

## 监控

## 日志

