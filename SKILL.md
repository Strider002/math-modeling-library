---
name: math-modeling-library
description: Use for mathematical modeling, modeling competitions, data analysis, prediction, optimization, evaluation, simulation, modeling-paper delivery, or maintenance of the evidence-gated mathematical-modeling knowledge base. Do not use for isolated elementary calculations or definitions that do not need model selection, data work, validation, implementation, or knowledge-base maintenance.
---

# Mathematical Modeling Library

Use the maintained knowledge base as the only source of local modeling guidance. Do not copy method content into this file.

## Resolve the knowledge root

Set `KB_ROOT` to the directory containing this `SKILL.md` when that directory also contains `routing-manifest.yaml`. On this computer, if the installed skill is only a launcher, use `D:\数学建模\library`.

If the root, required files, or routing scripts are unavailable, state what is missing and its impact. Do not reconstruct local rules from memory.

## Start a task

1. Read [the library instructions](AGENTS.md) and [the permanent quality core](00Q_永久质量核心.md) completely.
2. If the route is unclear, run `KB_ROOT\tools\route_knowledge.ps1 -ListRoutes`.
3. Select the smallest applicable route IDs and current stages from the task goal, data structure, response support, and risk. Run:

   ```powershell
   & "$KB_ROOT\tools\route_knowledge.ps1" -RouteId <id...> -Stage <stage...>
   ```

4. Read every returned `required` file completely. Read `optional` files only when their stated condition applies. Do not preload `deferred` or `forbidden` resources.
5. At the start of substantive work, briefly report the files read, route IDs, and current stage.

For a definition or one isolated formula that does not require data, model selection, computation, implementation, or a conclusion, read the permanent quality core and only the directly relevant topic file.

For sensitivity analysis, uncertainty propagation, bootstrap stability, algorithmic stability, clustering stability, or conclusion-flip diagnostics, use route sensitivity_analysis with stage validation_audit. Add implementation when code or repeated experiments are requested. The route's method card defines the perturbation object, dependence-preserving resampling unit, full-pipeline reruns, reporting distribution, and failure criteria; do not replace it with a generic plus/minus percentage sweep.

## Respect stage gates

- Before reading, cleaning, joining, exploring, or engineering data, enter `data`.
- Before selecting or fitting models, enter `model_selection` and `validation_design`.
- Before coding, experiments, or reproduction, enter `implementation`.
- Before formal model comparison, interpretation, or conclusions, enter `validation_audit`.
- Before delivering a paper, report, code package, or competition submission, enter `delivery` or `code_delivery` as applicable.

Do not bypass a gate to save context.

## Execute an end-to-end competition project

When the user asks to build or deliver a complete project, use the repository tools instead of tracking stages only in prose:

1. Initialize with `tools\new_modeling_project.ps1` and inspect `project-state.json`.
2. Use `tools\modeling_stage.ps1 -Action Check` before each stage transition; do not treat file presence as scientific validation.
3. Before paper numbers are finalized, use `tools\freeze_results.ps1`; verify the manifest again before packaging.
4. Audit the PDF with `tools\validate_submission.ps1`. Keep the private anonymity denylist outside the public repository.
5. Build a local review bundle with `tools\build_submission.ps1` only after result verification and PDF validation pass. Follow current competition rules for the actual upload format.

Use `benchmarks\manifest.json` only as a fixed evaluation specification. Its current `specification_only` status is not evidence that the Skill improves award outcomes.

### Apply the CUMCM AI-use delivery gate

For a CUMCM paper or support-material delivery, recheck the current official AI-use rule before packaging and read the CUMCM sections in `12_论文写作与可视化.md` and `13_竞赛工作流与检查清单.md`. Determine `NotUsed` or `Used` from the team's actual process; do not infer, conceal, or reconstruct a false history.

For the 2026 trial rule, place the applicable official declaration before the references. If AI was used, require a support PDF named exactly `AI工具使用详情.pdf`, use `AI工具使用详情模板.md` as a truthful drafting aid, and keep the team's manual review and verification evidence. Call `tools\validate_submission.ps1` with `-CumcmAiUse NotUsed`, or with `-CumcmAiUse Used -AiDetailsPath <path>` as applicable. The mechanical check does not prove the declaration is truthful or the human verification adequate.

## Maintain the knowledge base

Treat the library as read-only unless the user explicitly authorizes an update. Before any update, use route `knowledge_maintenance` and read all required resources. Preserve original evidence, update `CHANGELOG.md`, and run `tools\validate_library.ps1`. If routing or entry protocols change, also regenerate routing documentation and run the golden routing tests in the order required by `AGENTS.md`.

Enter `sources\` only for an exact evidence trace, dynamic-fact check, or reproduction task. Award papers and third-party repositories are cases or leads, not automatic authority.

For claims already migrated into `evidence\claims_registry.json`, preserve the claim ID, registered source locator, document location, and matching `` `source:...` `` marker. The registries are a validated subset, not a replacement for `sources\来源与证据台账.md`.

### Learn from completed projects

When the user explicitly asks to preserve a modeling retrospective, separate three layers:

1. Put task-specific numbers, artifacts, failures, and unresolved issues in one dated retrospective based on `建模复盘模板.md`.
2. Promote only cross-task workflow lessons into the relevant library topic; do not turn one dataset's thresholds, model choice, or metric differences into universal guidance.
3. Change this launcher only when invocation, routing, maintenance, or stopping behavior should change; do not copy the retrospective or method content into the skill.

For multi-step competition projects, route the work toward one canonical workspace, one current run manifest, and one machine-readable result registry. After an end-to-end solution has passed out-of-training validation and its main invariants, distinguish correctness blockers from optional evidence or presentation improvements. If repeated “final” revisions keep exposing conflicts, audit the single source of truth and artifact pipeline before expanding the model.

## Non-negotiable quality rules

- Never invent data, sources, formulas, parameters, thresholds, results, awards, or citations.
- Mark unresolved claims as `待核验` and keep conclusions within the verified scope.
- Check formulas for definitions, conditions, dimensions, boundary behavior, and implementation consistency.
- Require a structure-matched simple baseline and an out-of-training validation design.
- Do not call a heuristic or numerical result globally optimal without a proof, bound, or valid optimality certificate.
- Keep raw problem statements, data, PDFs, web snapshots, and external code read-only and traceable by source, version, access time, and hash.
