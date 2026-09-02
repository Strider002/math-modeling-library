# 安装为 Codex Skill

仓库根目录本身就是 `math-modeling-library` Skill，不需要复制第二份方法正文。

## 方式一：直接克隆到 skills 目录

适合只在 Codex 中维护和使用该仓库：

```powershell
$skillPath = Join-Path $env:USERPROFILE '.codex\skills\math-modeling-library'
git clone https://github.com/Strider002/math-modeling-library.git $skillPath
```

如果目标目录已经存在，先检查它是否包含未提交内容；不要直接覆盖。

## 方式二：独立仓库加目录联接

适合把知识库保存在独立磁盘，同时让 Codex 只维护一个事实源：

```powershell
$repoPath = 'D:\数学建模\library'
$skillPath = Join-Path $env:USERPROFILE '.codex\skills\math-modeling-library'
New-Item -ItemType Junction -Path $skillPath -Target $repoPath
```

创建前确认 `$skillPath` 不存在。目录联接删除时只删除联接本身，不删除目标知识库。

## 安装检查

```powershell
Get-Content -LiteralPath (Join-Path $skillPath 'SKILL.md') -TotalCount 8
& (Join-Path $skillPath 'tools\route_knowledge.ps1') -ListRoutes
```

然后在 Codex 中显式测试：

```text
Use $math-modeling-library to identify the minimum route for a time-series forecasting task.
```

## 更新

如果是直接克隆或联接到 Git 仓库，在仓库工作区确认没有未提交冲突后执行：

```powershell
git -C $repoPath pull --ff-only
```

更新后运行：

```powershell
& (Join-Path $repoPath 'tools\validate_library.ps1') -LibraryRoot $repoPath
```

## 卸载

若使用目录联接，只删除准确的联接路径。删除前用 `Get-Item` 确认 `LinkType` 为 `Junction`；不要对目标知识库执行递归删除。

## 适用边界

- Skill 会自动匹配建模、预测、优化、评价、仿真、数据分析和竞赛交付任务。
- 简单计算或单个定义只读取最小必要内容。
- 知识库默认只读；只有用户明确授权维护时才允许写入。
- 原始论文和外部代码不会因为存在于本地 `sources/` 就自动成为可信依据。
