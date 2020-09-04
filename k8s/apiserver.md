<!--
 * @Description:
 * @version:
 * @Author: zhu733756
 * @Date: 2020-09-03 10:30:34
 * @LastEditors: zhu733756
 * @LastEditTime: 2020-09-03 16:18:13
-->

## 声明式 API 与 Kubernetes 编程范式

- 命令式命令行操作
  - 滚动更新中，每一步都需要命令行控制【做菜的步骤】
  - 注重过程控制
- 声明式操作
  - 【要什么菜，不管步骤，实时滚动更新】
    - 提交一个定义好的 API 对象来“声明”，我所期望的状态是什么样子。
    - 以 PATCH 的方式对 API 对象进行修改，而无需关心本地原始 YAML 文件的内容
    - 在完全无需外界干预的情况下， 通过基于 API 对象的增删改查实现完成对“实际状态”和“期望状态”的调谐过程

## istio 项目

- 目标
  - Istio 项目明明需要在无感每个 Pod 里安装一个 Envoy 容器
  - 监控流量进行微服务治理
- 实现
  - 首先，Istio 会将这个 Envoy 容器本身的定义，以 ConfigMap 的方式保存在 Kubernetes 当中

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: envoy-initializer
data:
  config:|
    containers:
      - name: envoy
        image: lyft/envoy:845747db88f102c0fd262ab234308e9e22f693a1
        command: ["/usr/local/bin/envoy"]
        args:
          - "--concurrency 4"
          - "--config-path /etc/envoy/envoy.json"
          - "--mode serve"
        ports:
          - containerPort: 80
            protocol: TCP
        resources:
          limits:
            cpu: "1000m"
            memory: "512Mi"
          requests:
            cpu: "100m"
            memory: "64Mi"
        volumeMounts:
          - name: envoy-conf
            mountPath: /etc/envoy
    volumes:
      - name: envoy-conf
        configMap:
          name: envoy
```

- 接下来，Istio 将一个编写好的 Initializer，作为一个 Pod 部署在 Kubernetes 中

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: envoy-initializer
  name: envoy-initializer
spec:
  containers:
    - name: envoy-initializer
      image: envoy-initializer:0.0.1
      imagePullPolicy: Always
```

- 控制器实现逻辑
  - 如果这个 Pod 里面已经添加过 Envoy 容器，那么就“放过”这个 Pod，进入下一个检查周期。
  - 而如果还没有添加过 Envoy 容器的话，它就要进行 Initialize 操作了，即：修改该 Pod 的 API 对象（doSomething 函数）。

```go
for {
  // 获取新创建的 Pod
  pod := client.GetLatestPod()
  // Diff 一下，检查是否已经初始化过
  if !isInitialized(pod) {
    // 没有？那就来初始化一下
    doSomething(pod)
  }
}
```

- Pod 里合并的字段
  - 获取 configmap
  - 添加进去空的 pod
  - 利用 patch 合并字段

```go
func doSomething(pod) {
  cm := client.Get(ConfigMap, "envoy-initializer")

  newPod := Pod{}
  newPod.Spec.Containers = cm.Containers
  newPod.Spec.Volumes = cm.Volumes

  // 生成 patch 数据
  patchBytes := strategicpatch.CreateTwoWayMergePatch(pod, newPod)

  // 发起 PATCH 请求，修改这个 pod 对象
  client.Patch(pod.Name, patchBytes)
}
```

- init

```yaml
apiVersion: admissionregistration.k8s.io/v1alpha1
kind: InitializerConfiguration
metadata:
  name: envoy-config
initializers:
  // 这个名字必须至少包括两个 "."
  - name: envoy.initializer.kubernetes.io
    rules:
      - apiGroups:
          - "" // 前面说过， "" 就是 core API Group 的意思
        apiVersions:
          - v1
        resources:
          - pods
```

```yaml
apiVersion: v1
kind: Pod
metadata
  annotations:
    "initializer.kubernetes.io/envoy": "true"
    ...
```

## 工作原理

- API 对象
  - 储存
    - 保存在 etcd 中
  - 例子
    - `/apis/batch/v1/jobs`
  - 组成
    - Group（API 组 `batch`(离线业务的意思)）
    - Version（API 版本 `v1`）
    - Resource（API 资源类型 `jobs`）
  - 特例
    - Pod、Node 不需要`Group`的, 归属在`api`下
      - `/api/v1/pods`
      - `/api/v1/nodes`
- API 的管理
  - 版本号管理
    - 向后兼容，根据 api 的版本号保存多个版本
  - 资源类型
    - 提交 yaml 文件，发送 post 请求
    - 进入 `MUX` 和 `Routes` 流程
      - `url` 和 `handler` 的绑定
        - `MUX`
          - `server/mux/container.go`
        - `routes`
          - `server/routes/*.go`
      - 根据用户提交的 YAML 文件里的字段，创建对象
      - `Admission`和`Validation`
        - 初始化控制器
        - 验证定义的字段
          - 验证通过会保存在 etcd 中的 Registry 数据库，作为一个对象
      - 序列化，保存 api
