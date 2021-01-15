## GOLANG学习笔记

#### GOLANG环境搭建

- ###### GOROOT

  - `golang`源码文件的安装目录，需要配置为环境变量

- ###### `GOBIN`

  - `GO `程序生成的`可执行文件（executable file）`的路径，将`GOROOT`配置为环境变量即可

- ###### GOPATH

  - 若干工作区目录的路径, 也就是你的`workspace`或者代码区，需要配置为环境变量

- ###### GOPROXY

  - 设置`goproxy`, 加速`package` 拉取
  - `windows`配置过程如下：
    - 版本在`1.13`以上可如下配置
    - `go env -w GO111MODULE=on`
    - `go env -w GOPROXY=https://goproxy.cn,direct`
  - `mac`或者`linux`配置如下：
    - `export GO111MODULE=on `
    - `export GOPROXY=https://goproxy.cn`

- ###### `IDLE`

  - `vscode`
  - `goland`
  - 或者其它

- ###### `mod`

  - `Go` 的包管理方式
    - ` monorepo `
    - `vendor: v1.5`
    - `mod: v1.11`
  - 开启`mod`
    - `windows`
      - `go env -w GO111MODULE=on` 
    - `mac or linux`
      - `export GO111MODULE=on`

- ###### 注意事项

  - `GOPATH`和`GOROOT`尽量不要放在一起
  - 查看`go`的`version`
    - `go version`
  - 查看 `env`
    - `go env`
    - 查看配置的三个配置项
      - `go env GOROOT`
      - `go env GOPATH`
      - `go env GOPROXY`

- 参考配图

  ![img](https://cdn.processon.com/5fe44930e401fd549c7f1aad?e=1608800064&token=trhI0BY8QfVrIGn9nENop6JAc6l5nZuxhjQ62UfM:wPDgkNRsfa9SQOIwIjsdlMWmJg4=)