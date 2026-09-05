# 竞赛工程工作流

本工具链把知识库的阶段门禁落实为可检查的项目状态、文件哈希和提交审计。它检查“产物是否存在且未被悄悄改变”，不能自动判断模型是否科学，也不能承诺奖项。

## 1. 初始化项目

```powershell
./tools/new_modeling_project.ps1 -Path D:\work\case01 -Contest CUMCM -Problem C
./tools/modeling_stage.ps1 -ProjectRoot D:\work\case01 -Action Status
```

项目包含 `problem → data → model_selection → implementation → validation → paper → submission` 七阶段。每阶段所需产物写入 `project-state.json`；只有当前阶段文件齐全时才能 `-Action Advance`。这只是机械完整性门禁，仍须按 Skill 路由读取对应方法和质量规则。

## 2. 冻结结果

```powershell
./tools/freeze_results.ps1 -ProjectRoot D:\work\case01 -Paths results/metrics.csv,results/figure01.png
./tools/freeze_results.ps1 -ProjectRoot D:\work\case01 -Verify
```

清单记录相对路径、字节数、SHA-256、修改时间和可得的 Git commit。表格、图片或模型输出变化后验证会失败；需要重算时应重新运行实验、审查差异并显式重新冻结，不能手改论文数字绕过。

## 3. PDF 与提交审计

```powershell
./tools/validate_submission.ps1 -PaperPath D:\work\case01\paper\solution.pdf -Profile CUMCM -CumcmAiUse NotUsed -DenyListPath D:\work\private-denylist.txt -RequireTextExtraction
./tools/build_submission.ps1 -ProjectRoot D:\work\case01 -PaperPath D:\work\case01\paper\solution.pdf -Profile CUMCM -CumcmAiUse NotUsed -DenyListPath D:\work\private-denylist.txt
```

匿名词表应保存在项目外或私有工作区，每行一个不得出现的姓名、学校、赛区或账号。若使用了 AI，
把 `-CumcmAiUse NotUsed` 改为 `-CumcmAiUse Used -AiDetailsPath D:\work\case01\AI工具使用详情.pdf`；
详情可按 [AI 工具使用详情模板](../模板/AI工具使用详情模板.md) 整理。校验器会检查使用状态、详情文件名和
PDF 文件头，但不能证明声明真实或人工核验充分。`-RequireTextExtraction` 在没有 `pdftotext` 时会
失败关闭。页数检查依赖 `pdfinfo`；脚本会明确报告未执行的检查。生成的 ZIP 是本地审阅包，不等同于
赛事上传格式；国赛和美赛仍分别遵循当年官方规则。

## 4. 证据绑定

- `来源资料/来源与证据台账.md`：完整来源 ID 台账。
- `证据注册/source_registry.json`：首批机械校验来源子集。
- `证据注册/claims_registry.json`：高风险主张、正文位置、来源定位和复核日期。
- 正文使用反引号包裹的 `source:` 前缀与真实台账 ID；示例前缀和占位 ID 在此刻意分开，避免被校验器误认为正式引用。

当前只迁移七条高风险主张，不代表全库已经逐公式绑定。扩展时先加入台账，再加来源注册、主张注册和正文标记，最后运行全库校验。

## 5. 历史赛题基准

`基准评测/manifest.json` 固定五个案例、基线和产物契约，`基准评测/evaluation-rubric.json` 固定双盲评分维度。仓库不分发题面和附件；只有合法下载、锁定输入哈希、完成 Skill/对照双组解答并由至少两名盲评者评分后，才可报告效果。当前状态是 `specification_only`。

## 6. 验证命令

```powershell
./tests/run_engineering_tests.ps1
./tools/generate_routing_docs.ps1 -Check
./tools/test_routing.ps1
./tools/validate_library.ps1 -Portable
./tools/validate_github_release.ps1 -PublicRelease
```
