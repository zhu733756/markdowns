<!--
 * @Description: 
 * @version: 
 * @Author: zhu733756
 * @Date: 2020-09-02 13:40:50
 * @LastEditors: zhu733756
 * @LastEditTime: 2020-09-02 15:02:42
-->
## 问题

- Master 节点和 Slave 节点需要有不同的配置文件（即：不同的 my.cnf）以及不同的读写逻辑；
- Master 节点和 Salve 节点需要能够传输备份信息文件；
  - 1. 如果这个 Pod 是 Master 节点，我们要怎么做；
  - 2. 如果这个 Pod 是 Slave 节点，我们又要怎么做。
- 在 Slave 节点第一次启动之前，需要执行一些初始化 SQL 操作；

## 解决

- ConfigMap
  - 我们只需要给主从节点分别准备两份不同的 MySQL 配置文件，然后根据 Pod 的序号
（Index）挂载进去即可。
    - master.cnf 开启了 log-bin，即：使用二进制日志文件的方式进行主从复制，这是一个标准的设置。
    - slave.cnf 开启了 super-read-only，代表的是从节点会拒绝除了主节点的数据同步操作之外的所有写操作，即：它对用户是只读的。
  - 接下来，我们需要创建两个 Service 来供 StatefulSet 以及用户使用
    - 第一个名叫mysql的 Service 是一个 Headless Service, 为 Pod分配DNS记录来固定它的拓扑状态。
    - 第二个名叫mysql-read的 Service，则是一个常规的 Service。

- InitContainer
  - 在本例中，有状态的应用的多个实例使用同一个pod模板创建
    - master和slave共同一个docker镜像
  - 两个initContainer
    - 从 Pod 的 hostname 里，读取到了 Pod 的序号，以此作为 MySQL 节点的 server-id，添加启动配置。
    - 在 Slave Pod 启动前，从 Master 或者其他 Slave Pod 里拷贝数据库数据到自己的目录下。

- sidecar
  - 容器首先会判断当前 Pod 的 /var/lib/mysql 目录下，是否有xtrabackup_slave_info 这个备份信息文件，然后生成 change_master_to.sql.in文件
    - 如果有，说明这个文件由slave生成，于是重命名
    - 没有的话，却又binlog文件说明是master生成，解析文杰拼装成sql语句
  - ncat传输数据
  - 由于 sidecar 容器和 MySQL 容器同处于一个 Pod 里，所以它是直接通过Localhost 来访问和备份 MySQL 容器里的数据的，非常方便

- container


- link 
  - https://github.com/oracle/kubernetes-website/blob/master/docs/tasks/run-application/mysql-statefulset.yaml