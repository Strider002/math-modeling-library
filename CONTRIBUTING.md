# Contributing

[中文贡献指南](CONTRIBUTING.zh-CN.md)

Contributions are welcome when they improve traceability, correctness, reproducibility, or navigation without weakening the evidence gates.

## Before you start

1. Read `AGENTS.md` and `00Q_永久质量核心.md`.
2. Run the `knowledge_maintenance` route and read every required file.
3. Keep third-party papers, datasets, archives, and unlicensed code out of Git.
4. Open an issue first when a change would alter routing, rename canonical files, or affect many cross-references.

## Branches

Create a short-lived branch from `main`:

- `使用文档/<topic>` for documentation;
- `i18n/<topic>` for translations;
- `feature/<topic>` for new capability;
- `fix/<topic>` for corrections;
- `ci/<topic>` for validation automation;
- `chore/<topic>` for repository maintenance.

Do not maintain separate Chinese and English branches. Language versions belong in the same release.

## Evidence requirements

- Do not invent data, formulas, parameters, results, rules, or award identities.
- Bind important claims to a traceable source, exact location, version, scope, and verification status.
- Treat award papers as case evidence. Independently verify formulas, assumptions, and software behavior.
- Mark unresolved material as `待核验` and keep it out of normative method guidance.
- Include a structure-matched baseline and out-of-training validation for performance claims.
- Do not claim global optimality for a heuristic without proof, a bound, or a valid certificate.

## Documentation and translation

Chinese topic files are currently canonical. An English translation must link to its Chinese source, preserve limitations, and avoid adding unsupported claims. Update both languages in the same pull request when shared semantics change.

## Validation

Run before opening a pull request:

```powershell
./tools/validate_library.ps1
./tools/validate_github_release.ps1
```

Use portable mode in a clean clone without the local evidence store:

```powershell
./tools/validate_library.ps1 -Portable
```

If routing, the manifest, a generated routing view, or an entry protocol changes, also run in order:

```powershell
./tools/generate_routing_docs.ps1
./tools/test_routing.ps1
./tools/validate_library.ps1
```

## Pull requests

Describe the problem, changed files, evidence, validation commands, remaining uncertainty, and public-distribution impact. A passing mechanical check does not prove mathematical correctness.

By contributing, you confirm that you have the right to submit the material. Unless agreed otherwise before submission, software contributions are offered under MIT and original documentation contributions under CC BY 4.0; see [LICENSES.md](LICENSES.md).