- 自定义资源 `CRD`
  - 自定义资源类型的 API 描述，包括：组（Group）、版本（Version）、资源类型（Resource）等。
    - 这相当于告诉了计算机：兔子是哺乳动物。
  - 自定义资源类型的对象描述，包括：Spec、Status 等。
    - 这相当于告诉了计算机：兔子有长耳朵和三瓣嘴。
  - 具体做法
    - 资源引用
    ```yaml
    apiVersion: samplecrd.k8s.io/v1
    kind: Network
    metadata:
      name: example-network
    spec:
      cidr: "192.168.0.0/16"
      gateway: "192.168.0.1"
    ```
    - 资源定义
    ```yaml
    apiVersion: apiextensions.k8s.io/v1beta1
    kind: CustomResourceDefinition
    metadata:
      name: networks.samplecrd.k8s.io
    spec:
      group: samplecrd.k8s.io
      version: v1
      names:
        kind: Network
        plural: networks
      scope: Namespaced
    ```
    - 代码生成
      - https://github.com/resouer/k8s-controller-custom-resource

## 定义资源控制器

- 基于声明式 API 的业务功能实现，往往需要通过控制器模式来“监视”API 对象的变化（比如，创建或者删除 Network），然后以此来决定实际要执行的具体工作。

```go
func main() {
  ...

  cfg, err := clientcmd.BuildConfigFromFlags(masterURL, kubeconfig)
  ...
  kubeClient, err := kubernetes.NewForConfig(cfg)
  ...
  networkClient, err := clientset.NewForConfig(cfg)
  ...

  networkInformerFactory := informers.NewSharedInformerFactory(networkClient, ...)

  controller := NewController(kubeClient, networkClient,
  networkInformerFactory.Samplecrd().V1().Networks())

  go networkInformerFactory.Start(stopCh)

  if err = controller.Run(2, stopCh); err != nil {
    glog.Fatalf("Error running controller: %s", err.Error())
  }
}
```

- main 函数
  - 根据 Master 配置（APIServer 的地址端口和 kubeconfig 的路径）创建 kubeClient 和 networkClient
    - 控制器就会直接使用默认 ServiceAccount 数据卷里的授权信息，来访问 APIServer
  - main 函数为 Network 对象创建一个叫作 InformerFactory 工厂，生成一个 informer 给控制器
    - Informer 使用 Reflector 包维护`networkClient`与`apiserver`的连接
    - Reflector 使用的是一种叫作 ListAndWatch 的方法，来获取并监听 Network 对象实例的变化
      - 同步本地缓存，FIFO
      - 触发事先定义好的注册好的 ResourceEventHandler【由控制器注册时给他】
  - 启动 informer，启动自定义控制器

```go
//控制器的定义
func NewController(
  kubeclientset kubernetes.Interface,
  networkclientset clientset.Interface,
  networkInformer informers.NetworkInformer) *Controller {
  ...
  controller := &Controller{
    kubeclientset:    kubeclientset,
    networkclientset: networkclientset,
    networksLister:   networkInformer.Lister(),
    networksSynced:   networkInformer.Informer().HasSynced,
    workqueue:        workqueue.NewNamedRateLimitingQueue(...,  "Networks"),
    ...
  }
    networkInformer.Informer().AddEventHandler(cache.ResourceEventHandlerFuncs{
    AddFunc: controller.enqueueNetwork,
    UpdateFunc: func(old, new interface{}) {
      oldNetwork := old.(*samplecrdv1.Network)
      newNetwork := new.(*samplecrdv1.Network)
      if oldNetwork.ResourceVersion == newNetwork.ResourceVersion {
        return
      }
      controller.enqueueNetwork(new)
    },
    DeleteFunc: controller.enqueueNetworkForDelete,
 return controller
}
```

```go
// controller.run()
func (c *Controller) Run(threadiness int, stopCh <-chan struct{}) error {
  ---
  if ok := cache.WaitForCacheSync(stopCh, c.networksSynced); !ok {
  return fmt.Errorf("failed to wait for caches to sync")
  }
  ---
  for i := 0; i < threadiness; i++ {
  go wait.Until(c.runWorker, time.Second, stopCh)
  }
  ---
  return nil
}
```

- Informer 本质和原理
  - 其实就是一个带有本地缓存和索引机制的、可以注册 EventHandler 的 client。
  - 每经过 resyncPeriod 指定的时间，Informer 维护的本地缓存，都会使用最近一次 LIST 返回的结果强制更新一次，从而保证缓存的有效性
- 启动控制循环
  - 首先，等待 Informer 完成一次本地缓存的数据同步操作；
  - 然后，直接通过 goroutine 启动一个（或者并发启动多个）“无限循环”的任务
- 获取 yaml 文件更新后的期望状态
  - workqueue 事件队列中 Get 一个事件
  - 从缓存中拿不到这个对象，意味着这个 Network 对象的 Key 是通过前面的“删除”事件添加进工作队列的，需要调用 Neutron 的 API，把这个 Key 对应的 Neutron 网络从真实的集群里删除掉。
- 获取实际状态
  - 通过 Neutron 来查询这个 Network 对象对应的真实网络是否存在
