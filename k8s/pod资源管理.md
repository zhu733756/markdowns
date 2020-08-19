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
      -     openstack
  
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
