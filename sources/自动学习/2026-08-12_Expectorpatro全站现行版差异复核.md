# Expectorpatro/math 全站现行版差异复核

> 日期：2026-08-12  
> 固定提交：`df67be9e166221776f96883a5f2cd42df2a73f49`  
> 基线：`71cd56e942c4cb4f4418ea1dce77a17e6b58a455`  
> 用途：说明本轮相对旧知识库审计究竟更新了什么，不冒充全站数学正确性证明。

## 1. 完整性证据

- 官方归档：422 文件、43,107,762 bytes；ZIP SHA-256
  `947953B46939AEB2CFB5C4CF63EF7FC01426D36CDCFDE95DC300D71587FD8E8A`。
- 186 个 UTF-8 文本文件机械读取：2,690,769 bytes、2,261,697 Unicode 字符、57,862 行，
  UTF-8 解码错误 0。
- 正则机械清点（只反映环境标记，不代表语义数量）：definition 584、theorem 291、property 205、
  lemma 40、corollary 20、proof 533、algorithm 25、公式环境 3,729、figure 29、input 114、URL 27、
  TODO/unsure/change/improvement 类标记 126。
- sitemap 52 个 URL 全部成功；52 个页面与提交构建物逐字节相同，共 15,915,663 bytes。
- 完整发布目录证据及 121 个公开文件清单哈希见
  `2026-08-12_Expectorpatro全站独立版本核验.md`。

因此可以声称“现行站点与该提交逐字节锁定且文本文件全部进入机械清单”，不能声称“人工逐字证明
所有公式和证明正确”。数学结论仍由专题方法卡的独立来源与复算控制。

## 2. 旧审计后的内容提交

从基线到现行版共有 5 个内容提交，集中于：

1. 凸优化新增梯度下降；
2. 线性模型大幅重写并新增/重做计算实验；
3. 机器学习新增模型训练章、树模型正文和两个树模型实验；
4. 神经网络大幅重写；
5. PCA 大幅重写，聚类、因子分析、点估计及少量数学基础有局部修改。

没有发生实质改动的章节继续沿用 2026-07-30 全章审计；发生改动的正文重新定位风险，不把旧源码行号
或旧错误自动套到现行版。

## 3. 本轮语义结论

### 3.1 已修正，不再算现行错误

- PCA 变量表示质量分母已改为被解释变量方差；
- 85% 累计贡献率已明确为经验规则；
- 增加最大保留方差/最小平均平方重构误差定理及证明；
- 增加 SVD、平行分析、验证选维、PCR 偏差—方差、零/重特征值边界；
- 树模型旧版 `FindBestSplit` 最优赋值方向问题已修复；
- 神经网络更早版本的 sigmoid 范围和 LSTM cell state 原文问题已按专项记录撤销。

### 3.2 现行版仍需隔离

- 线性模型仍把 VIF 直接定义为 `(X'X)^(-1)` 对角元，仍给未说明尺度/矩阵的 100/1000 条件数
  固定分级，仍以 `max` 写 Hoerl--Kennard 候选，GLM 统一式仍混淆工作响应与参数增量；
- 因子分析、NMF、CCA 与判别的维数/符号/自由度风险仍按 `28` 隔离；
- 聚类的算法/指标适用边界仍按 `26`，不能以计算实验图形代替稳定性与外部验证；
- 模型训练章的随机划分与普通 K 折不适用于时间、空间、主体或重叠窗口数据；
- 树模型 OOB、相关 Bagging、特征重要性与 XGBoost 版本语义风险仍按 `31`；
- 神经网络当前公式/伪代码冲突和卷积/池化边界仍按 `32` 与 2026-08-09 专项记录；
- EM 网页是抽象变分/坐标上升讲解，支持条件、GEM、GMM 退化、停止与验证以 `33` 为准。

## 4. 现行关键源码哈希

| 源码 | SHA-256 |
|---|---|
| `statistics/Linear-model/linear-model.tex` | `CC77F72F5B4C73F2C3ECDAA42DB19F31DC55F5FBA17084F94A5991052F2F5A1B` |
| `statistics/Linear-model/linear-regression.tex` | `9C1814C8CBB21CF3C1CC57106A3C1AFA3C2A1C1ED6C7F66545AE4819F2312956` |
| `statistics/Linear-model/logistic.tex` | `AC32D683DCA16D1C6138C5E35F0EF51AAE3F053867AC1F24C8915EED27560F2A` |
| `statistics/multivariate/pca.tex` | `8F1F9A678F3A2E00F93127ACBF016903E57519AD04D5EF2938C7829A8F98E8DD` |
| `statistics/multivariate/fa.tex` | `C5ADBFB985425DADB080AFD065D58E0416A323410505D55DC57DE71AFEBDECA7` |
| `statistics/multivariate/cluster.tex` | `82DC954D4134C195AF45C8CF1B6B1B546032EC5EAD015D5D6E5DB877A1974F1A` |
| `statistics/machine-learning/training.tex` | `02BA7D9B5C90F0DD0B1222933A8679AF54BA9662C373C044E3DDC2AC0D864B92` |
| `statistics/machine-learning/tree.tex` | `2DDD90B13DFDEBCEBCB72471D42343764D5549B7A4C6CDA5599D5C1AD5F3C8CB` |
| `statistics/machine-learning/nn.tex` | `2981D7EC4A2F598A2B4DE0798AE1423821FF17228479386454B7B6346BD04577` |
| `statistics/statistical-computing/main.tex` | `2DAC885C844761FA0A8C107578212D7C34CAECF2E48DF8FBCE4C6301F3EBA00F` |

## 5. 知识库写回

- 更新 `knowledge/advanced/30_Expectorpatro全站知识映射与使用边界.md` 的版本、覆盖证据和现行/历史问题状态；
- 修正 `knowledge/advanced/27_主成分分析严谨方法卡.md` 中 PCA 分母问题的时态；
- 在 `knowledge/advanced/32_神经网络严谨方法卡.md` 登记独立 `gru.py` 的禁止直接复用边界；
- 新增 `2026-08-12_gru附件代码审计.md`；
- 保留 `knowledge/advanced/33_EM算法与潜变量模型严谨方法卡.md` 的原审计结论，因为用户附件与此前审计副本字节相同。
