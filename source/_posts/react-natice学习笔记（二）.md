---
title: react-natice 学习笔记（二）
date: 2017-07-01 16:42:53
tags: [JavaScript, 前端, React-Native]
categories: React-Native
---
一个应用通常是不会只有一个页面的，所以为了实现多页跳转，要用到导航组件
### StackNavigator的使用
做一个两页的demo吧，首先创建两个文件，MainScreen.js 和 ProfileScreen.js
在app.js中import
```javascript
import { StackNavigator, } from 'react-navigation';
import MainScreen from './MainScreen.js';
import ProfileScreen from './ProfileScreen.js';

export default App = StackNavigator({
  Main: {screen: MainScreen},
  Profile: {screen: ProfileScreen},
});
```
通过StackNavigator注册导航，感觉跟路由很像啊
然后分别在MainScreen.js 和 ProfileScreen.js 渲染视图
```javascript
// MainScreen.js:
import React from 'react';
import {
	StyleSheet,
	Text,
	View,
	Image,
	Button,
	Alert
} from 'react-native';

export default class MainScreen extends React.Component {
  static navigationOptions = {
		title: '首页',
  };
  render() {
    const { navigate } = this.props.navigation;
    return (
        <View style={styles.container}>
            <Image 
                source={ require('./images/laopo.jpg') }
                style={styles.laopo}
            />
            <Text>上面那个是我老婆</Text>
            <Button
                title="看更多..."
                color="#841584"
                onPress={() =>
                    navigate('Profile')
                }
            />
        </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
  laopo: {
     width: 450,
     height: 500,
     left: 40,
     top: -80
  }
});
```
可以通过navigate()跳转导航
```javascript
// ProfileScreen.js
import React from 'react';
import { StyleSheet, Text, View, ScrollView, Image, Button, NavigatorIOS} from 'react-native';

export default class ProfileScreen extends React.Component {
  static navigationOptions = {
    title: 'Aimer!!!',
  };
  render() {
    const { navigate } = this.props.navigation;
		let content = [];
		for (let i = 0; i < myImage.length; i ++) {
			content.push(<Image key={i} source={myImage[i]} style={ styles.image }/>);
		}
    return (
        <View style={styles.container}>
            {/*<Image source={myImage[0]} style={ styles.image }/>*/}
            { content }
            <Button style={ styles.navbar }
                title="回首页"
                onPress={() =>
                    navigate('Main')
                }
            />
        </View>
    );
  }
}

const myImage = [
	require('./images/aimer.jpg'),
	require('./images/aimer2.jpg'),
	require('./images/aimer_live1.jpg')
]

const styles = StyleSheet.create({
	container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
  navbar: {
      top: 500
  },
	image: {
		height: 200,
		margin: 10
	}
});
```
效果如图：
![图片](https://alwaysloseall.github.io/image/2017/06/react-native_2.PNG)
首页的图之前发过了，就不发了

(end)