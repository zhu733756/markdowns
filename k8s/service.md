<!--
 * @Description:
 * @version:
 * @Author: zhu733756
 * @Date: 2020-08-26 11:40:10
 * @LastEditors: zhu733756
 * @LastEditTime: 2020-09-08 17:07:59
-->

## 基本概念

- Service 是 Kubernetes 的核心概念，通过创建 Service，可以为一组具有相同功能的容器应用提供一个统一的入口地址，并且将请求负载分发到后端的各个容器应用上。

## 字段

- version
  - v1
- kind
  - Service
- metadata
  - name
  - namespace
  - labels[]
  - annotation[]
- spec
  - selector[]
    - label Selector 的配置，将选择具有 Label 标签的 Pod 作为管理范围
  - type
    - ClusterIP
      - 虚拟服务的 IP 地址，作用于 Pod 访问，在 Node 上 kube-proxy 通过设置的 iptables 进行转发
    - NodePort
      - 使用 Node 的 IP 地址和宿主机的端口就能访问服务
    - LoadBlancer
      - 使用外接负载均衡器完成到服务的负载分发，需要在 spec.status.loadBlancer 字段指定外部服务均衡器的 IP 地址，并同时定义 nodePort 和 clusterIP
  - clusterIP
  - sessionAffinity
    - 是否支持 session，同一个客户端访问的请求分发给相同的后端
      - ClientIP
      - None
  - ports[]
    - name
      - 端口名称
    - protocol
      - 端口协议
    - port
      - 服务监听端口
    - targetPort
      - 需要转发的后端 Pod 端口号
    - nodePort
      - 当 spec.type=NodePort,指定映射物理机端口号
- status
  - loadBalancer
    - ingress 【外部负载均衡区】
      - ip 【外部负载均衡器 ip】
      - hostname 【外部负载均衡器 host】

## 访问 pod

- 直接访问
  - 直接通过 Pod 的 IP 地址和端口号可以访问到容器应用内的服务，但是 Pod 的 IP 地址是不可靠的，例如当 Pod 所在的 Node 发生故障时，Pod 将被 Kubernetes 重新调度到另一个 Node，Pod 的 IP 地址将发生变化。
  - 更重要的是，如果容器应用本身是分布式的部署方式，就需要在这些实例的前端设置一个负载均衡器来实现请求的分发。
- Service 服务

  - 为了使客户端能负载均衡地访问 Pod，又保持 pod 的隔离性，对 pod 的删除和新增无感知
  - 原理：
    - 系统为它分配了一个虚拟的 IP 地址，clusterIP，采用 RoundRobin 模式对客户端请求进行负载分发，访问 kublete 上的 kube-proxy 代理到 pod
    - 另一方面，Pod 的创建和销毁都会实时更新 Service 的 Endpoint 数据，可以实现去中心完成服务发现
  - 创建
    - 比如，如果已经存在了 RC 副本控制器，可以使用如下命令
      - kubectl expose rc webapp【rc 的名称】
    - 此外，还能为 deployment/rs/rc/yaml 文件/pod 直接创建 service

- 外部服务 Service

  - 在某些环境中，应用系统需要将一个外部数据库作为后端服务进行连接，或将另一个集群或 Namespace 中的服务作为服务的后端
    - 可以先创建一个无 Label 的 Selector 的 Service
    - 再创建一个与 service 同名的 Endpoint

- 无头 Service

  - 在某些应用场景中，开发人员希望自己控制负载均衡的策略，不使用 Service 提供的默认负载均衡的功能，或者应用程序希望知道属于同组服务的其他实例
  - Kubernetes 提供了 Headless Service 来实现这种功能，即不为 Service 设置 ClusterIP（入口 IP 地址），仅通过 Label Selector 将后端的 Pod 列表返回给调用的客户端。

