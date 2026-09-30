---
title: 救活沉睡博客，以及 Grok Bot 帮得上的地方
date: 2026-09-30 11:00:00
tags: [Hexo, GitHub Actions, 博客, NexT]
categories: 博客运维
---

这个博客从 2018 年 11 月左右就停更了。文章还在，主题还是当年的 NexT，我自己再打开仓库，都会犹豫要不要动。

今年想重新发布，也想有一个自己的域名。我打开 Grok Bot，让它陪我看这个站。它是我在 Cursor 里用的桌面助手。我说得很笼统：这是一个停了很久的 Hexo 博客，源码在 GitHub 上，我想让它重新能打开。

它先看仓库。文章和配置在源码分支 `hexo`，GitHub Pages 读的是生成好的静态页。分清之后，Hexo、Node 和 NexT 换到现在还能构建的版本。外观还是原来那套浅色，旧文章的地址没改。发布收成一次构建、两个出口：改动合进 `hexo` 之后，[alwaysloseall.github.io](https://alwaysloseall.github.io/) 和 [blog.nekodayo.com](https://blog.nekodayo.com/) 一起更新。GitHub Pages 留着，是因为以前的链接还指着那儿。

步骤不在这篇里。做法见 [Hexo 博客升级与 GitHub Actions 双端发布教程](</2026/09/29/Hexo 博客升级与 GitHub Actions 双端发布教程/>)，经过见 [从沉睡到双端发布](</2026/09/29/从沉睡到双端发布：博客升级与 GitHub Actions 记录/>)。

升级做完，我用同一次对话写了那两篇。短的只讲经过，教程才写步骤。对着助手往下说，第一稿常常像运维笔记。我让它按给人看的方式再收一收：站醒了，两个地址是同一份站点，旧链接还在。

现在两边都能打开：

- [https://alwaysloseall.github.io/](https://alwaysloseall.github.io/)
- [https://blog.nekodayo.com/](https://blog.nekodayo.com/)

## Grok Bot 这次帮得上的地方

就这个仓库而言，顺手的是这几件。都是我实际用到的。

**对话里把项目往前推。** 我想要的结果先说出来。仓库怎么分、该动哪一层，在来回里看清楚，再做下一步。

**云端 Pull Request。** 改动由它开 PR，合进 `hexo`。合并之后 GitHub Actions 构建，两个站一起变。我看 diff，觉得对了再合。

**公开文章的语气。** 同一段对话里可以再写一版，把运维笔记收成读者能读的经过。博客要写成什么样，还是我自己定。

**停在同一个仓库。** 结构、发布分支、上一篇的语气，下一句还能接上，不用每次把这个站重新介绍一遍。

一个停了八年的站，靠这些来回，又开始更新了。
