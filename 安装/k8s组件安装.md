<!--
 * @Description: 
 * @version: 
 * @Author: zhu733756
 * @Date: 2020-08-28 17:05:14
 * @LastEditors: zhu733756
 * @LastEditTime: 2020-08-28 17:06:45
-->

## helm

- 阿里云镜像
  - registry.cn-qingdao.aliyuncs.com/kubeoperator/tiller:v2.16.9
- 脚本
  - helm init --upgrade \
    -i registry.cn-qingdao.aliyuncs.com/kubeoperator/tiller:v2.16.9 \
    --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts 