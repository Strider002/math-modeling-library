# Competition Engineering Workflow

This toolchain turns stage gates into checkable project state, artifact hashes, and submission audits. It verifies mechanical completeness and immutability; it does not decide whether a model is scientifically valid or promise an award.

## Project state

```powershell
./tools/new_modeling_project.ps1 -Path D:\work\case01 -Contest CUMCM -Problem C
./tools/modeling_stage.ps1 -ProjectRoot D:\work\case01 -Action Status
```

The state file tracks seven stages from problem definition through submission. `Advance` fails while required artifacts are missing.

## Freeze and verify results

```powershell
./tools/freeze_results.ps1 -ProjectRoot D:\work\case01 -Paths results/metrics.csv,results/figure01.png
./tools/freeze_results.ps1 -ProjectRoot D:\work\case01 -Verify
```

The manifest records relative paths, byte counts, SHA-256 hashes, timestamps, and a Git commit when available. Any later artifact change causes verification to fail.

## Audit and build a review package

```powershell
./tools/validate_submission.ps1 -PaperPath D:\work\case01\paper\solution.pdf -Profile CUMCM -DenyListPath D:\work\private-denylist.txt -RequireTextExtraction
./tools/build_submission.ps1 -ProjectRoot D:\work\case01 -PaperPath D:\work\case01\paper\solution.pdf -Profile CUMCM
```

Keep the private denylist outside the public repository. Text extraction requires `pdftotext`; page counting uses `pdfinfo`. The generated ZIP is a local review bundle, not a claim about the official upload format.

## Evidence and benchmarks

The evidence registries pilot mechanical binding for seven high-risk claims. The benchmark manifest fixes five historical case specifications and a blind rubric, but no paired end-to-end experiment has been run. The repository therefore makes no competition-effect claim.

## Verify

```powershell
./tests/run_engineering_tests.ps1
./tools/test_routing.ps1
./tools/validate_library.ps1 -Portable
./tools/validate_github_release.ps1 -PublicRelease
```

