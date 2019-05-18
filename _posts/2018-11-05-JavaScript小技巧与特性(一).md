---
title: 
key: jsxiaojiqiao
tags: [前端]
---

JavaScript是一种函数优先的轻量级解释型或即使编译型的编程语言。应用范围近年变得很广泛。在webapp、web页面、node.js等均有JavaScript的身影。本次文档只关注JavaScript本身在开发中遇到的问题以及各版本特性比较，不局限于网页或某一寄宿环境。

### 保留小数问题(开发中遇到过)
```js
toFixed()
    例子：3.1415926.toFixed(2);//输出3.14 //向上舍入
Math.floor()
    使用：Math.floor(3.1415926 * 100) / 100;//输出结果为3.14 //向下舍入
Math.ceil()
    使用：Math.ceil(3.1415926 * 100) / 100;//输出结果为3.14 //向上舍入
```

### 箭头函数=>()(ES6也行，简化代码)

=>函数是ES6中新增的特性，一种匿名函数写法，可以大大简化代码量，同时也修复了匿名函数上下文获取不正确的问题，但也要合理运用不然会降低可读性。
箭头函数写法 `Fn => 1+Fn`;
示例：
正常函数：
```js
Function(arg){
    1+arg;
}
```
箭头函数：
`arg => 1+arg`
使用规则：只有一个参数可以用上边的写法，多个参数的话用括号括起来`(a,b) => a+b;`复杂方法体需要用大括号括起来`(a,b) => { return a + b;};`返回一个对象用括号把键值对括起来`()=>({a:1})`或者`()=>{return {a:1}}`;

**修复this作用域**
一般我们在使用匿名函数的时候如果需要修改或使用上层的变量时，使用this是不能成功获取的，此时的this指向的是匿名函数，所以无法获取上层的变量。
```js
  var obj = {
    a:100,
    b:function(){
        //var self = this; 解决办法 缓存this到变量
        window.setTimeout(function(){//匿名函数
          console.info(this.a);//输出undefind，此时this指向当前匿名函数
          //console.info(self.a);此时使用可以获取正确的a
        },100);
    }
}
```
当遇到这种情况的时候使用箭头函数可以很好的解决这个问题。


```js
var obj = {
	a:100,
	b:function(){
		window.setTimeout(()=>console.info(this.a),100);//此时可以正确输出a的值10，this指向obj对象
	}
}
```

使用箭头函数可以大量的减少代码量，并且使代码结构更清晰，而且对this作用域的修正可以省去很多不必要的中间变量，节省空间提升运行效率，但在嵌套使用时，还是应该使用花括号括起来，不要用极简的格式，不然会降低可读性。

### !!() 强制转换为布尔值(小技巧，简化代码，不知道具体数据那个版本的规范，目测都支持)
因为JS是弱语言类型，对于变量类型的定义并没有Java中那么严格，所以在实际使用过程中会造成一定的影响。在使用过程中需要使用明确的布尔值类型时，可以使用这个方法。
写法：!!(a) //返回一个布尔值;

使用示例：
```js
    var a = null;
    console.info(!!(a))//输出 false
```
理解过程：
```js
 var a = null; //转换为boolean 为 false 
 !a = true;//取反为 true
 !!a = false;//再取反为 false
 !!(a) = false;//输出false
```

使用场景：
当对于一个给定的参数或变量，已知不能为`null/undeined/0/''`等参数时，可以使用`!!()`函数强制转换成布尔值，方便后面使用。具体示例在JQuery源码中可以查看:

```js
grep: function( elems, callback, inv ) {  
    var ret = [], retVal;  
    inv = !!(inv);  //给出第三个参数，并且不为null/undeined/0/''**
    // Go through the array, only saving the items  
    // that pass the validator function  
    for ( var i = 0, length = elems.length; i < length; i++ ) {  
        retVal = !!(callback( elems[ i ], i ));  //此处同理 返回值存在并且不为**null/undeined/0/''
        if ( inv !== retVal ) { 
            ret.push( elems[ i ] );  
        }  
    }  
    return ret;  
}  
```
`!!()函数`的使用方法其实和使用`if()`判断或者`!(!a)`是等效的，但是在一些场景下合理使用这个函数可以减少一些代码量。不过鉴于可读性问题，酌情使用。
### 函数默认值(ES6特性，小技巧，简化代码)
在开发过程中经常遇到函数的参数在没有传值或者传值不全时需要设置默认值的场景，一般的解决方案是判断参数是否为空，然后决定使用传入值还是默认值，在ES6中函数的参数支持使用默认值，可以减少很多在没传参时的默认值设置。
```js
function (a = 100){
    console.info(a);//当a没有传入时，输出默认值100，有值时输出传入值
}
```