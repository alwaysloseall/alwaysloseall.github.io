# alwaysloseall.github.io

Hexo 源码在 `hexo` 分支，生成的静态站发布在 `master`（不是 `main`）。

线上站点：https://alwaysloseall.github.io/

## 环境

已在本仓库验证的版本：

| 工具 | 版本 |
| --- | --- |
| Node.js | **12.22.12**（见 `.nvmrc`） |
| npm | 6.14.16（随 Node 12 自带） |
| Hexo | 3.9.0 |
| 主题 | NexT **5.1.0**（子模块 `themes/next` @ `515b543`） |
| 部署插件 | hexo-deployer-git 3.0.0 |

请用 nvm 切到 Node 12，不要用 Node 14 或更新的版本。Hexo 3.9 在 Node 14+ 上会把 `public/` 写成空文件（生成日志仍显示成功）。Node 16 / 18 / 22 同样不行。

```bash
nvm install
nvm use
node -v   # v12.22.12
```

## 第一次安装

```bash
git clone --branch hexo https://github.com/alwaysloseall/alwaysloseall.github.io.git
cd alwaysloseall.github.io
git submodule update --init
npm install
```

`themes/next` 是 [theme-next/hexo-theme-next](https://github.com/theme-next/hexo-theme-next) 的子模块。仓库里曾经只有 gitlink、没有 `.gitmodules`，直接克隆时主题目录是空的，`hexo generate` 会失败。

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

正常结果大约是：

- 首页 `public/index.html`
- 13 篇文章，固定链接 `:year/:month/:day/:title/`
- 4 个分类、12 个标签
- 主题方案 Pisces

## 部署

部署会把 `public/` 拷进临时目录 `.deploy_git`，然后执行：

```text
git push --force HEAD:master
```

远程是本仓库的 **`master`**。这会覆盖 GitHub Pages 正在用的站点。确认 `public/` 没问题后再在自己的机器上执行，不要在未看过生成结果时部署。

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
2. 或者用有 `repo` 权限的 Personal Access Token。不要把 token 写进仓库。需要 token 时把 `repo` 改成下面这种形式（`hexo-deployer-git` 3 只在对象写法里读取 `token`）：

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
3. 本机如果有 SSH key，可以把 url 改回 `git@github.com:alwaysloseall/alwaysloseall.github.io.git`，**`branch: master` 要留着**。不写 branch 时，旧版 deployer 可能推到 `gh-pages`。

## 主题设置从哪来

2018-11-20 线上站用的是 NexT Pisces（头像、菜单、GitHub / 微博、Disqus），但这些改动当时只留在本地主题配置里，没有提交。子模块检出的是上游默认配置（Muse）。

`scripts/next-live-settings.js` 会在生成前把这些设置写回，避免下次部署把外观退回 Muse。

另外两篇文章的 front-matter 把 `layout` 写成了 `nodejs` 和 `typescript`，主题里没有这两个模板。生成时会按 `post` 渲染，源文件不动。

站点配置里的 Disqus shortname 原来是 `alwayslosall`（少了一个 e）。2018 年页面加载的是 `alwaysloseall.disqus.com`，现已改成后者。

## 已知风险

- NexT 5.1.0 很旧，页面里仍是 jQuery 2、Fancybox、Font Awesome 4。
- Disqus 短名还在，服务本身可能已经不可用。
- Node 固定在 12。这条版本线已经停止维护，只为了让 Hexo 3.9 写出非空 HTML。
- `hexo deploy` 对 `master` 是 `--force` 推送。`master` 上目前只有生成产物，没有 CNAME。
- 固定链接含中文和空格，和 2018 年线上路径一致。升级 Hexo 大版本前先对比 `public/` 里的文章路径。
