[CmdletBinding(DefaultParameterSetName = 'Freeze')]
param(
    [Parameter(Mandatory = $true)][string]$ProjectRoot,
    [Parameter(Mandatory = $true, ParameterSetName = 'Freeze')][string[]]$Paths,
    [Parameter(Mandatory = $true, ParameterSetName = 'Verify')][switch]$Verify
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$rootPrefix = $root.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$resultsDirectory = Join-Path $root 'results'
if (-not (Test-Path -LiteralPath $resultsDirectory)) { $null = New-Item -ItemType Directory -Path $resultsDirectory }
$manifestPath = Join-Path $resultsDirectory 'results-manifest.json'

function Resolve-ProjectFile {
    param([string]$Value)
    $candidate = if ([IO.Path]::IsPathRooted($Value)) { [IO.Path]::GetFullPath($Value) } else { [IO.Path]::GetFullPath((Join-Path $root $Value)) }
    if (-not $candidate.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Artifact is outside the project root: $Value"
    }
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { throw "Artifact not found: $Value" }
    return $candidate
}

if ($Verify) {
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Missing results manifest: $manifestPath" }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $failures = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in @($manifest.entries)) {
        $localPath = Join-Path $root (([string]$entry.path) -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $localPath -PathType Leaf)) {
            $failures.Add("MISSING $($entry.path)")
            continue
        }
        $actual = (Get-FileHash -LiteralPath $localPath -Algorithm SHA256).Hash
        if ($actual -ne [string]$entry.sha256) { $failures.Add("HASH_MISMATCH $($entry.path)") }
        if ((Get-Item -LiteralPath $localPath).Length -ne [int64]$entry.bytes) { $failures.Add("SIZE_MISMATCH $($entry.path)") }
    }
    foreach ($failure in $failures) { Write-Output $failure }
    Write-Output "VERIFIED_ENTRIES=$(@($manifest.entries).Count)"
    if ($failures.Count -gt 0) { Write-Output 'RESULT_FREEZE_STATUS=FAIL'; exit 1 }
    Write-Output 'RESULT_FREEZE_STATUS=PASS'
    exit 0
}

$entries = @()
foreach ($pathValue in @($Paths | Sort-Object -Unique)) {
    $fullPath = Resolve-ProjectFile -Value $pathValue
    if ($fullPath -eq $manifestPath) { throw 'The result manifest cannot freeze itself.' }
    $relative = $fullPath.Substring($rootPrefix.Length).Replace([IO.Path]::DirectorySeparatorChar, '/')
    $item = Get-Item -LiteralPath $fullPath
    $entries += [ordered]@{
        path = $relative
        sha256 = (Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash
        bytes = $item.Length
        last_write_utc = $item.LastWriteTimeUtc.ToString('o')
    }
}
if ($entries.Count -eq 0) { throw 'At least one artifact must be frozen.' }

$sourceCommit = $null
try {
    $candidateCommit = (& git -C $root rev-parse HEAD 2>$null | Select-Object -First 1)
    if ($LASTEXITCODE -eq 0) { $sourceCommit = [string]$candidateCommit }
} catch { $sourceCommit = $null }
$manifest = [ordered]@{
    schema_version = '1.0.0'
    frozen_at = [DateTimeOffset]::UtcNow.ToString('o')
    source_commit = $sourceCommit
    entries = $entries
}
$temporaryPath = $manifestPath + '.tmp.' + $PID
try {
    [IO.File]::WriteAllText($temporaryPath, ($manifest | ConvertTo-Json -Depth 10) + "`n", [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporaryPath -Destination $manifestPath -Force
} finally {
    if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Force }
}
Write-Output "RESULT_MANIFEST=$manifestPath"
Write-Output "FROZEN_ENTRIES=$($entries.Count)"
Write-Output 'RESULT_FREEZE_STATUS=PASS'
exit 0
