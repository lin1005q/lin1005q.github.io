---
title: 
date: 2018-02-22 10:19
tags: 其他
---

## 谷歌浏览器地址栏按TAB 自动切换到搜索框

### 一般的查询是这么操作的

1. 浏览器地址栏输入`baidu.com`
2. 页面响应完成之后,在搜索框输入待检索的字符,点击搜索按钮或`Enter`键
3. 百度返回响应

支持open search 之后可以这么操作

1. 在地址栏输入`baidu.com` 按 `Tab`键
2. 直接输入待检索的字符
3. 百度返回响应

为网站添加open search支持,可以支持站外搜索.

### 先看一下百度是怎么做的

在baidu.com页面f12查看`link`标签
```html
<link rel="search" type="application/opensearchdescription+xml" href="/content-search.xml" title="百度搜索">
```

继续看一下[`content-search.xml`](https://www.baidu.com/content-search.xml)
```xml
<?xml version="1.0" encoding="UTF-8"?> 
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
    <ShortName>百度搜索</ShortName>
    <Url type="text/html" template="https://www.baidu.com/s?wd={searchTerms}"/> 
</OpenSearchDescription>
```

### 自己玩一下

以`https://weihai4099.github.io`为例.它是一个纯静态网站,没有后台没有数据库,全部以前端模板构建完成.
想为它添加一个全站搜索,按照套路是不可能的,但是我们可以借助github的仓库内搜索.间接达到效果.

一共需要添加一个文件,修改一个文件

在`_includes/head.html`添加`link`标签
```html
<!--自定义 open search 搜索-->
<link rel="search" type="application/opensearchdescription+xml" href="/content-search.xml" title="custom搜索">
```

添加content-search.xml文件
```xml
<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
    <ShortName>weihai4099</ShortName>
    <Url type="text/html" template="https://github.com/weihai4099/weihai4099.github.io/search?utf8=%E2%9C%93&amp;q={searchTerms}&amp;type="/>
</OpenSearchDescription>

```

最后 `git commit` and `git push`就可以在浏览器地址栏输入`weihai4099.github.io`+Tab+待检索的字符.进行全站搜索.

后期可以在页面添加一个搜索框,js拼接字符串进行页面跳转,效果会更好

## 参考链接

1. [谷歌浏览器地址栏按TAB 自动切换到搜素框。 这个搜索框有什么必须条件才可以触发这个操作？](https://www.zhihu.com/question/38370457)
2. [OpenSearch Wikipedia](https://en.wikipedia.org/wiki/OpenSearch)


