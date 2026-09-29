'use strict';

// 两篇文章的 front-matter 把 layout 写成了 nodejs / typescript。
// NexT 没有这两个模板，生成前改回 post，不改源文件。
hexo.extend.filter.register('before_generate', () => {
  hexo.locals.get('posts').forEach(post => {
    if (post.layout === 'nodejs' || post.layout === 'typescript') {
      post.layout = 'post';
    }
  });
});
