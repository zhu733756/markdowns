| **序号** | **内网IP**   | **内网端口** | **外网端口** |                              |
| -------- | ------------ | ------------ | ------------ | ---------------------------- |
| 1        | 192.168.10.7 | 30000        | 10000        | https协议端口                |
| 2        | 192.168.10.7 | 30001        | 10001        | Quic协议外网端口             |
| 3        | 192.168.10.7 | 30002        | 10002        | cloudhub首次token获取证书    |
| 4        | 192.168.10.7 | 30003        | 10003        | cloudstream端口              |
| 5        | 192.168.10.7 | 30004        | 10004        | tunnel端口（edgestream连接） |

#### Ks-installer

add advertiseAddress to yaml file, then install kubeedge:

```
https://github.com/kubesphere/ks-installer/blob/release-3.1/deploy/cluster-configuration.yaml
```

edit ks-installer, reomove kubeedge status, add advertiseAddress, restart ks-installer deployment

```
kubectl edit cc ks-installer  -n kubesphere-system 
```

#### kubeedge pods

kubectl -n kubeedge get pods

#### Add edge node && Monitoring

- Prerequisites :  docker + nsswitch.conf

- console: 
  - run cmd on edge node

#### Deploy workloads to edge node

refers to kubeedge/example/**apache-beam-analysis**/

https://github.com/zhu733756/examples/tree/dev-0.1/apache-beam-analysis

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ke-apachebeam-analysis-deployment
  labels:
    app: ke-apachebeam-analysis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ke-apachebeam-analysis
  template:
    metadata:
      labels:
        app: ke-apachebeam-analysis
    spec:
      hostNetwork: true
      containers:
      - name: ke-apachebeam-analysis
        image: containerise/ke_apache_beam:ke_apache_analysis_v1.2
      - name: publisher
        image: zhu733756/ke-testbeam:ke-v1.2
      nodeSelector:
        node-role.kubernetes.io/edge: ""
      tolerations:
      - effect: NoSchedule
        key: node-role.kubernetes.io/edge
        operator: Exists
```

#### Remove edge node

##### edge node

- remove your workloads

- ./keadm reset 
- apt remove mosquitto

- rm -rf /var/lib/kubeedge /var/lib/edged /etc/kubeedge/ca /etc/kubeedge/certs

- rm -rf /etc/kubeedge

- rm -rf /usr/local/bin/edgecore

##### cloud node

kubectl get nodes

kubectl delete node xxxx

#### images

![image-20210518182608095](../../../../AppData/Roaming/Typora/typora-user-images/image-20210518182608095.png)



