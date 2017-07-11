---
title: react-native 学习笔记（三）
date: 2017-07-11 10:30:05
tags: [JavaScript, 前端, React-Native]
categories: React-Native
---

## react-native android打包
之前用create-react-native-app创建的应用在打包方面不是很实用，要通过expo打包，所以之后我使用了官方推荐的react-native-cli来创建应用

### 搭建开发环境
这一点在文档上已经很清晰了
中文：[https://reactnative.cn/docs/0.46/getting-started.html](https://reactnative.cn/docs/0.46/getting-started.html)
原文：[https://facebook.github.io/react-native/docs/getting-started.html](https://facebook.github.io/react-native/docs/getting-started.html)
需要注意的是这里都没有说明在react-native run-android的时候需要启动虚拟机，需要自己在android里面手动启动

### 打包应用
我把之前做的B/S应用改成了R-N应用，首页上采用了R-N的模块，内页使用了WebView以重用之前的代码
#### 生成签名密钥
打包android应用需要生成一个签名密钥
>keytool -genkey -v -keystore my-release-key.keystore -alias my-key-alias -keyalg RSA -keysize 2048 -validity 10000
这条命令会要求你输入密钥库（keystore）和对应密钥的密码，然后设置一些发行相关的信息。最后它会生成一个叫做my-release-key.keystore的密钥库文件。

#### 设置gradle变量
把my-release-key.keystore文件放到你工程中的android/app文件夹下。
编辑C:\Users\用户名\.gradle\gradle.properties（没有这个文件你就创建一个），添加如下的代码（注意把其中的****替换为相应密码）

>MYAPP_RELEASE_STORE_FILE=my-release-key.keystore
MYAPP_RELEASE_KEY_ALIAS=my-key-alias
MYAPP_RELEASE_STORE_PASSWORD=*****
MYAPP_RELEASE_KEY_PASSWORD=*****

#### 添加签名到项目的gradle配置文件
编辑你项目目录下的android/app/build.gradle，添加如下的签名配置：
>...
android {
    ...
    defaultConfig { ... }
    signingConfigs {
        release {
            storeFile file(MYAPP_RELEASE_STORE_FILE)
            storePassword MYAPP_RELEASE_STORE_PASSWORD
            keyAlias MYAPP_RELEASE_KEY_ALIAS
            keyPassword MYAPP_RELEASE_KEY_PASSWORD
        }
    }
    buildTypes {
        release {
            ...
            signingConfig signingConfigs.release
        }
    }
}
...

#### 修改应用名称和图标
编辑项目目录下的：android\app\src\main\res\values\strings.xml

<string name="app_name">MyProject</string>
MyProject改成你需要的名字就好了。

图标在android\app\src\main\res文件夹下每个mipmap开头的文件夹下有一个不同尺寸的版本，可以自行输出，也可以使用Android Studio批量修改。

#### 生成发行APK包
运行如下命令：
>cd android && ./gradlew assembleRelease
生成的APK文件位于android/app/build/outputs/apk/app-release.apk，即可用于发布

#### 启用Proguard代码混淆来缩小APK文件的大小（可选）
Proguard是一个Java字节码混淆压缩工具，它可以移除掉React Native Java（和它的依赖库中）中没有被使用到的部分，最终有效的减少APK的大小。

重要：启用Proguard之后，你必须再次全面地测试你的应用。Proguard有时候需要为你引入的每个原生库做一些额外的配置。参见app/proguard-rules.pro文件。

要启用Proguard，设置minifyEnabled选项为true：
>def enableProguardInReleaseBuilds = true