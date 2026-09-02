[CmdletBinding()]
param([string]$LibraryRoot = (Split-Path -Parent $PSScriptRoot))

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("modeling-project-test-$PID")
try {
    $init = Join-Path $LibraryRoot 'tools\new_modeling_project.ps1'
    $stage = Join-Path $LibraryRoot 'tools\modeling_stage.ps1'
    $output = @(& $init -Path $temporaryRoot -Contest CUMCM -Problem 'synthetic-test' 2>&1)
    $initOk = $?
    if (-not $initOk -or -not (($output -join "`n").Contains('PROJECT_INIT_STATUS=PASS'))) { throw "Project init failed: $output" }
    $check = @(& $stage -ProjectRoot $temporaryRoot -Action Check 2>&1)
    if ($LASTEXITCODE -eq 0 -or -not (($check -join "`n").Contains('STAGE_CHECK_STATUS=FAIL'))) { throw 'Missing artifact was not rejected.' }
    [IO.File]::WriteAllText((Join-Path $temporaryRoot 'artifacts\problem-scope.md'), "# Problem scope`n", [Text.UTF8Encoding]::new($false))
    $advance = @(& $stage -ProjectRoot $temporaryRoot -Action Advance 2>&1)
    if ($LASTEXITCODE -ne 0 -or -not (($advance -join "`n").Contains('NEXT_STAGE=data'))) { throw "Stage advance failed: $advance" }
    $state = Get-Content -LiteralPath (Join-Path $temporaryRoot 'project-state.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$state.current_stage -ne 'data' -or [string]$state.stages[0].status -ne 'completed') {
        throw 'State transition was not persisted.'
    }
    Write-Output 'PROJECT_WORKFLOW_TEST_STATUS=PASS'
} finally {
    if (Test-Path -LiteralPath $temporaryRoot) { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force }
}
