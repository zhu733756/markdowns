<!--
 * @Description: 
 * @version: 
 * @Author: zhu733756
 * @Date: 2020-08-25 14:52:57
 * @LastEditors: zhu733756
 * @LastEditTime: 2020-08-25 14:59:51
-->
## ReplicaSet 和 ReplicaController

- 区别
  - 选择器
    - set除了支持等值label筛选以外，还支持in查询
  - 更新pods
    - set使用rollout进行更新
    - crontroller 使用rolling-update