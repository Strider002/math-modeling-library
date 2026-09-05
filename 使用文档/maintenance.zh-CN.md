# 知识维护、分支与发布流程

本文面向知识库维护者。建模任务仍应通过路由脚本选择最小知识集合。

## 分支约定

`main` 是唯一长期分支，必须保持可安装、可路由、可验证。中文和英文是同一版本中的文件，不使用长期语言分支。

短期分支按目的命名：

- `使用文档/<topic>`：README、索引和说明文档；
- `i18n/<topic>`：翻译与语言同步；
- `feature/<topic>`：新增方法、工具或能力；
- `fix/<topic>`：纠错；
- `ci/<topic>`：自动验证；
- `chore/<topic>`：发布、依赖和仓库维护。

短期分支通过 Pull Request 合并，合并后删除。个人维护阶段不保留长期 `dev`；只有确有独立发布节奏时再引入 release 分支。`gh-pages` 仅用于未来的静态文档站。

## 修改流程

1. 明确修改范围，并确认知识库写入已获授权。
2. 读取 `AGENTS.md`、`00Q_永久质量核心.md`，运行 `knowledge_maintenance` 路由。
3. 完整读取路由返回的 required 文件；外部证据只按精确目标读取。
4. 在短期分支中修改，不覆盖原始资料。
5. 更新 `CHANGELOG.md`，说明原因、证据、验证和影响范围。
6. 运行全库、Skill 与 GitHub 分发检查。
7. 检查差异，只提交本任务文件。
8. 推送并通过 Pull Request 合并。

## 验证命令

```powershell
./tools/validate_library.ps1
./tools/validate_github_release.ps1
```

在不含本机外部原件的干净克隆或 CI 中：

```powershell
./tools/validate_library.ps1 -Portable
```

计划把仓库切成公开前必须执行严格检查：

```powershell
./tools/validate_github_release.ps1 -PublicRelease
```

严格检查失败时不能公开。机械检查通过只证明当前规则覆盖范围内的结构与分发边界一致，不证明每个数学结论绝对正确。

## 路由变更

若修改 `routing-manifest.yaml`、路由脚本、生成视图或入口协议，按顺序执行：

```powershell
./tools/generate_routing_docs.ps1
./tools/test_routing.ps1
./tools/validate_library.ps1
```

只修改 README、贡献说明或普通专题正文时，不重新生成未变化的路由视图。

## 翻译同步

中文专题是当前规范性正文。英文入口应：

- 链接到对应中文原文；
- 不自行扩写中文原文没有的结论；
- 在语义变化时与中文版本同一 PR 更新；
- 尚未翻译的文件明确链接中文原文，不伪装成完整英文覆盖。

## 发布顺序

1. README 与文档导航稳定；
2. 中英文入口可用；
3. 贡献、安全、引用与 CI 文件齐全；
4. 第三方版权、个人信息、密钥和大文件检查通过；
5. 许可证范围由仓库所有者明确选择；
6. `-PublicRelease` 严格检查通过；
7. 创建版本标签，再更改仓库可见性；
8. 公开后配置 `main` ruleset，至少阻止删除和强推，并要求验证状态通过。

## 停止条件

出现许可证未定、第三方内容权限不明、敏感信息、验证失败、引用冲突或分支差异包含无关文件时，停止发布，不以 README 声明代替问题解决。
