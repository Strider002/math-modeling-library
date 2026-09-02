[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Path,
    [ValidateSet('CUMCM', 'MCM-ICM', 'Generic')][string]$Contest = 'Generic',
    [Parameter(Mandatory = $true)][string]$Problem
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$stageDefinitions = @(
    @{ id = 'problem'; required = @('artifacts/problem-scope.md') },
    @{ id = 'data'; required = @('artifacts/data-audit.md') },
    @{ id = 'model_selection'; required = @('artifacts/model-plan.md', 'artifacts/validation-plan.md') },
    @{ id = 'implementation'; required = @('artifacts/reproduction.md') },
    @{ id = 'validation'; required = @('artifacts/validation-report.md', 'results/results-manifest.json') },
    @{ id = 'paper'; required = @('paper/solution.pdf') },
    @{ id = 'submission'; required = @('submission/submission-manifest.json') }
)

$target = [IO.Path]::GetFullPath($Path)
if (Test-Path -LiteralPath $target) {
    if (-not (Test-Path -LiteralPath $target -PathType Container)) {
        throw "Project path exists but is not a directory: $target"
    }
    $existing = @(Get-ChildItem -LiteralPath $target -Force)
    if ($existing.Count -gt 0) {
        throw "Refusing to initialize a non-empty directory: $target"
    }
} else {
    $null = New-Item -ItemType Directory -Path $target
}

foreach ($directory in @('artifacts', 'data', 'src', 'results', 'paper', 'submission')) {
    $null = New-Item -ItemType Directory -Path (Join-Path $target $directory)
}

$now = [DateTimeOffset]::UtcNow.ToString('o')
$projectId = Split-Path -Leaf $target
$stages = @()
for ($i = 0; $i -lt $stageDefinitions.Count; $i++) {
    $stages += [ordered]@{
        id = $stageDefinitions[$i].id
        status = if ($i -eq 0) { 'in_progress' } else { 'pending' }
        required_artifacts = @($stageDefinitions[$i].required)
        completed_at = $null
        artifact_hashes = [ordered]@{}
    }
}
$state = [ordered]@{
    schema_version = '1.0.0'
    project_id = $projectId
    contest = $Contest
    problem = $Problem
    created_at = $now
    updated_at = $now
    current_stage = 'problem'
    stages = $stages
}

$statePath = Join-Path $target 'project-state.json'
$temporaryPath = $statePath + '.tmp.' + $PID
try {
    $json = $state | ConvertTo-Json -Depth 10
    [IO.File]::WriteAllText($temporaryPath, $json + "`n", [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporaryPath -Destination $statePath
} finally {
    if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Force }
}

Write-Output "PROJECT_ROOT=$target"
Write-Output "PROJECT_STATE=$statePath"
Write-Output 'CURRENT_STAGE=problem'
Write-Output 'PROJECT_INIT_STATUS=PASS'
exit 0
