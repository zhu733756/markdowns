<!--
 * @Description: 
 * @version: 
 * @Author: zhu733756
 * @Date: 2020-08-25 15:45:45
 * @LastEditors: zhu733756
 * @LastEditTime: 2020-08-25 15:51:30
-->

## 说明

- 在该StatefulSet的定义中包括两个容器：mongo和mongo-sidecar。
  - mongo是主服务程序
  - mongo-sidecar是将多个mongo实例进行集群设置的工具
    - mongo-sidecar中的环境变量如下。
        - MONGO_SIDECAR_POD_LABELS：
          - 设置为mongo容器的标签，用于sidecar查询它所要管理的MongoDB集群实例。
        - KUBERNETES_MONGO_SERVICE_NAME：
          - 它的值为mongo，表示sidecar将使用mongo这个服务名来完成MongoDB集群的设置。
  
- replicas=3表示这个MongoDB集群由3个mongo实例组成。
  
- volumeClaimTemplates是StatefulSet最重要的存储设置。
  - 在annotations段设置volume.beta.kubernetes.io/storage-class="fast"表示使用名为fast的StorageClass自动为每个mongo Pod实例分配后端存储。
  - resources.requests.storage=100Gi表示为每个mongo实例都分配100GiB的磁盘空间。