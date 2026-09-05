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

    $cumcmMissingStatus = @(& $validator -PaperPath $paper -Profile CUMCM 2>&1)
    if ($LASTEXITCODE -eq 0 -or -not (($cumcmMissingStatus -join "`n").Contains('CUMCM_AI_USE_STATUS'))) {
        throw "CUMCM AI-use status gate did not fail: $cumcmMissingStatus"
    }
    $cumcmNotUsed = @(& $validator -PaperPath $paper -Profile CUMCM -CumcmAiUse NotUsed 2>&1)
    if ($LASTEXITCODE -ne 0 -or -not (($cumcmNotUsed -join "`n").Contains('SUBMISSION_VALIDATION_STATUS=PASS'))) {
        throw "CUMCM NotUsed validation failed: $cumcmNotUsed"
    }
    $cumcmMissingDetails = @(& $validator -PaperPath $paper -Profile CUMCM -CumcmAiUse Used 2>&1)
    if ($LASTEXITCODE -eq 0 -or -not (($cumcmMissingDetails -join "`n").Contains('CUMCM_AI_DETAILS'))) {
        throw "CUMCM AI details gate did not fail: $cumcmMissingDetails"
    }
    $aiDetails = Join-Path $temporaryRoot 'AI工具使用详情.pdf'
    Write-MinimalPdf -Path $aiDetails
    $cumcmUsed = @(& $validator -PaperPath $paper -Profile CUMCM -CumcmAiUse Used -AiDetailsPath $aiDetails 2>&1)
    if ($LASTEXITCODE -ne 0 -or -not (($cumcmUsed -join "`n").Contains('SUBMISSION_VALIDATION_STATUS=PASS'))) {
        throw "CUMCM Used validation failed: $cumcmUsed"
    }
    $wrongAiDetails = Join-Path $temporaryRoot 'ai-details.pdf'
    Write-MinimalPdf -Path $wrongAiDetails
    $cumcmWrongName = @(& $validator -PaperPath $paper -Profile CUMCM -CumcmAiUse Used -AiDetailsPath $wrongAiDetails 2>&1)
    if ($LASTEXITCODE -eq 0 -or -not (($cumcmWrongName -join "`n").Contains('CUMCM_AI_DETAILS_FILENAME'))) {
        throw "CUMCM AI details filename gate did not fail: $cumcmWrongName"
    }

    $builder = Join-Path $LibraryRoot 'tools\build_submission.ps1'
    $built = @(& $builder -ProjectRoot $temporaryRoot -PaperPath $paper -Profile Generic 2>&1)
    if ($LASTEXITCODE -ne 0 -or -not (($built -join "`n").Contains('SUBMISSION_BUILD_STATUS=PASS'))) { throw "Package build failed: $built" }
    $reviewPackage = Join-Path $temporaryRoot 'submission\review-package.zip'
    if (-not (Test-Path -LiteralPath $reviewPackage)) { throw 'Review package was not created.' }
    Remove-Item -LiteralPath $reviewPackage -Force
    Remove-Item -LiteralPath (Join-Path $temporaryRoot 'submission\submission-manifest.json') -Force
    $cumcmBuilt = @(& $builder -ProjectRoot $temporaryRoot -PaperPath $paper -Profile CUMCM -CumcmAiUse Used -AiDetailsPath $aiDetails 2>&1)
    if ($LASTEXITCODE -ne 0 -or -not (($cumcmBuilt -join "`n").Contains('SUBMISSION_BUILD_STATUS=PASS'))) {
        throw "CUMCM review package build failed: $cumcmBuilt"
    }
    $expanded = Join-Path $temporaryRoot 'expanded'
    Expand-Archive -LiteralPath $reviewPackage -DestinationPath $expanded
    if (-not (Test-Path -LiteralPath (Join-Path $expanded 'AI工具使用详情.pdf') -PathType Leaf)) {
        throw 'CUMCM review package omitted AI details PDF.'
    }
    Write-Output 'SUBMISSION_TOOLS_TEST_STATUS=PASS'
} finally {
    if (Test-Path -LiteralPath $temporaryRoot) { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force }
}
