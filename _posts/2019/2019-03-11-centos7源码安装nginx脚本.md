---
title: centos7源码安装nginx脚本
key: nginx
tags: [web服务器,shell,nginx]
---


**ROOT用户安装（nginx 443端口需要root权限）**


```bash

yum update

mkdir /root/soft && cd /root/soft

yum install -y wget nc curl telnet

wget http://nginx.org/download/nginx-1.17.7.tar.gz

tar -zxvf nginx-1.17.7.tar.gz

cd nginx-1.17.7

yum install -y gcc gcc-c++ automake pcre pcre-devel zlip zlib-devel openssl openssl-devel

./configure --with-threads --with-file-aio --with-http_ssl_module --with-http_v2_module --with-stream --with-http_sub_module

make 

make install 

ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx

```