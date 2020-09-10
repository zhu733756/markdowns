<!--
 * @Description:
 * @version:
 * @Author: zhu733756
 * @Date: 2020-08-26 13:45:01
 * @LastEditors: zhu733756
 * @LastEditTime: 2020-09-07 16:46:28
-->

> [1.iptables 详解](https://www.jianshu.com/p/ee4ee15d3658)

- iptables 其实就是 NetFilter 的界面
- Netfilter 子系统的作用，就是 Linux 内核里挡在“网卡”和“用户态进程”之间的一道防火墙

  - 在 iptables 中，这些“检查点”被称为：链（Chain）
  - 所谓“检查点”实际上就是内核网络协议栈代码里的 Hook

- ip 包的去向
  - 本机处理
    - Netfilter 会设置一个名叫 INPUT 的“检查点”, 流入路径（Input Path）结束
    - IP 包通过传输层进入用户空间，交给用户进程处理
    - 通过本机发出返回的 IP 包, 这个 IP 包就进入了流出路径（Output Path)
      - IP 包首先还是会经过主机的路由表进行路由
        - OUTPUT
        - POSTROUTING
  - 转发至目的地处理
    - FORWARD 检查点
      - FORWARD“检查点”完成后，IP 包就会来到流出路径
      - 流出路径直接来到 POSTROUTING 检查点
  - 最终检查点
    - POSTROUTING 的作用，其实就是上述两条路径，最终汇聚在一起的“最终检查点”。
