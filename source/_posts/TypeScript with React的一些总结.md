---
layout: typescript
title: TypeScript with React的一些总结
date: 2018-11-20 14:16:05
tags: [TypeScript, 前端, React]
---

久了没更新blog，算下来也有一年多了，这一年作为一个重度依赖React前端工作者，想对自己工作有所总结。所以呢，这一篇文章就用于总结一些 TypeScript with React 的经验吧。

### 项目架构
自从 UmiJS 发布以来，我在公司及个人项目中得到很好的应用。所以这里分享的也是基于此框架建立的解决方案。
基本的目录结构：
```
umi version: 1.x
+ dist                // 生产环境构建产物
+ mock                // mock 文件所在目录，基于 express
+ node_modules        // 依赖库
+ src                 
  + assets              // 资源目录
  + components          // 组件
  + layouts             // 布局组件
    -index.tsx           // 全局布局
  + models              // dva models
  + pages               // router page
  + services            // 通信services
  + utils               // 工具函数
  - global.ts             // 可以在这里加入 polyfill
  - global.less           // 约定的全局样式文件，自动引入
- .umirc.js
- .webpackrc.js
- package.json
- tsconfig.json
- typings.d.ts
```

### 文件分析

#### tsconfig.json
> ts的配置文件

```json
{
    "compilerOptions": {
      "target": "es6",
      "module": "es6",
      "moduleResolution": "node",
      "jsx": "react",
      "baseUrl": ".",
      "paths": {
        "src": ["src"],
        "services/*": ["src/services/*"],        
        "components/*": ["src/components/*"],
        "assets/*": ["src/assets/*"],
        "utils/*": ["src/utils/*"]
      },
      "allowSyntheticDefaultImports": true,
      "experimentalDecorators": true
    }
  }

```

#### typings.d.ts
```typescript
declare module "*.css";

declare module "*.less";

declare module "*.png";

declare module "*.gif";

declare module "BMap"; // BMap

declare module "BMapLib"; // BMapLib

interface Window { // umi允许通过window.g_app 访问store
    g_app: {
        _store: {
            dispatch: Function,
            getState: Function
        }
    }
}

interface Array<T> { // 使用中发现这个函数会报错？？？
    includes: (item: T) => boolean
}

```

#### 编写一个标准的React Component
```
+ MyComponent
  + __snapshots__ // 测试快照
    - index.react.test.tsx.snap // 快照文件
  - index.tsx
  - index.less // 组件样式，采用的css module
  - index.react.test.tsx // jest test
  - PropsType.ts
```
PropsType.ts
```typescript
interface PropsType {
    style?: React.CSSProperties, // 父容器style
    headstyle?: React.CSSProperties, // 头部样式
    titleTextstyle?: React.CSSProperties, // 标题文字样式
    iconImg?: string, // 图标图片
    color?: string,
    title?: string,
    children?: React.ReactNode,
    right?: React.ReactNode, // 右侧内容
}

export default PropsType;
```

index.tsx

```tsx
import React from 'react';
import styles from "./index.less";

import PropsType from "./PropsType";

export default ({ style, headstyle, titleTextstyle, iconImg, color, title, children, right }: PropsType) => {
    return (
        <div className={styles.container} style={style}>
            <div className={styles.head} style={headstyle}>
                {
                    title ?
                        <div className={styles.title}>
                            {
                                iconImg ?
                                    <img
                                        className={styles.iconImg}
                                        src={iconImg}
                                    />
                                    :
                                    <span className={styles.icon} style={{ backgroundColor: color || "#2f81f8" }}>
                                    </span>
                            }
                            <span className={styles.titleText} style={titleTextstyle}>{title}</span>
                        </div>
                        :
                        <div></div>
                }
                <div className={styles.right}>
                    {right}
                </div>
            </div>
            <div className={styles.content}>
                {children}
            </div>
        </div>
    );
}
```

index.react.test.tsx

```tsx
import React from "react";
import CustomIconList from "./index";
import renderer from "react-test-renderer";

test("CustomIconList render", () => {
    const component = renderer.create(
        <CustomIconList
            style={{ height: 200 }}
            headstyle={{ backgroundColor: "#0f0" }}
            iconImg="icon-test"
            color="#f00"
            title="test title"
            titleTextstyle={{ fontSize: 12 }}
            right={<span>test right</span>}
        >
            <span>test children</span>
        </CustomIconList>
    ).toJSON();
    expect(component).toMatchSnapshot();
});
```

