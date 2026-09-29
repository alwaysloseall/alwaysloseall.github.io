---
title: 从沉睡到双端发布：博客升级与 GitHub Actions 记录
date: 2026-09-29 16:00:00
tags: [Hexo, GitHub Actions, 博客, NexT]
categories: 博客运维
---

这篇算运维笔记。博客从 2018 年 11 月 20 日左右就停在那儿，主题还是当年的 NexT 5。源码和线上各 13 篇，一对一还能对上，内容倒是没丢，只是构建链老得有点不好意思打开。这次想把它挂到自己的域名上，顺手把 Hexo 和主题升到现在能生成的版本。下面记实际做了什么，省得过两年又得从头翻 Actions 日志。

## 为什么折腾

线上一直是 [https://alwaysloseall.github.io/](https://alwaysloseall.github.io/)，仓库是 [alwaysloseall/alwaysloseall.github.io](https://github.com/alwaysloseall/alwaysloseall.github.io)。

另外想要 [https://blog.nekodayo.com/](https://blog.nekodayo.com/)。`nekodayo.com` 上本来就有 Caddy，站点根目录是 `/var/www/blog`，配置在 `/etc/caddy/www/blog.conf`。机器只负责把静态文件吐出去，上面不跑 Hexo。生成还是在构建环境里做，做完把 `public/` 放过去就行。

所以这次其实是两件事：把沉睡的构建链拉起来，以及同一份生成结果同时出现在 GitHub Pages 和这台机器上。

## 仓库里的两条分支

没有 `main`。约定一直是这样：

- `hexo`：Hexo 源码。`_config.yml`、`source/_posts`、主题相关配置都在这条分支。
- `master`：生成出来的静态站，给 GitHub Pages 用。

文章原文只放在 `hexo`。`master` 上是 HTML。后面的自动发布会用 force orphan 推 `master`，每次只留下最新站点那一个提交，别在那条分支上改文章。

固定链接还是 `:year/:month/:day/:title/`。旧文路径没动。

## 依赖和主题

升级合进 `hexo` 的是 [PR #3](https://github.com/alwaysloseall/alwaysloseall.github.io/pull/3)，squash 成 `c428614`。

做了这些：

- `.nvmrc` 指到 Node 26。
- Hexo 升到 8.x，锁的是 8.1.2。Hexo 8 要求 Node `>= 20.19.0`。
- 主题不再用当年 `themes/next` 里的 NexT 5，改成 npm 上的 `hexo-theme-next` 8.x（8.29.0）。站点自己的覆盖写在根目录 `_config.next.yml`，不去改 `node_modules`。
- 站点 `url` 换成真实地址 `https://alwaysloseall.github.io`，部署分支仍是 `master`，`language` 改成 `zh-CN`。NexT 8 的语言文件叫这个名字，继续写以前的 `zh-Hans`，菜单会落到错误语言。

本地 `hexo generate` 过了之后，把静态结果部署到 `master`。线上变成 NexT 8 的 Pisces，浅色，页脚年份还是从 2017 算起。外观和 2018 年那版不是同一套页面结构，链接还在。

两件小事先搁着：

- 《react-native学习笔记（一）》里有一张 `react-native_1.PNG`，地址 404。图文件不在仓库里，这篇没去改那篇文章。
- 重新生成时，要是拿文件修改时间当文章的 updated，「更新于」会看起来像刚改过。`_config.yml` 里把 `updated_option` 设成了 `empty`，避免一克隆，日期集体变成今天。

## 为什么两边一起发

自定义域名是多一个入口。GitHub Pages 那个地址用了很多年，旧链接还指着它。所以选了一次构建、两个目的地：GitHub Pages 的 `master`，以及 `blog.nekodayo.com` 对应的 `/var/www/blog`。两边吃同一份 `public/`，固定链接不用拆成两套。

## Workflow 的三步

自动发布是 [PR #4](https://github.com/alwaysloseall/alwaysloseall.github.io/pull/4)，squash 成 `a8ff25f`。文件是 `.github/workflows/deploy.yml`，名字叫 Deploy。

触发条件：push 到 `hexo`，或者在 Actions 里手动 Run workflow。

先 `build`，后面两个发布都等它成功，彼此之间不互相等待。一边失败，另一边还可以继续。

1. **build**：按 `.nvmrc` 装 Node，`npm ci`，然后 `npx hexo clean && npx hexo generate`。生成完会检查 `public/` 里有没有按年月日分目录的文章页。没有就失败，免得一份空站盖掉 `master` 和服务器。产物打成 artifact，留 14 天。
2. **deploy-pages**：用 `peaceiris/actions-gh-pages` 和 Actions 自带的 `GITHUB_TOKEN`，把 `public/` force orphan 推到本仓库 `master`。同时放上 `.nojekyll`，GitHub Pages 不会再用 Jekyll 处理这些文件。
3. **deploy-nekodayo**：SSH 上去，用 `rsync --delete` 把 `public/` 同步到 `/var/www/blog`。没另外指定的话，默认是 `root@nekodayo.com`。`--delete` 会让这个目录和本次生成结果对齐，目录里多出来的文件会被删掉。`hexo` 上的原文不在同步范围内。

本机的 `npx hexo deploy` 仍然只更新 `master`，不会 rsync 到服务器。日常发文走这条 workflow。

## Secrets

服务器那一步的密钥在仓库 **Settings → Secrets and variables → Actions**。私钥只放这里，不进 git，也不写进文章。

| Secret | 作用 |
| --- | --- |
| `NEKODAYO_SSH_KEY` | 服务器部署必填。一把只给这次部署用的 ed25519 私钥，公钥在服务器对应用户的 `authorized_keys` 里。注释类似 `github-actions-blog-nekodayo`。 |
| `NEKODAYO_KNOWN_HOSTS` | 建议配置，用来固定主机密钥。不配的话，任务可能会当场 `ssh-keyscan` 一次，等于首次信任当次返回的密钥。 |
| `NEKODAYO_HOST` | 可选，默认 `nekodayo.com`。 |
| `NEKODAYO_USER` | 可选，默认 `root`。 |

`GITHUB_TOKEN` 由 Actions 注入，不用自己再建一个 secret。

这把部署钥匙和日常登录用的钥匙分开。没配 `NEKODAYO_SSH_KEY` 时，只有 `deploy-nekodayo` 会失败，`deploy-pages` 仍然可以先把 GitHub Pages 发出去。

## 第一次跑通

密钥就位、workflow 合进 `hexo` 之后，第一次成功的运行是：

[actions/runs/36540405843](https://github.com/alwaysloseall/alwaysloseall.github.io/actions/runs/36540405843)

`build`、`deploy-pages`、`deploy-nekodayo` 都是绿的。两个地址都能打开现在这份博客：

- [https://alwaysloseall.github.io/](https://alwaysloseall.github.io/)
- [https://blog.nekodayo.com/](https://blog.nekodayo.com/)

## 以后怎么发

在 `hexo` 上改文章或新加一篇，直接 push，或者开 PR 再合并进 `hexo`。Actions 会构建一次，两个站一起更新。

想手动跑：Actions → Deploy → Run workflow。

旧文别改链接。这篇也走同一条 `:year/:month/:day/:title/`。
