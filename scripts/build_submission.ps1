#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectRoot,
    [Parameter(Mandatory = $true)][string]$PaperPath,
    [ValidateSet('CUMCM', 'MCM-ICM', 'Generic')][string]$Profile = 'Generic',
    [string]$ControlNumber,
    [string]$DenyListPath,
    [string[]]$SupportPaths = @(),
    [ValidateSet('Unspecified', 'NotUsed', 'Used')][string]$CumcmAiUse = 'Unspecified',
    [string]$AiDetailsPath,
    [switch]$RequireTextExtraction
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'project_paths.ps1')
$root = Get-SafeProjectRoot -Path $ProjectRoot
function Get-PackageInput {
    param([string]$Value)
    $relative = if ([IO.Path]::IsPathRooted($Value)) { [IO.Path]::GetRelativePath($root, [IO.Path]::GetFullPath($Value)) } else { $Value }
    return Resolve-ProjectArtifact -Root $root -RelativePath $relative -MustExist
}
$paper = Get-PackageInput -Value $PaperPath
$archivePath = Resolve-ProjectArtifact -Root $root -RelativePath 'submission/review-package.zip'
$manifestPath = Resolve-ProjectArtifact -Root $root -RelativePath 'submission/submission-manifest.json'
if ((Test-Path -LiteralPath $archivePath) -or (Test-Path -LiteralPath $manifestPath)) {
    throw 'Refusing to overwrite an existing review package or submission manifest.'
}
$files = [Collections.Generic.List[string]]::new()
$files.Add($paper)
foreach ($value in $SupportPaths) { $files.Add((Get-PackageInput -Value $value)) }
$validationArgs = @{ PaperPath = $paper; Profile = $Profile; CumcmAiUse = $CumcmAiUse }
if ($ControlNumber) { $validationArgs.ControlNumber = $ControlNumber }
if ($DenyListPath) { $validationArgs.DenyListPath = $DenyListPath }
if ($AiDetailsPath) {
    $details = Get-PackageInput -Value $AiDetailsPath
    $validationArgs.AiDetailsPath = $details
    if ($Profile -eq 'CUMCM' -and $CumcmAiUse -eq 'Used') { $files.Add($details) }
}
if ($RequireTextExtraction) { $validationArgs.RequireTextExtraction = $true }
$files = @($files | Sort-Object -Unique)
$names = @($files | ForEach-Object { [IO.Path]::GetFileName($_) })
if (@($names | Group-Object | Where-Object Count -gt 1).Count -gt 0) {
    throw 'Distinct input files have the same archive basename; rename explicitly before packaging.'
}
if ($archivePath -in $files -or $manifestPath -in $files) { throw 'The package cannot include its own outputs.' }
& (Join-Path $PSScriptRoot 'validate_submission.ps1') @validationArgs
if ($LASTEXITCODE -ne 0) { throw 'PDF precheck failed; no package was created.' }
& (Join-Path $PSScriptRoot 'verify_results.ps1') -ProjectRoot $root
if ($LASTEXITCODE -ne 0) { throw 'Result verification failed; no package was created.' }

$directory = Split-Path -Parent $archivePath
if (-not (Test-Path -LiteralPath $directory)) { $null = New-Item -ItemType Directory -Path $directory }
Assert-NoReparsePath -Path $archivePath
Compress-Archive -LiteralPath $files -DestinationPath $archivePath -CompressionLevel Optimal
$manifest = [ordered]@{
    schema_version = '1.0.0'
    profile = $Profile
    created_at = [DateTimeOffset]::UtcNow.ToString('o')
    review_package = 'submission/review-package.zip'
    sha256 = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
    bytes = (Get-Item -LiteralPath $archivePath).Length
    included_files = @($files | ForEach-Object { [IO.Path]::GetRelativePath($root, $_).Replace('\', '/') })
    upload_note = 'Local review bundle only. Verify current competition rules for actual submission format. Nothing was uploaded.'
}
$bytes = [Text.UTF8Encoding]::new($false).GetBytes(($manifest | ConvertTo-Json -Depth 8) + "`n")
$stream = [IO.File]::Open($manifestPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
Write-Output "REVIEW_PACKAGE=$archivePath"
Write-Output "SUBMISSION_MANIFEST=$manifestPath"
Write-Output 'SUBMISSION_BUILD_STATUS=PASS'
exit 0
