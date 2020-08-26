<!--
 * @Description: 
 * @version: 
 * @Author: zhu733756
 * @Date: 2020-08-26 11:40:10
 * @LastEditors: zhu733756
 * @LastEditTime: 2020-08-26 16:51:13
-->

## 基本概念
- Service是Kubernetes的核心概念，通过创建Service，可以为一组具有相同功能的容器应用提供一个统一的入口地址，并且将请求负载分发到后端的各个容器应用上。

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
    - label Selector的配置，将选择具有Label标签的Pod作为管理范围
  - type
    - ClusterIP
      - 虚拟服务的IP地址，作用于Pod访问，在Node上kube-proxy通过设置的iptables进行转发
    - NodePort
      - 使用Node的IP地址和宿主机的端口就能访问服务
    - LoadBlancer
      - 使用外接负载均衡器完成到服务的负载分发，需要在spec.status.loadBlancer字段指定外部服务均衡器的IP地址，并同时定义nodePort和clusterIP
  - clusterIP
  - sessionAffinity
    - 是否支持session，同一个客户端访问的请求分发给相同的后端
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
      - 需要转发的后端Pod端口号
    - nodePort  
      - 当spec.type=NodePort,指定映射物理机端口号
- status
  - loadBalancer
    - ingress 【外部负载均衡区】
      - ip 【外部负载均衡器ip】
      - hostname 【外部负载均衡器host】


## 访问pod

- 直接访问
  - 直接通过Pod的IP地址和端口号可以访问到容器应用内的服务，但是Pod的IP地址是不可靠的，例如当Pod所在的Node发生故障时，Pod将被Kubernetes重新调度到另一个Node，Pod的IP地址将发生变化。
  - 更重要的是，如果容器应用本身是分布式的部署方式，就需要在这些实例的前端设置一个负载均衡器来实现请求的分发。
  
- Service服务
  - 为了使客户端能负载均衡地访问Pod，又保持pod的隔离性，对pod的删除和新增无感知
  - 原理：
    - 系统为它分配了一个虚拟的IP地址，clusterIP，采用RoundRobin模式对客户端请求进行负载分发，访问kublete上的kube-proxy代理到pod
    - 另一方面，Pod的创建和销毁都会实时更新Service的Endpoint数据，可以实现去中心完成服务发现
  - 创建
    - 比如，如果已经存在了RC副本控制器，可以使用如下命令
      - kubectl expose rc webapp【rc的名称】
    - 此外，还能为deployment/rs/rc/yaml文件/pod直接创建service

- 外部服务Service
  - 在某些环境中，应用系统需要将一个外部数据库作为后端服务进行连接，或将另一个集群或Namespace中的服务作为服务的后端
    - 可以先创建一个无Label的Selector的Service
    - 再创建一个与service同名的Endpoint

- 无头Service
  - 在某些应用场景中，开发人员希望自己控制负载均衡的策略，不使用Service提供的默认负载均衡的功能，或者应用程序希望知道属于同组服务的其他实例
  - Kubernetes提供了Headless Service来实现这种功能，即不为Service设置ClusterIP（入口IP地址），仅通过Label Selector将后端的Pod列表返回给调用的客户端。

- 外部访问pod
  - 将容器应用的端口号映射到物理机
    - 设置容器级别的hostPort,将容器应用的端口号映射到物理机上
      - Pod.spec.containers.ports.hostPort
    - Service的端口号映射到物理机
      - 通过设置Pod级别的hostNetwork=true，该Pod中所有容器的端口号都将被直接映射到物理机上。
  - 将service的端口号映射到物理机
    - nodePort映射到物理机
      - Service.type=NodePort
    - 通过设置LoadBalancer映射到云服务商提供的LoadBalancer地址

- DNS服务
  - SkyDNS
  - KubeDNS
    - kubedns
      - 监控service资源变化生成DNS记录
    - dnsmasq
      - 从kubedns中获取DNS记录，提供缓存，提供查询服务 
    - sidecar 
      - 对以上两个组件进行健康检查
  - CoreDNS
    - 单个容器架构，只用一个容器便实现了KubeDNS内3个容器的全部功能。
  
- Ingress: HTTP 7层路由机制
  - 定义和说明
    - 用于将不同URL的访问请求转发到后端不同的Service，以实现HTTP层的业务路由机制
    - Kubernetes使用了一个Ingress策略定义和一个具体的Ingress Controller，两者结合并实现了一个完整的Ingress负载均衡器
    - 使用Ingress进行负载分发时，Ingress Controller基于Ingress规则将客户端请求直接转发到Service对应的后端Endpoint（Pod）上，这样会跳过kube-proxy的转发功能，kube-proxy不再起作用。
  - 解释
    - ◎ 对http://mywebsite.com/api的访问将被路由到后端名为api的Service；
    - ◎ 对http://mywebsite.com/web的访问将被路由到后端名为web的Service；
    - ◎ 对http://mywebsite.com/docs的访问将被路由到后端名为docs的Service。
  - example
    - 为Nginx容器设置了hostPort，将容器应用监听的80和443端口号映射到物理机上，使得客户端应用可以通过URL地址“http://物理机IP:80”或“https://物理机IP:443”来访问该Ingress Controller。【DemonSet】
    - 为了让Ingress Controller正常启动，还需要为它配置一个默认的backend，用于在客户端访问的URL地址不存在时，返回一个正确的404应答。【Deployment】
- Ingress的策略配置技巧
  - 转发到单个后端服务上
    - Ingress.spec.rules []
      - host: mywebsite.com
      - http:
        - paths []:
          - path: /demo
          - backend
            - serviceName: webapp
            - servicePort: 8080
  - 同一域名下，不同的URL路径被转发到不同的服务上
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

- 为了Ingress提供HTTPS的安全访问，可以为Ingress中的域名进行TLS安全证书的设置。
  - （1）创建自签名的密钥和SSL证书文件。
  - （2）将证书保存到Kubernetes中的一个Secret资源对象上。
  - （3）将该Secret对象设置到Ingress中。