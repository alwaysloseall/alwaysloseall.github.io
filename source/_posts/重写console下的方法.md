---
title: 重写console下的方法
date: 2017-06-29 09:27:32
tags: [JavaScript, webApi, 前端]
categories: web前端
---

#### 实现方式
还是最近在做的移动端调试工具，需要重写window.console对象，通过重写可以将之后代码中的控制台输出映射到自己的输出面板中。
上代码，重写的逻辑是很简单的。
```javascript
var tempFunction, color,
    output = document.querySelector('#output');

for (var key in console) {
    if (key.match(/log|debug|error|info|warn|dir/)) {
        tempFunction = console[key];
        switch (key) {
            case 'log':
                color = '#1F2D3D';
                break;
            case 'debug':
                color = '#1D8CE0';
                break;
            case 'error':
                color = '#FF4949';
                break;
            case 'info':
                color = 'blue';
                break;
            case 'warn':
                color = '#F7BA2A';
                break;
            case 'dir':
                color = '#58B7FF';
                break;
            default:
                color = '#1F2D3D';
                break;
        }
        (function (color) {
            console[key] = function () {
                var result = '';
                for (var i = 0; i < arguments.length; i ++) {
                    if ('object' == typeof arguments[i]) {
                        //TODO
                        //递归遍历对象控制输出，这里不做演示，在我的ajax-watcher库里是用的jquery插件
                    } else {
                        result += arguments[i];
                    }
                }
                var element = document.createElement("p");
                element.style.color = color;
                element.innerText = result;
                output.appendChild(element);
                tempFunction.apply(console, arguments);
            }.bind(window);
        })(color);
    }
}
```
#### 详情解释
1. ```for (var key in console)``` 遍历console对象，因为console对象下并不是所有方法都需要重写，所以这里用```key.match(/log|debug|error|info|warn|dir/)```筛选出需要重写的方法
2. ```tempFunction = console[key];``` 用临时遍历保存console下的方法，并根据key更换最后需要显示的颜色
3. 闭包保留color，直接```console[key] = function () {};```重写console下的方法
4. 重写方法的内部实现根据需求来写