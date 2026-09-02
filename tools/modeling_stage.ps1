[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectRoot,
    [ValidateSet('Status', 'Check', 'Advance')][string]$Action = 'Status'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Save-StateAtomically {
    param([Parameter(Mandatory = $true)]$State, [Parameter(Mandatory = $true)][string]$Path)
    $temporaryPath = $Path + '.tmp.' + $PID
    try {
        $json = $State | ConvertTo-Json -Depth 10
        [IO.File]::WriteAllText($temporaryPath, $json + "`n", [Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
    } finally {
        if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Force }
    }
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$statePath = Join-Path $root 'project-state.json'
if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    throw "Missing project-state.json: $statePath"
}
$state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
$expectedStages = @('problem', 'data', 'model_selection', 'implementation', 'validation', 'paper', 'submission')
$actualStages = @($state.stages | ForEach-Object { [string]$_.id })
if (@(Compare-Object $expectedStages $actualStages -SyncWindow 0).Count -ne 0) {
    throw 'project-state.json has an invalid or reordered stage list.'
}
if ([string]$state.current_stage -eq 'complete') {
    Write-Output 'CURRENT_STAGE=complete'
    Write-Output 'STAGE_STATUS=PASS'
    exit 0
}

$current = @($state.stages | Where-Object { [string]$_.id -eq [string]$state.current_stage })
if ($current.Count -ne 1) { throw "Invalid current_stage: $($state.current_stage)" }
$stage = $current[0]
$missing = [System.Collections.Generic.List[string]]::new()
$hashes = [ordered]@{}
foreach ($relativePath in @($stage.required_artifacts | ForEach-Object { [string]$_ })) {
    $localPath = Join-Path $root ($relativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $localPath -PathType Leaf)) {
        $missing.Add($relativePath)
        continue
    }
    $hashes[$relativePath] = (Get-FileHash -LiteralPath $localPath -Algorithm SHA256).Hash
}

Write-Output "CURRENT_STAGE=$($state.current_stage)"
Write-Output "REQUIRED_ARTIFACTS=$(@($stage.required_artifacts).Count)"
Write-Output "MISSING_ARTIFACTS=$($missing.Count)"
foreach ($item in $missing) { Write-Output "MISSING=$item" }

if ($Action -eq 'Status') {
    Write-Output "STAGE_STATUS=$($stage.status)"
    exit 0
}
if ($Action -eq 'Check') {
    if ($missing.Count -gt 0) { Write-Output 'STAGE_CHECK_STATUS=FAIL'; exit 1 }
    Write-Output 'STAGE_CHECK_STATUS=PASS'
    exit 0
}
if ($missing.Count -gt 0) {
    Write-Output 'STAGE_ADVANCE_STATUS=FAIL'
    exit 1
}

$stage.status = 'completed'
$stage.completed_at = [DateTimeOffset]::UtcNow.ToString('o')
$stage.artifact_hashes = [pscustomobject]$hashes
$currentIndex = [array]::IndexOf($expectedStages, [string]$state.current_stage)
if ($currentIndex -eq $expectedStages.Count - 1) {
    $state.current_stage = 'complete'
} else {
    $nextId = $expectedStages[$currentIndex + 1]
    $next = @($state.stages | Where-Object { [string]$_.id -eq $nextId })[0]
    $next.status = 'in_progress'
    $state.current_stage = $nextId
}
$state.updated_at = [DateTimeOffset]::UtcNow.ToString('o')
Save-StateAtomically -State $state -Path $statePath
Write-Output "NEXT_STAGE=$($state.current_stage)"
Write-Output 'STAGE_ADVANCE_STATUS=PASS'
exit 0
