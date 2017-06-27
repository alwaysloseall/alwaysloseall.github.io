---
title: 造了个监听ajax请求的轮子
date: 2017-06-26 19:48:47
tags: [JavaScript, ajax, jQuery]
categories: web前端
---

突发奇想造了个轮子，用于在移动开发，尤其是在微信上开发时不便于调试的问题。其实大部分时候用微信开发者工具都是可以解决的，但是有时也有在实机上测试的需求。
> 现在已经放在GitHub上了，地址: [https://github.com/alwaysloseall/ajax-watcher](https://github.com/alwaysloseall/ajax-watcher)

#### 核心部分是监听ajax请求的API，现在只做了依赖jQuery的部分
```javascript
    $(document).ajaxSend(function (e, jqXHR, ajaxOptions) {
        if (openStatus) {
            DOM.mask.show();
            DOM.container.show();
        }
        if (container.find('div[url="'+ajaxOptions.url+'"]').length) {
            container.find('div[url="'+ajaxOptions.url+'"]').remove();
        }
        var content = $(
            '<div class="ajax-watcher-content" url='+ ajaxOptions.url +' style="display: inline-block; overflow: auto; color: #fff; max-width: 45%; border: 1px solid #fff; padding: 10px; position: relative; height: 40%; word-wrap: break-word; word-break: normal;">\
                <span style="color: #fff; position: absolute; top: 0; right: 5px;">关闭</span>\
                <p style="color: #fff;">url:</br>'+ajaxOptions.url+'</p>\
                <p style="color: #fff;">type:  '+ajaxOptions.type+'</p>\
                <p style="color: #fff;">params:</br>'+ajaxOptions.data.replace(/\&/g, '</br>')+'</p>\
                <p style="color: #fff;">status:  loadding...</p>\
            </div>'
        );
        DOM.container.append(content);
        content.children('span').on('click', function () {
            content.remove();
        });
    }).ajaxComplete(function (e, xhr, settings) {             
        var content = container.find('div[url="'+settings.url+'"]');
        content.find('p:eq(3)').html('status:  '+xhr.status+'');
        var json = $('<div style="color: #fff;"></div>');
        if (xhr.responseJSON) {
            json.JSONView(xhr.responseJSON);
            content.append('<p style="color: #fff;">response:  </p>');
            content.append(json);
        } else {
            content.append(
                '<p style="color: #fff;">responseText:  '+xhr.responseText+'</p>'
            );
        }
        if (xhr.responseJSON) {
            //ToDo
        }
    });
```
``` $(document).ajaxSend(callback).ajaxComplete(callback) ``` 用于监听通过jQuery发起的ajax请求

#### 以后要做的部分是用原生js去写这部分功能，通过重写XMLHttpRequest构造函数，在XHR实例的原型上重写open, send, onreadystatechange方法来实现