- 参照

  - kubectl get ns default -o yaml

- 实例
	
	- 创建ns实例
	  
	    - apiVersion:v1
	      - kind: Namespace
	      - metadata:
	        - name:develop
	      - spec:
	        - 可以留空
		  
		- 陈述式创建
		  
			- kubectl create -f xxx.yaml
			
		- 申明式创建
		
			- kubectl apply -f xxxx.yaml
		
	- 创建pod实例
	
	    - 生成yaml
	
	        - kubect  get pods
	        - kubectl get pods -o yaml xxxx --export  > mainfests/basic/pods.yaml
	
	    - 参考
	
	        - apiVersion:v1
	- kind:Pod
	        - metadata：
	
	            - createTimestamp
	    - name
	                - pod-demo
	            - namespace
	                - develop
	        - spec:【单个容器】
	        
	    - containers:【list [object]】
	                - -【单个容器要加这个-】image: ikubernbetes/myapp:v1
	            - imagePullPolicy:IfNotPresent
	                        - 【tag:latest,always】
	                    - name:myapp
	                    - resource:{}
	                - dnsPolicy:ClusterFirst【集群优先】
	                - enableServiceLinks【service反代】
	                    - true
	                - nodeName:【绑定节点】
	                    - xxx 
	                - restartPolicy：
	                    - always【宕机重启】
	                - schedlerName:
	                    - xxx
	                - securityContext:{}
	        - spec:【多个容器】
	            - -
	                - name：myapp
	                    - image: ikubernetes/myapp:v1
	                    - ports:
	                      - -
	                          - name: http
	                          - protocol: TCP
	                          - containerPort: 80
	                          - hostPort:8080
	            - -
	                - name:  bbox 
	            - image:  busybox:latest
	                - imagePullPolicy:  IfNotPresent
	            - command:["/bin/sh","-c", "sleep 86400"]
	
- 交互接口

  - kubectl exec  pod-demo【pod名称 】 -c bbox【容器中子容器】 -n prod -it -- /bin/bash
  - kubectl logs pod-demo【pod名称 】  -c myapp -n prod

- pod访问

  - 10.244.0.0/16能否被集群外部的客户端访问？
    - service，nodePort
    - hostPort
    - hostNetwork【docker中的host:nona模式】

- explain
  
- kubectl explain Pods.spec.containers....
  
- 搜索官方文档

	- kubernetes reference
	    -  https://kubernetes.io/zh/docs/reference/
	
	
	   ​		