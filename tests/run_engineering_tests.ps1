[CmdletBinding()]
param([string]$LibraryRoot = (Split-Path -Parent $PSScriptRoot))

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$tests = @('test_project_workflow.ps1', 'test_result_freeze.ps1', 'test_submission_tools.ps1')
foreach ($test in $tests) {
    $path = Join-Path $PSScriptRoot $test
    Write-Output "RUN $test"
    & $path -LibraryRoot $LibraryRoot
    if (-not $?) { throw "$test failed." }
}
$benchmarkValidator = Join-Path $LibraryRoot 'tools\validate_benchmarks.ps1'
Write-Output 'RUN validate_benchmarks.ps1'
& $benchmarkValidator -LibraryRoot $LibraryRoot
if (-not $?) { throw 'Benchmark validation failed.' }
Write-Output "ENGINEERING_TESTS=$($tests.Count + 1)"
Write-Output 'ENGINEERING_TEST_STATUS=PASS'
