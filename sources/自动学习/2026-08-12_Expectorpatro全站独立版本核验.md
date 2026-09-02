# Expectorpatro 数学教材全站独立版本核验

> 核验日期：2026-08-12（Asia/Shanghai）  
> 证据边界：仅使用作者自己的 GitHub Pages 站点、`Expectorpatro/math` 官方仓库、该仓库 GitHub API、Raw GitHub 与本地两个附件。  
> 文档角色：版本、覆盖范围与附件溯源记录；不等同于公式正确性证明，也不直接修改主知识库。  
> 重要措辞：本次对全站采用机械枚举、逐文件下载、字节比较、文本检索和哈希；人工目视完整检查了 `EM.pdf` 11 页，并人工定位 EM/GRU 主源码与附件差异。没有声称对 52 个网页、422 个仓库 blob 或全部公式进行了人工逐字阅读。

## 1. 结论摘要

1. 目标站点明确对应官方仓库 [`Expectorpatro/math`](https://github.com/Expectorpatro/math)。站点 HTML 自报 `textbook-repository=Expectorpatro/math`，仓库 `homepage` 反向指向目标站。
2. 截至本次核验，公开 `main` 为不可变提交 [`df67be9e166221776f96883a5f2cd42df2a73f49`](https://github.com/Expectorpatro/math/commit/df67be9e166221776f96883a5f2cd42df2a73f49)，提交时间 `2026-08-07T14:09:03Z`，消息 `2026.8.7, nn`。对应 Pages 工作流运行成功，部署目录是 `html/site`。
3. 该提交的发布目录有 123 个文件，其中 `.generated-site` 和 `.nojekyll` 是部署控制标记；其余 121 个公开文件共 22,032,769 bytes。本次把这 121 个文件逐一从线上重新下载并与提交快照比较，最终 **121/121 字节完全一致**。因此本文后续的页面和资产清单可固定到该提交，而不是把可变的 `main` 当作永久证据。
4. 官方 sitemap 给出 52 个页面，全部 HTTP 200：4 个站点级页面和 48 个 `chapters/` 页面。发布物另有 69 个非 HTML 资产。
5. 用户的两个 `EM.pdf` 副本字节完全相同；附件 PDF 共 11 页，已全部渲染并目视检查。当前官方站点也有 EM 章节，但附件 PDF **不是当前仓库/站点中的同一文件或同版正文**：仓库快照中没有 PDF blob；PDF 中文连续片段与当前 EM 主源码未显示正文级复用，最长共同连续中文仅 7 字。能确定的是作者、主题和时间线相符，不能据此认定 PDF 由当前站点源码直接生成。
6. `gru.py` 可被 Python 3.12 编译，但不与当前仓库任何 blob 字节相同，也不等同于 `external-repo:markdown/GRU.md` 的完整代码块。附件与该代码块存在显著共享结构，但大小、配置和实现均有扩展；只能定为“高度相关的后续/分支版本候选”，不能证明是站点当前主源码。站点当前 GRU 教材主源码是 `statistics/machine-learning/nn.tex`，而 `external-repo:markdown/GRU.md` 是仓库中的补充笔记，未进入当前 Pages 发布目录。

## 2. 官方仓库、提交与部署证据链

| 项目 | 已核验值 | 第一方证据 |
|---|---|---|
| 官方仓库 | `Expectorpatro/math` | [仓库首页](https://github.com/Expectorpatro/math)；站点 `<meta name="textbook-repository">` |
| 站点 | `https://expectorpatro.github.io/math/` | [GitHub Pages 首页](https://expectorpatro.github.io/math/)；仓库 API `homepage` |
| 默认分支 | `main` | [仓库](https://github.com/Expectorpatro/math) 与 GitHub REST repo metadata |
| 固定提交 | `df67be9e166221776f96883a5f2cd42df2a73f49` | [固定提交](https://github.com/Expectorpatro/math/commit/df67be9e166221776f96883a5f2cd42df2a73f49) |
| 提交时间 | `2026-08-07T14:09:03Z` | 同上 |
| 提交消息 | `2026.8.7, nn` | 同上 |
| 仓库树 | 505 entries；422 blobs；83 trees；Git Trees API `truncated=false` | [固定提交递归树 API](https://api.github.com/repos/Expectorpatro/math/git/trees/df67be9e166221776f96883a5f2cd42df2a73f49?recursive=1) |
| Pages 触发 | `main` push 或手工触发 | [pages.yml](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/.github/workflows/pages.yml) |
| 部署输入 | checkout 后上传 `html/site` | 同上 |
| 成功运行 | Actions run `31186165353`，head SHA 与固定提交相同，2026-08-07T14:09:38Z 完成 | [Actions run](https://github.com/Expectorpatro/math/actions/runs/31186165353) |
| 部署环境 | `github-pages`，目标为本站 | [deployment statuses API](https://api.github.com/repos/Expectorpatro/math/deployments/5796008182/statuses) |
| 站点响应 | GitHub Pages；首页 `Last-Modified: Fri, 07 Aug 2026 14:09:32 GMT` | [首页](https://expectorpatro.github.io/math/) 的 HTTP 响应 |
| 发布目录版本标记 | `html/site/.generated-site = site-build-v1` | [固定提交发布目录](https://github.com/Expectorpatro/math/tree/df67be9e166221776f96883a5f2cd42df2a73f49/html/site) |
| 站点内容日期 | `content_updated=2026-08-07` | [site-meta.json](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/html/data/site-meta.json) |

匿名请求 GitHub Pages 配置 REST endpoint 返回 404，且本次看到的历史部署 artifact 已过期，故没有依赖这两个接口来宣称发布来源。来源结论由仓库内工作流、成功 Actions run、deployment status、目标 URL 和逐文件字节一致性共同支持。

### 2.1 发布物逐文件字节覆盖

机械步骤：Git Trees API 枚举固定提交 → 下载 commit zip 快照 → 枚举 `html/site` → 对除两个部署控制标记外的每个文件向线上同路径发起 GET → 比较文件长度和 SHA-256。首次 119 个成功，2 个因瞬时超时/不完整读取失败；两项分别重试后也精确一致。

| 集合 | 文件数 | 字节数 | 清单 SHA-256 |
|---|---:|---:|---|
| 全部线上公开发布物 | 121 | 22,032,769 | `6E4F842EFB9370EE5E61D60565518EFBEB9CA5774648D159AD9ACF202C284678` |
| HTML 页面 | 52 | 15,915,663 | `EB196DE20C6C0B64828B7738BE7A744F67C602ABD4C7B3161B928FA32BEBFE4F` |
| PNG | 29 | 2,010,616 | `E988324AA4D2EF2391D8E175637E9A895326A292AD7F7F60F1EA78FEEE4AAB63` |
| 根目录自有 JS | 14 | 106,466 | `60EA6A3B7EF68904084966B41A40D4783AF1FA47BF2C16C1EDA798B22728185D` |
| `site_libs` | 20 | 1,645,313 | `B4D8F8C1DDF7CD11052CBE35D7FC431B9A3560276A3F96D50C5C043013E04F91` |
| CSS | 8 | 1,195,799 | `996CAE70DCBD704AC7589CEA7EFE5DC03983F9939438D2B15D63784C3563B7D0` |
| search/sitemap/robots/favicon | 4 | 2,273,761 | `AA9B26FC2CB4825C7FEF48AF559C22D7B37C06A1FEF00BCF5F0463B0D428EDFD` |

“清单 SHA-256”的可复现定义：把该集合内文件按仓库相对路径字典序排序，每行写成 `<path>\t<byte length>\t<SHA256 uppercase>\n`，再对全部 UTF-8 文本求 SHA-256。它不是 Git tree SHA，也不是把文件内容简单串接后的 SHA。

## 3. 页面全集

官方 [`sitemap.xml`](https://expectorpatro.github.io/math/sitemap.xml) 列出 52 个 URL，本次逐项 GET 均为 HTTP 200。

### 3.1 站点级页面（4）

- [首页](https://expectorpatro.github.io/math/index.html)
- [参考文献](https://expectorpatro.github.io/math/references.html)
- [项目状态](https://expectorpatro.github.io/math/project-status.html)
- [符号记号说明](https://expectorpatro.github.io/math/notation.html)

### 3.2 教材内容页面（48）

- 前言 1 页：`preface.html`。
- 编号正文 18 章：
  1. [线性空间](https://expectorpatro.github.io/math/chapters/linear-space.html)
  2. [矩阵](https://expectorpatro.github.io/math/chapters/matrix.html)
  3. [度量空间](https://expectorpatro.github.io/math/chapters/metric-space.html)
  4. [微积分](https://expectorpatro.github.io/math/chapters/calculus.html)
  5. [概率测度](https://expectorpatro.github.io/math/chapters/probability-measure.html)
  6. [概率初步](https://expectorpatro.github.io/math/chapters/probability-basics.html)
  7. [渐近理论初步](https://expectorpatro.github.io/math/chapters/asymptotic-theory.html)
  8. [凸集](https://expectorpatro.github.io/math/chapters/convex-sets.html)
  9. [统计初步](https://expectorpatro.github.io/math/chapters/statistics-basics.html)
  10. [参数点估计](https://expectorpatro.github.io/math/chapters/point-estimation.html)
  11. [统计假设检验](https://expectorpatro.github.io/math/chapters/hypothesis-testing.html)
  12. [贝叶斯统计](https://expectorpatro.github.io/math/chapters/bayesian-statistics.html)
  13. [统计计算方法](https://expectorpatro.github.io/math/chapters/statistical-computing.html)
  14. [线性模型](https://expectorpatro.github.io/math/chapters/linear-models.html)
  15. [多元统计](https://expectorpatro.github.io/math/chapters/multivariate-statistics.html)
  16. [时间序列分析](https://expectorpatro.github.io/math/chapters/time-series.html)
  17. [机器学习](https://expectorpatro.github.io/math/chapters/machine-learning.html)
  18. [因果推断](https://expectorpatro.github.io/math/chapters/causal-inference.html)
- 附录 1 页：当前实际输入“数域、等价关系、矩阵、不等式”四块；`appendix/appendix.tex` 中 `code-functions` 被注释，不能算作当前站点正文。
- 后记 1 页。
- 术语 27 页：术语总页 1，加 A–Z 分页 26。

章节完成度不是质量认证。官方 `chapter-progress.json` 给出的百分比是项目自报状态；它不能替代公式、证明与代码的独立核验。

## 4. 资产、代码与计算清单

### 4.1 当前公开非 HTML 资产（69）

- 29 个 PNG：`_tikz/` 28 个生成图；`probability-theory/asymptotic/CDF-of-c-and-d-variables.png` 1 个原图。
- 27 个 JS：站点根目录自有脚本 14；`site_libs` 中 13。
- 8 个 CSS：站点根目录 2；`site_libs` 中 6。
- 1 个 WOFF、1 个 SVG、1 个 JSON、1 个 XML、1 个 TXT。

根目录自有 14 个 JS 的内容哈希：

| 文件 | bytes | SHA-256 |
|---|---:|---|
| `computation-copy.js` | 5,332 | `DB40D5F0D065CB19ADC6F6AF781A450CF155DDB67D62026E2BF7C48649A0A682` |
| `density-distributions.js` | 8,661 | `81F4104295BEEC31AFA842C79F4A26C84505D14CD8E605882C8D978397A74042` |
| `density-loader.js` | 2,232 | `CC128004FCBDE841F6C54CC37946668C3B84B7A2FD9CB804E195239A3DBC51EA` |
| `density-math.js` | 6,493 | `44CB999C8084494BDB751397D07F6719E1AD6D9B4D9C3BC2B992D98DD80BD21C` |
| `density-plots.js` | 17,411 | `DC6ABFBF5A857F4CF02746B9D2DBC5D635575329E548ED8740E15708B52346F7` |
| `density-probe.js` | 3,726 | `E100DFBCBE1B5AB8C7BBAD8E8D9073038729C62A4312EB68C42C42B626378FDE` |
| `density-renderer.js` | 11,984 | `44D6CF2025C4ABAE46EBDA06765B84F140A59E7BE67AA9A03C9C4481E5FA85D7` |
| `formula-copy.js` | 6,538 | `1223F1197FD7E40EB31879FE72B2864E5C4223A9211F65F11F877593B603B1B1` |
| `textbook-content-ui.js` | 10,292 | `8296A83A0ECC26D19E6E743A8D168461F795A1CB9B074C8A7FDD529BBB62CD89` |
| `textbook-page-ui.js` | 8,151 | `6679A76C8E90C173EB8AD273A86EA14D61507856653CC7CEE6533C2F1647B5C0` |
| `textbook-reading.js` | 13,075 | `95EFD72CAEDAC339F3775788D58B49555ED0445A9894DDAE38613FF5591FCBA5` |
| `textbook-theme.js` | 5,461 | `456EBEECAE4AA6D1E725E8C27A2E96DE85A6C9593DC398707EEEFBECEBE6F810` |
| `textbook-toc.js` | 5,842 | `EA80E64E06670BB150693909BEFE25413FC48D778587E2DB452C5797A7159BC3` |
| `textbook-ui.js` | 1,268 | `EEF62D6193F26246AA674D0C866DBE615DB197C2BDD07D890B9E0C04B1B3F06C` |

其余大类使用第 2.1 节的分类清单哈希固定；完整路径集合由固定提交的 [`html/site`](https://github.com/Expectorpatro/math/tree/df67be9e166221776f96883a5f2cd42df2a73f49/html/site) 和上述清单算法可复算。HTML 静态 `href/src` 直接引用的唯一内部非 HTML 目标为 51 个（PNG 29、JS 13、CSS 8、SVG 1）；其余脚本可能由内联加载器动态请求，因此“51 个直接引用”不能误写成“全站仅 51 个资产”。

### 4.2 计算实验与可下载源

当前站内没有 `.ipynb`、`.qmd`、`.py`、`.R` 的显式下载链接，也没有 `download` 属性或 `raw.githubusercontent.com` 下载入口；网页只给出仓库总入口。章节中嵌入 12 个计算实验，对应官方仓库的 12 个主要可编辑源文件：9 个 `.ipynb`、3 个 `.qmd`。

| 实验 | 固定提交源文件 | bytes | SHA-256 |
|---|---|---:|---|
| Newton 局部二次收敛 | [`analysis.ipynb`](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/optimization/convex/computations/01-newton-convergence/python/analysis.ipynb) | 129,756 | `C9F7FF5EC3AB5103D2361A9CC8645547CBB2F52E6C9AE2144C173FA854C572D8` |
| 线性回归 | [`analysis.qmd`](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/statistics/Linear-model/computations/01-linear-regression/r/analysis.qmd) | 6,379 | `271FB4927DF1D83FDA2A2D6953287AA84EB4D0612AA14C2CDA4296D22FE79EA7` |
| 复共线性与岭回归 | [`analysis.qmd`](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/statistics/Linear-model/computations/02-multicollinearity-ridge/r/analysis.qmd) | 5,082 | `A5297E9BB7A1E2EE321A67E0EA8D7AFF1FEF20ABB6B3CF7BEE4FEDF6877A9743` |
| 分类树 | [`analysis.ipynb`](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/statistics/machine-learning/computations/01-decision-tree-classification/python/analysis.ipynb) | 325,169 | `5125BACCF69FB862B29B71B826BE9EFF0478C2E146DA79D47D8A23E0A2DEA0A4` |
| 回归树 | [`analysis.ipynb`](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/statistics/machine-learning/computations/02-decision-tree-regression/python/analysis.ipynb) | 203,552 | `B5F746BF18737132A82DBA660A94932CA6E8ED5F94DDC898C4F5DEA704BB8307` |
| PCA | [`analysis.qmd`](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/statistics/multivariate/computations/01-pca/r/analysis.qmd) | 14,757 | `0357F4F0739835EEC9BE7344E00AB22F346297DB3794EFE99DB58E8AB71E64FE` |
| K-means | [`analysis.ipynb`](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/statistics/multivariate/computations/02-kmeans/python/analysis.ipynb) | 794,316 | `7F253CE288FFF24A539BEB04DA0B766C71DE8A998E63514FCE771B445FA9D18F` |
| 凝聚层次聚类 | [`analysis.ipynb`](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/statistics/multivariate/computations/03-agglomerative-clustering/python/analysis.ipynb) | 221,563 | `C2EAA3EA94BEE5A2CAF34A950DA74E349C9B33EE39354DC64ECCA54C37000BB8` |
| DBSCAN | [`analysis.ipynb`](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/statistics/multivariate/computations/04-dbscan/python/analysis.ipynb) | 686,473 | `75888FBB27367A4BF4AD581844AAF0FF3C9CD5B09E96151549D83A691B48EC53` |
| OPTICS | [`analysis.ipynb`](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/statistics/multivariate/computations/05-optics/python/analysis.ipynb) | 888,886 | `6F1F76EA0CF425E51CF37FE9CA48DD086754520C13D0EDFF389DD84A4ACC2B3D` |
| 非线性方程 | [`analysis.ipynb`](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/statistics/statistical-computing/computations/01-nonlinear-equations/python/analysis.ipynb) | 78,704 | `62233D8E9A783D6C211A36AAD4DA3B8C13667BEB1767C7311137BB11420BBBEB` |
| 多项式逼近 | [`analysis.ipynb`](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/statistics/statistical-computing/computations/02-polynomial-approximation/python/analysis.ipynb) | 119,659 | `B12320EB975AE92F03C471460F37166AB350BBDED22A853632711DD88FC5C8DE` |

这里的“12 个源”指计算实验的主要可编辑输入，不包括仓库中同时提交的渲染 `analysis.html`。它们可从官方仓库下载，但不是网页中的显式下载按钮。

## 5. EM 附件的版本与来源核验

### 5.1 文件身份与完整覆盖

| 文件 | bytes | SHA-256 | 结论 |
|---|---:|---|---|
| `C:\Users\Strid\Documents\WeChat Files\wxid_2xr84dr8jcek22\FileStorage\Temp\Copy\EM.pdf` | 204,761 | `9E4D38092D48DA41423A89149613397ABEA0E0D492B09113FCED5C8D4534D6C4` | 用户本轮附件 |
| `D:\数学建模\EM.pdf` | 204,761 | `9E4D38092D48DA41423A89149613397ABEA0E0D492B09113FCED5C8D4534D6C4` | 与本轮附件逐字节相同 |

PDF 为 11 页，元数据 `Creator=LaTeX with hyperref`、`Producer=xdvipdfmx (20250205)`、`CreationDate=D:20260625113815+08'00'`；可见标题《EM 算法》、署名倪兴程、日期 2026-06-25。11 页已全部渲染并目视检查，章节为“潜变量、问题、EM 算法（求解潜变量分布、求解参数值、算法步骤总结）”。提取文本共 6,971 字符；该文本抽取结果 UTF-8 SHA-256 为 `674783DEB7C0FF6FEE7054F96D8D063B266E9521526279422EFB8D80E71CFC00`。文本哈希依赖 pypdf 6.x 的提取顺序，仅用于本次可复现比较，不是 PDF 原始字节哈希。

### 5.2 当前站点的 EM 主源码

- 当前主源码：[`statistics/statistical-computing/main.tex`](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/statistics/statistical-computing/main.tex#L482)，完整文件 29,923 bytes，SHA-256 `2DAC885C844761FA0A8C107578212D7C34CAECF2E48DF8FBCE4C6301F3EBA00F`；EM 小节始于物理行 482。
- 当前发布页面：[统计计算方法的 EM 小节](https://expectorpatro.github.io/math/chapters/statistical-computing.html#em-f307c3c2)，发布 HTML 356,890 bytes，SHA-256 `4FC1D8720B53AFBA272807C25EF77F67A0C605BD7F2FB8A1E02D16C0A60ED40D`。
- 当前源码采用抽象概率空间记号 `f,g,p_\theta`，明确使用 KL 分解和坐标上升叙述；附件以逐样本 `x_i,z_i,q_i`、GMM 和 Jensen 取等条件展开。二者讲同一主题，但结构、记号和正文不同。

### 5.3 可追溯结论

- 固定提交的 422 个 blob 中没有 `.pdf`；递归计算全部仓库文件 SHA-256 也没有附件 PDF 的字节匹配。因此附件不是当前仓库中已提交的 PDF 资产。
- 对附件提取文本与当前 EM 主源码做中文字符级机械比较：附件 2,875 个中文字符；当前 EM 小节 607 个；最长相同连续中文仅 7 字“统计模型中观测”。8、12、16、20 字连续中文窗口均无共同项。该方法忽略公式和标点，因此只能用于排除“正文逐字同版”，不能证明思想无关。
- PDF 日期 2026-06-25；仓库 EM 主源码历史中 2026-05-12 已出现 `Variational Method and EM Algorithm`，随后 2026-07-23 仍有修改。时间线允许作者在同一主题上另写讲义，但官方仓库没有提供把本地 PDF 连接到具体 commit 的构建脚本、下载 URL 或同哈希文件。

**判定：**作者身份、主题与大致时间线相符；但没有第一方文件链证明附件由站点仓库生成。附件与当前站点 EM 内容不是逐字同版，不能把网站固定提交当作 PDF 的原始发行版。

## 6. `gru.py` 的版本与来源核验

### 6.1 附件身份与最低可运行性

| 项目 | 值 |
|---|---|
| 路径 | `C:\Users\Strid\Documents\WeChat Files\wxid_2xr84dr8jcek22\FileStorage\File\2026-08\gru.py` |
| 大小 | 18,771 bytes |
| 行数 | 532（按换行统计） |
| SHA-256 | `E2AFD45731485F163883DF1FFB3F1611A343451C52C138EE735FA889DB5D9001` |
| 静态语法 | `python -m py_compile` 在 Python 3.12.7 下通过 |

语法通过不等于训练流程正确或无数据泄漏；本记录没有运行其依赖数据、训练 3000 epochs 或验证模型指标。

### 6.2 当前站点和仓库中的 GRU 材料

- 当前教材主源码：[`statistics/machine-learning/nn.tex`](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/statistics/machine-learning/nn.tex#L842)，52,420 bytes，SHA-256 `2981D7EC4A2F598A2B4DE0798AE1423821FF17228479386454B7B6346BD04577`；“门控循环单元”始于物理行 842。
- 当前发布页：[机器学习章](https://expectorpatro.github.io/math/chapters/machine-learning.html)，869,815 bytes，SHA-256 `8006EA663D5BFCB3A1F60E03C55D1AB135A7D7680F111F28AB713CB4FED1F6CE`；当前 GRU 锚点是 `id--4bae4a6d`。
- 仓库补充笔记：[`markdown/GRU.md`](https://github.com/Expectorpatro/math/blob/df67be9e166221776f96883a5f2cd42df2a73f49/markdown/GRU.md)，15,607 bytes，439 行，SHA-256 `0423F5FF284C214A729DCE3A5FCCCCEB43B122D8D8D341A297A04215CB37DC95`。该文件不在 `html/site`，当前站点 sitemap 也无 GRU 独立页，所以它不是当前 Pages 发布正文。

### 6.3 附件与仓库代码的机械比较

1. 对固定提交全部文件做 SHA-256 搜索，附件哈希匹配数为 0；即不存在完全相同的已提交 blob。
2. `external-repo:markdown/GRU.md` 有 3 个 Python 代码块；大小分别为 130、30、11,105 UTF-8 bytes。附件 18,771 bytes，三个代码块均不与附件字节或规范化换行文本完全相同。
3. 对最大代码块与附件按去除行尾空格的行序列比较：仓库代码块 320 行、附件 531 行；顺序匹配 190 行；SequenceMatcher ratio `0.44653349`；最长连续相同行为 24 行。两者均能被 Python AST 解析。
4. `external-repo:markdown/GRU.md` 的公开历史只有 2025-05-06 初始版本和 2025-06-22 修改版本；对这两次版本的全部 Python 代码块逐项比较，也没有附件的精确字节匹配。
5. 附件在共同 GRUNet/训练骨架上增加或修改了 `xx_size`、BatchNorm、Adamax、提前停止、日志、缓存、MPS/device 逻辑和特定数据路径等；因此“相关”是有机械证据的，但“由哪个 commit 导出”没有第一方证据。

**判定：**`gru.py` 不是当前站点教材主源码，也不是当前或已发现历史 `external-repo:markdown/GRU.md` 代码块的同版文件。它很可能是同一骨架的扩展或分支版本；“很可能”是基于共同类名、函数结构和 190 行顺序匹配作出的推断，不是来源事实。

## 7. 可复现性、边界与后续使用规则

### 7.1 本次真正覆盖了什么

- 机械覆盖：固定提交完整递归树；`html/site` 123 个文件；121 个公共发布物的线上下载和逐字节比较；52 个 sitemap URL 的可达性；仓库全部文件对两个附件哈希的精确匹配搜索；EM 文本和 GRU 代码的差异比较。
- 人工覆盖：`EM.pdf` 11 页全部版面；站点/仓库的 EM、GRU 主源码入口；附件与当前材料差异的关键位置；发布工作流和项目元数据。
- 没有覆盖：52 页所有公式、证明、示例代码的逐条数学正确性；所有外部参考文献的真实性；全部运行时代码路径和动态浏览器请求；`gru.py` 的端到端训练与指标复现。

### 7.2 为什么不能写“一个字一个字人工对照全站”

本次可以准确声称“当前发布的 121 个公共文件与固定提交中的发布目录逐字节一致”，因为这是哈希和字节比较的结论。不能声称“人工一个字一个字读完全站并证明全部正确”：站点有 52 个 HTML 页面、约 15.9 MB HTML，仓库有 422 个 blob，且数学正确性不能由文本相同自动推出。后续若要审查知识库与站点的知识差异，应以本快照为版本底座，再按章进行公式、定义、例题和代码的独立来源核验。

### 7.3 动态更新规则

- 任何后续核验都应先查询 `main` 当前 SHA。若不再是 `df67be9e…`，不得沿用本文的“121/121”结论到新版本。
- 引用源码时优先使用本文的 commit 固定链接；可变 `main` 只适合作为查看最新内容的入口。
- EM/GRU 附件应继续保留各自 SHA-256，不因文件名、作者相同或内容相似就登记为站点源码副本。
- 本记录是证据台账，不授权把网站结论无审查地写入主知识库；数学公式仍需原始论文/权威教材交叉核验，代码仍需独立测试。
