

## k8s学习笔记

### k8s快速了解

#### 来源

- `borg`项目
- 使用`go`语言编写

#### 主从架构简介

![kubernetes arch](https://bxdc-static.oss-cn-beijing.aliyuncs.com/images/20200510122933.png)

![kubernetes high level component archtecture](https://bxdc-static.oss-cn-beijing.aliyuncs.com/images/20200510122959.png)

###### `Master` 节点

- `kube-apiserver`负责集群通信

  - 特点
    - `API Server` 会与 `etcd `进行通信
    - 其它模块都必须通过 `API Server`的`restful`接口访问集群状态
  - 好处
    - 保证集群状态访问的安全
    - 隔离了集群状态访问和后端存储，存储技术不限于`etcd`，提高了可扩展性

- `kube-sheduler` 负责容器调度
  
  - 主要用于收集和分析当前 Kubernetes 集群中所有 Node 节点的资源 (包括内存、CPU 等) 负载情况，然后依据资源占用情况分发新建的 Pod 到 Kubernetes 集群中可用的节点
  - 实时监测 Kubernetes 集群中未分发和已分发的所有运行的 Pod
  - 实时监测 Node 节点信息，由于会频繁查找 Node 节点，所以 Scheduler 同时会缓存一份最新的信息在本地
  - 在分发 Pod 到指定的 Node 节点后，会把 Pod 相关的 Binding 信息写回 API Server，以方便其它组件使用
  
- `kube-colltroller-manager`维护管理集群状态，负责管理各种控制器

  ![kube-controller-manager](https://bxdc-static.oss-cn-beijing.aliyuncs.com/images/20200510123033.png)

- etcd

###### `Node`节点

- `kubelet `是负责容器真正运行的核心组件
  - 负责 `Node` 节点上 `Pod `的创建、修改、监控、删除等全生命周期的管理
    - 通过调用容器运行时接口`CRI`来实现容器绑定`Volume、Port、 Network `等
  - 定时上报本地 Node 的状态信息给 API Server
- `kube-proxy`解决了外部网络访问内部应用
  - `kube-proxy`从 API Server 获取 Services 和 Endpoints 的配置信息，然后根据其配置信息在 `Node` 上启动一个 `Proxy` 的进程并监听相应的服务端口
  - `kube-proxy`后端使用随机、轮循等负载均衡算法进行调度

### 名词解释

#### **容器**

- 定义：

  - 可重复的、可运行的、集成了应用的运行时环境

- 本质

  - 一种特殊的单进程

  - 拥有独立的名称空间、控制组以及rootfs

    - 名称空间实现了容器隔离

      - Pid、Mount、UTS、IPC、Network 和 User等

    - 控制组`Linux Cgroups`实现了容器的运行资源控制

      - CPU、内存、磁盘、网络带宽
      
    - `rootfs`实现了容器的文件系统隔离
- 切换并挂载根目录
      - `Docker` 在镜像的设计中，引入了层（layer）的概念，实现了增量rootfs

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

- `pod`创建原理

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

  - `ImagePullPolicy`
    
    - `Always`
  - 每次创建 Pod 都重新拉取一次镜像
    
    - `Never` 或者 `IfNotPresent`
    
  - 不主动拉取，只有在宿主机不存在时才去拉取
  
- `OnFailure`
      - 当容器终止运行且退出码不为0时，由kubelet自动重启该容器

  - `LifeStyle`

    - `postStart`
  
    - 容器启动后立即执行一个操作

    - ```
    livenessProbe
      ```

      - 可以配置存活探测的频率、以及存活探测的接口【执行命令或者请求api】

    - readinessProbe

      - 可读性探针
  
    - `preStop`
    
      - 同步进行容器被杀死后的执行的一个操作

  - resources

    - `pod`运行资源限制

- 预写入容器配置【通过volumes挂载】

  - `Secret`

    - 写入`etcd`，适合保存非明文账号密码，作为环境变量或者挂载文本传递

  - `ConfigMap`

    - 写入配置信息，挂载在一个目录或者设置成环境变量【获取cm的全部或者某个key】

  - `Downward API`

    ```
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

  - `PodPreset` 对象

    - 定义的`pod`通过`label`选择器继承该定义
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
  - `iptables -t 表名 <-A/I/D/R> 规则链名 [规则号] <-i/o 网卡名> -p 协议名 <-s 源IP/源子网> --sport 源端口 <-d 目标IP/目标子网> --dport 目标端口 -j 动作`

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

  - ###### FULLNAT模式

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
  - headless Service: 利用的是 Service 的 DNS 方式，DNS服务解析到的是PodIP

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
- PVC，都以“<PVC 名字 >-<StatefulSet 名字 >-< 编号 >”的方式命名
- StorageClass是自动地为集群里存在的每一个 PVC，调用存储插件创建对应的 PV【动态创建pv】

#### CRD&[Operator](https://github.com/operator-framework/operator-sdk/blob/master/README.md)

- `Custom Resource Define` 简称 CRD，是 Kubernetes为提高可扩展性让开发者去自定义资源的一种方式
- `CRD `资源可以动态注册到集群中

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

    ```
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
  - `ReplicaSet Controller`: 简称RS
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
        - Pod 的创建，也是严格按照编号顺序**升序**进行的，当前一个ready后才会创建后一个
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

#### **调度器**

- 功能
  - 负责接收`Controller Manager`创建的新的`Pod`，为其选择一个合适的`Node`，并将信息写入`etcd`中
  - `Node`上的kubelet通过API Server监听到调度器产生的`Pod`绑定信息，获取`Pod`清单，下载`image`，并启动容器
- 调度流程
  - 预选调度：遍历所有目标Node，筛选出符合要求的候选节点
  - 优选策略：采用优选策略确定最优节点

### 架构原理

#### 分层架构

- 核心层：Kubernetes 最核心的功能，对外提供 API 构建高层的应用，对内提供插件式应用执行环境
- 应用层：部署（无状态应用、有状态应用、批处理任务、集群应用等）和路由（服务发现、DNS 解析等）
- 管理层：系统度量（如基础设施、容器和网络的度量），自动化（如自动扩展、动态 Provision 等）以及策略管理（RBAC、Quota、PSP、NetworkPolicy 等）
- 接口层：kubectl 命令行工具、客户端 SDK 以及集群联邦
- 生态系统：在接口层之上的庞大容器集群管理调度的生态系统，可以划分为两个范畴
  - Kubernetes 外部：日志、监控、配置管理、CI、CD、Workflow、FaaS、OTS 应用、ChatOps 等
  - Kubernetes 内部：CRI、CNI、CVI、镜像仓库、Cloud Provider、集群自身的配置和管理等

### 安全

#### `RBAC`权限控制

###### `API`对象

- 声明式`API`设计
- 不同的`API`路径有不同的版本隔离
  - Alpha
  - Beta
  - 稳定级别
- 查询资源cmdline
  - `kubectl get --raw /apis/batch/v1 | python -m json.tool`
  - 使用命令行开启一个`proxy`，然后使用`curl`请求
    - `kubectl proxy`会在终端开启一个`127.0.0.1:8001`的服务
    - 开启另一个终端，`curl http://127.0.0.1:8001/apis/batch/v1`

###### `RBAC`

- `k8s`的`API`对象都是模型化的
  - 资源对象包含`pods`/`ConfigMaps`/`Deployments`/`nodes`等
  - 资源对象的操作有`create`/`get`/`delete`/`update`/`edit`/`watch`/`exec`/`patch`等
- `RBAC`中重要字段概念
  - `Rule`
    - 规则，作用于不同`API Group`上的一组操作集合
  - `Role`和`ClusterRole`
    - `Role`定义的规则适用于`namespace`,`ClusterRole`定义的规则作用于整个集群
    - 这两种角色都属于`API`资源对象
  - `Subject`
    - `User Account`，用户账户
    - `Group`， 关联多个账户
    - `Service Account`，服务账号，和`namespace`关联
  - `RoleBinding`和`ClusterRoleBinding`
    - 角色和集群角色绑定，将`Subject`与`Role`进行绑定

###### 创建角色

- `Role API  ` 或者`ClusterRole API`对象`yaml`清单包含字段, 不同之处是前者需要指定`namespace`
  - `apiGroup`，组
  - `resources`，资源列表
  - `verbs`, 操作

###### 创建角色权限绑定

- `subjects`
  - `Kind`，`User`或者`Group`或者`ServiceAccount`
  - `name`，创建的主体账户名称
  - `apiGroup`，可以留空
- `roleRef`
  - `Kind`，`Role`或者`ClusterRole`
  - `name`，创建的角色名称
  - `apiGroup`，可以留空

###### `ServiceAccount`

- 只能访问某个`namespace`的`ServiceAccount`
  - `RoleBinding`中填写`namespace: your namespace`
  - `system:serviceaccount:kube-system:your sa `
- 访问全局的`ServiceAccount`
  - 使用`ClusterRoleBinding`

#### `Security Context`

###### 应用场景

- 运行容器使用`sysctl`运行命令修改内核参数，`docker`使用`--privileged`参数来使用特权模式

###### k8s提供三种解决方案

- Container-level Security Context：仅应用到指定的容器
- Pod-level Security Context：应用到 Pod 内所有容器以及 Volume
- Pod Security Policies（PSP）：应用到集群内部所有 Pod 以及 Volume

###### 如何设置`pod`字段

- 访问权限控制：根据用户 ID（UID）和组 ID（GID）来限制对资源（比如：文件）的访问权限

  ```
  securityContext:
      runAsUser: 1000 #UID, userId为1000
      runAsGroup: 3000 #GID, groupIDw为3000
      fsGroup: 2000 # fsGroup, 所有者以及在指定的数据卷下创建的任何文件，其 GID 都为 2000
  ```

  ![Security Context List](https://www.qikqiak.com/k8strain/assets/img/security/security-context-list.png)

- Linux Capabilities：给某个特定的进程超级权限，而不用给 root 用户所有的 privileged 权限

  - 几个概念

    - 特权进程（UID=0，也就是超级用户, 拥有所有的内核权限）和非特权进程（UID!=0)
    - `SUID(Set User ID on execution)`，允许用户以可执行文件的 owner 权限来运行，有安全隐患
    -  Linux 引入了 `Capabilities` 机制来对 root 权限进行了更加细粒度的控制

  - 原理

    - 在执行特权操作时，如果进程的有效身份不是 root，就去检查是否具有该特权操作所对应的 

      `capabilites`，并以此决定是否可以进行该特权操作

    - [可选设置项](https://www.qikqiak.com/k8strain/assets/img/security/docker-drop-capabilites.png)

  - 如何使用

    ```
    $ sudo setcap cap_net_admin,cap_net_raw-p /bin/ping # p:Permitted
    $ getcap /bin/ping
    ```

  - `docker`中通过 `--cap-add`和`--cap-drop`来设置

- `k8s Capalibilities yaml`样例

  ```
  apiVersion: v1
  kind: Pod
  metadata:
    name: cpb-demo
  spec:
    containers:
    - name: cpb
      image: busybox
      args:
      - sleep
      - "3600"
      securityContext:
        capabilities:
          add: # 添加
          - NET_ADMIN
          drop:  # 删除
          - KILL
  ```

- 为容器设置`SELINUX`标签

  ```
  securityContext:
    seLinuxOptions:
      level: "s0:c123,c456"
  ```

#### 准入控制器

###### 概念

- 准入控制器是在对象持久化之前用于对 `Kubernetes API Server` 的请求进行拦截的代码段，在请求经过**身份验证**和**授权之后**放行通过

###### 具体过程

![k8s api request lifecycle](https://bxdc-static.oss-cn-beijing.aliyuncs.com/images/k8s-api-request-lifecycle.png)

- 检查集群中是否启用了` admission webhook `控制器，并根据需要进行配置。
- 编写处理准入请求的 HTTP 回调，回调可以是一个部署在集群中的简单 HTTP 服务，甚至也可以是一个 `serverless` 函数，例如[这个项目](https://github.com/kelseyhightower/denyenv-validating-admission-webhook)。
- 通过 `MutatingWebhookConfiguration` 和 `ValidatingWebhookConfiguration` 资源配置 admission webhook。

###### 编写 webhook

- 开启`apiserver`中`MutatingAdmissionWebhook` 和 `ValidatingAdmissionWebhook` 这两个控制器

  ````
  --enable-admission-plugins=NodeRestriction,MutatingAdmissionWebhook,ValidatingAdmissionWebhook
  ````

- 验证

  ```
  kubectl api-versions |grep admission
  ```

- [样例参考](https://github.com/cnych/admission-webhook-example)
  - `webhook.go`
    - 进行验证的主要逻辑，通过`label`和`annotations`来实现是否需要准入验证
  - `main.go`
    - 启动一个服务，监听终止信号
  - 签发证书脚本：`./deployment/webhook-create-signed-cert.sh`

### 网络

### 监控

#### Prometheus

##### 特点

- 具有由 metric 名称和键/值对标识的时间序列数据的多维数据模型
- 有一个灵活的查询语言
- 不依赖分布式存储，只和本地磁盘有关
- 通过 HTTP 的服务拉取时间序列数据
- 也支持推送的方式来添加时间序列数据
- 还支持通过服务发现或静态配置发现目标
- 多种图形和仪表板支持

##### 组成

- `Prometheus Server`：用于抓取指标、存储时间序列数据
- `exporter`：暴露指标让任务来抓
- `pushgateway`：`push` 的方式将指标数据推送到该网关
- `alertmanager`：处理报警的报警组件 `adhoc`：用于数据查询

##### 生态架构图

![prometheus architecture](https://raw.githubusercontent.com/zhu733756/bedpic/main/imagesprometheus-architecture.png)

##### 通过配置启动

```
$ ./prometheus --config.file=prometheus.yml
$  cat prometheus.yml
global: #全局配置
  scrape_interval:     15s
  evaluation_interval: 15s

rule_files: #指定了报警规则所在的位置
  # - "first.rules"
  # - "second.rules"

scrape_configs: #采集的对象资源
  - job_name: prometheus #采集 prometheus 服务本身的时间序列数据
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'example-random'
     # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:8080', 'localhost:8081']
        labels:
          group: 'production'
      - targets: ['localhost:8082']
        labels:
          group: 'canary'
```

通过`Promenade ui`查看采集的对象

![prometheus webui metrics](https://raw.githubusercontent.com/zhu733756/bedpic/main/imagesprometheus-webui-metrics.png)

##### 应用监控

只需要暴露一个api，提供metrics路径访问即可

##### 重启`Prometheus`

```
curl -X POST "http://10.244.3.174:9090/-/reload"
```

##### 集群节点

对于集群的监控一般我们需要考虑以下几个方面：

- Kubernetes 节点的监控：比如节点的 cpu、load、disk、memory 等指标
- 内部系统组件的状态：比如 kube-scheduler、kube-controller-manager、kubedns/coredns 等组件的详细运行状态
- 编排级的 metrics：比如 Deployment 的状态、资源请求、调度和 API 延迟等数据指标

 `kube-state-metrics` 和 `metrics-server` 主要区别如下：

- `kube-state-metrics` 主要关注的是业务相关的一些元数据，比如 Deployment、Pod、副本状态等
- `metrics-server` 主要关注的是[资源度量 API](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/instrumentation/resource-metrics-api.md) 的实现，比如 CPU、文件描述符、内存、请求延时等指标。

##### 自定义node-exporter

- 配置`node-exporter` 暴露给`prometheus`，是运行在容器中的，所以我们在 Pod 中需要配置一些 Pod 的安全策略，这里我们就添加了 `hostPID: true`、`hostIPC: true`、`hostNetwork: true` 3个策略，用来使用主机的 `PID namespace`、`IPC namespace` 以及主机网络；

- 此外，还需要将主机的 `/dev`、`/proc`、`/sys`这些目录挂载到容器中，这些因为我们采集的很多节点数据都是通过这些文件夹下面的文件来获取到的，比如我们在使用 `top` 命令可以查看当前 cpu 使用情况，数据就来源于文件 `/proc/stat`；

- 如果希望 master 节点也一起被监控，如果有必须，则需要添加相应的容忍；

- 支持5中服务发现模式，分别是：`Node`、`Service`、`Pod`、`Endpoints`、`Ingress`。

```
- job_name: 'kubernetes-nodes'
  kubernetes_sd_configs:
  - role: node
    relabel_configs:
  - source_labels: [__address__] #采集之前替换端口，寻找一个不需要验证端口
    regex: '(.*):10250'
    replacement: '${1}:9100'
    target_label: __address__
    action: replace
  - action: labelmap #监控分组分类查询，通过集群中 Node 节点的 Label 标签获取
    regex: __meta_kubernetes_node_label_(.+)
```

- 对于 `kubernetes_sd_configs` 下面可用的元信息标签如下：
  - `__meta_kubernetes_node_name`：节点对象的名称
  - `_meta_kubernetes_node_label`：节点对象中的每个标签
  - `_meta_kubernetes_node_annotation`：来自节点对象的每个注释
  - `_meta_kubernetes_node_address`：每个节点地址类型的第一个地址（如果存在）

- 由于 prometheus 可以访问 Kubernetes 的一些资源对象，所以需要配置 rbac 相关认证
- 跳过证书校验

```
- job_name: 'kubernetes-kubelet'
  kubernetes_sd_configs:
  - role: node
  scheme: https
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    insecure_skip_verify: true #这里
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  relabel_configs:
  - action: labelmap
    regex: __meta_kubernetes_node_label_(.+)
```

- 如果出现挂在目录访问操作权限问题了，这个时候我们就可以通过 `securityContext` 来为 Pod 设置下 volumes 的权限，通过设置 `runAsUser=0` 指定运行的用户为 root

```
......
securityContext:
  runAsUser: 0
volumes:
- name: data
  hostPath:
    path: /data/prometheus/
- configMap:
    name: prometheus-config
  name: config-volume
```

- 容器监控

```
- job_name: 'kubernetes-cadvisor'
  kubernetes_sd_configs:
  - role: node
  scheme: https
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  relabel_configs:
  - action: labelmap
    regex: __meta_kubernetes_node_label_(.+)
  - target_label: __address__
    replacement: kubernetes.default.svc:443
  - source_labels: [__meta_kubernetes_node_name]
    regex: (.+)
    target_label: __metrics_path__
    replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor
    # node 的服务发现模式，因为每一个节点下面都有 kubelet，自然都有 cAdvisor 采集到的数据指标
```

- 监控pod && 服务发现

```
- job_name: 'kubernetes-endpoints'
  kubernetes_sd_configs:
  - role: endpoints
  relabel_configs:
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
    action: keep
    regex: true
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
    action: replace
    target_label: __scheme__
    regex: (https?)
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
    action: replace
    target_label: __metrics_path__
    regex: (.+)
  - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
    action: replace
    target_label: __address__
    regex: ([^:]+)(?::\d+)?;(\d+)
    replacement: $1:$2
  - action: labelmap
    regex: __meta_kubernetes_service_label_(.+)
  - source_labels: [__meta_kubernetes_namespace]
    action: replace
    target_label: kubernetes_namespace
  - source_labels: [__meta_kubernetes_service_name]
    action: replace
    target_label: kubernetes_name
  - source_labels: [__meta_kubernetes_pod_name]
    action: replace
    target_label: kubernetes_pod_name
```

```
$ kubectl get svc kube-dns -n kube-system -o yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    prometheus.io/port: "9153"  # metrics 接口的端口
    prometheus.io/scrape: "true"  # 这个注解可以让prometheus自动发现
  creationTimestamp: "2019-11-08T11:59:50Z"
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: KubeDNS
  name: kube-dns
  namespace: kube-system
......
```

#### Grafana

##### 优势

Grafana 是一个可视化面板，有着非常漂亮的图表和布局展示，功能齐全的度量仪表盘和图形编辑器，支持 Graphite、zabbix、InfluxDB、Prometheus、OpenTSDB、Elasticsearch 等作为数据源，比 Prometheus 自带的图表展示功能强大太多，更加灵活，有丰富的插件，功能更加强大。

##### 单机部署

###### docker

```
$ docker run -d --name=grafana -p 3000:3000 grafana/grafana
```

###### volume 挂载

grafana 将 dashboard、插件这些数据保存在 `/var/lib/grafana` 这个目录下面的，所以我们这里如果需要做数据持久化的话，就需要针对这个目录进行 volume 挂载声明

###### root 用户运行

```
# 由于changelog提到userid 和 groupid 都有所变化
securityContext:
   runAsUser: 0
```

###### 暴露svc

对外暴露 grafana 这个服务，所以我们需要一个对应的 Service 对象

###### 插件

进入容器后，运行以下命令，由于我们挂载了volumes，所以重启后插件生效；

```
grafana-cli plugins install devopsprodigy-kubegraf-app
grafana-cli plugins install Grafana-piechart-panel
```

##### `dashboard`

###### 官方市场

https://grafana.com/grafana/dashboards

###### 导入`dashboard`

导入一个`node-exporter`数据，例如 https://grafana.com/grafana/dashboards/8919 

![import](https://raw.githubusercontent.com/zhu733756/bedpic/main/images20200319193258.png)

###### 自定义`Dashboard`

添加PromQL计算语句

![Queries](https://raw.githubusercontent.com/zhu733756/bedpic/main/images20200320130313.png)

添加过滤参数

![Add Variable](https://raw.githubusercontent.com/zhu733756/bedpic/main/images20200320132058.png)

![match node name](https://raw.githubusercontent.com/zhu733756/bedpic/main/images20200320132924.png)

#### PromQL

##### 特点

`PromQL` 是 Prometheus 内置的数据查询语言，其提供对时间序列数据丰富的查询，聚合以及逻辑运算能力的支持。并且被广泛应用在 Prometheus 的日常应用当中，包括对数据查询、可视化、告警处理。

##### 时间序列

Prometheus 会将所有采集到的样本数据以时间序列的方式保存在**内存数据库**中，并且定时保存到硬盘上。

```
  ^
  │     . . . . . . . . . . . . . . . . .   . .   
  │     . . . . . . . . . . . . . . . . . . .   
  │     . . . . . . . . . .   . . . . . . . .   
  │     . . . . . . . . . . . . . . . .   . .  
  v
    <------------------ 时间 ---------------->
    
```

在时间序列中的每一个点称为一个样本（sample），样本由以下三部分组成：

- 指标(metric)：metric name 和描述当前样本特征的 labelsets
  - 通式：`  <metric name>{<label name> = <label value>, ...}`
  - 指标和`label`名称要符合：`[a-zA-Z_:][a-zA-Z0-9_:]*`
- 时间戳(timestamp)：一个精确到毫秒的时间戳
- 样本值(value)： 一个 float64 的浮点型数据表示当前样本的值

```
<--------------- metric ---------------------><-timestamp -><-value->
http_request_total{status="200", method="GET"}@1434417560938 => 94355
http_request_total{status="200", method="GET"}@1434417561287 => 94334

http_request_total{status="404", method="GET"}@1434417560938 => 38473
http_request_total{status="404", method="GET"}@1434417561287 => 38544

http_request_total{status="200", method="POST"}@1434417560938 => 4748
http_request_total{status="200", method="POST"}@1434417561287 => 4785
```

每个不同的 `metric_name`和 `label` 组合都称为**时间序列**，表达式包括以下四种类型之一：

- 瞬时向量（Instant vector）：一组时间序列，每个时间序列包含单个样本，它们共享相同的时间戳。也就是说，表达式的返回值中只会包含该时间序列中的最新的一个样本值。而相应的这样的表达式称之为瞬时向量表达式。
- 区间向量（Range vector）：一组时间序列，每个时间序列包含一段时间范围内的样本数据，这些是通过将时间选择器附加到方括号中的瞬时向量（例如[5m]5分钟）而生成的。
- 标量（Scalar）：一个简单的数字浮点值。
- 字符串（String）：一个简单的字符串值。

##### 指标类型

###### **Counter-计数器**

`Counter` (只增不减的计数器) 类型的指标其工作方式和计数器一样，只增不减。常见的监控指标，如 `http_requests_total`、`node_cpu_seconds_total` 都是 `Counter` 类型的监控指标。

通过 `rate()` 函数获取 HTTP 请求量的增长率：

```
rate(http_requests_total[5m])
```

查询当前系统中，访问量前 10 的 HTTP 请求：

```
topk(10, http_requests_total)
```

###### Gauge-可增可减的仪表盘

与 `Counter` 不同，`Gauge`（可增可减的仪表盘）类型的指标侧重于反应系统的当前状态。

例如`node_memory_MemFree_bytes`（主机当前空闲的内存大小）、`node_memory_MemAvailable_bytes`（可用内存大小）都是 `Gauge` 类型的监控指标。

通过 `PromQL` 内置函数 `delta()` 可以获取样本在一段时间范围内的变化情况。例如，计算 CPU 温度在两个小时内的差异：

```
delta(cpu_temp_celsius{host="zeus"}[2h])
```

还可以直接使用 `predict_linear()` 对数据的变化趋势进行预测。例如，预测系统磁盘空间在4个小时之后的剩余情况：

```
predict_linear(node_filesystem_free_bytes[1h], 4 * 3600)
```

###### Histogram 和 Summary

在大多数情况下人们都倾向于使用某些量化指标的平均值，例如 CPU 的平均使用率、页面的平均响应时间。

`Histogram` 和 `Summary` 主用用于统计和分析样本的分布情况。

与 `Summary` 类型的指标相似之处在于 `Histogram` 类型的样本同样会反应当前指标的记录的总数(以 `_count` 作为后缀)以及其值的总量（以 `_sum` 作为后缀）。不同在于 `Histogram` 指标直接反应了在不同区间内样本的个数，区间通过标签 le 进行定义。

##### 查询

###### 标签过滤

- `=` 等于
- `!=` 不等于
- `=~` 匹配正则表达式
- `!~` 与正则表达式不匹配

```shel
node_cpu_seconds_total{instance="ydzs-master"}
```

###### 范围选择器

时间范围通过数字来表示，单位可以使用以下其中之一的时间单位：

- s - 秒
- m - 分钟
- h - 小时
- d - 天
- w - 周
- y - 年

范围选择器必须是标量或者瞬时向量才可以绘制图形, 以下查询语句在graph查询会有问题：

```
node_cpu_seconds_total{instance="ydzs-master", mode="idle"}[1m]
```

以上表达式中，每一个时间序列中都有多个时间戳多个值，所以没办法渲染。

Prometheus 中对瞬时向量和区间向量有很多操作的[函数](https://prometheus.io/docs/prometheus/latest/querying/functions)，不过对于区间向量来说最常用的函数并不多，使用最频繁的有如下几个函数：

- `rate()`: 计算整个时间范围内区间向量中时间序列的每秒平均增长率
- `irate()`: 仅使用时间范围中的**最后两个数据点**来计算区间向量中时间序列的每秒平均增长率，`irate` 只能用于绘制快速变化的序列，在长期趋势分析或者告警中更推荐使用 `rate` 函数
- `increase()`: 计算所选时间范围内时间序列的增量，它基本上是速率乘以时间范围选择器中的秒数

```
rate(node_cpu_seconds_total{instance="ydzs-master", mode="idle"}[1m])
```

位移操作的关键字是 `offset`，比如我们可以查询30分钟之前的 master 节点 CPU 的空闲指标数据：

```
node_cpu_seconds_total{instance="ydzs-master", mode="idle"} offset 30m
```

###### 关联查询

`sum by`

```
sum(node_cpu_seconds_total{mode="idle"}) by (instance)
```

`on`

```
node_cpu_seconds_total{instance="ydzs-master", cpu="0", mode="idle"} + on(mode) node_cpu_seconds_total{instance="ydzs-node1", cpu="0", mode="idle"}
```

`on` 关键字只能用于一对一的匹配中, 可以使用 `group_left` 或`group_right` 关键字。这两个关键字将匹配分别转换为**多对一**或**一对多**匹配。比如通过 [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) 这个工具来获取 Kubernetes 集群的各种状态指标，包括 Pod 的基本信息，执行如下所示的查询语句：

```
container_cpu_user_seconds_total{namespace="kube-system"} * on (pod) group_left() kube_pod_info
```

###### 瞬时向量和标量结合

```
node_cpu_seconds_total{instance="ydzs-master"} * 10
```

#### AlertManger

##### 处理流程

![alertmanager workflow](https://raw.githubusercontent.com/zhu733756/bedpic/main/images20200326101221.png)

在 Prometheus 中一条告警规则主要由以下几部分组成：

- 告警名称：用户需要为告警规则命名，当然对于命名而言，需要能够直接表达出该告警的主要内容
- 告警规则：告警规则实际上主要由 `PromQL` 进行定义，其实际意义是当表达式（PromQL）查询结果持续多长时间（During）后出发告警

启动参数中指定了配置文件 ，告警内容写在文件里面，通过cm挂载进去

Prometheus的alert资源清单：

```
alerting:
  alertmanagers:
    - static_configs:
      - targets: ["alertmanager:9093"]
```

##### 报警规则

警报规则允许你基于 Prometheus 表达式语言的表达式来定义报警报条件，并在触发警报时发送通知给外部的接收者。

```
 rules.yml: |
    groups:
    - name: test-node-mem
      rules:
      - alert: NodeMemoryUsage
        expr: (node_memory_MemTotal_bytes - (node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes)) / node_memory_MemTotal_bytes * 100 > 20
        for: 2m
        labels:
          team: node
        annotations:
          summary: "{{$labels.instance}}: High Memory usage detected"
          description: "{{$labels.instance}}: Memory usage is above 20% (current value is: {{ $value }}"
```

- `alert`：告警规则的名称
- `expr`：是用于进行报警规则 PromQL 查询语句
- `for`：评估等待时间（Pending Duration），用于表示只有当触发条件持续一段时间后才发送告警，在等待期间新产生的告警状态为`pending`, 这个参数主要用于降噪，很多类似响应时间这样的指标都是有抖动的
- `labels`：自定义标签，允许用户指定额外的标签列表，把它们附加在告警上
- `annotations`：指定了另一组标签，它们不被当做告警实例的身份标识，它们经常用于存储一些额外的信息，用于报警信息的展示之类的

通过 `$labels.变量` 可以访问当前告警实例中指定标签的值，`$value` 则可以获取当前 PromQL 表达式计算的样本值。

一个报警信息在生命周期内有下面3种状态：

- `pending`: 表示在设置的阈值时间范围内被激活了
- `firing`: 表示超过设置的阈值时间被激活了
- `inactive`: 表示当前报警信息处于非活动状态

##### 路由配置

```
routes:
- receiver: email
  group_wait: 10s
  match:
    team: node
```

##### Inhibition和 Silences

![alert workflow](https://raw.githubusercontent.com/zhu733756/bedpic/main/images20200326105135.png)

##### WebHook 接收器

 AlertManager 支持很多中报警接收器，比如 slack、微信之类的，其中最为灵活的方式当然是使用 webhook 了，我们可以定义一个 webhook 来接收报警信息，然后在 webhook 里面去进行处理，需要发送怎样的报警信息我们自定义就可以

##### 记录规则

一种能够类似于后台批处理的机制在后台完成这些复杂运算的计算，对于使用者而言只需要查询这些运算结果即可。Prometheus 通过`Recoding Rule` 规则支持这种后台计算的方式，可以实现对复杂查询的性能优化，提高查询效率。

```
groups:
- name: example
  rules:
  - record: job:http_inprogress_requests:sum
    expr: sum(http_inprogress_requests) by (job)
    # 添加或者覆盖的标签
	labels:[ <labelname>: <labelvalue> ]
```

### 日志

## 存储

## Service Mesh 实践

## Kubernetes 多租户

## Kubernetes DevOps 

### 其他

#### 资源配额

- 相关定义

  | Resource               | Description                                                  |
  | ---------------------- | ------------------------------------------------------------ |
  | cpu                    | Total requested cpu usage                                    |
  | memory                 | Total requested memory usage                                 |
  | pods                   | Total number of active pods where phase is pending or active. |
  | services               | Total number of services                                     |
  | replicationcontrollers | Total number of replication controllers                      |
  | resourcequotas         | Total number of resource quotas                              |
  | secrets                | Total number of secrets                                      |
  | persistentvolumeclaims | Total number of persistent volume claims                     |

- `Requests vs. Limits`

  - For an example, consider the following scenarios relative to tracking quota on CPU:

    | Pod  | Container | Request CPU | Limit CPU | Result                                                       |
    | ---- | --------- | ----------- | --------- | ------------------------------------------------------------ |
    | X    | C1        | 100m        | 500m      | The quota usage is incremented 100m                          |
    | Y    | C2        | 100m        | none      | The quota usage is incremented 100m                          |
    | Y    | C2        | none        | 500m      | The quota usage is incremented 500m since request will default to limit |
    | Z    | C3        | none        | none      | The pod is rejected since it does not enumerate a request.   |

  - The quota may be allocated as follows:  it is encouraged that the user define a **LimitRange** with **LimitRequestRatio** to control burst out behavior.

    | Pod  | Container | Request CPU | Limit CPU | Tier       | Quota Usage |
    | ---- | --------- | ----------- | --------- | ---------- | ----------- |
    | X    | C1        | 1           | 4         | Burstable  | 1           |
    | Y    | C2        | 2           | 2         | Guaranteed | 2           |
    | Z    | C3        | 1           | 3         | Burstable  | 1           |

- [`links`]( https://github.com/kubernetes/community/blob/master/contributors/design-proposals/resource-management/admission_control_resource_quota.md)

- `cgroups`

  - `/sys/fs/cgroup/cpu/cpu.cfs_quota_us`
  - `/sys/fs/cgroup/cpu/cpu.cfs_period_us`

- 单位

  - 一个请求 0.5 CPU 的容器保证会获得请求 1 个 CPU 的容器的 CPU 的一半。 你可以使用后缀 `m` 表示毫。例如 `100m` CPU、100 milliCPU 和 0.1 CPU 都相同。 精度不能超过 1m。
  - CPU 请求只能使用绝对数量，而不是相对数量。0.1 在单核、双核或 48 核计算机上的 CPU 数量值是一样的。

