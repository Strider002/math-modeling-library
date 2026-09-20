#Requires -Version 7.0
[CmdletBinding(DefaultParameterSetName = 'Freeze')]
param(
    [Parameter(Mandatory = $true)][string]$ProjectRoot,
    [Parameter(Mandatory = $true, ParameterSetName = 'Freeze')][string[]]$Paths,
    [Parameter(Mandatory = $true, ParameterSetName = 'Verify')][switch]$Verify,
    [string]$ManifestPath = 'results/results-manifest.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($Verify) {
    & (Join-Path $PSScriptRoot 'verify_results.ps1') -ProjectRoot $ProjectRoot -ManifestPath $ManifestPath
    exit $LASTEXITCODE
}
. (Join-Path $PSScriptRoot 'project_paths.ps1')
$root = Get-SafeProjectRoot -Path $ProjectRoot
$destination = Resolve-ProjectArtifact -Root $root -RelativePath $ManifestPath
if (Test-Path -LiteralPath $destination) { throw 'Refusing to overwrite an existing results manifest. Use a new manifest path for a new run.' }
$entries = @()
$seen = [Collections.Generic.HashSet[string]]::new($(if ($IsWindows) { [StringComparer]::OrdinalIgnoreCase } else { [StringComparer]::Ordinal }))
foreach ($value in $Paths) {
    $file = Resolve-ProjectArtifact -Root $root -RelativePath $value -MustExist
    if ($file -eq $destination) { throw 'The manifest cannot freeze itself.' }
    if (-not $seen.Add($file)) { throw "Duplicate artifact: $value" }
    $item = Get-Item -LiteralPath $file
    $entries += [ordered]@{
        path = [IO.Path]::GetRelativePath($root, $file).Replace('\', '/')
        sha256 = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
        bytes = $item.Length
        last_write_utc = $item.LastWriteTimeUtc.ToString('o')
    }
}
if ($entries.Count -eq 0) { throw 'At least one artifact is required.' }
$manifest = [ordered]@{
    schema_version = '1.0.0'
    frozen_at = [DateTimeOffset]::UtcNow.ToString('o')
    source_commit = $null
    entries = $entries
}
$parent = Split-Path -Parent $destination
if (-not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent }
Assert-NoReparsePath -Path $destination
$bytes = [Text.UTF8Encoding]::new($false).GetBytes(($manifest | ConvertTo-Json -Depth 8) + "`n")
$stream = [IO.File]::Open($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
Write-Output "RESULT_MANIFEST=$destination"
Write-Output "FROZEN_ENTRIES=$($entries.Count)"
Write-Output 'RESULT_FREEZE_STATUS=PASS'
exit 0
