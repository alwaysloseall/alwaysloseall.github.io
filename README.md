# alwaysloseall.github.io

Hexo 源码在 `hexo` 分支，生成的静态站发布在 `master`（不是 `main`）。

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
- `hexo deploy` 对 `master` 是 `--force` 推送。`master` 上目前只有生成产物，没有 CNAME。
- 升级 Hexo 或主题大版本后，先对比 `public/` 里的文章路径再部署。
