---
date: 2020-01-21 23:11:00 +0800
key: nginx配置default_server
tags: [web服务器]
---



## 现象
1. 直接以ip访问。nginx默认会以第一个server进行响应。
2. 以一个未配置的域名访问，nginx也会以第一个server进行响应。

## 为什么
如果一个ip绑定了多个域名，或者将域名的二级域名泛解析到同一个ip，那么会遇到default_server的问题。

## 配置

### http

```conf
server {
    listen 1.2.3.4:80 default_server;
    listen [::]:80 default_server;
    server_name _;

    server_name_in_redirect off;
    log_not_found off;

    return 410;
}
```

### https

https比http处理相对比较麻烦一点，不能直接的重定向到http。必须首先建立成功的ssl连接，否则，一切都是白扯。

创建一个自签名的证书,执行如下脚本，过程中无须输入任何内容，一路默认执行。

```bash
openssl req -newkey rsa:2048 -nodes -keyout default_server-key.pem -x509 -days 3650 -out default_server.pem
```

```conf
server {
    listen 443 ssl http2 default_server;
    server_name _;

    ssl_certificate /usr/local/www/default_server/default_server.pem;
    ssl_certificate_key /usr/local/www/default_server/default_server-key.pem;

    server_name_in_redirect off;
    log_not_found off;
    return 410;
}

```

>[410 Gone](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Status/410?utm_source=mozilla&utm_medium=devtools-netmonitor&utm_campaign=default)