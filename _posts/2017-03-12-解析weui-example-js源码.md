---
title: 解析weui-example.js源码
date: 2017-03-12 16:27:48
tags: [前端]
---

[原文件地址](https://weui.io/example.js)

# 文件总览

* 将源码下载以后,进行合并

```javascript
/**
 * Created by jf on 2015/9/11.
 * Modified by bear on 2016/9/7.
 */
$(function () {
    var pageManager = {
    function fastClick(){
    function preload(){
    function androidInputBugFix(){
    function setJSAPI(){
    function setPageManager(){
    function init(){
    init();
});
```

* 可以看出`domcument.ready()`之后定义了一个变量和6个`function`,然后直接调用init()进行初始化操作
* 这里使用pageManager变量使用闭包防止污染全局变量
* 分析init()

```javascript
function init(){
    preload();//预加载
    fastClick();//快速点击
    androidInputBugFix();//安卓输入框bug解决
    setJSAPI();//设置jsapi
    setPageManager();//设置页面管理器 这里使用#做路由

    //js特性 动态设置属性值 将pageManager 赋值给全局变量
    window.pageManager = pageManager;
    //此处设置home ,以后使用home() 将url的描点修改为''
    //window.home 可以用作跨域通信使用
    //location.hash 是设置当前的hash 即#的值 使用#做路由
    window.home = function(){
        location.hash = '';
    };
}
```

接下来挨个分析pageManager变量以及init方法中调用的五个方法

# 分模块解析

## pageManager 变量定义

```javascript
var pageManager = {
    $container: $('#container'),
    _pageStack: [],
    _configs: [],
    _pageAppend: function(){},
    _defaultPage: null,
    _pageIndex: 1,
    setDefault: function (defaultPage) {
    setPageAppend: function (pageAppend) {
    init: function () {
    push: function (config) {
    go: function (to) {
    _go: function (config) {
    back: function () {
    _back: function (config) {
    _findInStack: function (url) {
    _find: function (key, value) {
    _bind: function (page) {
};
```

pageManager类似于java中的实体类,里面有一些设置其属性的方法.类似于java 的getter,setter此处只是定义,待到调用时再分析

## preload();//预加载

```javascript
function preload(){
    $(window).on("load", function(){
        var imgList = [
            "./images/layers/content.png",
            "./images/layers/navigation.png",
            "./images/layers/popout.png",
            "./images/layers/transparent.gif"
        ];
        for (var i = 0, len = imgList.length; i < len; ++i) {
            /*
            创建一个Image对象：var a=new Image();    
            定义Image对象的src: a.src=”xxx.gif”;    
            这样做就相当于给浏览器缓存了一张图片。
            */
            new Image().src = imgList[i];
        }
    });
}

```

使用`new Image().src`赋值,浏览器即会请求此图片,只不过不会在页面显示,类似缓存操作.当页面某一图片的src修改为已缓存列表中的某一项时,就可以立即显示图片,省去加载的时间.

## fastClick();//直译:更快速的点击  白话:让点击事件更快执行

```javascript
function fastClick(){
    //是否支持触屏事件
    var supportTouch = function(){
        try {
            document.createEvent("TouchEvent");
            return true;
        } catch (e) {
            return false;
        }
    }();
    var _old$On = $.fn.on;
    //重载$.fn.on     weui.io 使用zepto.js
    $.fn.on = function(){
        if(/click/.test(arguments[0]) && typeof arguments[1] == 'function' && supportTouch){ // 只扩展支持touch的当前元素的click事件
            var touchStartY, callback = arguments[1];
            _old$On.apply(this, ['touchstart', function(e){
                touchStartY = e.changedTouches[0].clientY;
            }]);
            _old$On.apply(this, ['touchend', function(e){
                if (Math.abs(e.changedTouches[0].clientY - touchStartY) > 10) return;

                e.preventDefault();
                callback.apply(this, [e]);
            }]);
        }else{
            _old$On.apply(this, arguments);
        }
        return this;
    };
}
```

细节不去多看,`fastClick()`函数的目的是[重载jquery on方法实现click事件在移动端的快速响应](http://www.cnblogs.com/willian/p/3527265.html)将click点击事件替换为触屏事件,降低交互延迟.

## androidInputBugFix();//安卓输入框bug解决

```javascript
function androidInputBugFix(){
    // .container 设置了 overflow 属性, 导致 Android 手机下输入框获取焦点时, 输入法挡住输入框的 bug
    // 相关 issue: https://github.com/weui/weui/issues/15
    // 解决方法:
    // 0. .container 去掉 overflow 属性, 但此 demo 下会引发别的问题
    // 1. 参考 http://stackoverflow.com/questions/23757345/android-does-not-correctly-scroll-on-input-focus-if-not-body-element
    //    Android 手机下, input 或 textarea 元素聚焦时, 主动滚一把
    if (/Android/gi.test(navigator.userAgent)) {
        window.addEventListener('resize', function () {
            if (document.activeElement.tagName == 'INPUT' || document.activeElement.tagName == 'TEXTAREA') {
                window.setTimeout(function () {
                    document.activeElement.scrollIntoViewIfNeeded();
                }, 0);
            }
        })
    }
}
```

原作者写的很清楚,不过表示做页面没考虑的这么细过,一直以功能优先,大厂很注重用户体验啊 

## setJSAPI();//设置jsapi

```javascript
function setJSAPI(){
    var option = {
        title: 'WeUI, 为微信 Web 服务量身设计',
        desc: 'WeUI, 为微信 Web 服务量身设计',
        link: "https://weui.io",
        imgUrl: 'https://mmbiz.qpic.cn/mmemoticon/ajNVdqHZLLA16apETUPXh9Q5GLpSic7lGuiaic0jqMt4UY8P4KHSBpEWgM7uMlbxxnVR7596b3NPjUfwg7cFbfCtA/0'
    };

    $.getJSON('https://weui.io/api/sign?url=' + encodeURIComponent(location.href.split('#')[0]), function (res) {
        wx.config({
            beta: true,
            debug: false,
            appId: res.appid,
            timestamp: res.timestamp,
            nonceStr: res.nonceStr,
            signature: res.signature,
            jsApiList: [
                'onMenuShareTimeline',
                'onMenuShareAppMessage',
                'onMenuShareQQ',
                'onMenuShareWeibo',
                'onMenuShareQZone',
                // 'setNavigationBarColor',
                'setBounceBackground'
            ]
        });
        wx.ready(function () {
            /*
                wx.invoke('setNavigationBarColor', {
                color: '#F8F8F8'
                });
                */
            wx.invoke('setBounceBackground', {
                'backgroundColor': '#F8F8F8',
                'footerBounceColor' : '#F8F8F8'
            });
            wx.onMenuShareTimeline(option);
            wx.onMenuShareQQ(option);
            wx.onMenuShareAppMessage({
                title: 'WeUI',
                desc: '为微信 Web 服务量身设计',
                link: location.href,
                imgUrl: 'https://mmbiz.qpic.cn/mmemoticon/ajNVdqHZLLA16apETUPXh9Q5GLpSic7lGuiaic0jqMt4UY8P4KHSBpEWgM7uMlbxxnVR7596b3NPjUfwg7cFbfCtA/0'
            });
        });
    });
}
```

通过getJson到后台进行动态的配置参数 这里的wx变量是在别的地方定义的

## setPageManager();//设置页面管理器 这里使用#做路由

关键的页面管理来了

先看图 是weui.io的页面dom图
![](/ws/images/解析weui-example.js源码.jpg "dom结构图")

```javascript
//为pageManager变量进行赋值
function setPageManager(){
    /* 
     *  网站使用zepto.js 类似jquery
     *  选择器获取所左右指定属性的script元素集合 
     */
    var pages = {}, tpls = $('script[type="text/html"]');
    //获取当前窗口的高
    var winH = $(window).height();
    //遍历tpls,将其包装后放入pages
    for (var i = 0, len = tpls.length; i < len; ++i) {
        var tpl = tpls[i], name = tpl.id.replace(/tpl_/, '');
        pages[name] = {
            name: name,
            url: '#' + name,
            template: '#' + tpl.id
        };
    }
    //设置pages属性的属性值
    pages.home.url = '#';
    //pages内的元素一次调用闭包方法
    for (var page in pages) {
        pageManager.push(pages[page]);
    }
    //调用三个方法,第一个传的参数是一个function 链式调用
    pageManager.setPageAppend(function($html){
        var $foot = $html.find('.page__ft');
        if($foot.length < 1) return;

        if($foot.position().top + $foot.height() < winH){
            $foot.addClass('j_bottom');
        }else{
            $foot.removeClass('j_bottom');
        }
    })
    .setDefault('home')
    .init();
}
```

//以下为方法解释说明 按调用的先后顺序

```javascript
push: function (config) {
    //原生的js 数组push方法,将元素塞入数组 
    //闭包对象内的this 指pageManager对象(一般情况,特殊情况如bind,call,apply除外)
    this._configs.push(config);
    //返回this,可以jquery风格的链式调用
    return this;
}
//设置属性值
setPageAppend: function (pageAppend) {
    this._pageAppend = pageAppend;
    return this;
}
//设置默认页
setDefault: function (defaultPage) {
    //在之前的_configs兑现之呢个找到home页赋值给_defaultPage
    this._defaultPage = this._find('name', defaultPage);
    return this;
}
//在所有pages数组中根据特定属性值进行查找 
_find: function (key, value) {
    var page = null;
    //_configs是之前push进去的  详见push方法
    for (var i = 0, len = this._configs.length; i < len; i++) {
        if (this._configs[i][key] === value) {
            page = this._configs[i];
            break;
        }
    }
    return page;
}
//init是初始化方法,同时也是理解#页面路由的最重要的方法
init: function () {
    //保存当前pageManager对象的快照给self对象.
    var self = this;
    //给window绑定事件 
    $(window).on('hashchange', function () {
        var state = history.state || {};
        var url = location.hash.indexOf('#') === 0 ? location.hash : '#';
        var page = self._find('url', url) || self._defaultPage;
        if (state._pageIndex <= self._pageIndex || self._findInStack(url)) {
            self._back(page);
        } else {
            self._go(page);
        }
    });
    //如果有即赋值
    if (history.state && history.state._pageIndex) {
        this._pageIndex = history.state._pageIndex;
    }

    this._pageIndex--;
    //获取#后面的url
    var url = location.hash.indexOf('#') === 0 ? location.hash : '#';
    //获取即将要跳转的页面,在之前push的数组中,如果没有找到就跳转到默认页即首页
    var page = self._find('url', url) || self._defaultPage;
    //跳转
    this._go(page);
    return this;
}
//页面跳转的具体方法
_go: function (config) {
    this._pageIndex ++;
    //设置h5 state属性值,可以前进后退
    history.replaceState && history.replaceState({_pageIndex: this._pageIndex}, '', location.href);
    //获取html内容 对应的script内的html内容
    var html = $(config.template).html();
    //为html添加css类
    var $html = $(html).addClass('slideIn').addClass(config.name);
    //绑定事件 如果动画完成 替换css
    $html.on('animationend webkitAnimationEnd', function(){
        $html.removeClass('slideIn').addClass('js_show');
    });
    //将html添加到待显示的dom中
    this.$container.append($html);
    //call指定this去执行
    this._pageAppend.call(this, $html);
    //放入堆栈中,点击后退按钮页面重刷新不需要再次去取指,直接从此取即可
    this._pageStack.push({
        config: config,
        dom: $html
    });
    //如果没有绑定事件 就进行绑定 
    if (!config.isBind) {
        this._bind(config);
    }
    /*
     * _go方法是页面跳转的方法,此方法走完页面的初始化工作已经完成 以后可以带#url直接打开对应的子页面 这一步只是对应的待显示的dom已经放到该放的位置,至今未找到css,进行显示隐藏切换的code(原理)
     */
    return this;
}
//页脚的考虑
_pageAppend:function($html){
    var $foot = $html.find('.page__ft');
    if($foot.length < 1) return;

    if($foot.position().top + $foot.height() < winH){
        $foot.addClass('j_bottom');
    }else{
        $foot.removeClass('j_bottom');
    }
}
//进行事件绑定
_bind: function (page) {
    // page对象中是否有events属性,若有将事件进行绑定,,没有直接赋值已绑定 此例中没有此属性,按直接赋值true
    var events = page.events || {};
    for (var t in events) {
        for (var type in events[t]) {
            this.$container.on(type, t, events[t][type]);
        }
    }
    page.isBind = true;
}
```

以上代码走完,一个流程就走完了,以后通过调用`window.pageManager.go(id);`直接跳转到对应的页面也可以注册事件处理

```javascript
$('.js_item').on('click', function(){
    var id = $(this).data('id');
    window.pageManager.go(id);
});
```

如果点击后退按钮,会触发history的state修改,使用添加的`onhashchange`事件处理去_back()原理同_go()类似,remove dom节点

# 总结

小小一个js文件,用到的点却很多
`闭包` `call` `hashchange` `history.state` `数组操作` `jq选择器` `$.on()` `this指向` `newImage()` `click与touch事件响应顺序` `apply` `js真假值判断`

1. 使用闭包避免污染全局.
2. 使用state可以前进后退.
3. 使用script标签存储html内容 避免页面加载过于长.
4. 手机端touch事件处理.
5. css切换至今没懂,知道用的是绝对定位,但当container里包含首页div和在显示div时,却没有重叠 也不是z-index 感觉像是透明度

f12 对比着看Elements 和source是打断点会更快的理解逻辑流程
![](/ws/images/解析weui-example.js源码.gif)