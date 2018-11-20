---
layout: nodejs
title: 'nodejs addon Hello,World'
date: 2017-09-15 11:06:04
tags: [Nodejs, C++]
categories: NodeJs
---

nodejs自身v8的addon可以通过c++实现高效的拓展功能

下面将通过js调用addon输出Hello,World

* node -v: 8.4.0
* npm -v: 5.3.0
较低版本的node好像会有问题，之前用7.*好像不行(逃

首先安装node-gyp,在工程根目录创建binding.gyp

npm install node-gyp -g
```bash
binding.gyp
{
  "targets": [
    {
      "target_name": "hello",
      "sources": ["native\hello.cc"]
    }
  ]
}
```
创建native目录并在其中创建.cc文件：

```cpp
hello.cc
#include <node.h>
#include <v8.h>
void Method(const v8::FunctionCallbackInfo<v8::Value>& args) 
{
	v8::Isolate* isolate = args.GetIsolate();
	v8::HandleScope scope(isolate);
	args.GetReturnValue().Set(
		v8::String::NewFromUtf8(isolate, "Hello,World"));
}
void init(v8::Local<v8::Object> exports) {
	NODE_SET_METHOD(exports, "hello", Method);
}
NODE_MODULE(hello, init); //arg0与target_name一致
```
在工程根目录下 node-gyp configure 后会生相应的vs工程在build中，然后在vs中Release

在生成后，写js去调用：
```javascript
var hello = require('./build/Release/hello.node').hello();
console.log(hello);
```
输出结果:
![图片](https://alwaysloseall.github.io/image/2017/09/node-addon-01.png)
