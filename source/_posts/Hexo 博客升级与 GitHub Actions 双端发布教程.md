---
title: Hexo 博客升级与 GitHub Actions 双端发布教程
date: 2026-09-29 17:00:00
tags: [Hexo, GitHub Actions, NexT, 教程]
categories: 博客运维
---

这篇按本仓库的做法，说明怎样把一个停在旧 Hexo 上的 GitHub Pages 博客升到当前能构建的版本，并用一次 GitHub Actions 构建同时发布到 GitHub Pages 和一台 VPS 的静态目录。

想先看这件事的经过，可以读 [从沉睡到双端发布](</2026/09/29/从沉睡到双端发布：博客升级与 GitHub Actions 记录/>)。做完之后，同一份站点在这两个地址上：

- [https://alwaysloseall.github.io/](https://alwaysloseall.github.io/)
- [https://blog.nekodayo.com/](https://blog.nekodayo.com/)

下面的分支名、目录和 secret 名都是本仓库的。你的 Pages 分支如果叫 `gh-pages`，把文中的 `master` 换成你的发布分支，两处保持一致即可。

## 开始之前

先确认这几样东西已经在：

1. **源码分支和发布分支是分开的。** 文章、`_config.yml`、主题配置写在源码分支。本仓库源码分支叫 `hexo`。GitHub Pages 读的是另一条只放静态文件的分支，本仓库是 `master`（有的仓库用 `gh-pages`）。不要把 `hexo` 设成 Pages 的发布分支，否则 Pages 会去渲染 Markdown 源码。
2. **本机能装上当前的 Node。** Hexo 8 要求 Node `>= 20.19.0`。本仓库把版本写在 `.nvmrc`，目前是 `26.10.0`。
3. **有一台 Linux VPS，并且能 SSH 上去。** 上面跑 Caddy 或 nginx，把某个目录当成网站根。本仓库这个目录是 `/var/www/blog`。服务器上要有 OpenSSH 和 `rsync`，不需要安装 Hexo 或 Node。
4. **网站根目录只放这次要发布的静态文件。** 后面的同步带 `--delete`，目录里多出来的文件会被删掉。

## 升级构建链

旧环境常见的组合是 Node 12、Hexo 3、NexT 5。这套在现在的系统上往往装不上，也和当前的 GitHub Actions 镜像对不齐。升级时让本机和 CI 读同一份版本说明。

### 把 Node 写进 `.nvmrc`

`.nvmrc` 里只放一行版本号，例如 `26.10.0`。本机：

```bash
nvm install
nvm use
node -v
```

`package.json` 的 `engines.node` 写成 `>=20.19.0`，避免有人用过旧的 Node 跑 `npm ci`。Actions 里用 `actions/setup-node`，并设置 `node-version-file: .nvmrc`，这样 CI 和本机读的是同一个文件。

### Hexo 8，主题改走 npm

依赖按本仓库锁定的版本安装：

| 包 | 版本 |
| --- | --- |
| hexo | 8.1.2 |
| hexo-theme-next | 8.29.0 |
| hexo-deployer-git | 4.0.0 |

主题用 npm 包，不再用 `themes/next` 这种 git 子模块。旧子模块指着 2017 年的 NexT 5.1.0，这个仓库里还曾经没有 `.gitmodules`，克隆之后主题目录并不可靠。

`hexo-theme-next` 注册出来的主题名仍是 `next`，所以 `_config.yml` 里继续写：

```yaml
theme: next
```

站点自己的外观放在仓库根目录的 `_config.next.yml`。Hexo 会用它覆盖 `node_modules/hexo-theme-next` 里的默认值。要改配色、菜单、页脚，改这份文件。不要改 `node_modules` 里的主题源码，下次 `npm ci` 会盖掉。

本仓库在 `_config.next.yml` 里保留了原来的 Pisces 方案，并关掉了 NexT 8 默认打开的暗色模式。你的站点按自己的外观写，和发布流程无关。

### 地址、语言、固定链接、发布分支

这几项写在 `_config.yml`，升级时逐项核对，不要顺手“整理”旧路径。

```yaml
url: https://alwaysloseall.github.io
root: /
permalink: :year/:month/:day/:title/
language: zh-CN

deploy:
  type: git
  repo: https://github.com/alwaysloseall/alwaysloseall.github.io.git
  branch: master
```

为什么要改 `language`：NexT 8 的简体语言文件是 `zh-CN.yml`。旧配置里常见的 `zh-Hans` 对不上这份文件，菜单会落到主题的默认语言。

为什么固定链接不动：`:title` 取的是文章文件名。旧文章路径里有中文和空格，和 2018 年线上一致。改成英文 slug、`:name` 或 `:id`，原来的外链会 404。升级后先对比 `public/` 里的文章路径，再允许发布。

`deploy.branch` 必须和后面 Actions 的 `publish_branch` 相同。本机的 `npx hexo deploy` 只按这一段把 `public/` force push 到该分支，不会同步 VPS。双端发布以 Actions 为准。

### 本地生成一次

```bash
npm ci
npx hexo clean
npx hexo generate
```

看两样东西：

- `public/index.html` 存在且不是空文件
- 每篇文章仍在 `public/年/月/日/标题/index.html`

`npx hexo server` 可以在 http://localhost:4000 看页面。`public/` 已在 `.gitignore` 里，不要提交。

有的旧文章在 front matter 里把 `layout` 写成了主题不存在的名字。NexT 8 没有对应模板时，那一篇生成会出问题。本仓库有两篇写成了 `nodejs` 和 `typescript`，`scripts/fix-legacy-layouts.js` 在生成前把它们按 `post` 渲染，不改原文。你的站点如果没有这种历史字段，不必加这个脚本。

## 一次构建，两个出口

工作流文件是 `.github/workflows/deploy.yml`，名称 `Deploy`。两种情况会启动它：向 `hexo` push，或在 Actions 页面手动 Run workflow（`workflow_dispatch`）。

真正往 `master` 和服务器写文件，还要求 `github.ref == 'refs/heads/hexo'`。因此只有对源码分支的 push，以及在 `hexo` 上手动 Run workflow，会发布。从别的分支手动运行时，`build` 仍会生成，两个发布 job 会被跳过。尚未合并的 Pull Request 不会触发这条工作流；合并进 `hexo` 时的那次 push 才会。

三个 job 的关系如下。名字和仓库里的一致：

```yaml
name: Deploy

on:
  push:
    branches:
      - hexo
  workflow_dispatch:

concurrency:
  group: dual-deploy
  cancel-in-progress: false

jobs:
  build:
    # setup-node 读取 .nvmrc，cache: npm
    # npm ci
    # npx hexo clean && npx hexo generate
    # 检查 public/index.html 和按年月日分目录的文章页
    # actions/upload-artifact，名称 site，保留 14 天

  deploy-pages:
    needs: build
    if: github.ref == 'refs/heads/hexo'
    # 下载 site 到 public/
    # peaceiris/actions-gh-pages@v4
    #   github_token: ${{ secrets.GITHUB_TOKEN }}
    #   publish_dir: ./public
    #   publish_branch: master
    #   force_orphan: true
    #   enable_jekyll: false

  deploy-nekodayo:
    needs: build
    if: github.ref == 'refs/heads/hexo'
    # 下载同一份 site 到 public/
    # bash .github/scripts/deploy-nekodayo.sh
    # rsync -az --delete 到用户@主机:/var/www/blog
```

`deploy-pages` 和 `deploy-nekodayo` 都只 `needs: build`，彼此不依赖。一次构建上传一份名为 `site` 的 artifact，两个发布 job 各下载这一份，避免各生成一次后内容对不上。

`cancel-in-progress: false` 是故意的：新的 push 不会取消已经在跑的发布，免得 rsync 或推分支停在半截。

### GitHub Pages

`deploy-pages` 使用 [peaceiris/actions-gh-pages](https://github.com/peaceiris/actions-gh-pages)。`github_token` 用 Actions 自带的 `secrets.GITHUB_TOKEN`，不用再为 Pages 建一个 secret。

`force_orphan: true` 让 `master` 每次只剩「最新站点」这一个提交，历史留在 `hexo`。`enable_jekyll: false` 会在站点根放 `.nojekyll`，GitHub Pages 不会再用 Jekyll 处理这个目录。

这个 job 声明了 `contents: write`。若推送报没有写权限，到 **Settings → Actions → General → Workflow permissions**，选择 **Read and write permissions**。`master` 如果禁止 force push，orphan 推送也会失败，需要允许 GitHub Actions 向这条分支 force push。

`master` 上如果曾经手工放过 `CNAME`，下次 orphan 发布会盖掉。自定义域名文件要放进会进入 `public/` 的源码里，而不是只放在发布分支上。

### VPS

`deploy-nekodayo` 不在服务器上跑 Hexo。它下载 `public/`，用仓库里的 `.github/scripts/deploy-nekodayo.sh` 经 SSH 执行：

```bash
rsync -az --delete public/ 用户@主机:/var/www/blog/
```

脚本里的目标路径写死为 `/var/www/blog`。主机和用户有默认值，也可以用 secret 覆盖（见下一节）。同步结束后会在服务器上检查 `/var/www/blog/index.html` 非空。

`--delete` 的范围只是这个网站根目录：本次 `public/` 里没有的文件，会从 `/var/www/blog` 删掉。`hexo` 分支上的 Markdown 不在这台机器上，不会被 rsync 碰到。

Caddy 或 nginx 只要把站点根指到这个目录。Web 服务器配置不在这条工作流里，升级 Hexo 时不用改它，除非你同时换了目录。

## 配 Actions secrets

路径：**Settings → Secrets and variables → Actions → New repository secret**。Secret 属于仓库，不随分支变化。希望第一次推到 `hexo` 时服务器也成功，就先把密钥加好，再合并工作流。

用一把只给这个博客部署的密钥，不要复用你平时登录服务器或 GitHub 的私钥。不要设口令，Actions 不能在中途输入 passphrase。私钥不要提交进仓库。

```bash
ssh-keygen -t ed25519 -C "github-actions-blog-deploy" -f nekodayo_deploy -N ""
```

把 `nekodayo_deploy.pub` 追加到服务器上对应用户的 `authorized_keys`。本仓库默认用户是 `root`，文件是 `/root/.ssh/authorized_keys`。若你把 `NEKODAYO_USER` 改成别的用户，公钥就要进那个用户的 `authorized_keys`，并且该用户对 `/var/www/blog` 有写权限。

| Secret | 放什么 |
| --- | --- |
| `NEKODAYO_SSH_KEY` | 必填。`nekodayo_deploy` 私钥全文（OpenSSH 格式，保留换行） |
| `NEKODAYO_KNOWN_HOSTS` | 建议。`ssh-keyscan` 的输出，用来固定主机密钥 |
| `NEKODAYO_HOST` | 可选。默认 `nekodayo.com` |
| `NEKODAYO_USER` | 可选。默认 `root` |

在仓库目录里写入（私钥路径按你上一步的文件名）：

```bash
gh secret set NEKODAYO_SSH_KEY < nekodayo_deploy
gh secret set NEKODAYO_KNOWN_HOSTS < <(ssh-keyscan -t ed25519,ecdsa,rsa nekodayo.com)
```

`gh secret set` 会保留换行。写完后私钥文件留在本机或删掉。

`NEKODAYO_KNOWN_HOSTS` 保存之前，先对主机指纹。本机：

```bash
ssh-keyscan -t ed25519 nekodayo.com | ssh-keygen -lf -
```

在服务器上：

```bash
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

两边一致再写入 secret。这个 secret 空着时，脚本会当场 `ssh-keyscan` 并信任当次返回的密钥。那是首次信任：当次连接若被劫持，记下来的会是别人的主机密钥。配好 `NEKODAYO_KNOWN_HOSTS` 之后，脚本使用 `StrictHostKeyChecking=yes`，不再扫描。

服务器上还没有 `rsync` 时，`deploy-nekodayo` 会失败并提示安装。装好后重跑该 job 即可。

## 生成结果不像站点时，不要发布

`build` 在上传 artifact 之前做检查，核心是：

```bash
test -s public/index.html
find public -mindepth 3 -path 'public/20*/*/*/index.html' -print -quit
```

`index.html` 缺失或为空，或者找不到 `public/20xx/月/日/.../index.html` 这种文章页，这一步会失败退出。`deploy-pages` 和 `deploy-nekodayo` 都依赖 `build`，所以两处都不会被覆盖。

这个查找方式和本仓库的固定链接绑在一起：`:year/:month/:day/:title/`。如果你改了 permalink，要同时改工作流里的 `find`，否则正常站点也会被当成空站拦下。

## 服务器失败时，Pages 仍然可以成功

两个发布 job 互不等待。`NEKODAYO_SSH_KEY` 没配、SSH 登录失败、主机密钥对不上、服务器没有 `rsync`，都只会让 `deploy-nekodayo` 失败。`deploy-pages` 仍会把同一份 artifact 推到 `master`。

整次 workflow 会显示失败，因为服务器没有同步上。打开该次运行，看 `deploy-pages` 自己的结论。`site` 这个 artifact 保留 14 天，密钥或服务器补好之后可以只重跑 `deploy-nekodayo`，也可以再推一次 `hexo`，或手动 Run workflow。

## 平时怎么发一篇

改动都发生在源码分支：新文章放 `source/_posts/`，日期写在 front matter 里。然后任选一种方式触发 `Deploy`：

1. 直接 push 到 `hexo`
2. 开 Pull Request，合并进 `hexo`（合并会产生一次指向 `hexo` 的 push）
3. 在 Actions 里对工作流 `Deploy` 选 **Run workflow**，分支选 `hexo`

发之前在本机跑一次 `npx hexo generate`，确认新文章出现在 `public/年/月/日/标题/`，旧文章的路径没有变。本机的 `npx hexo deploy` 只会更新 `master`，要让 VPS 一起更新，用上面三种里的一种。
