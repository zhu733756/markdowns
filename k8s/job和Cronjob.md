<!--
 * @Description: 
 * @version: 
 * @Author: zhu733756
 * @Date: 2020-09-02 16:02:05
 * @LastEditors: zhu733756
 * @LastEditTime: 2020-09-02 17:06:39
-->
##  应用

- 离线任务
- 批量任务

## 字段

-  restartPolicy=Never
   -  离线计算的 Pod 永远都不应该被重启，否则它们会再重新计算一遍
   -  离线作业失败后 Job Controller 就会不断地尝试创建一个新 Pod
   -  restartPolicy 在 Job 对象里只允许被设置为 Never 和 OnFailure；而在 Deployment 对象里，restartPolicy 则只允许被设置为 Always

- 最长允许运行时间
  - spec.activeDeadlineSeconds

- 重试次数
  -  backoffLimit: 5

- 在任意时间最多可以启动多少个 Pod 同时运行
  - spec.parallelism

- Job 至少要完成的 Pod 数目，即 Job 的最小完成数
  - spec.completions


## 工作原理

- 控制对象是pod
- 控制器在控制循环中进行的调谐（Reconcile）操作，通过并行度、完成度、等参数的值来计算在周期中应该创建或者删除Pod数目


## 三种常用的、使用 Job 对象的方法

- 外部管理器 +Job 模板【TensorFlow 社区的 KubeFlow 项目】
```
apiVersion: batch/v1
kind: Job
metadata:
name: process-item-$ITEM
labels:
  jobgroup: jobexample
spec:
template:
    metadata:
    name: jobexample
    labels:
      jobgroup: jobexample
    spec:
    containers:
    - name: c
      image: busybox
      command: ["sh", "-c", "echo Processing item $ITEM && sleep 5"]
    restartPolicy: Never
```
  - 创建 Job 时，替换掉 $ITEM 这样的变量；
  - 所有来自于同一个模板的 Job，都有一个 jobgroup: jobexample 标签，也就是说这一组 Job 使用这样一个相同的标识。


- 第二种用法：拥有固定任务数目的并行 Job【“任务总数固定”的场景】
  
```
apiVersion: batch/v1
kind: Job
metadata:
  name: job-wq-1
spec:
  completions: 8
  parallelism: 2
  template:
    metadata:
      name: job-wq-1
    spec:
      containers:
      - name: c
        image: myrepo/job-wq-1
        env:
        - name: BROKER_URL
          value: amqp://guest:guest@rabbitmq-service:5672
        - name: QUEUE
          value: job1
      restartPolicy: OnFailure
```
  - 在这个实例中，我选择充当工作队列的是一个运行在 Kubernetes 里的 RabbitMQ。所以，我们需要在 Pod 模板里定义 BROKER_URL，来作为消费者。
  - 一旦你用 kubectl create 创建了这个 Job，它就会以并发度为 2 的方式，每两个 Pod 一组，创建出 8 个 Pod。每个 Pod 都会去连接 BROKER_URL，从 RabbitMQ 里读取任务，然后各自进行处理。

- 指定并行度（parallelism），但不设置固定的 completions 的值【任务总数未知】
```
apiVersion: batch/v1
kind: Job
metadata:
  name: job-wq-2
spec:
  parallelism: 2
  template:
    metadata:
      name: job-wq-2
    spec:
      containers:
      - name: c
        image: gcr.io/myproject/job-wq-2
        env:
        - name: BROKER_URL
          value: amqp://guest:guest@rabbitmq-service:5672
        - name: QUEUE
          value: job2
      restartPolicy: OnFailure
```
    - 自己决定什么时候启动新 Pod，什么时候 Job 才算执行完成

## Cronjob
```
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            args:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes cluster
          restartPolicy: OnFailure
```
- concurrencyPolicy=Allow，这也是默认情况，这意味着这些 Job 可以同时存在；
- concurrencyPolicy=Forbid，这意味着不会创建新的 Pod，该创建周期被跳过；
- concurrencyPolicy=Replace，这意味着新产生的 Job 会替换旧的、没有执行完的 Job。
- spec.startingDeadlineSeconds 时间窗口，过去 200 s 里，如果 miss 的数目达到了 100 次，那么这个 Job 就不会被创建执行了

## 补充
spec.ttlSecondsAfterFinished=100执行完毕后删除