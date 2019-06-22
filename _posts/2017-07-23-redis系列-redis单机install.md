---
date: 2019-06-22 12:11
title: redis系列--redis单机install
tags: [redis]
---

单机很简单 几个命令
Linux 下安装
下载地址：<http://redis.io/download>
本教程使用的最新文档版本为 5.0.5，下载并安装：

```bash
wget http://download.redis.io/releases/redis-5.0.5.tar.gz
//yum安装gcc 需要 gcc依赖
yum install gcc-c++ tcl
tar xzf redis-5.0.5.tar.gz
cd redis-5.0.5
make
make MALLOC=libc(如果报错的话)
```

make完后 redis-5.0.5目录下会出现编译后的redis服务程序redis-server,还有用于测试的客户端程序redis-cli,两个程序位于安装目录 src 目录下：
下面启动redis服务.

```bash
cd src
./redis-server
```

注意这种方式启动redis 使用的是默认配置。也可以通过启动参数告诉redis使用指定配置文件使用下面命令启动。

```bash
$ cd src
$ ./redis-server redis.conf
```

redis.conf是一个默认的配置文件。我们可以根据需要使用自己的配置文件。
启动redis服务进程后，就可以使用测试客户端程序redis-cli和redis服务交互了。 比如：

```bash
$ cd src
$ ./redis-cli
redis> set foo bar
OK
redis> get foo
"bar"
```

以上copy自菜鸟教程 这是个好地方,一般的技术入门都从他开始,链接在下面
> http://www.runoob.com/redis/redis-install.html

单机一般都是自己测试用,
下面列几个单机的配置项

```text
requirepass password(密码)
port 6379(端口)
daemonize yes (后台进程模式)

```

单机自己玩这三个就可以了