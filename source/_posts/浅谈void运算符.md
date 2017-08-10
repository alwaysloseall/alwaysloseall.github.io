---
title: 浅谈void运算符
date: 2017-08-10 16:31:54
tags: [JavaScript, webApi, 前端]
categories: web前端
---

最近开了个新坑，其实并不是开坑(逃---兴趣使然，所以想看一下underscore.js的源码，所以俺跟着@hanzichi的解读文章一起了解咯
[解读文章地址](https://github.com/hanzichi/underscore-analysis)

### 关于void运算符，参考自MDN
先放[相关地址](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/void)
MDN对void运算符的解释如下：
>The void operator evaluates the given expression and then returns undefined.

就是说 void 运算符 对给定的表达式进行求值，然后返回 undefined。就是说void后面不管跟什么，最后都会返回一个undefined，比如 void 0, void(0), void(1+1) 等等。
在以前的使用中俺只在处理a标签默认事件，当然现在在MDN上查到了更多用法辣
#### 立即调用的函数表达式
在使用立即执行的函数表达式时，可以利用 void 运算符让 JavaScript 引擎把一个函数识别成函数表达式而不是函数声明（语句）。
```javascript
void function iife() {
    var bar = function () {};
    var baz = function () {};
    var foo = function () {
        bar();
        baz();
     };
    var biz = function () {};

    foo();
    biz();
}();
```
#### JavaScript URIs
当用户点击一个以 javascript: URI 时，浏览器会对冒号后面的代码进行求值，然后把求值的结果显示在页面上，这时页面基本上是一大片空白，这通常不是我们想要的。只有当这段代码的求值结果是 undefined 的时候，浏览器才不会去做这件傻事，所以我们经常会用 void 运算符来实现这个需求。像下面这样：
```html
<a href="javascript:void(0);">
  这个链接点击之后不会做任何事情，如果去掉 void()，
  点击之后整个页面会被替换成一个字符 0。
</a>
<p> chrome中即使<a href="javascript:0;">也没变化，firefox中会变成一个字符串0 </p>
<a href="javascript:void(document.body.style.backgroundColor='green');">
  点击这个链接会让页面背景变成绿色。
</a>
```

### 为什么用「void 0」代替「undefined」
在underscore的源码中，没有出现undefined，而用 void 0 代替之，之所以要这么处理是因为undefined在一些情况下可能会被重写，下面列出这几种情况
1. undefined 并不是保留词（reserved word），它只是全局对象的一个属性，在低版本 IE 中能被重写。
```javascript
var undefined = 10;

// undefined -- chrome
// 10 -- IE 8
alert(undefined);
```
2. undefined 在 ES5 中已经是全局对象的一个只读（read-only）属性了，它不能被重写。但是在局部作用域中，还是可以被重写的
```javascript
(function() {
  var undefined = 10;

  // 10 -- chrome
  alert(undefined);
})();

(function() {
  undefined = 10;

  // undefined -- chrome
  alert(undefined);
})();
```
在进行一些值判断的时候就可以用 void 0 了:
```javascript
var a = [];

// true
a === void 0;
```
所以综上所述，用「void 0」代替「undefined」是一个正确的选择，而且还可以节省代码空间，事实上，不少 JavaScript 压缩工具在压缩过程中，正是将 undefined 用 void 0 代替掉了。