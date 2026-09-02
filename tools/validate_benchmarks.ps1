[CmdletBinding()]
param(
    [string]$LibraryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ManifestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $LibraryRoot).Path
if ([string]::IsNullOrWhiteSpace($ManifestPath)) { $ManifestPath = Join-Path $root 'benchmarks\manifest.json' }
$manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$errors = [System.Collections.Generic.List[string]]::new()
if ([string]$manifest.status -ne 'specification_only') { $errors.Add('BENCHMARK_STATUS must_be_specification_only_until_executed_results_exist') }
$cases = @($manifest.cases)
if ($cases.Count -lt 3 -or $cases.Count -gt 5) { $errors.Add("BENCHMARK_CASE_COUNT actual=$($cases.Count)") }
foreach ($duplicate in @($cases.id | Group-Object | Where-Object { $_.Count -gt 1 })) { $errors.Add("BENCHMARK_DUPLICATE id=$($duplicate.Name)") }

$ledgerPath = Join-Path $root 'sources\来源与证据台账.md'
$ledgerText = Get-Content -LiteralPath $ledgerPath -Raw -Encoding UTF8
foreach ($case in $cases) {
    foreach ($field in @('id','contest','problem','title','official_source_id','task_type')) {
        if ([string]::IsNullOrWhiteSpace([string]$case.$field)) { $errors.Add("BENCHMARK_FIELD_MISSING case=$($case.id) field=$field") }
    }
    if (@($case.baseline_requirements).Count -eq 0) { $errors.Add("BENCHMARK_BASELINE_MISSING case=$($case.id)") }
    $sourceId = [string]$case.official_source_id
    if ($ledgerText -notmatch ('(?m)^\|\s*' + [regex]::Escape($sourceId) + '\s*\|')) {
        $errors.Add("BENCHMARK_SOURCE_UNKNOWN case=$($case.id) source=$sourceId")
    }
    foreach ($inputPath in @($case.local_inputs | ForEach-Object { [string]$_ })) {
        if ([IO.Path]::IsPathRooted($inputPath) -or $inputPath -match '(^|[\\/])\.\.([\\/]|$)') {
            $errors.Add("BENCHMARK_INPUT_PATH_UNSAFE case=$($case.id) path=$inputPath")
        }
    }
}
$required = @($manifest.required_artifacts | ForEach-Object { [string]$_ })
foreach ($artifact in @('artifacts/problem-scope.md','artifacts/data-audit.md','artifacts/model-plan.md','artifacts/validation-plan.md','artifacts/reproduction.md','artifacts/validation-report.md','results/results-manifest.json','paper/solution.pdf','submission/submission-manifest.json')) {
    if ($artifact -notin $required) { $errors.Add("BENCHMARK_ARTIFACT_MISSING path=$artifact") }
}
$rubricPath = Join-Path $root (([string]$manifest.rubric) -replace '/', [IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $rubricPath -PathType Leaf)) { $errors.Add("BENCHMARK_RUBRIC_MISSING path=$($manifest.rubric)") }
else {
    $rubric = Get-Content -LiteralPath $rubricPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (@($rubric.criteria).Count -lt 8 -or -not [bool]$rubric.blind_review_required -or [int]$rubric.minimum_reviewers -lt 2) {
        $errors.Add('BENCHMARK_RUBRIC_INSUFFICIENT')
    }
}
Write-Output "BENCHMARK_CASES=$($cases.Count)"
Write-Output "ERRORS=$($errors.Count)"
foreach ($errorItem in $errors) { Write-Output "ERROR $errorItem" }
if ($errors.Count -gt 0) { Write-Output 'BENCHMARK_VALIDATION_STATUS=FAIL'; exit 1 }
Write-Output 'BENCHMARK_VALIDATION_STATUS=PASS'
exit 0
