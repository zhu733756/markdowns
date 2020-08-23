## CronJob

#### example

```
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: cronjob-example
  labels:
    app: mycronjob
spec:
  schedule: "*/2 * * * *"
  jobTemplate:
    metadata:
      labels:
        app: mycronjob-jobs
    spec:
      parallelism: 2
      template:
        spec:
          containers:
          - name: myjob
            image: alpine
            command:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes cluster; sleep 10
          restartPolicy: OnFailure
```

#### Kind

- CronJob

#### metadata

- name
- labels

#### version

- batch/v1beta1

#### spec

- schedule 【跟定时任务的配置一致】

  - "* */2 * * *"

- jobTemplate

  - 用来指明用于执行的的定时job模板
  - 字段
    - metadata
    - specmetadataspec

 - concurrencyPolicy
     - Allow
          - 运行任务并发执行
     - Forbid 
          - 如果任务已经启动，则不再重新启动
     - Replace
          - 终止当前任务，并重启一个任务
     - failedJobsHistoryLimit	
          - 保留的失败完成任务的数量
     - startingDeadlineSeconds
          - 可选的结束时间，针对错过调度的任务的启动
     -  successfulJobsHistoryLimit
          - 保留的成功完成任务的 数量
     - suspend
          - 告诉控制器的是否延缓执行后续执行的标志

  