# alwaysloseall.github.io

Hexo 源码在 `hexo` 分支，生成的静态站发布在 `master`（不是 `main`）。推送到 `hexo` 后，GitHub Actions 会生成站点，发布到 `master`，并 rsync 到 `nekodayo.com:/var/www/blog`。

线上站点：https://alwaysloseall.github.io/

## 环境

用当前最新版本，不要再用 Node 12 / Hexo 3 / NexT 5。

| 工具 | 版本 |
| --- | --- |
| Node.js | **26.10.0**（见 `.nvmrc`，当前最新版） |
| npm | 11（随 Node 26 自带） |
| Hexo | 8.1.2 |
| 主题 | [hexo-theme-next](https://www.npmjs.com/package/hexo-theme-next) **8.29.0**（npm 安装，不是 git 子模块） |
| 部署插件 | hexo-deployer-git 4.0.0 |

Hexo 8 要求 Node `>= 20.19.0`。本仓库在 Node 26.10.0 上生成通过。

```bash
nvm install
nvm use
node -v   # v26.10.0
```

## 第一次安装

```bash
git clone --branch hexo https://github.com/alwaysloseall/alwaysloseall.github.io.git
cd alwaysloseall.github.io
npm install
```

主题在 `node_modules/hexo-theme-next`。站点覆盖项写在根目录 `_config.next.yml`，不要改 `node_modules` 里的主题文件。

## 本地预览

```bash
npx hexo server
```

浏览器打开 http://localhost:4000 。`Ctrl+C` 停止。

## 生成

```bash
npx hexo clean
npx hexo generate
```

也可以用 `npm run g`。产物在 `public/`（已 gitignore，不要提交）。

正常结果：

- 首页 `public/index.html`
- 13 篇文章，固定链接 `:year/:month/:day/:title/`（含中文和空格，和 2018 年线上路径一致）
- 4 个分类、12 个标签
- 主题方案 Pisces，界面语言简体中文

## 部署

推送到 `hexo` 会走下面的「自动部署」。本机 `npx hexo deploy` 只更新 `master`，不会同步服务器。

部署会把 `public/` 拷进临时目录 `.deploy_git`，然后执行：

```text
git push --force HEAD:master
```

远程是本仓库的 **`master`**。这会覆盖 GitHub Pages 正在用的站点。确认 `public/` 没问题后再在自己的机器上执行。

```bash
npx hexo clean
npx hexo generate
npx hexo deploy
```

`_config.yml` 里的地址是 HTTPS：

```yaml
deploy:
  type: git
  repo: https://github.com/alwaysloseall/alwaysloseall.github.io.git
  branch: master
```

认证（云端环境没有 SSH key，所以不用 `git@github.com:...`）：

1. 本机已 `gh auth login` 时，可以先 `gh auth setup-git`，再 `npx hexo deploy`。
2. 或者用有 `repo` 权限的 Personal Access Token。不要把 token 写进仓库。需要 token 时把 `repo` 改成对象（`hexo-deployer-git` 只在这种写法里读取 `token`）：

```yaml
deploy:
  type: git
  repo:
    url: https://github.com/alwaysloseall/alwaysloseall.github.io.git
    branch: master
    token: $GITHUB_TOKEN
  message: "Site updated: {{ now('YYYY-MM-DD HH:mm:ss') }}"
```

环境变量没设置时，这种写法会直接报错。
3. 本机如果有 SSH key，可以把 url 改回 `git@github.com:alwaysloseall/alwaysloseall.github.io.git`，**`branch: master` 要留着**。

## 自动部署

`.github/workflows/deploy.yml` 在 **push 到 `hexo`** 或 Actions 里手动 **Run workflow** 时运行。发布步骤只在 `hexo` 上执行。三个任务拆开，服务器失败不会挡住 Pages：

| 任务 | 做什么 |
| --- | --- |
| `build` | 按 `.nvmrc` 安装 Node（Hexo 8 需要 `>= 20.19.0`），`npm ci`，然后 `npx hexo clean && npx hexo generate` |
| `deploy-pages` | 用 [peaceiris/actions-gh-pages](https://github.com/peaceiris/actions-gh-pages) 和自带的 `GITHUB_TOKEN`，把 `public/` **force orphan** 推到本仓库 `master`。不用额外密钥 |
| `deploy-nekodayo` | 用 `NEKODAYO_SSH_KEY` 经 SSH `rsync` 到 `/var/www/blog`。默认 `root@nekodayo.com` |

没配 `NEKODAYO_SSH_KEY` 时，`deploy-nekodayo` 失败，日志里会写出要添加的 secret 和命令。`deploy-pages` 仍会发布。整次 workflow 是红的，因为服务器没同步上；打开该次运行可以看见 `deploy-pages` 自己的结果。

**第一次要双端都成功，先把下面的 secret 加到仓库，再把 workflow 合并进 `hexo`。** Secret 是仓库级的，与分支无关。合并时如果还没有 `NEKODAYO_SSH_KEY`，那一次 push 只会完成 GitHub Pages。之后补上密钥，重跑失败的 `deploy-nekodayo`（构建产物保留 14 天），或再推一次 `hexo`，或手动 Run workflow。密钥写好之前，服务器部署会失败。

### 要添加的 Actions secrets

路径：**Settings → Secrets and variables → Actions → New repository secret**。

也可以在本机、这个仓库目录里：

```bash
ssh-keygen -t ed25519 -C "github-actions-blog-deploy" -f nekodayo_deploy -N ""
# 把 nekodayo_deploy.pub 追加到服务器对应用户的 authorized_keys
# root 默认是 /root/.ssh/authorized_keys
gh secret set NEKODAYO_SSH_KEY < nekodayo_deploy
gh secret set NEKODAYO_KNOWN_HOSTS < <(ssh-keyscan -t ed25519,ecdsa,rsa nekodayo.com)
```

生成用的私钥文件留在本机或删掉，不要提交。`gh secret set` 会保留换行，私钥按 OpenSSH 原文粘贴即可，不要设口令（Actions 不能交互输入口令）。

| Secret | 是否必须 | 内容 |
| --- | --- | --- |
| `NEKODAYO_SSH_KEY` | 服务器部署必须 | 登录部署用户的私钥全文 |
| `NEKODAYO_KNOWN_HOSTS` | 建议 | `ssh-keyscan -t ed25519,ecdsa,rsa nekodayo.com` 的输出 |
| `NEKODAYO_HOST` | 可选 | 默认 `nekodayo.com` |
| `NEKODAYO_USER` | 可选 | 默认 `root` |

`GITHUB_TOKEN` 由 Actions 注入，不用新建 secret。

写入 `NEKODAYO_KNOWN_HOSTS` 之前，核对主机指纹。两边一致再保存：

```bash
ssh-keyscan -t ed25519 nekodayo.com | ssh-keygen -lf -
```

在服务器上：

```bash
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

没配 `NEKODAYO_KNOWN_HOSTS` 时，任务会当场 `ssh-keyscan`，并信任这次返回的主机密钥。这是首次信任：这次网络如果被劫持，记下的可能是别人的密钥。配好该 secret 后就不再扫描。

Pages 推送如果报 `Write access to repository not granted` 或 403：打开 **Settings → Actions → General → Workflow permissions**，选择 **Read and write permissions**。`deploy-pages` 已声明 `contents: write`。`master` 若禁止 force push，orphan 推送也会失败，需要允许 GitHub Actions 向 `master` force push。

### 服务器目录

目标路径固定为 `/var/www/blog`。`rsync --delete` 让这个目录和本次 `public/` 一致，生成结果里没有的文件会从这里删掉。`hexo` 上的文章不会被删，固定链接仍是 `:year/:month/:day/:title/`。这个目录只放站点文件。

服务器需要已安装 `rsync` 和 OpenSSH。没有 `rsync` 时 `deploy-nekodayo` 会失败并提示安装。同步结束会检查 `/var/www/blog/index.html` 非空。

本机 `npx hexo deploy` 仍然只 force push `master`，不会 rsync。

`master` 每次发布变成只含最新站点的一个提交（force orphan），并带上 `.nojekyll`，GitHub Pages 不会再用 Jekyll 处理。源码历史在 `hexo`。当前 `master` 没有 CNAME；如果以后只在 `master` 上手工放了 CNAME，下次发布会盖掉，应把 CNAME 放进会生成到 `public/` 的源文件。

生成结果里如果看不到按年月日分目录的文章页，`build` 会失败，不会去覆盖 `master` 和服务器。

## 从旧配置迁过来的几处

- 站点 `language` 从 `zh-Hans` 改成 `zh-CN`。NexT 8 的语言文件是 `zh-CN.yml`，继续写 `zh-Hans` 时菜单会落到错误语言。
- 主题不再是 `themes/next` 子模块（原先指向 2017 年的 NexT 5.1.0，而且仓库里曾经没有 `.gitmodules`）。现在由 npm 包 `hexo-theme-next@8.29.0` 提供。
- 外观仍按 2018 年线上站设置：Pisces、浅色（关掉主题默认的暗色）、头像、GitHub / 微博、Disqus `alwaysloseall`、页脚起始年 2017。这些写在 `_config.next.yml`。
- 关键词写在 `source/_data/head.njk`。NexT 8 没有旧版的 `keywords` 配置项。
- 两篇文章的 `layout` 是 `nodejs` / `typescript`，主题里没有这两个模板。`scripts/fix-legacy-layouts.js` 会在生成时按 `post` 渲染，不改原文。
- Disqus shortname 曾经写成 `alwayslosall`（少了一个 e），已改为 `alwaysloseall`。

## 已知风险

- NexT 8 的页面结构和脚本与 2018 年的 NexT 5 不同。固定链接还在，外观不会和旧站逐像素一致。
- 主题默认带 CC BY-NC-SA 配置，侧栏和文末默认不显示。若要改许可，改 `_config.next.yml` 的 `creative_commons`。
- Disqus 短名还在，服务本身可能已经不可用。
- 本机 `hexo deploy` 和 Actions 的 `deploy-pages` 都会 force push `master`。`master` 上是生成产物，没有 CNAME。Actions 用 orphan 提交，不保留 `master` 上一次的站点历史。
- 升级 Hexo 或主题大版本后，先对比 `public/` 里的文章路径再部署。
