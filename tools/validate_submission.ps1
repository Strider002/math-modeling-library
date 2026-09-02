[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PaperPath,
    [ValidateSet('CUMCM', 'MCM-ICM', 'Generic')][string]$Profile = 'Generic',
    [string]$ControlNumber,
    [string]$DenyListPath,
    [switch]$RequireTextExtraction
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$paper = (Resolve-Path -LiteralPath $PaperPath).Path
$item = Get-Item -LiteralPath $paper
if ($item.Extension -ne '.pdf') { $errors.Add('PAPER_EXTENSION expected=.pdf') }
$stream = [IO.File]::OpenRead($paper)
try {
    $buffer = New-Object byte[] 5
    $count = $stream.Read($buffer, 0, 5)
    $magic = if ($count -eq 5) { [Text.Encoding]::ASCII.GetString($buffer) } else { '' }
    if ($magic -ne '%PDF-') { $errors.Add('PAPER_MAGIC invalid_pdf_header') }
} finally { $stream.Dispose() }

$limit = switch ($Profile) { 'CUMCM' { 20MB } 'MCM-ICM' { 25MB } default { 25MB } }
if ($item.Length -gt $limit) { $errors.Add("PAPER_SIZE bytes=$($item.Length) limit=$limit") }
if ($Profile -eq 'MCM-ICM') {
    if ([string]::IsNullOrWhiteSpace($ControlNumber)) {
        $errors.Add('CONTROL_NUMBER required_for_mcm_icm')
    } elseif ($item.BaseName -ne $ControlNumber) {
        $errors.Add("PAPER_FILENAME expected=$ControlNumber.pdf actual=$($item.Name)")
    }
}

$pdfInfo = Get-Command pdfinfo -ErrorAction SilentlyContinue
if ($null -ne $pdfInfo) {
    $infoOutput = @(& $pdfInfo.Source $paper 2>&1)
    if ($LASTEXITCODE -ne 0) { $errors.Add('PDFINFO failed') }
    $pageLine = $infoOutput | Where-Object { $_ -match '^Pages:\s+(\d+)' } | Select-Object -First 1
    if ($null -ne $pageLine -and $pageLine -match '^Pages:\s+(\d+)') {
        $pages = [int]$Matches[1]
        Write-Output "PDF_PAGES=$pages"
        if ($Profile -eq 'CUMCM' -and $pages -gt 31) { $warnings.Add("CUMCM_PAGE_REVIEW pages=$pages includes_summary_and_possible_appendices") }
        if ($Profile -eq 'MCM-ICM' -and $pages -gt 25) { $warnings.Add("MCM_PAGE_REVIEW pages=$pages AI_report_may_be_outside_limit") }
    }
} else {
    $warnings.Add('PDFINFO unavailable_page_count_not_checked')
}

$denyTerms = @()
if (-not [string]::IsNullOrWhiteSpace($DenyListPath)) {
    $denyPath = (Resolve-Path -LiteralPath $DenyListPath).Path
    $denyTerms = @(Get-Content -LiteralPath $denyPath -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and -not $_.StartsWith('#') })
}
$pdftotext = Get-Command pdftotext -ErrorAction SilentlyContinue
if ($denyTerms.Count -gt 0 -or $RequireTextExtraction) {
    if ($null -eq $pdftotext) {
        if ($RequireTextExtraction) { $errors.Add('PDFTOTEXT required_but_unavailable') } else { $warnings.Add('PDFTOTEXT unavailable_denylist_not_scanned') }
    } else {
        $temporaryText = Join-Path ([IO.Path]::GetTempPath()) ("modeling-paper-$PID.txt")
        try {
            $null = & $pdftotext.Source -enc UTF-8 $paper $temporaryText 2>&1
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $temporaryText)) {
                $errors.Add('PDFTOTEXT failed')
            } else {
                $text = Get-Content -LiteralPath $temporaryText -Raw -Encoding UTF8
                foreach ($term in $denyTerms) {
                    if ($text.IndexOf($term, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
                        $item.Name.IndexOf($term, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                        $errors.Add("ANONYMITY_DENYLIST term=$term")
                    }
                }
            }
        } finally {
            if (Test-Path -LiteralPath $temporaryText) { Remove-Item -LiteralPath $temporaryText -Force }
        }
    }
}

Write-Output "PAPER_BYTES=$($item.Length)"
Write-Output "PROFILE=$Profile"
Write-Output "WARNINGS=$($warnings.Count)"
foreach ($warning in $warnings) { Write-Output "WARNING $warning" }
Write-Output "ERRORS=$($errors.Count)"
foreach ($errorItem in $errors) { Write-Output "ERROR $errorItem" }
if ($errors.Count -gt 0) { Write-Output 'SUBMISSION_VALIDATION_STATUS=FAIL'; exit 1 }
Write-Output 'SUBMISSION_VALIDATION_STATUS=PASS'
exit 0