- 外部访问 pod

  - 将容器应用的端口号映射到物理机
    - 设置容器级别的 hostPort,将容器应用的端口号映射到物理机上
      - Pod.spec.containers.ports.hostPort
    - Service 的端口号映射到物理机
      - 通过设置 Pod 级别的 hostNetwork=true，该 Pod 中所有容器的端口号都将被直接映射到物理机上。
  - 将 service 的端口号映射到物理机
    - nodePort 映射到物理机
      - Service.type=NodePort
    - 通过设置 LoadBalancer 映射到云服务商提供的 LoadBalancer 地址

- DNS 服务
  - SkyDNS
  - KubeDNS
    - kubedns
      - 监控 service 资源变化生成 DNS 记录
    - dnsmasq
      - 从 kubedns 中获取 DNS 记录，提供缓存，提供查询服务
    - sidecar
      - 对以上两个组件进行健康检查
  - CoreDNS
    - 单个容器架构，只用一个容器便实现了 KubeDNS 内 3 个容器的全部功能。
- Ingress: HTTP 7 层路由机制
  - 定义和说明
    - 用于将不同 URL 的访问请求转发到后端不同的 Service，以实现 HTTP 层的业务路由机制
    - Kubernetes 使用了一个 Ingress 策略定义和一个具体的 Ingress Controller，两者结合并实现了一个完整的 Ingress 负载均衡器
    - 使用 Ingress 进行负载分发时，Ingress Controller 基于 Ingress 规则将客户端请求直接转发到 Service 对应的后端 Endpoint（Pod）上，这样会跳过 kube-proxy 的转发功能，kube-proxy 不再起作用。
  - 解释
    - ◎ 对http://mywebsite.com/api的访问将被路由到后端名为api的Service；
    - ◎ 对http://mywebsite.com/web的访问将被路由到后端名为web的Service；
    - ◎ 对http://mywebsite.com/docs的访问将被路由到后端名为docs的Service。
  - example
    - 为 Nginx 容器设置了 hostPort，将容器应用监听的 80 和 443 端口号映射到物理机上，使得客户端应用可以通过 URL 地址“http://物理机 IP:80”或“https://物理机 IP:443”来访问该 Ingress Controller。【DemonSet】
    - 为了让 Ingress Controller 正常启动，还需要为它配置一个默认的 backend，用于在客户端访问的 URL 地址不存在时，返回一个正确的 404 应答。【Deployment】
- Ingress 的策略配置技巧

  - 转发到单个后端服务上
    - Ingress.spec.rules []
      - host: mywebsite.com
      - http:
        - paths []:
          - path: /demo
          - backend
            - serviceName: webapp
            - servicePort: 8080
  - 同一域名下，不同的 URL 路径被转发到不同的服务上
    - Ingress.spec.rules []
      - host: mywebsite.com
      - http:
        - paths []:
          - path: /demo
          - backend
            - serviceName: webapp
            - servicePort: 8080
          - path: /doc
          - backend
            - serviceName: doc
            - servicePort: 8080
  - 不同的域名（虚拟主机名）被转发到不同的服务上

- 为了 Ingress 提供 HTTPS 的安全访问，可以为 Ingress 中的域名进行 TLS 安全证书的设置。
  - （1）创建自签名的密钥和 SSL 证书文件。
  - （2）将证书保存到 Kubernetes 中的一个 Secret 资源对象上。
  - （3）将该 Secret 对象设置到 Ingress 中。

## 容器“跨主网络”的实现原理。

- 运行机制
  - “隧道”机制
    - 它首先对发出端的 IP 包进行 UDP 封装，然后在接收端进行解封装拿到原始的 IP 包，进而把这个 IP 包转发给目标容器。这就好比，Flannel 在不同宿主机上的两个容器之间打通了一条“隧道”，使得这两个容器可以直接使用 IP 地址进行通信，而无需关心容器和宿主机的分布情况。
- UDP
  - container 1 -》 flannel0 -》 flannelId -》 eth0 -》eth0 -》 flannelId -》flannel0 -》container 2
  - UDP 模式有严重的性能问题，所以已经被废弃了
    - 额外处理步骤 ：flanneld 的处理过程
