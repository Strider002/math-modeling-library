# Evidence-Gated Mathematical Modeling Library

English | [简体中文](README.md)

[![Validate library](https://github.com/Strider002/math-modeling-library/actions/workflows/validate.yml/badge.svg)](https://github.com/Strider002/math-modeling-library/actions/workflows/validate.yml)

A mathematical-modeling knowledge base that can be installed as a Codex Skill. It routes each task to the smallest relevant set of methods and covers data auditing, forecasting, evaluation, optimization, statistical learning, mechanistic modeling, simulation, validation, and competition-paper delivery.

The project does not promise that a model is “absolutely correct.” Instead, it requires important claims to remain traceable to data, assumptions, formulas, implementations, validation evidence, and sources. Award-winning papers are treated as case evidence, not as unquestionable authority.

## Highlights

- **Task-aware routing:** `routing-manifest.yaml` is the single machine-readable routing source.
- **Stage gates:** data, model selection, validation design, implementation, audit, and delivery have explicit stop conditions.
- **Evidence levels:** official records, primary research, textbooks, award papers, and community material have different evidentiary roles.
- **Validation first:** complex models require a structure-matched baseline and out-of-training validation.
- **Codex Skill packaging:** `SKILL.md` handles discovery and routing while the maintained topic files remain the only method source.

## Quick start

```powershell
git clone https://github.com/Strider002/math-modeling-library.git
Set-Location math-modeling-library
./tools/route_knowledge.ps1 -ListRoutes
./tools/route_knowledge.ps1 -RouteId regression_general -Stage model_selection,validation_design
```

To install the repository as a Codex Skill, clone it directly into the Codex skills directory or keep it elsewhere and create a directory junction. See the [installation guide](docs/installation.en.md).

After installation, invoke it explicitly with:

```text
Use $math-modeling-library to analyze this modeling task.
```

Matching modeling tasks may also trigger the skill automatically. Isolated arithmetic and simple definitions do not load the full workflow.

## How it works

```text
User task
   ↓
SKILL.md + AGENTS.md + permanent quality core
   ↓
route_knowledge.ps1 resolves task type and stage
   ↓
Minimum required method cards and stage gates
   ↓
Baseline, out-of-training validation, sensitivity, and delivery audit
```

The README is not a routing source. Chinese remains the canonical language for the maintained method cards. See the [architecture guide](docs/architecture.zh-CN.md) and [Chinese knowledge index](docs/INDEX.zh-CN.md) for the full structure.

## Minimum quality contract

1. Never invent data, sources, parameters, formulas, results, rules, or awards.
2. Freeze the estimand, response support, dependence structure, validation unit, and simple baseline before model selection.
3. Audit formulas for definitions, assumptions, dimensions, boundary behavior, and implementation consistency.
4. Keep preprocessing, feature selection, and tuning inside the training boundary.
5. Do not call a heuristic result globally optimal without a proof, bound, or valid certificate.
6. Keep conclusions within the scope of the data, identification assumptions, and out-of-training evidence.

The complete operational rules currently live in Chinese in [00Q_永久质量核心.md](00Q_永久质量核心.md) and [00A_证据与质量门禁.md](00A_证据与质量门禁.md).

## Documentation

- [Installation](docs/installation.en.md)
- [Chinese knowledge index](docs/INDEX.zh-CN.md)
- [Architecture and single source of truth](docs/architecture.zh-CN.md)
- [Maintenance and branch workflow](docs/maintenance.zh-CN.md)
- [Source, copyright, and publication policy](docs/source-policy.zh-CN.md)
- [Contributing](CONTRIBUTING.md) / [中文贡献指南](CONTRIBUTING.zh-CN.md)
- [Security and privacy reporting](SECURITY.md)

## Repository boundary

Git distributes maintained knowledge text, routing definitions, tests, tools, and auditable text records that may be shared. Third-party papers, problem attachments, images, archives, spreadsheets, and web snapshots remain in the local evidence store by default and are not redistributed through GitHub.

## Release status

The repository is still being prepared for a public release. Accessibility must not be interpreted as permission to copy, modify, or redistribute the contents until the license scope has been selected and the strict public-release gate passes.

## Citation and contributions

Citation metadata is available in [CITATION.cff](CITATION.cff). Before contributing, read [CONTRIBUTING.md](CONTRIBUTING.md). Claims about formulas, rules, performance, or awards must include traceable evidence and scope conditions.

## One-line principle

**Define the problem before choosing a model; audit the data before fitting; validate before interpreting.**
