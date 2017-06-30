---
title: react-native 初探
date: 2017-06-29 14:29:22
tags: [JavaScript, webApi, 前端, React-Native]
categories: React-Native
---
前端圈聊这个react-native也好长一段时间了，以前也写过一段时间react，不是react吹，所以一直没玩这个native，看来我还是naive啊。

### Getting Started
我现在用的ios手机，但是我没macOS啊，所以只有用Create React Native App这个工具了，官网是这么说的，反正就是可以直接跑在手机上啦，但是不能用第三方的组件。
>Create React Native App is the easiest way to start building a new React Native application. It allows you to start a project without installing or configuring any tools to build native code - no Xcode or Android Studio installation required (see Caveats).

#### 安装
首先安装Create React Native App
```
npm install -g create-react-native-app
```
这里要注意npm的版本问题，必需用npm@4.x的版本。
![notSupport](https://alwaysloseall.github.io/image/2017/06/notSupport.png)
如果遇到这种报错,就需要手动先安装react
![needReact](https://alwaysloseall.github.io/image/2017/06/needReact.png)
```
npm install -g react
```

#### 创建&启动
安装好之后就可以创建项目啦，创建后进入项目目录然后执行npm start
```
create-react-native-app FirstApp
cd FirstApp
npm start
```
一切就绪之后命令行中就会显示二维码，在appStore里面下载安装Expo扫码就可以预览项目了。
如下：
![guide](https://alwaysloseall.github.io/image/2017/06/guide.png)
点击Got it按钮
显示的页面就是项目目录下app.js的内容了，修改app.js并保存，页面会自动刷新。

(end)