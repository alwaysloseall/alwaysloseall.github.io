'use strict';

/**
 * themes/next 固定在 NexT 5.1.0（子模块 515b543）。
 * 2018-11-20 发布到 master 的外观改动没有进 git，这里在生成前写回，
 * 避免下次部署从 Pisces 退回主题默认的 Muse。
 *
 * 两篇文章的 layout 写成了 nodejs / typescript，主题里没有这两个模板。
 * 生成时改回 post，不改源文件。
 */
hexo.extend.filter.register('before_generate', function () {
  var theme = hexo.theme.config;

  theme.keywords = 'vldh, alwaysloseall, blog, 失败者, 勃学';
  theme.scheme = 'Pisces';
  theme.since = 2017;
  theme.menu = {
    home: '/',
    categories: '/categories',
    archives: '/archives',
    tags: '/tags'
  };
  theme.avatar = 'https://avatars2.githubusercontent.com/u/20535775?v=3&s=460';
  theme.social = {
    GitHub: 'https://github.com/alwaysloseall',
    weibo: 'http://weibo.com/alwaysloseall'
  };
  theme.disqus.enable = true;
  // 站点 _config.yml 里曾经写成 alwayslosall（少了一个 e）。
  // 2018 年线上脚本是 alwaysloseall.disqus.com。
  theme.disqus.shortname = 'alwaysloseall';
  theme.disqus.count = true;

  hexo.locals.get('posts').forEach(function (post) {
    if (post.layout === 'nodejs' || post.layout === 'typescript') {
      post.layout = 'post';
    }
  });
});
