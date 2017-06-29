---
title: 浏览器中监听全局的报错API
date: 2017-06-27 19:48:29
tags: [JavaScript, webApi, 前端]
categories: web前端
---

#### onerror事件
window对象下可以通过onerror事件监听全局的抛错信息。
最近在做一个移动端的调试工具库，所以了解了一下这个API，使用方法如下：
```javascript
window.onerror = function (message, source, lineno, colno, error) {
    //Todo
};
```
#### 参数介绍
这里只能给onerror赋值，不能通过window.addEventListener添加事件监听。
* ```message``` 错误信息
* ```source``` 错误来源(来源文件)
* ```lineno``` 报错行
* ```colno``` 报错列
* ```error``` error对象