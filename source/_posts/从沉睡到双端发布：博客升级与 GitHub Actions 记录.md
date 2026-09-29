---
title: 从沉睡到双端发布
date: 2026-09-29 16:00:00
tags: [Hexo, GitHub Actions, 博客, NexT]
categories: 博客运维
---

这个博客从 2018 年 11 月左右就停更了。主题还是当年的 NexT 5，文章倒没丢，停的时候大概十三篇，源码和线上也能对上。只是构建环境停在那年，我自己再打开都有点发怵。

今年想给它一个自己的域名：[blog.nekodayo.com](https://blog.nekodayo.com/)。[alwaysloseall.github.io](https://alwaysloseall.github.io/) 用了很多年，以前的链接还指着那儿，所以 GitHub Pages 留着。两个地址看的是同一份站点。

仓库里，文章和配置写在源码那条分支上；GitHub Pages 用的是生成出来的静态页面。自己的域名也只放静态文件，服务器上并不跑 Hexo。

架子换了一代：Hexo 到 8，主题到 NexT 8，Node 换成现在还能用来构建的版本。外观还是原来那套浅色版式。旧文章的地址没改，以前的链接应该还能打开。

发布是一次构建、两个出口。源码推上去之后，GitHub Actions 会生成一次站点，同时更新 GitHub Pages 和 blog.nekodayo.com。之后写新文章也一样：改源码，推上去，两个站一起变。

现在两边都能打开：

- [https://alwaysloseall.github.io/](https://alwaysloseall.github.io/)
- [https://blog.nekodayo.com/](https://blog.nekodayo.com/)
