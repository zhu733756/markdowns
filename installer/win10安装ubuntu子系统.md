## win10安装ubuntu子系统&&vim快速国内源

### 安装适用于 Linux 的 Windows 子系统

以**管理员身份**打开 PowerShell 并运行：

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

##  更新到 WSL 2

若要更新到 WSL 2，必须满足以下条件：

- 按 Win键 + R，检查你的 Windows 版本，然后键入 **winver**，选择“确定”。 （或者在 Windows 命令提示符下输入 `ver` 命令）。 
- 如果内部版本低于 19041，请在设置中进行安全更新，或者下载助手进行更新 https://www.microsoft.com/zh-cn/software-download/windows10 ![1593857973469](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\1593857973469.png)

### 启用“虚拟机平台”可选组件

安装 WSL 2 之前，必须启用“虚拟机平台”可选功能。

以管理员身份打开 PowerShell 并运行：

PowerShell复制

```powershell
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

**重新启动**计算机，以完成 WSL 安装并更新到 WSL 2。

### 安装ubuntu

 打开 [Microsoft Store](https://aka.ms/wslstore)，并选择你偏好的 Linux 分发版。 

![1593859067662](C:\Users\Administrator\Desktop\markdowns\pngs\1593859067662.png)

### 安装国内源&&vim技巧分享

首先复制一份，追加后缀为.bak，以免误操作。

```
cd /etc/apt
cp sources.list sources.list.bak
ll
```

![1593859631257](C:\Users\Administrator\Desktop\markdowns\pngs\1593859631257.png)

接着，找到[清华镜像国内源地址]( https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/ )，选择你的ubuntu版本,然后把下面这一块全部复制下来，准备粘贴到sources.list里面。

![1593859938313](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\1593859938313.png)

操作一个文件一般使用vim:

```
vim sources.list
```

2. 输入:set nu , 显示行数
3. 如果想进入第一行或者最后一行：

- :$ 跳转到最后一行
- :1 跳转到第一行
- shift+g 跳转到最后一行
- gg 跳转到第一行

3. 如果想要进行全选操作：

- **全选（高亮显示**）：按esc后，然后ggvG或者ggVG
- **全部复制：**按esc后，然后ggyG
- **全部删除：**按esc后，然后dG

4. 批量注释：`:起始行号,结束行号s/^/注释符/g`

按照上述的方法进行全部删除后粘贴，保存退出即可：

![1593860853296](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\1593860853296.png)

然后更新国内：

```
sudo apt update
```

至此，ubuntu环境搭建好了，下一篇介绍怎么安装docker。