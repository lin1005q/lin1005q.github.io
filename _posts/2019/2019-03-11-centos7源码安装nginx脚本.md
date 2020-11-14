---
title: centos7源码安装nginx脚本
key: nginx
tags: [web服务器,shell,nginx]
---


## 更新系统

```bash
yum update -y
```

## 安装nginx到非root用户目录下

```bash
yum update

yum install -y wget nc curl telnet gcc gcc-c++ automake pcre pcre-devel zlip zlib-devel openssl openssl-devel

useradd test

su - test

wget http://nginx.org/download/nginx-1.19.4.tar.gz

tar -zxvf nginx-1.19.4.tar.gz

mkdir nginx_home

cd nginx-1.19.4

./configure --with-http_dav_module --with-threads --with-file-aio --with-http_ssl_module --with-http_v2_module --with-stream --with-http_sub_module --with-http_auth_request_module --with-http_stub_status_module --with-http_realip_module --prefix=/home/test/nginx_home

make
make install
```

## 添加nginx环境变量方便操作

```bash
# 追加环境变量配置  
echo 'export PATH=$PATH:/home/test/nginx_home/sbin' >> ~/.bashrc
source ~/.bashrc
```

## 启动nginx

```bash
# 启动nginx
nginx
# 修改配置文件后，重启nginx
nginx -s reload
# 测试配置文件格式是否正确
nginx -t
# 停止nginx
nginx -s stop

```



## 添加自启脚本

```bash
# User和Group必须指定  否则开机自启后，root用户可以启停，而普通用户无权限启停

cat <<EOF > /usr/lib/systemd/system/nginx.service
[Unit]
Description=nginx
After=network.target

[Service]
User=test
Group=test
Type=forking
ExecStart=/home/test/nginx_home/sbin/nginx
ExecReload=/home/test/nginx_home/sbin/nginx -s reload
ExecStop=/home/test/nginx_home/sbin/nginx -s quit
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl enable nginx.service
systemctl status nginx.service

```

## 允许test用户监听1024以下端口

```bash
setcap cap_net_bind_service=+eip /home/test/nginx_home/sbin/nginx
```

## 添加健康检查模块

*nginx开源版本并不支持健康检查并移除不健康的节点，这里通过开源的patch来处理*

```bash

# user root
yum install patch -y
# user test
su - test
# 同时支持 stream 和 http 的upstream健康检查
git clone https://github.com/zhouchangxun/ngx_healthcheck_module.git
# 仅支持http的健康检查
git clone https://github.com/yaoweibin/nginx_upstream_check_module.git

cd nginx-1.19.4

patch -p1 < /home/test/ngx_healthcheck_module/nginx_healthcheck_for_nginx_1.16+.patch

./configure --with-http_dav_module --with-threads --with-file-aio --with-http_ssl_module --with-http_v2_module --with-stream --with-http_sub_module --with-http_auth_request_module --with-http_stub_status_module --with-http_realip_module --prefix=/home/test/nginx_home --add-module=/home/test/ngx_healthcheck_module

make
make install

```

## root快速部署

```bash

yum update

mkdir /root/soft && cd /root/soft

yum install -y wget nc curl telnet

wget http://nginx.org/download/nginx-1.19.4.tar.gz

tar -zxvf nginx-1.19.4.tar.gz

cd nginx-1.19.4

yum install -y gcc gcc-c++ automake pcre pcre-devel zlip zlib-devel openssl openssl-devel

./configure --with-threads --with-file-aio --with-http_ssl_module --with-http_v2_module --with-stream --with-http_sub_module

make 

make install 

ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx

```

> [CentOS7设置nginx开机自启动](https://www.jianshu.com/p/ca5ee5f7075c)

> [分享几个让 Linux 非 Root 用户运行的程序使用特权端口的技巧](https://www.hi-linux.com/posts/26613.html)

> [nginx:download](http://nginx.org/en/download.html)

> [https://github.com/yaoweibin/nginx_upstream_check_module](https://github.com/yaoweibin/nginx_upstream_check_module)

> [https://github.com/zhouchangxun/ngx_healthcheck_module](https://github.com/zhouchangxun/ngx_healthcheck_module)

> [Linux上搭建nginx+nginx_upstream_check_module模块实现后端节点健康检查](https://blog.csdn.net/Tam_KIng/article/details/106002173)

> [Nginx+upstream针对后端服务器容错的配置说明](https://www.cnblogs.com/kevingrace/p/8185218.html)