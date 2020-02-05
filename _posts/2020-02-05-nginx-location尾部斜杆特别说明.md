---
date: 2020-01-29 23:30:00 +0800
key: nginx-location尾部斜杆特别说明
tags: [nginx]
---

当访问`a.com`时，想自动跳转到`a.com/test`。用nginx怎么实现。

```bash
location =/ {
  return 301 /test;
}

```

## URL尾部的/需不需要

关于URL尾部的/有三点也需要说明一下。第一点与location配置有关，其他两点无关。

* location中的字符有没有/都没有影响。也就是说/user/和/user是一样的。
* 如果URL结构是https://domain.com/的形式，尾部有没有/都不会造成重定向。因为浏览器在发起请求的时候，默认加上了/。虽然很多浏览器在地址栏里也不会显示/。这一点，可以访问baidu验证一下。
* 如果URL的结构是https://domain.com/some-dir/。尾部如果缺少/将导致重定向。因为根据约定，URL尾部的/表示目录，没有/表示文件。所以访问/some-dir/时，服务器会自动去该目录下找对应的默认文件。如果访问/some-dir的话，服务器会先去找some-dir文件，找不到的话会将some-dir当成目录，重定向到/some-dir/，去该目录下找默认文件。可以去测试一下你的网站是不是这样的。