- VXLAN【Virtual Extensible LAN（虚拟可扩展局域网）】
  - 减少了用户态到内核态的切换次数，并且把核心的处理逻辑都放在内核态进行
  - 做法：
    - 拿到 MAC 地址，Linux 内核就可以开始二层封包工作了
    - 然后，Linux 内核会把这个数据帧封装进一个 UDP 包里发出去。
    - 接下来的流程，就是一个正常的、宿主机网络上的封包工作。
  - 流程：
    - container 1 -》 cni0 -》 flannel.1 -》 eth0 -》eth0 -》 flannel.1 -》cni0 -》container 2

## k8s 网络模型

- 共性

  - 通过 docker0 网桥连接用户的容器
  - 在宿主机上创建特殊的设备
    - UDP: TUN
    - VXLAN: VTEP

- Kubernetes 在启动 Infra 容器之后，就可以直接调用 CNI 网络插件，为这个 Infra 容器的 Network Namespace，配置符合预期的网络栈。

  - Network Namespace 的网络栈组成
    - 网卡（Network Interface）
    - 回环设备（Loopback Device）
    - 路由表（Routing Table）
    - iptables 规则。

- CNI 插件的工作原理

  - 当 kubelet 组件需要创建 Pod 的时候，它第一个创建的一定是 Infra 容器。所以在这一步，dockershim 就会先调用 Docker API 创建并启动 Infra 容器，紧接着执行一个叫作 SetUpPod 的方法。这个方法的作用就是：为 CNI 插件准备参数，然后调用 CNI 插件为 Infra 容器配置网络

- k8s 网络模型

  - 所有容器都可以直接使用 IP 地址与其他容器通信，而无需使用 NAT。
  - 所有宿主机都可以直接使用 IP 地址与所有容器通信，而无需使用 NAT。反之亦然。
  - 容器自己“看到”的自己的 IP 地址，和别人（宿主机或者容器）看到的地址是完全一样的。

- host-gw 工作原理

  - 将每个 Flannel 子网（Flannel Subnet，比如：10.244.1.0/24）的“下一跳”，设置成了该子网对应的宿主机的 IP 地址
  - 这台“主机”（Host）会充当这条容器通信路径里的“网关”（Gateway）
  - Flannel host-gw 模式必须要求集群宿主机之间是二层连通的
  - 通过 Etcd 和宿主机上的 flanneld 来维护路由信息

- calico
  - BGP 的全称是 Border Gateway Protocol，即：边界网关协议

## NetworkPolicy 【k8s 网络隔离】

- 限制

  - pod 默认是运行访问的
  - podSelector 定义了 NetworkPolicy 的限制范围
    - 选中的 pod 就会进入“拒绝所有的状态
  - NetworkPolicy 定义的规则，其实就是“白名单”
    - ingress 【流入，允许流入的“白名单”和端口】
    - egress 【流出，允许流出的“白名单”和端口】

- 注意 namespaceSelector 和 podSelector 与和或的逻辑

```yaml
  ingress:
  #与的逻辑
  - from:
    - namespaceSelector:
        matchLabels:
          user: alice
    - podSelector:
        matchLabels:
          role: client
  ...
  #和的逻辑
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          user: alice
    podSelector:
        matchLabels:
          role: client
```

- 原理就是 iptables
  - Kubernetes 网络插件对 Pod 进行隔离，其实是靠在 NetworkPolicy 对应的 iptable 规则来实现的。

```go
for dstIP := range 所有被 networkpolicy.spec.podSelector 选中的 Pod 的 IP 地址
  for srcIP := range 所有被 ingress.from.podSelector 选中的 Pod 的 IP 地址
    for port, protocol := range ingress.ports {
      iptables -A KUBE-NWPLCY-CHAIN -s $srcIP -d $dstIP -p $protocol -m $protocol --dport $port -j ACCEPT
    }
  }
}
```

- cni 网络插件中的实现

```go
for pod := range 该 Node 上的所有 Pod {
    if pod 是 networkpolicy.spec.podSelector 选中的 {
        iptables -A FORWARD -d $podIP -m physdev --physdev-is-bridged -j KUBE-POD-SPECIFIC-FW-CHAIN
        iptables -A FORWARD -d $podIP -j KUBE-POD-SPECIFIC-FW-CHAIN
        ...
    }
}

```

