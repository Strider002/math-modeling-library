# 调用架构与单一事实源

本文解释知识库怎样被 Codex Skill 调用，以及哪些文件可以人工维护。它是架构说明，不是第二套路由配置。

## 六层结构

1. **触发层**：`SKILL.md` 描述适用任务、根目录解析与最小启动流程。
2. **永久层**：`AGENTS.md` 与 `00Q_永久质量核心.md` 保存任何正式建模任务都不能跳过的规则。
3. **路由层**：`routing-manifest.yaml` 是唯一手工维护的机器路由；`00B_任务路由与最小读取集.md` 由脚本生成。
4. **方法层**：阶段门禁和专题方法卡提供实际建模知识，只加载当前任务需要的部分。
5. **执行层**：项目状态机、结果冻结、提交审计和基准规范把门禁落实为可执行检查。
6. **证据层**：`sources/` 保存完整台账与原始材料；`evidence/` 保存高风险主张的机械绑定子集。

## 调用流程

```text
识别任务目标、数据结构、响应支持集、当前阶段与风险
                         ↓
             选择最少必要的 RouteId
                         ↓
       route_knowledge.ps1 读取 routing-manifest.yaml
                         ↓
     返回 required / optional / deferred / forbidden
                         ↓
  完整读取 required；按真实触发条件读取 optional
```

示例：

```powershell
./tools/route_knowledge.ps1 -ListRoutes
./tools/route_knowledge.ps1 -RouteId regression_general -Stage model_selection,validation_design
```

## 单一事实源

- 路由事实只修改 `routing-manifest.yaml`。
- `00B_任务路由与最小读取集.md` 是生成视图，不手工改题型映射。
- 每种方法的完整定义只保存在一个主专题；索引和 README 只给链接与使用边界。
- 来源身份以 `sources/来源与证据台账.md` 为当前权威登记。
- `evidence/source_registry.json` 与 `evidence/claims_registry.json` 只登记已迁移的高风险主张，不取代完整来源台账。
- README 面向首次访问者，不承担机器路由功能。

## 阶段门禁

| 阶段 | 进入条件 | 核心检查 |
|---|---|---|
| `data` | 读取、清洗、连接或探索数据前 | 来源、口径、主键、缺失、异常、时间与泄漏 |
| `model_selection` | 选择或拟合模型前 | 目标、响应支持集、依赖结构与简单基线 |
| `validation_design` | 正式比较模型前 | 验证单位、外层划分、主指标与调参边界 |
| `implementation` | 编码、实验或复现前 | 公式—代码一致性、环境、种子与不变量 |
| `validation_audit` | 解释正式结果前 | 训练外证据、残差、敏感性、压力测试与不确定性 |
| `delivery` | 提交报告或论文前 | 数字追溯、引用、局限、格式与提交规则 |

## 为什么暂不移动编号文件

当前方法卡路径被清单、脚本、测试和文档交叉引用。把几十个编号文件直接移入子目录会造成大范围路径迁移，并可能破坏本机 Skill。公开准备阶段先通过 README 和 `docs/` 改善导航；若以后迁移目录，应单独建立分支，更新清单和全部引用，并运行路由生成、黄金测试与全库验证。

## 相关入口

- [知识库总索引](INDEX.zh-CN.md)
- [安装说明](installation.zh-CN.md)
- [维护与分支流程](maintenance.zh-CN.md)
- [来源与公开政策](source-policy.zh-CN.md)
