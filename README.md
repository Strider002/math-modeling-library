# 数学建模方法库

面向国赛、美赛与一般数学建模的独立 Agent Skill。它与另一 Skill 共享网站导航，但不依赖另一仓库才能使用。

[在线导航与阅读](https://strider002.github.io/math-modeling-library/) · [下载与使用](https://strider002.github.io/math-modeling-library/download.html) · [建模方法库](https://github.com/Strider002/math-modeling-library) · [审查与论文图表](https://github.com/Strider002/math-modeling-review)

## 导航

2026-10-20 · v1.1.0：同步经公开审查的验证与表达规范，新增任务契约/绑定数字审计、PDF 文本审查，并加固只读结果清单复核。见 [交付审计指南](references/规范/交付审计.md)。未把私人知识库整体上传，也未声称完成全部案例复现。

- [这个 Skill 做什么](#这个-skill-做什么)
- [主要内容](#主要内容)
- [下载与使用](#下载与使用)
- [本地预览网站](#本地预览网站)
- [发布与维护边界](#发布与维护边界)

## 这个 Skill 做什么

用于问题拆解、数据审计、模型选择、求解实现、验证与论文交付；按题型和阶段选择所需方法。

- **问题与数据**：拆解目标、约束和输出，检查来源、单位、样本结构、缺失与数据泄漏。
- **模型选择与实现**：覆盖统计回归、预测、评价、优化、机器学习、机理仿真、网络空间及文本/信号/图像任务。
- **验证与不确定性**：设置简单基线、结构匹配的训练外验证，检查约束、误差、敏感性与结论稳定性。
- **论文与交付**：维护可追溯结果、实验记录和交付检查；按实际赛事复查规则。

## 主要内容

| 内容 | 数量或入口 |
|---|---|
| 方法专题 | 41 篇，[阅读导航](references/阅读导航.md) |
| 题型与阶段路由 | 37 条，[路由清单](routing-manifest.yaml) |
| 历史项目复盘 | 10 篇，[项目索引](references/项目经验/项目索引.md) |
| 工程辅助工具 | [工具说明](references/工程工具说明.md) |
| 竞赛规则核对 | [官方规则入口](references/竞赛规则核对.md) |

历史复盘仅作条件案例，不是当前任务的实验结果；不默认加载全库。

本仓库根目录的 [SKILL.md](SKILL.md) 是 Agent 入口；`references/`、`scripts/`、`assets/` 和 `agents/` 为 Skill 资源。`docs/` 与 `web-tools/` 仅用于网站和打包，不是运行 Skill 的前置依赖。

## 下载与使用

从网站的“下载与使用”页面或 [GitHub Releases](https://github.com/Strider002/math-modeling-library/releases) 获取独立 ZIP，解压后保留 `math-modeling-library/SKILL.md` 与完整配套目录。ZIP 不含网站依赖或 Git 历史。使用前核对下载页的 SHA-256。

Codex 可将解压后的完整目录放入项目的 `.agents/skills/`，再在对话中显式调用 `$math-modeling-library`；不要覆盖已有同名 Skill。其他支持 `SKILL.md` 的工具按其官方说明配置，未逐一验证兼容性。参见 [OpenAI 官方技能文档](https://learn.chatgpt.com/docs/build-skills)。

示例：`$math-modeling-library 请先根据题面与数据说明，提出简单基线和训练外验证方案。暂不运行代码。`

PowerShell 辅助工具要求 PowerShell 7；阅读文档与规划任务不要求运行脚本。审查包默认只读，任何执行代码、重算或改稿仍须符合用户授权。

## 本地预览网站

使用 Node.js 22 或更高版本：

```sh
npm ci
npm test
npm run build
npm run preview
```

`npm run build` 只读取 `publication.json` 中显式批准的 Skill 文件，生成网页、下载包及校验信息。添加公开文件时先审查内容，再更新清单；不要让构建程序扫描私人目录。

两个仓库的 `docs/.vitepress/portal.json`、公共主题和构建工具来自同一套发布模板；修改公共导航时应同步到两个仓库。两站均保留完整导航，不要求浏览器从另一个站点加载脚本。

## 发布与维护边界

- 仅包含获准公开的文本、模板、来源元数据与工具；不提供第三方原始论文、数据或图片。
- 未公开成果及其派生内容不得进入仓库、提交历史、网站搜索索引或下载包。
- 不承诺获奖、提高获奖率、模型必然正确或绝对无风险。
- 工程验证不等于重新运行所有案例，也不等于当届赛事合规审查。
- 软件使用 MIT；原创文档使用 CC BY 4.0；第三方材料另受原许可约束，见 [许可证范围](LICENSES.md)。

由 Strider002 维护。