#### 页面基类的定义
```tsx
import React, { Component } from "react";
import router from 'umi/router';
import qs from "qs";
import moment from 'moment';

import { RouteComponentProps } from 'react-router';
import { FormComponentProps } from 'antd/lib/form';
import { DispatchProp } from 'react-redux';

interface PageComponentInterface<P = {}, S = {}, SS = any> extends Component<P, S, SS> {
    
}

interface PropsType extends RouteComponentProps<any>, FormComponentProps, DispatchProp<any>{
    
}

export default class PageComponent<P extends PropsType, S> extends Component<P, S> implements PageComponentInterface<P, S> {

    public searchParams = qs.parse(this.props.location.search, { ignoreQueryPrefix: true });

    goBackHandle = () => {
        router.goBack();
    };

    searchResetHandle = () => {
		this.props.form.resetFields();
		router.push(`?`);
    };
    
	searchBtnHandle = (e: React.MouseEvent) => {
        e.preventDefault();
		this.props.form.validateFields((error, values: Object) => {
			if (!error) {
                Object.keys(values).forEach(key => {
                    if (moment.isMoment(values[key])) {
                        values[key] = (values[key] as moment.Moment).valueOf();
                    }
                });
				router.push(`?${qs.stringify({
					...values,
                })}`);
			}
		});
    };
    
	handlePaginationChange = (page, pageSize) => {
		const oldParams = qs.parse(this.props.location.search, { ignoreQueryPrefix: true });
		const newParams = { ...oldParams, pageIndex: page, pageSize: pageSize };
		if (oldParams.pageSize && oldParams.pageSize != pageSize) {
			newParams.pageIndex = 1;
		}
		router.push(`?${qs.stringify(newParams)}`);
    };
}
```

使用方法：
```tsx
import {connect} from 'dva';
import React from "react";

@connect(({ tradePlan, loading }) => ({
    list: tradePlan.list,
    pagination: tradePlan.pagination,
    loading: loading.effects['tradePlan/queryList']
}))
class Index extends PageComponent<PropsType, StateType> {

}
```
实例上就会挂载基类上的方法

#### 工具类的应用

validator.ts

```typescript
interface NumberRegClass {
    
}

interface NumberRegConstructorOptions {
    positive: boolean //正数
}

export class NumberReg extends RegExp implements NumberRegClass {

    /**
     * @param  {number} int 整数位
     * @param  {number} decimals 小数位
     * @param  {NumberRegConstructorOptions} options? 参数
     */
    constructor(int: number, decimals: number, options?: NumberRegConstructorOptions) {
        const { positive = false } = options || {};
        super(`^(${positive ? '' : '\\-?'})([1-9]\\d{0,${int - 1}}|0)${decimals ? `(\\.\\d{0,${decimals - 1}}[1-9])` : ''}?$`);
    }

    /**
     * 验证bit位的整数
     * @param  {number} bit 整数位数
     * @returns RegExp
     */
    static int(bit: number): RegExp { //整数
        return new RegExp(`^(\\-?[1-9]\\d{0,${bit - 1}}|0)$`);
    }
}
```

validator.test.ts

```typescript
import { NumberReg } from './validator';

/// <reference types="jest" />

test('NumberReg test', () => { // 数字正则
    const number5and4 = new NumberReg(5, 4);
    expect(number5and4.test('12345.1234')).toBe(true);
    expect(number5and4.test('-12345.1234')).toBe(true);
    expect(number5and4.test('0.1234')).toBe(true);
    expect(number5and4.test('-0.1234')).toBe(true);
    expect(number5and4.test('12345.12345')).toBe(false);
    expect(number5and4.test('12345.120')).toBe(false);
    expect(number5and4.test('123456.12')).toBe(false);
    expect(number5and4.test('-123456.12')).toBe(false);
});
```

### 总结
以上，是部分运用在TypeScript with React的小结而已，感觉通篇的代码也贴得太多了。（然而还有很多不知道怎么描述。
总之，就是让可复用的组件能够独立的进行编写，测试。
为所有的工具类函数提供unit test，才能更完善的服务于业务。