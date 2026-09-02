[CmdletBinding()]
param([string]$LibraryRoot = (Split-Path -Parent $PSScriptRoot))

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-MinimalPdf {
    param([Parameter(Mandatory = $true)][string]$Path)
    $objects = @(
        '<< /Type /Catalog /Pages 2 0 R >>',
        '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>',
        "<< /Length 35 >>`nstream`nBT /F1 12 Tf 20 100 Td (OK) Tj ET`nendstream",
        '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'
    )
    $builder = [Text.StringBuilder]::new()
    $null = $builder.Append("%PDF-1.4`n")
    $offsets = [System.Collections.Generic.List[int]]::new()
    for ($i = 0; $i -lt $objects.Count; $i++) {
        $offsets.Add([Text.Encoding]::ASCII.GetByteCount($builder.ToString()))
        $null = $builder.Append("$($i + 1) 0 obj`n$($objects[$i])`nendobj`n")
    }
    $xrefOffset = [Text.Encoding]::ASCII.GetByteCount($builder.ToString())
    $null = $builder.Append("xref`n0 6`n0000000000 65535 f `n")
    foreach ($offset in $offsets) { $null = $builder.Append(('{0:0000000000} 00000 n ' -f $offset) + "`n") }
    $null = $builder.Append("trailer`n<< /Size 6 /Root 1 0 R >>`nstartxref`n$xrefOffset`n%%EOF`n")
    [IO.File]::WriteAllBytes($Path, [Text.Encoding]::ASCII.GetBytes($builder.ToString()))
}

$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("modeling-submission-test-$PID")
try {
    $null = New-Item -ItemType Directory -Path (Join-Path $temporaryRoot 'results') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $temporaryRoot 'paper') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $temporaryRoot 'submission') -Force
    $metrics = Join-Path $temporaryRoot 'results\metrics.csv'
    [IO.File]::WriteAllText($metrics, "metric,value`nMAE,1.25`n", [Text.UTF8Encoding]::new($false))
    $freezeTool = Join-Path $LibraryRoot 'tools\freeze_results.ps1'
    $null = & $freezeTool -ProjectRoot $temporaryRoot -Paths 'results/metrics.csv'
    if (-not $?) { throw 'Result freeze setup failed.' }
    $paper = Join-Path $temporaryRoot 'paper\solution.pdf'
    Write-MinimalPdf -Path $paper
    $validator = Join-Path $LibraryRoot 'tools\validate_submission.ps1'
    $valid = @(& $validator -PaperPath $paper -Profile Generic 2>&1)
    if ($LASTEXITCODE -ne 0 -or -not (($valid -join "`n").Contains('SUBMISSION_VALIDATION_STATUS=PASS'))) { throw "PDF validation failed: $valid" }
    $builder = Join-Path $LibraryRoot 'tools\build_submission.ps1'
    $built = @(& $builder -ProjectRoot $temporaryRoot -PaperPath $paper -Profile Generic 2>&1)
    if ($LASTEXITCODE -ne 0 -or -not (($built -join "`n").Contains('SUBMISSION_BUILD_STATUS=PASS'))) { throw "Package build failed: $built" }
    if (-not (Test-Path -LiteralPath (Join-Path $temporaryRoot 'submission\review-package.zip'))) { throw 'Review package was not created.' }
    Write-Output 'SUBMISSION_TOOLS_TEST_STATUS=PASS'
} finally {
    if (Test-Path -LiteralPath $temporaryRoot) { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force }
}
