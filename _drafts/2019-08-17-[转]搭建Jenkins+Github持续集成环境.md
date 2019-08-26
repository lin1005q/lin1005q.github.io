---
date: 2019-08-17 22:37:00
key: 搭建Jenkins+Github持续集成环境
tags: [git,转载]
---

# 安装jdk

```bash
[root@instance-lk55n60q ~]# rpm -qa|grep java 
python-javapackages-3.4.1-11.el7.noarch
tzdata-java-2019b-1.el7.noarch
[root@instance-lk55n60q ~]# yum remove python-javapackages-3.4.1-11.el7.noarch tzdata-java-2019b-1.el7.noarch
```

yum -y list java*

https://my.oschina.net/andyfeng/blog/601291


