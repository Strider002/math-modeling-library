# 严谨数学建模知识库（Evidence-Gated Mathematical Modeling Library）

[English](README.en.md) | 简体中文

[![Validate library](https://github.com/Strider002/math-modeling-library/actions/workflows/validate.yml/badge.svg)](https://github.com/Strider002/math-modeling-library/actions/workflows/validate.yml)

代码：[MIT](LICENSE) · 原创文档：[CC BY 4.0](LICENSE-DOCS) · [许可证范围](LICENSES.md)

一个可作为 Codex Skill 使用的、带证据门禁的数学建模知识库。它按任务和阶段只加载必要方法，覆盖数据审计、预测、评价、优化、统计学习、机理建模、仿真、验证与竞赛论文交付。

本项目不承诺“模型绝对正确”。它要求每个重要结论都能追溯到数据、假设、公式、实现、验证和来源，并把获奖论文视为案例证据，而不是无需复核的权威答案。

## 核心特点（Highlights）

- **按需路由**：`routing-manifest.yaml` 是唯一机器路由事实源，避免每次加载整个知识库。
- **阶段门禁**：数据、选模、验证设计、实现、审计和交付各有明确停止条件。
- **证据分级**：官方资料、原始论文、教材、获奖论文与社区资料承担不同证据角色。
- **验证优先**：复杂模型必须有结构匹配的简单基线和训练外验证。
- **工程闭环**：项目状态、产物哈希、PDF 匿名审计和本地审阅包都有可执行工具。
- **证据绑定试点**：七条高风险规则/公式主张已绑定正文位置和来源注册表，并由校验器检查。
- **可作为 Skill 安装**：`SKILL.md` 负责触发和路由，专题正文仍是唯一知识源。

## 快速开始（Quick Start）

### 直接查看路由（Inspect Routes）

```powershell
git clone https://github.com/Strider002/math-modeling-library.git
Set-Location math-modeling-library
./tools/route_knowledge.ps1 -ListRoutes
./tools/route_knowledge.ps1 -RouteId regression_general -Stage model_selection,validation_design
```

### 安装为 Codex Skill（Install as a Codex Skill）

可以把仓库直接克隆到 Codex skills 目录，或者保留在独立位置并创建目录联接。完整步骤见[安装说明](使用文档/installation.zh-CN.md)。安装后可显式调用：

```text
Use $math-modeling-library to analyze this modeling task.
```

符合描述的数学建模任务也可自动触发；简单算术或孤立定义不会加载完整建模流程。

### 初始化一项完整竞赛工程（Initialize a Competition Project）

```powershell
./tools/new_modeling_project.ps1 -Path D:\work\case01 -Contest CUMCM -Problem C
./tools/modeling_stage.ps1 -ProjectRoot D:\work\case01 -Action Status
```

结果冻结、PDF 检查、匿名扫描和审阅包命令见[竞赛工程工作流](使用文档/engineering-workflow.zh-CN.md)。

## 工作方式（How It Works）

```text
用户任务
   ↓
SKILL.md + AGENTS.md + 00Q 永久质量核心
   ↓
route_knowledge.ps1 解析任务类型与阶段
   ↓
最小 required 方法卡与阶段门禁
   ↓
基线、训练外验证、敏感性与交付审计
```

机器调用不以 README 作为路由事实源。详细架构见[调用架构](使用文档/architecture.zh-CN.md)，完整文件导航见[知识库索引](使用文档/INDEX.zh-CN.md)。

## 目录结构（Repository Layout）

```text
知识库/
├─ 基础方法/       01—19 基础方法与竞赛工作流
├─ 进阶方法/       22—40 进阶标准与严谨方法卡
└─ 竞赛论文/       国赛与美赛优秀论文案例方法论
模板/               可复用的消化、复盘与 AI 使用模板
复盘记录/           按日期保存的任务级复盘
使用文档/           安装、架构、维护和中英文工作流
质量审计/           质量审计报告与历史基线
证据注册/           已迁移高风险主张的结构化证据绑定
来源资料/           来源台账与本地证据区
基准评测/           历年赛题评测规范与盲评分表
tools/ + tests/      路由、验证、交付工具及回归测试
```

根目录只保留 Skill 入口、路由与质量门禁、项目说明、许可证和协作文件。

## 最小质量协议（Minimum Quality Contract）

1. 不编造数据、来源、参数、公式、实验结果、规则或奖项。
2. 先冻结任务目标、响应支持集、依赖结构、验证单位和简单基线。
3. 公式检查定义、成立条件、量纲、边界和代码一致性。
4. 数据变换、特征筛选和调参不能越过训练/验证边界。
5. 启发式结果没有证明、界或证书时，不称为全局最优。
6. 结论强度不超过数据、识别假设和训练外证据。

完整红线见[永久质量核心](00Q_永久质量核心.md)与[证据门禁](00A_证据与质量门禁.md)。

## 文档导航（Documentation）

- [完整知识库索引](使用文档/INDEX.zh-CN.md)
- [调用架构与单一事实源](使用文档/architecture.zh-CN.md)
- [安装为 Codex Skill](使用文档/installation.zh-CN.md)
- [竞赛工程工作流](使用文档/engineering-workflow.zh-CN.md)
- [知识维护与分支流程](使用文档/maintenance.zh-CN.md)
- [来源、版权与公开边界](使用文档/source-policy.zh-CN.md)
- [中文贡献指南](CONTRIBUTING.zh-CN.md) / [English contribution guide](CONTRIBUTING.md)
- [安全与隐私报告](SECURITY.md)

## 仓库边界（Repository Boundary）

Git 只分发原创或允许公开的知识正文、路由、测试、工具和可审计文本记录。第三方论文全文、题目附件、图片、压缩包、数据表和网页快照默认只保留在本地证据库，不通过 GitHub 再分发。详细规则见[来源与公开政策](使用文档/source-policy.zh-CN.md)。

## 引用与贡献（Citation and Contributions）

引用元数据见 [CITATION.cff](CITATION.cff)。贡献前请阅读[贡献指南](CONTRIBUTING.zh-CN.md)，任何公式、规则、性能或获奖事实都必须绑定可核验来源与适用条件。

## 一句话准则（One-Line Principle）

**先定义问题，再检查数据；先做基线，再加复杂度；先核验来源与公式，再解释结果。**
