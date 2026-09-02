# Security and Privacy / 安全与隐私

## Report privately

Do not open a public issue for exposed credentials, private datasets, personal information, malicious external code, or a path that accidentally redistributes restricted source material. Use GitHub's private vulnerability-reporting entry when it is available. If it is unavailable, contact the repository owner privately through the GitHub account before disclosing details.

请勿在公开 Issue 中提交密钥、访问令牌、私人数据、个人信息、恶意外部代码，或可能造成受限原文再分发的路径。优先使用 GitHub 的私密漏洞报告入口；入口不可用时，先通过仓库所有者的 GitHub 账号私下联系。

## Include

- the affected file and revision;
- the minimum reproduction steps;
- the potential impact;
- whether a secret has already been revoked;
- a redacted example when possible.

报告应包含受影响文件与版本、最小复现步骤、潜在影响、密钥是否已经撤销，并尽可能使用脱敏示例。

## Scope

Security reports include credential exposure, unsafe execution paths, dependency-install behavior, destructive file operations, privacy leaks, and distribution of material that should remain in the local evidence store. Ordinary mathematical corrections should use an Issue or Pull Request and follow the evidence policy.

安全范围包括凭据暴露、不安全执行路径、依赖安装行为、破坏性文件操作、隐私泄露，以及本应留在本地证据区的材料被错误分发。普通数学纠错应通过 Issue 或 Pull Request，并遵守证据门禁。
