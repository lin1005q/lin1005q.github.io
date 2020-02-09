---
date: 2017-07-23 19:45
title: redis系列--redis集群install
tags: [redis]
---
生产环境单机肯定是不行

redis 集群据我了解有三种方式

1. 客户端集群 客户端连接通过hash 类似hashmap的方式去把存储的东西打散到不同的节点去存储. 缺点是:服务端的节点会不平衡,有的节点多,有的节点少.
2. 代理 客户端和服务端之间增加一层代理 可控性进一步加强(代理自己可控) 缺点是 增加一层维护 代理有损耗 不适合小公司
3. 服务端集群 是redis官方在v3以后 提出的一种集群方式 最少6个节点 3主三从 优点是官方维护.

>[redis集群方案](https://www.zhihu.com/question/21419897)

其他还见过有哨兵模式,但这里说的是上面的3 既 官方发布的redis cluster.

第一次搭生产,下面的具体的配置文件详情
搭建redis集群 只用于做session 共享,不做其他.故不持久化处理

* bind 132.90.101.230 (绑定ip 生产必须绑定 如果机器绑定多ip,配置客户端访问的ip)
* appendonly no(类似于mysql binlog,故障恢复时使用)[参考](http://blog.nosqlfan.com/html/199.html)
* daemonize yes (后台进程模式)
* port 6371 (端口号)
* cluster-enabled yes(是否启用集群)
* cluster-config-file nodes-6371.conf (集群配置文件 此文件是系统自动生成,定义好文件名即可)
* cluster-node-timeout 15000 (节点的延迟)
* protected-mode yes (保护模式 保护模式下 要进行绑定ip和 使用密码)
* tcp-backlog 511
* timeout 0(指定在一个 client 空闲多少秒之后关闭连接（0 就是不管它）)
* tcp-keepalive 300
* supervised no (可以通过upstart和systemd管理Redis守护进程，这个参数是和具体的操作系统相关的。)
* pidfile /var/run/redis_6379.pid
* loglevel notice
* logfile *.log
* requirepass password (登录密码)
* save "" (不进行持久化操作 同时把快照和aof相关设置注释掉)
* maxmemory 1536mb (设置最大内存 生产必须设置)
* maxmemory-policy allkeys-lru (内存满了以后的内存清理策略 优先清理最少使用的)

>[redis 不持久化操作配置内存清理](http://blog.csdn.net/qq_18860653/article/details/53230903)
>[redis 配置详细讲解](http://www.cnblogs.com/cxd4321/archive/2012/12/14/2817669.html "redis 配置详细讲解")

```bash
mkdir 6381 6382 6383 6384 6385 6386
```

将上面的配置文件copy五份,最后一共6份.每一份里面的`bind` `port` `cluster-config-file` `pidfile` `logfile` 必须不同,但是`requirepass`必须一致

然后 每一份都在命令行启动起来

```bash
redis-server /**/*.conf
```

```bash
root@q:~# ps -ef |grep redis
root      3801  3779  0 19:50 pts/1    00:00:00 grep --color=auto redis
root     16941     1  0 6月29 ?       00:14:48 redis-server *:6379
q	     17388     1  0 6月29 ?       00:23:41 redis-server *:6381 [cluster]
q 	     17463     1  0 6月29 ?       00:23:40 redis-server *:6382 [cluster]
q        17488     1  0 6月29 ?       00:23:45 redis-server *:6383 [cluster]
q        17499     1  0 6月29 ?       00:23:30 redis-server *:6384 [cluster]
q        17509     1  0 6月29 ?       00:23:40 redis-server *:6385 [cluster]
q        17521     1  0 6月29 ?       00:23:29 redis-server *:6386 [cluster]
```

当看到6个都起来了可以继续下一步了
安装redis-gem
redis cluster 是通过一个ruby脚本创建的
所以要安装脚本文件

```bash
yum -y install ruby ruby-devel rubygems rpm-build
gem install redis
```

如果生产不联网,可以在官网下载redis-3.3.3.gem 很好找的
ruby环境 机子上肯定有, 然后`gem install -l redis-3.3.3.gem` -l 本地安装

接下来还需要一步 修改ruby 源码中的默认密码
如果不走这一步
搭建集群的配置文件中是不能配置密码的.因为ruby源码中没有配置redis连接密码,它连接不通每一个节点.

命令行执行`find / -name "client.rb"`

```bash
root@q:~# find / -name "client.rb"
/usr/lib/ruby/2.3.0/xmlrpc/client.rb
/var/lib/gems/2.3.0/gems/redis-3.3.3/lib/redis/client.rb
```

显然第二个是目标 vi修改文件内容


![这里写图片描述](/images/redis/update redis ruby.png)

把password那行修改为你设置的密码 注意带双引号
继续

需要一个脚本 这个脚本在redis源码的src目录下
启动命令
`redis-trib.rb create --replicas 1 127.0.0.1:6381 127.0.0.1:6382 127.0.0.1:6383 127.0.0.1:6384 127.0.0.1:6385 127.0.0.1:6386` replicas  后面的1 代表每个主一个从 后面跟上6个实例的真实ip和端口号   ip要填写成客户端访问的ip(如果绑定多个ip的话)`
![网上找的图](/images/redis/20170723200334146.png)

继续输入yes

![这里写图片描述](/images/redis/20170723200444015.png)

至此redis 集群就已经安装完毕了