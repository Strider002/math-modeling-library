[CmdletBinding()]
param([string]$LibraryRoot = (Split-Path -Parent $PSScriptRoot))

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("modeling-freeze-test-$PID")
try {
    $null = New-Item -ItemType Directory -Path (Join-Path $temporaryRoot 'results') -Force
    $artifact = Join-Path $temporaryRoot 'results\metrics.csv'
    [IO.File]::WriteAllText($artifact, "metric,value`nMAE,1.25`n", [Text.UTF8Encoding]::new($false))
    $tool = Join-Path $LibraryRoot 'tools\freeze_results.ps1'
    $freeze = @(& $tool -ProjectRoot $temporaryRoot -Paths 'results/metrics.csv' 2>&1)
    $freezeOk = $?
    if (-not $freezeOk -or -not (($freeze -join "`n").Contains('RESULT_FREEZE_STATUS=PASS'))) { throw "Freeze failed: $freeze" }
    $verify = @(& $tool -ProjectRoot $temporaryRoot -Verify 2>&1)
    if ($LASTEXITCODE -ne 0 -or -not (($verify -join "`n").Contains('RESULT_FREEZE_STATUS=PASS'))) { throw "Verify failed: $verify" }
    [IO.File]::AppendAllText($artifact, "RMSE,2.00`n", [Text.UTF8Encoding]::new($false))
    $tamper = @(& $tool -ProjectRoot $temporaryRoot -Verify 2>&1)
    if ($LASTEXITCODE -eq 0 -or -not (($tamper -join "`n").Contains('RESULT_FREEZE_STATUS=FAIL'))) { throw 'Tampered artifact was not rejected.' }
    Write-Output 'RESULT_FREEZE_TEST_STATUS=PASS'
} finally {
    if (Test-Path -LiteralPath $temporaryRoot) { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force }
}
