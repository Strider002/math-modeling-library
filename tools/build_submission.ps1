[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectRoot,
    [Parameter(Mandatory = $true)][string]$PaperPath,
    [ValidateSet('CUMCM', 'MCM-ICM', 'Generic')][string]$Profile = 'Generic',
    [string]$ControlNumber,
    [string]$DenyListPath,
    [string[]]$SupportPaths = @(),
    [switch]$RequireTextExtraction
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$validator = Join-Path $PSScriptRoot 'validate_submission.ps1'
$freezer = Join-Path $PSScriptRoot 'freeze_results.ps1'

$validationArgs = @{ PaperPath = $PaperPath; Profile = $Profile }
if (-not [string]::IsNullOrWhiteSpace($ControlNumber)) { $validationArgs.ControlNumber = $ControlNumber }
if (-not [string]::IsNullOrWhiteSpace($DenyListPath)) { $validationArgs.DenyListPath = $DenyListPath }
if ($RequireTextExtraction) { $validationArgs.RequireTextExtraction = $true }
$validationOutput = @(& $validator @validationArgs 2>&1)
foreach ($line in $validationOutput) { Write-Output "VALIDATION $line" }
if ($LASTEXITCODE -ne 0) { throw 'Submission validation failed; no package was created.' }

$freezeOutput = @(& $freezer -ProjectRoot $root -Verify 2>&1)
foreach ($line in $freezeOutput) { Write-Output "FREEZE $line" }
if ($LASTEXITCODE -ne 0) { throw 'Frozen results verification failed; no package was created.' }

$submissionDirectory = Join-Path $root 'submission'
if (-not (Test-Path -LiteralPath $submissionDirectory)) { $null = New-Item -ItemType Directory -Path $submissionDirectory }
$archivePath = Join-Path $submissionDirectory 'review-package.zip'
if (Test-Path -LiteralPath $archivePath) { throw "Refusing to overwrite existing package: $archivePath" }
$files = [System.Collections.Generic.List[string]]::new()
$files.Add((Resolve-Path -LiteralPath $PaperPath).Path)
foreach ($pathValue in $SupportPaths) { $files.Add((Resolve-Path -LiteralPath $pathValue).Path) }
Compress-Archive -LiteralPath $files.ToArray() -DestinationPath $archivePath -CompressionLevel Optimal

$archiveItem = Get-Item -LiteralPath $archivePath
$manifest = [ordered]@{
    schema_version = '1.0.0'
    profile = $Profile
    created_at = [DateTimeOffset]::UtcNow.ToString('o')
    review_package = 'submission/review-package.zip'
    sha256 = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
    bytes = $archiveItem.Length
    upload_note = if ($Profile -eq 'CUMCM') {
        'This is a local review bundle. Follow current CUMCM rules for separate paper and support-material uploads.'
    } elseif ($Profile -eq 'MCM-ICM') {
        'This is a local review bundle. Submit only the rule-compliant PDF unless current COMAP rules say otherwise.'
    } else { 'This is a local review bundle; verify destination-specific upload rules.' }
}
$manifestPath = Join-Path $submissionDirectory 'submission-manifest.json'
[IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 6) + "`n", [Text.UTF8Encoding]::new($false))
Write-Output "REVIEW_PACKAGE=$archivePath"
Write-Output "SUBMISSION_MANIFEST=$manifestPath"
Write-Output 'SUBMISSION_BUILD_STATUS=PASS'
exit 0
