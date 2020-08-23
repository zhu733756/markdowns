###### Web框架哪家强?

- Django

  - 功能强大、实例丰富、文档全面、社区庞大
  - 与关系型数据库结合好，分表分库轻而易举
  - 自带后台管理，大而全
  - 成熟好用的ORM框架
  - 自带模板渲染引擎
  
  - 厚重、缺乏灵活性(我只要打死一个小蚂蚁，你却出了九牛二虎之力)
  - 与非关系数据库结合不如flask
  
- Flask 
  - 微框架、代码简单、入门门槛低、Pythonic
  - 灵活、可以集成大量flask插件
     	 - ORM用sqlalchemy
     - 渲染引擎用Jinja
     - 等等 
  - 不需要去考虑 MVC 或者 MTV 设计
    - Flask 中有蓝图的设计，按功能划分模块。 
  - 支持多种数据库结合方式
  - 个人感觉，django的orm好用些

- Tornado（本人没用过，以下来自网络，原文见参考文献）
  - 少而精，注重性能优越，速度快
  - 异步非阻塞、解决高并发（请求处理是基于回调的非阻塞调用）
  - websockets 长连接
  - 内嵌了HTTP服务器
  - 单线程的异步网络程序，默认启动时根据CPU数量运行多个实例；利用CPU多核的优势
  - 自定义模块
  - 模板和数据库部分有很多第三方的模块可供选择，这样不利于封装为一个功能模块
-  总结：
  - 要性能， Tornado 首选（前提是数据查询效率比较高，这样才有优势）。
  - 要开发速度，Django 和 Flask 都行。 
  - 需求简单灵活，Flask就好。
  - 需求大且全，多个flask合在一起，还是和django一样。



###### 另一款更快、更Pythonic的web框架FastAPi

- 快速、bug少、调试方便、灵活、学习成本低

  - 速度方面，能够跟NodeJS和Go相媲美

  - 简明定义、能节约2-3倍的代码工作量

  - 减少40%的人为导致错误

  - 丰富编辑器支持，调试时间更少

- 设计灵活、文档少

- 基于openApi开放标准

    - 安全模式
      - HTTP 基本认证。
      - **OAuth2** (也使用 **JWT tokens**)。
      - API 密钥:
        - 请求头。
        - 查询参数。
        - Cookies, 等等。
    -  Open API 考量的几个点（以下来自 blog.csdn.net, 文章链接见文末）
      - 签名鉴权（我需要知道请求我的是谁,有没有访问这个接口的权限）
      - 流量控制（我不可能让你随随便便就无节制的访问我,我要能随时关停你）
      - 请求转发（请求过来的 url,需要找到真正的业务处理逻辑,api最好只负责接口的规范,不负责业务的实现）
      - 日志处理（你可以保持沉默,但你说的每一句话都会成为呈堂供证）
      - 异常处理（即使老子内部出了问题,你也不会看到我的异常堆栈信息,我会告诉你我病了,请稍后再试）
      - 参数规范（顺我者倡,逆我者亡）
      - 多机部署（我有九条命）
      - 异步回调（别想阻塞我,但我可以玩死你）
      - 错误信息（你要认识到自己错误）

- swagger-ui, 支持请求响应，测试数据调试等可视化操作

    - /doc

    <img src="file:///C:/Users/Lenovo/Desktop/pngs/index-03-swagger-02.png" alt="/doc  APi" style="zoom:33%;" />

    - /redoc

    <img src="file:///C:/Users/Lenovo/Desktop/pngs/index-06-redoc-02.png" alt="/redoc Api" style="zoom: 33%;" />

     )

- 更加的pythonic
  ```
  from typing import List, Dict
  from datetime import date
  
  from pydantic import BaseModel
  
  # Declare a variable as a str
  # and get editor support inside the function
  def main(user_id: str):
      return user_id
  
  # A Pydantic model
  class User(BaseModel):
      id: int
      name: str
      joined: date
      
  my_user: User = User(id=3, name="John Doe", joined="2018-07-19")
  
  second_user_data = {
      "id": 4,
      "name": "Mary",
      "joined": "2018-11-30",
  }
  
  my_second_user: User = User(**second_user_data)
  ```

- 无限制"插件"

- 测试
      - 100% 测试覆盖。
      - 代码库100% 类型注释。
      - 用于生产应用。
  
- Starlette 特性

- pydantic 特性

- 支持Python3.6及其以上版本的类型提示

###### 参考文献

  - https://fastapi.tiangolo.com/ 	
  - https://blog.csdn.net/sheep8521/article/details/88551542 
  - https://pydantic-docs.helpmanual.io
  - https://www.starlette.io
  -  https://www.cnblogs.com/timssd/p/10299066.html 






