###### k8s

- 14年  Google 开发

###### Pod（豌豆荚）

- 最小的逻辑单元
- 可以运行多个容器，共享UTS NET IPC名称空间
- 理解：一个豌豆荚（Pod）里面都多个豌豆（container）

###### Pod控制器

- Pod启动模板，用来保证pod运行的预期
  - 副本数
  - 生命周期
  - 健康状态检查
- 常见Pod控制器
  - deployment
  - daemonset
  - replicaset
  - statefulset
  - job
  - cronjob

###### Name

- 资源
  - apiVersion（api版本）
  - kind（类别）
  - metadata（元数据）
  - spec（定义清单）
  - status（状态，不需要定义）
- 名称
  - 定义在metadata中

###### NameSpace

- 名称空间
- 默认名称空间：
  - default
  - kube-system
  - kube-public

###### Label

- 用途
  - 实现不同维度的管理
  - 一个标签可以对应多个资源。
  - 一个资源也可以有多个标签。

- 组成

  - key=value

- 区别于注释

  - annotations

###### Label选择器

- 给资源打上标签，可以使用 标签选择器过滤指定的标签

- 等值关系：
  - 等于、不等于

- 集合关系：
  - 属于、不属于、存在

- 内嵌标签选择器字段
  - matchLabels
  - matchExpressions

###### Service

- 一组提供提供相同服务的Pod的对外访问接口
- service作用于那些pod通过标签选择器定义的
-  集群网络、区别于node网络和pod网络

###### ingress

- 在OSI网络参考模型下第七层的应用，对外暴露的接口
- service只能进行L4流量调度，ip+port
- ingress可以调度不同业务域、不同url访问路径的业务流量
- ingress -》service-》prod

###### 核心组件

- 存储中心etcd服务
- 主控节点master
  - kube-apiserver服务
    - rest api接口：鉴权、数据校验和集群状态
    - 通信枢纽
    - 资源分配
    - 集群安全机制
  - kube-controller-manager服务
    - 控制器管理器
  - kube-scheduler服务
    - 接受调度pod到适合的运算节点
    - 预算策略、优选策略
- 运算节点node
  - kube-kubelet服务
    - 获取pod的期望状态，并调用接口达到该状态
    - 定期汇报当前节点的状态给apiserver
    - 镜像和容器的清理
  - kube-proxy服务
    - 运行网络的代理，service资源的载体
    - 建立pod网络和集群网络的关系
    - 流量调度模式：
      - usersp

- minikube
  - 二进制部署
  - kubeadmin部署

- ###### 应用程序

  - 单机应用api转移成针对于k8s的应用
    - cloud native  app
    - seleverless, knative
      - 客户端访问才运行服务
      - 也就是FaaS
      - 无感知云计算
  - 微服务
    - 区别于单体应用程序

    - 分层架构，将每个业务功能隔离出来

    - 每个功能独立成应用服务

    - 服务注册、服务发现
      - 网状结构
      - 非静态
      - 服务总线
        - 管理组件的接口服务
        - 管理组件的网络服务
        - 高可用
      
    - 容器编排系统【解决了容器打包的根本性难题】
      - 服务注册和服务发现
      - 负载均衡
      - 自动扩容、缩容、迁移
      - 认证、配置、容量管理
      - 容器的提供和部署
      - 健康监控

- 容器编排系统
	- k8s
	- Docker Swarm
	- Masos and Marathon
    
- k8s集群节点
	- masters
		- control plane
		- 多个master是冗余设置，避免master宕机
	- node
		- worker plane
		- 多个node，用来负载均衡

- k8s架构
	- master交互手段 
		- api
		- cli
		- ui
	- 管理服务
		- api server 【申明式api】
		- scheduler 【评估服务部署在哪个node】
		- controller 【控制器、拉取镜像、自动创建与删除】
		- etcd【coreos公司开发】



      
