## Pod资源管理

- 什么是Pod

  - 同一个pod的容器使用IPC相互访问
  - 容器可以通过localhost访问
  - 容器继承pod的名称
  - 每个pod都有一个共享的网络空间ip地址
  - 同一个pod的volumes共享【共享存储卷】
  
- 通信网络

  - Node Network
    - 与外部网络通信的接口
  - Service Network
    - 反向代理
    - iptables或者ips
    - 实现方式
      - SkyDNS
      - kubeDNS
      - CoreDNS（第三代）

  - Pod Network
    - ip地址动态的
  
- Pod陈述式端口参数
  - Service：NodePort
  - hostPort：
    - pod所在节点的host的映射端口
  - hostNetwork：
    - pod所在节点的host端口
    - 此时pod共享宿主机端口
  
- 负载均衡调度
  - LBaaS
    - 负载均衡器
  - 供应商
    - 云计算供应商
      - openstack
  
- 资源类型
  - namespace
    - 名称空间
      - 同一个名称空间的pod不能同名
  
- Label
  - key-value键值对
    - key只能由字母数字下划线点号,只能以字母和数字开头，键值前缀不能超过253个字符，kubernetes.io不能作为键前缀
    - 键值不能超过63个字符
  - 创建时指定，也可以按需指定
  - 一个对象可拥有一个不止一个标签，而同一个标签也可以被添加到多个资源之上
  - 版本标签、环境标签、分层架构标签
  - yaml配置
    - labels:
      - project: hello
      - spider: some
  - 查询
    - 等值查询
      - =
      - !=
    - 集合关系
      - in
      - not in
      - KEY
      - !KEY
  - 逻辑
    - 同时制定多个选择器是与操作
    - 空值的选择器表示选择所有资源对象
    - 空的选择器无法选择任何资源
  - 命令行：
    - 查看标签选择器
      - kubectl get pods --show-labels
    - 添加或修改label
      - 修改yaml配置&& apply
      - kubectl label pods foo unhealthy=true
      - kubectl label pods foo unhealthy=true  --overwrite
    - 筛选pod
      - kubectl get pods --show-labels -l app=myapp
      - kubectl get pods --show-labels -l app!=myapp
      - kubectl get pods --show-labels -l "app in (myapp, ngx-dep)"
      - kubectl get pods --show-labels -l "app in (myapp, ngx-dep)" -L app
      - kubectl get pods --show-labels -l "app notin (myapp, ngx-dep)" -L app
      - kubectl get pods --show-labels -l '!app' -L app
  
- 资源注解
  - 键值对
  - 识别资源、可以配置资源
  - yaml配置
    - annotations:
      - ik8s.io/project: hello
  - 命令行
    - kubectl annotate
  
- pod生命周期
  - 初始化容器
    - 串行启动
  
- 启动
  
  - post start hook【启动后设置】
  - main container启动
  - 正常
  - 存活状态监测
    - 就绪状态监测
  - 结束
    - post stop hook 【结束后设置】
  - 字段
    - lifecycle【post start hook、post stop hook 】
      - postStart
      - preStop
    - livenessProbe
      - exec 容器内执行命令
      - httpGet http请求
      - tcpSocket socket三次握手
      - initialDelaySeconds 初始化多久后检测
      - timeoutSeconds 每次检测超时时间
    - readinessProbe
  
  - pod对象的相位

    - Pending
    - Running
    - Succeeded
    - Failed
    - Unknown

- Pod安全
  
  - securityContext
    - runAsNonRoot
    - runAsUser
    - selinuxOptions
  
- Pod资源管理

  - pods.spec.containers.resources
    - limits【上限】
      - cpu.limit=200m【1000m=1个核心】
    - requests【下限】
      - cpu.requests=200m【1000m=1个核心】
  - 服务质量类别
    - guaranteed
      - cpu上下限相等
    - Burstable 
      - 至少有一个容器设置了cpu或者内存资源request属性
    - BestEffort
      - 没有设置上下限

- 静态Pod
  - 是一类kubelete进行管理的仅存在于特定Node上的Pod。
  - 它们不能通过APIServer进行管理，无法与ReplicationController、Deployment或者DaemonSet进行关联，并且kubelet无法对它们进行健康检查。
  - 静态Pod总是由kubelet创建的，并且总在kubelet所在的Node上运行。

- Pod容器共享Volume
  - Pod.spec.containers
    - volumeMounts
      - name：app-logs
      - mountPath
  - volumes
    - name: app-logs
    - emptyDir: {}

