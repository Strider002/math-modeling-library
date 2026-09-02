param(
    [string]$LibraryRoot = (Split-Path -Parent $PSScriptRoot),
    [int64]$MaxTrackedFileBytes = 5MB,
    [switch]$PublicRelease
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $LibraryRoot).Path
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$publicReleaseReady = $true

if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) {
    throw "NOT_A_GIT_REPOSITORY root=$root"
}

$requiredDistributionFiles = @(
    'README.md',
    'README.en.md',
    'CONTRIBUTING.md',
    'CONTRIBUTING.zh-CN.md',
    'SECURITY.md',
    'CITATION.cff',
    '.github/workflows/validate.yml'
)
foreach ($requiredPath in $requiredDistributionFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $requiredPath) -PathType Leaf)) {
        $errors.Add("MISSING_DISTRIBUTION_FILE path=$requiredPath")
    }
}

$licenseCandidates = @('LICENSE', 'LICENSE.txt', 'LICENSE.md')
$hasLicense = @($licenseCandidates | Where-Object {
    Test-Path -LiteralPath (Join-Path $root $_) -PathType Leaf
}).Count -gt 0
if (-not $hasLicense) {
    $publicReleaseReady = $false
    if ($PublicRelease) {
        $errors.Add('MISSING_LICENSE public_release_blocked=true')
    } else {
        $warnings.Add('MISSING_LICENSE public_release_blocked=true')
    }
}

$blockedPrefixes = @(
    'sources/原文/',
    'sources/国赛/',
    'sources/美赛/',
    'sources/GitHub方法/'
)
$blockedSourceExtensions = @(
    '.pdf', '.jpg', '.jpeg', '.png', '.zip', '.rar', '.7z',
    '.xlsx', '.xls', '.html', '.htm'
)
$textExtensions = @(
    '.md', '.txt', '.json', '.yaml', '.yml', '.py', '.ps1',
    '.gitignore', '.gitattributes'
)
$secretPatterns = @(
    'ghp_[A-Za-z0-9]{20,}',
    'github_pat_[A-Za-z0-9_]{20,}',
    'sk-[A-Za-z0-9_-]{20,}',
    'AKIA[0-9A-Z]{16}',
    '-----BEGIN [A-Z ]*PRIVATE KEY-----',
    '(?i)(api[_-]?key|access[_-]?token|client[_-]?secret)\s*[:=]\s*["''][^"'']{8,}["'']'
)

$tracked = @(& git -c core.quotePath=false -C $root ls-files)
if ($LASTEXITCODE -ne 0) {
    throw 'GIT_LS_FILES_FAILED'
}

$totalBytes = [int64]0
$emailOccurrences = 0
foreach ($relativePath in $tracked) {
    $normalized = $relativePath -replace '\\', '/'
    $fullPath = Join-Path $root ($normalized -replace '/', [IO.Path]::DirectorySeparatorChar)

    foreach ($prefix in $blockedPrefixes) {
        if ($normalized.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $errors.Add("BLOCKED_SOURCE_PATH path=$normalized")
        }
    }

    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        $errors.Add("TRACKED_FILE_MISSING path=$normalized")
        continue
    }

    $file = Get-Item -LiteralPath $fullPath
    $totalBytes += $file.Length
    if ($file.Length -gt $MaxTrackedFileBytes) {
        $errors.Add("TRACKED_FILE_TOO_LARGE path=$normalized bytes=$($file.Length) max=$MaxTrackedFileBytes")
    }

    $extension = $file.Extension.ToLowerInvariant()
    if ($normalized.StartsWith('sources/', [System.StringComparison]::OrdinalIgnoreCase) -and
        $extension -in $blockedSourceExtensions) {
        $errors.Add("BLOCKED_SOURCE_EXTENSION path=$normalized extension=$extension")
    }

    $isText = $extension -in $textExtensions -or $file.Name -in @('.gitignore', '.gitattributes')
    if ($isText) {
        $content = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
        foreach ($pattern in $secretPatterns) {
            if ($content -match $pattern) {
                $errors.Add("POSSIBLE_SECRET path=$normalized pattern=$pattern")
            }
        }
        $emailOccurrences += [regex]::Matches(
            $content,
            '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
        ).Count
    }
}

if ($emailOccurrences -gt 0) {
    $publicReleaseReady = $false
    if ($PublicRelease) {
        $errors.Add("EMAIL_LIKE_OCCURRENCES count=$emailOccurrences public_release_blocked=true")
    } else {
        $warnings.Add("EMAIL_LIKE_OCCURRENCES count=$emailOccurrences review_before_public_release=true")
    }
}

$skillPath = Join-Path $root 'SKILL.md'
$skillHash = if (Test-Path -LiteralPath $skillPath -PathType Leaf) {
    (Get-FileHash -LiteralPath $skillPath -Algorithm SHA256).Hash
} else {
    $errors.Add('MISSING_SKILL_MD')
    ''
}

"LIBRARY_ROOT=$root"
"TRACKED_FILES=$($tracked.Count)"
"TRACKED_BYTES=$totalBytes"
"SKILL_SHA256=$skillHash"
"PUBLIC_RELEASE_MODE=$([bool]$PublicRelease)"
"PUBLIC_RELEASE_READY=$($publicReleaseReady -and $errors.Count -eq 0)"
"WARNINGS=$($warnings.Count)"
foreach ($warning in $warnings) {
    "WARNING $warning"
}
"ERRORS=$($errors.Count)"
foreach ($errorItem in $errors) {
    "ERROR $errorItem"
}

if ($errors.Count -gt 0) {
    'GITHUB_RELEASE_STATUS=FAIL'
    exit 1
}

'GITHUB_RELEASE_STATUS=PASS'
