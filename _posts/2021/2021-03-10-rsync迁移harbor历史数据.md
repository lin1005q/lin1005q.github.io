---
date: 2021-03-10 10:34:00 +0800
key: rsync迁移harbor历史数据
tags: [linux]
---



使用`docker-compose`部署`harbor`。因为容器内的文件权限与宿主机的权限不一致。所以不能直接用`rsync`进行迁移。


```bash
rsync -avP --delete /data/ root@ip:/data/
```

参数说明：
* -a 参数，相当于-rlptgoD
  * -r 是递归 
  * -l 是链接文件，意思是拷贝链接文件；
  * -p 表示保持文件原有权限；
  * -t 保持文件原有时间；
  * -g 保持文件原有用户组；
  * -o 保持文件原有属主；
  * -D 相当于块设备文件；
* -z 传输时压缩；
* -P 传输进度；
* -v 传输时的进度等信息；
