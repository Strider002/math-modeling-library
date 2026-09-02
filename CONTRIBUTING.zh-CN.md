# 中文贡献指南

[English](CONTRIBUTING.md)

欢迎能够提高可追溯性、正确性、可复现性或导航质量，并且不削弱证据门禁的贡献。

## 开始前

1. 阅读 `AGENTS.md` 与 `00Q_永久质量核心.md`。
2. 运行 `knowledge_maintenance` 路由并完整读取 required 文件。
3. 不要把第三方论文、数据包、压缩包或许可证不明的代码提交到 Git。
4. 若要修改路由、重命名规范文件或影响大量交叉引用，先创建 Issue 说明迁移范围。

## 分支

从 `main` 创建短期分支：

- `docs/<topic>`：文档；
- `i18n/<topic>`：翻译；
- `feature/<topic>`：新能力；
- `fix/<topic>`：纠错；
- `ci/<topic>`：自动验证；
- `chore/<topic>`：仓库维护。

不要维护独立的中文、英文长期分支；语言版本属于同一发布版本。

## 证据要求

- 不编造数据、公式、参数、结果、规则或奖项身份。
- 重要主张绑定来源、精确定位、版本、适用条件和核验状态。
- 获奖论文只作案例；公式、条件和软件行为需要独立核验。
- 未决内容标为“待核验”，不得写入规范性方法结论。
- 性能主张必须有结构匹配的基线与训练外验证。
- 启发式没有证明、界或有效证书时，不称为全局最优。

## 文档与翻译

中文专题是当前规范性正文。英文翻译必须链接中文原文、保留限制条件，不得增加原文没有证据支持的结论。共享语义变化时应在同一 Pull Request 更新两种语言。

## 验证

```powershell
./tools/validate_library.ps1
./tools/validate_github_release.ps1
```

不含本机证据原件的干净克隆使用：

```powershell
./tools/validate_library.ps1 -Portable
```

路由清单、脚本、生成视图或入口协议变化时，还要依次运行：

```powershell
./tools/generate_routing_docs.ps1
./tools/test_routing.ps1
./tools/validate_library.ps1
```

## Pull Request

说明问题、变更文件、证据、验证命令、剩余不确定性和公开分发影响。机械检查通过不等于数学结论已经被证明。

提交贡献表示你确认有权提供相关内容。除非提交前另有约定，软件贡献使用 MIT，原创文档贡献使用 CC BY 4.0；具体范围见 [LICENSES.md](LICENSES.md)。
