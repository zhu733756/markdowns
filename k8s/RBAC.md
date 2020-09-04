<!--
 * @Description:
 * @version:
 * @Author: zhu733756
 * @Date: 2020-09-03 16:35:35
 * @LastEditors: zhu733756
 * @LastEditTime: 2020-09-04 17:47:19
-->

## 基于角色的权限控制之 RBAC。

- k8s 中的授权工作的机制就是 RBAC
- 概念
  - Role：角色，它其实是一组规则，定义了一组对 Kubernetes API 对象的操作权限。一组权限规则列表。
  - RoleBinding：定义了“被作用者”和“角色”【权限列表】的绑定关系。
    - Subject：
      - 被作用者，既可以是“人”，也可以是“机器”，也可以使你在 Kubernetes 里定义的“用户”。
    - roleRef：
      - 被拥有者的引用
- Role

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: mynamespace
  name: example-role
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "watch", "list"]
```

- RoleBing

```yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: example-rolebinding
  namespace: mynamespace
subjects: #被拥有者
  - kind: User
    name: example-user
    apiGroup: rbac.authorization.k8s.io
roleRef: #被拥有者的引用
  kind: Role
  name: example-role
  apiGroup: rbac.authorization.k8s.io
```

- namespaced 对象与非 namespaced 对象

  - kind：
    - 将 role 与 role 并改成 ClusterRole 和 ClusterRoleBinding
  - namespaced 对象需要定义 namespace
  - 非 namespaced 不定义 namespace

- verbs

  - verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

- 为内置用户授权
  - 将 role 中的 kind 改为 ServiceAccount【内置用户】

```yaml
$ kubectl get sa -n mynamespace -o yaml
- apiVersion: v1
  kind: ServiceAccount
  metadata:
    creationTimestamp: 2018-09-08T12:59:17Z
    name: example-sa
    namespace: mynamespace
    resourceVersion: "409327"
    ...
  secrets:
  - name: example-sa-token-vmfg6 # 内置用户的授权交互对象
```

- serviceAccounts

  - 用户名字
    - system:serviceaccount:ServiceAccount 名字
  - 用户组的名字
    - system:serviceaccounts:Namespace 名字【不指定名称空间则是作用于整个系统里的所有 ServiceAccount】

- 内置集群角色
  - cluster-admin；
  - admin；
  - edit；
  - view。

## 总结

- 角色（Role），其实就是一组权限规则列表。而我们分配这些权限的方式，就是通过创建 RoleBinding 对象，将被作用者（subject）和权限列表进行绑定。
- 与之对应的 ClusterRole 和 ClusterRoleBinding，则是 Kubernetes 集群级别的 Role 和 RoleBinding，它们的作用范围不受 Namespace 限制
- 尽管权限的被作用者可以有很多种（比如，User、Group 等），但在我们平常的使用中，最普遍的用法还是 ServiceAccount。所以，Role + RoleBinding + ServiceAccount 的权限分配方式是你要重点掌握的内容
