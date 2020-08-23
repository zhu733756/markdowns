#### scrapy项目目录详解

- 目标
  - scrapy项目目录以及各路径文件的用处
  - scrapy的运行环境到底是怎样的
  - 精简爬虫项目文件

- scrapy项目目录以及各路径文件的用处

  ```
  website
   ├── scrapy.cfg
   ├── test.py
   └── website
       ├── bloomfilter
       │   ├── bloomfilter.py
       │   ├── connection.py
       │   ├── defaults.py
       │   ├── dupefilter.py
       │   ├── picklecompat.py
       │   ├── pipelines.py
       │   ├── queue.py
       │   ├── scheduler.py
       │   ├── spiders.py
       │   ├── utils.py
       │   └── __init__.py
       ├── commands
       │   ├── crawlall.py
       │   ├── crawlsome.py
       │   ├── crawl_order_category.py
       │   ├── getname.py
       │   └── __init__.py
       ├── connection.py
       ├── extensions
       │   ├── openCloseLogStats.py
       │   └── __init__.py
       ├── items.py
       ├── middlewares.py
       ├── pipelines.py
       ├── settings.py
       ├── spiders
       │   ├── all_channel
       │   ├── base.py
       │   ├── base_crawl.py
       │   ├── buwei
       │   ├── difang
       │   └── __init__.py
       ├── tools
       │   ├── extract_domains.py
       │   ├── public.py
       │   └── __init__.py
       └── __init__.py
  ```

  - 第一级目录
    - 项目名：website