```
# 本机上的网桥设备，发往目的地址是 podIP 的 IP 包
iptables -A FORWARD -d $podIP -m physdev --physdev-is-bridged -j KUBE-POD-SPECIFIC-FW-CHAIN
# 容器跨主通信
iptables -A FORWARD -d $podIP -j KUBE-POD-SPECIFIC-FW-CHAIN

# 我们会把 IP 包转交给前面定义的 KUBE-NWPLCY-CHAIN 规则去进行匹配
iptables -A KUBE-POD-SPECIFIC-FW-CHAIN -j KUBE-NWPLCY-CHAIN
# 如果匹配失败，IP 包就会来到第二条规则上。可以看到，它是一条 REJECT 规则。通过这条规则，不满足 NetworkPolicy 定义的请求就会被拒绝掉，从而实现了对该容器的“隔离
iptables -A KUBE-POD-SPECIFIC-FW-CHAIN -j REJECT --reject-with icmp-port-unreachable
...
```

## service dns 服务发现

- iptables 和 ipvs
  - 相比于 iptables，IPVS 在内核中的实现其实也是基于 Netfilter 的 NAT 模式，所以在转发这一层上，理论上 IPVS 并没有显著的性能提升。但是，IPVS 并不需要在宿主机上为每个 Pod 设置 iptables 规则，而是把对这些“规则”的处理放到了内核态，从而极大地降低了维护这些规则的代价。
- 解决的问题
  - 如何找到我的某一个容器？【服务发现】
- 服务发现
  - 针对 podIp 的变化，如何通过一个固定的方式访问到这个 Pod 呢？
  - default.svc.cluster.local

## 外部访问 service 的三种方法

- NodePort
  - 映射 pod 的端口【targetPod】到宿主机的【nodePort】
  - 一个外部的 client 通过 node 2 的地址访问一个 Service 的时候，node 2 上会有负载均衡规则
- LoadBlancer
  - Kubernetes 就会调用 CloudProvider 在公有云上为你创建一个负载均衡服务
- External Name
  - 将外部网络路由到 k8s 节点中进行内部访问

## DNS 无法访问故障排除

- 区分是 service 问题还是 DNS 问题
- 步骤
  - 在 pod 中运行`nslookup kubernetes.default`
  - 查询 kube-dns 的运行状态和日志
  - Service 没办法通过 ClusterIP 访问到的时候，你首先应该检查的是这个 Service 是否有 Endpoints：
    - `kubectl get endpoints hostnames`
    - Pod 的 readniessProbe 没通过，它也不会出现在 Endpoints 列表里
  - kube-proxy 是否在正确运行
    - `kubectl edit cm kube-proxy -n kube-system`
    - `kubectl logs -f -l k8s-app=kube-proxy -n kube-system`
    - `kubectl describe pod -l k8s-app=kube-proxy -n kube-system`
  - 如果 kube-proxy 一切正常，你就应该仔细查看宿主机上的 iptables 了
    - KUBE-SERVICES 或者 KUBE-NODEPORTS 规则对应的 Service 的入口链，这个规则应该与 VIP 和 Service 端口一一对应；
    - KUBE-SEP-(hash) 规则对应的 DNAT 链，这些规则应该与 Endpoints 一一对应；
    - KUBE-SVC-(hash) 规则对应的负载均衡链，这些规则的数目应该与 Endpoints 数目一致；
    - 如果是 NodePort 模式的话，还有 POSTROUTING 处的 SNAT 链。

## ingress

- Ingress 实际上就是 Kubernetes 对“反向代理”的抽象

  - 可以理解为 service 的 service，代理到其他 service 的负载均衡器

- 安装
  - https://github.com/kubernetes/ingress-nginx/blob/master/deploy/static/provider/baremetal/deploy.yaml
  - 参考文章
    - https://cloud.tencent.com/developer/article/1574048