- Pod的配置管理
  - 目标
    - 应用部署的一个最佳实践是将应用所需的配置信息与程序进行分离，这样可以使应用程序被更好地复用，通过不同的配置也能实现更灵活的功能。
    - 将应用打包为容器镜像后，可以通过环境变量或者外挂文件的方式在创建容器时进行配置注入，但在大规模容器集群的环境中，对多个容器进行不同的配置将变得非常复杂。
  - ConfigMap
    - 生成为容器内的环境变量。
    - 设置容器启动命令的启动参数（需设置为环境变量）。
    - 以Volume的形式挂载为容器内部的文件或目录。
  - example
    - ConfigMap.data
      - key:value
        - value 可以是文件内容
    - kubectl create configmap NAME --from-file=
      - [key=]source
      - config-files-dir
        - 文件名为key,内容为value
    - 联合volumes与volumeMounts, 通过volumes绑定的名称找到挂载的目录进行
      - volumesMounts-[[list]]
        - name: severxml
        - mountPath: target/dir
      - pod.spec.volumes-[[list]]
        - configmap
          - name: severxml
          - items[list]
            - key:
            - path:

- 在容器内获取Pod信息
  - pod.spec.env
    - name: MY_POD_NAME
      - valueFrom
        - fieldRef
          - fieldPath: metadata.name
          - fieldPath: status.podIP
  - 将容器资源信息注入为环境变量
    - 获取方式与第一种相同，看api文档
  - volume 挂载

- Pod 重启方式
  - ◎ Always：当容器失效时，由kubelet自动重启该容器。
  - ◎ OnFailure：当容器终止运行且退出码不为0时，由kubelet自动重启该容器。
  - ◎ Never：不论容器运行状态如何，kubelet都不会重启该容器

- Pod 调度
  - pod副本控制器RC【replication controller】
    - RC独立于所控制的Pod，并通过Label标签这个松耦合关联关系控制目标Pod实例的创建和销毁，
    - 随着Kubernetes的发展，RC也出现了新的继任者Deployment，用于更加自动地完成Pod副本的部署、版本更新、回滚等功能。
    - Deployment的特点是在哪个节点上，完全由Master的Scheduler经过一系列算法计算得出，用户无法决定。
  - label:NodeSelector
    - 希望某种Pod的副本全部在指定的一个或者一些节点上运行，比如希望将MySQL数据库调度到一个具有SSD磁盘的目标节点上，此时Pod模板中的NodeSelector属性就开始发挥作用了
    - 做法：
      - 为k8s-node-1节点打上一个zone=north标签
        - kubectl label nodes nodename key=value
      - 在Pod的定义中加上nodeSelector的设置
      - 运行kubectl create -f命令创建Pod，scheduler就会将该Pod调度到拥有zone=north标签的Node上
  - NodeAffinity：Node亲和性调度
    - requiredDuringSchedulingIgnoredDuringExecution要求只运行在amd64的节点上（beta.kubernetes.io/arch In amd64）。
    - preferredDuringSchedulingIgnoredDuringExecution的要求是尽量运行在磁盘类型为ssd（disk-type In ssd）的节点上。
  - PodAffinity：Pod亲和与互斥调度策略
    - Pod亲和与互斥的条件设置也是requiredDuringSchedulingIgnoredDuringExecution和preferredDuringSchedulingIgnoredDuringExecution。
  -  Taints和Tolerations（污点和容忍）
     -  可以用kubectl taint命令为Node设置Taint信息,Taint则正好相反，它让Node拒绝Pod的运行。
  -  Pod Priority Preemption：Pod优先级调度
     -  PriorityClasses.value
     -  spec.priorityClassName指定
  - StatefulSet
    - 有状态集群的调度。对于ZooKeeper、Elasticsearch、MongoDB、Kafka等有状态集群，虽然集群中的每个Worker节点看起来都是相同的，但每个Worker节点都必须有明确的、不变的唯一ID（主机名或IP地址），这些节点的启动和停止次序通常有严格的顺序。此外，由于集群需要持久化保存状态数据，所以集群中的Worker节点对应的Pod不管在哪个Node上恢复，都需要挂载原来的Volume，因此这些Pod还需要捆绑具体的PV
  - DaemonSet
    - 在每个Node上调度并且仅仅创建一个Pod副本。这种调度通常用于系统监控相关的Pod，比如主机上的日志采集、主机性能采集等进程需要被部署到集群中的每个节点，并且只能部署一个副本。
  - Cronjob：定时任务
    - 类似Linux Cron的定时任务Cron Job
  - Pod调度控制器Job
    - 对于批处理作业，需要创建多个Pod副本来协同工作，当这些Pod副本都完成自己的任务时，整个批处理作业就结束了。

- Pod的扩缩容
  - 手动
    - kubectl scale
  - 自动
    - 原理
      - Kubernetes中的某个Metrics Server（Heapster或自定义Metrics Server）持续采集所有Pod副本的指标数据
      - 当目标Pod副本数量与当前副本数量不同时，HPA控制器就向Pod的副本控制器（Deployment、RC或ReplicaSet）发起scale操作，调整Pod的副本数量，完成扩缩容操作
    - 指标
      - Pod资源使用率
        - Pod级别的性能指标，通常是一个比率值，例如CPU使用率。
      - Pod自定义指标
        - Pod级别的性能指标，通常是一个数值
      - object
        - 自定义指标
    - 公式
      - 当前副本数×（当前指标值/期望的指标值）的结果向上取整
      - kube-controller-manager服务的启动参数--horizontal-pod-autoscaler-tolerance进行设置，默认值为0.1（即10%）

