[CmdletBinding()]
param(
    [string]$LibraryRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$SkipRoutingTests,
    [switch]$Portable
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $LibraryRoot).Path
$allFiles = @(Get-ChildItem -LiteralPath $root -Recurse -File)
$markdownFiles = @($allFiles | Where-Object { $_.Extension -eq '.md' })
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$infos = [System.Collections.Generic.List[string]]::new()
$explicitSourceRefs = [System.Collections.Generic.List[object]]::new()

function Get-PropertyArray {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($null -eq $Object) {
        return @()
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        return @()
    }
    return @($property.Value) | Where-Object { $null -ne $_ }
}

function Get-RelativeLibraryPath {
    param([Parameter(Mandatory = $true)][string]$FullName)
    return $FullName.Substring($root.Length + 1).Replace('\', '/')
}

function Resolve-ManifestResource {
    param(
        [Parameter(Mandatory = $true)]$Resource,
        [Parameter(Mandatory = $true)][string]$Context
    )

    $pathProperty = $Resource.PSObject.Properties['path']
    $reasonProperty = $Resource.PSObject.Properties['reason']
    if ($null -eq $pathProperty -or [string]::IsNullOrWhiteSpace([string]$pathProperty.Value)) {
        $errors.Add("MANIFEST_RESOURCE_PATH context=$Context")
        return $null
    }
    if ($null -eq $reasonProperty -or [string]::IsNullOrWhiteSpace([string]$reasonProperty.Value)) {
        $errors.Add("MANIFEST_RESOURCE_REASON context=$Context path=$($pathProperty.Value)")
    }

    $relativePath = ([string]$pathProperty.Value).Split('#')[0]
    if ([IO.Path]::IsPathRooted($relativePath)) {
        $errors.Add("MANIFEST_ABSOLUTE_PATH context=$Context path=$relativePath")
        return $null
    }
    $localPath = Join-Path $root ($relativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $localPath)) {
        $errors.Add("MANIFEST_MISSING_RESOURCE context=$Context path=$relativePath")
    }
    return $relativePath
}

$tick = [string][char]96
$fenceToken = [string]::new([char]96, 3)
$codeFilePattern = [regex]::Escape($tick) + '([^' + [regex]::Escape($tick) +
    ']+\.md(?:#[^' + [regex]::Escape($tick) + ']*)?)' + [regex]::Escape($tick)
$sourceRefPattern = [regex]::Escape($tick) + 'source:([A-Za-z0-9][A-Za-z0-9._-]*)' +
    [regex]::Escape($tick)
$backtickFileRefs = 0
$externalFileRefs = 0
$externalRepoRefs = 0
$tombstoneRefs = 0
$portableLocalEvidencePrefixes = @(
    'sources/原文/',
    'sources/国赛/',
    'sources/美赛/',
    'sources/GitHub方法/'
)

foreach ($file in $markdownFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $relative = Get-RelativeLibraryPath -FullName $file.FullName
    $lines = [regex]::Split($text, '\r?\n')

    $h1Count = ([regex]::Matches($text, '(?m)^# ')).Count
    if ($h1Count -ne 1) {
        $errors.Add("H1_COUNT $relative expected=1 actual=$h1Count")
    }

    $previousHeadingLevel = 0
    foreach ($line in $lines) {
        if ($line -match '^(#{1,6})\s+') {
            $headingLevel = $Matches[1].Length
            if ($previousHeadingLevel -gt 0 -and ($headingLevel - $previousHeadingLevel) -gt 1) {
                $errors.Add("HEADING_LEVEL_JUMP $relative from=$previousHeadingLevel to=$headingLevel")
            }
            $previousHeadingLevel = $headingLevel
        }
    }

    $displayOpen = ([regex]::Matches($text, '\\\[')).Count
    $displayClose = ([regex]::Matches($text, '\\\]')).Count
    if ($displayOpen -ne $displayClose) {
        $errors.Add("DISPLAY_MATH $relative open=$displayOpen close=$displayClose")
    }

    $fenceCount = ([regex]::Matches($text, '(?m)^' + [regex]::Escape($fenceToken))).Count
    if (($fenceCount % 2) -ne 0) {
        $errors.Add("CODE_FENCE $relative count=$fenceCount")
    }

    foreach ($match in [regex]::Matches($text, '\[[^\]]*\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Trim('<', '>')
        if ($target -eq '' -or $target -match '^(https?://|mailto:|#)') {
            continue
        }
        $pathPart = $target.Split('#')[0]
        $resolved = if ([IO.Path]::IsPathRooted($pathPart)) {
            $pathPart
        } else {
            Join-Path $file.DirectoryName $pathPart
        }
        if (-not (Test-Path -LiteralPath $resolved)) {
            $errors.Add("LOCAL_LINK $relative -> $target")
        }
    }

    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
        $lineWithoutLinks = [regex]::Replace($lines[$lineIndex], '\[[^\]]*\]\([^)]+\)', '')
        foreach ($match in [regex]::Matches($lineWithoutLinks, $codeFilePattern)) {
            $backtickFileRefs++
            $target = $match.Groups[1].Value.Split('#')[0]

            if ($target -like 'external-file:*') {
                $externalFileRefs++
                $externalPath = $target.Substring('external-file:'.Length)
                if (-not [IO.Path]::IsPathRooted($externalPath)) {
                    $errors.Add("EXTERNAL_FILE_REF $relative line=$($lineIndex + 1) -> $externalPath")
                } elseif (-not (Test-Path -LiteralPath $externalPath -PathType Leaf)) {
                    if ($Portable) {
                        $infos.Add("PORTABLE_EXTERNAL_FILE_UNCHECKED file=$relative line=$($lineIndex + 1)")
                    } else {
                        $errors.Add("EXTERNAL_FILE_REF $relative line=$($lineIndex + 1) -> $externalPath")
                    }
                }
                continue
            }
            if ($target -like 'external-repo:*') {
                $externalRepoRefs++
                continue
            }
            if ($target -like 'tombstone:*') {
                $tombstoneRefs++
                $deletedPath = $target.Substring('tombstone:'.Length)
                $deletedLocal = Join-Path $root ($deletedPath -replace '/', [IO.Path]::DirectorySeparatorChar)
                if (Test-Path -LiteralPath $deletedLocal) {
                    $warnings.Add("TOMBSTONE_TARGET_EXISTS $relative line=$($lineIndex + 1) -> $deletedPath")
                }
                continue
            }
            if ($target -match '^(\.[A-Za-z0-9]+/){2,}\.[A-Za-z0-9]+$' -or
                $target -match '^[A-Za-z][A-Za-z0-9+.-]*://') {
                continue
            }

            $fromCurrent = Join-Path $file.DirectoryName ($target -replace '/', [IO.Path]::DirectorySeparatorChar)
            $fromRoot = Join-Path $root ($target -replace '/', [IO.Path]::DirectorySeparatorChar)
            $currentExists = Test-Path -LiteralPath $fromCurrent
            $rootExists = Test-Path -LiteralPath $fromRoot
            if (-not $currentExists -and -not $rootExists) {
                $normalizedTarget = $target -replace '\\', '/'
                $isPortableLocalEvidence = $Portable -and @(
                    $portableLocalEvidencePrefixes | Where-Object {
                        $normalizedTarget.StartsWith($_, [System.StringComparison]::OrdinalIgnoreCase)
                    }
                ).Count -gt 0
                if ($isPortableLocalEvidence) {
                    $infos.Add("PORTABLE_LOCAL_EVIDENCE_UNCHECKED file=$relative line=$($lineIndex + 1) target=$normalizedTarget")
                } else {
                    $errors.Add("BACKTICK_FILE_REF $relative line=$($lineIndex + 1) -> $target")
                }
            } elseif ($currentExists -and $rootExists) {
                $currentResolved = (Resolve-Path -LiteralPath $fromCurrent).Path
                $rootResolved = (Resolve-Path -LiteralPath $fromRoot).Path
                if ($currentResolved -ne $rootResolved) {
                    $errors.Add("AMBIGUOUS_BACKTICK_REF $relative line=$($lineIndex + 1) -> $target")
                }
            }
        }

        foreach ($match in [regex]::Matches($lineWithoutLinks, $sourceRefPattern)) {
            $explicitSourceRefs.Add([pscustomobject]@{
                Id = $match.Groups[1].Value
                File = $relative
                Line = $lineIndex + 1
            })
        }
    }
}

$readmePath = Join-Path $root 'README.md'
if (-not (Test-Path -LiteralPath $readmePath)) {
    $errors.Add('MISSING README.md')
} else {
    $readme = Get-Content -LiteralPath $readmePath -Raw -Encoding UTF8
    $readmePattern = [regex]::Escape($tick) + '([^' + [regex]::Escape($tick) + ']+\.md)' +
        [regex]::Escape($tick)
    $declared = @([regex]::Matches($readme, $readmePattern) |
        ForEach-Object { $_.Groups[1].Value } |
        Where-Object { $_ -notmatch '^(external-file:|external-repo:|tombstone:)' } |
        Sort-Object -Unique)
    foreach ($entry in $declared) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $entry))) {
            $errors.Add("README_DECLARATION missing=$entry")
        }
    }
}

$sourceIds = @()
$sourcesPath = Join-Path $root 'sources'
$ledgerCandidates = @()
if (Test-Path -LiteralPath $sourcesPath) {
    $ledgerCandidates = @(Get-ChildItem -LiteralPath $sourcesPath -File -Filter '*.md' |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8) -match '(?m)^\| ID \|'
        })
}
if ($ledgerCandidates.Count -ne 1) {
    $errors.Add("SOURCE_LEDGER expected=1 actual=$($ledgerCandidates.Count)")
} else {
    $ledgerPath = $ledgerCandidates[0].FullName
    $insideIdTable = $false
    foreach ($line in Get-Content -LiteralPath $ledgerPath -Encoding UTF8) {
        if ($line -match '^\|\s*ID\s*\|') {
            $insideIdTable = $true
            continue
        }
        if ($insideIdTable -and $line -match '^\|\s*:?-+:?\s*\|') {
            continue
        }
        if ($insideIdTable -and $line -match '^\|\s*([^|]+?)\s*\|') {
            $sourceIds += $Matches[1].Trim()
            continue
        }
        if ($insideIdTable -and $line -notmatch '^\|') {
            $insideIdTable = $false
        }
    }

    foreach ($duplicate in $sourceIds | Group-Object | Where-Object { $_.Count -gt 1 }) {
        $errors.Add("DUPLICATE_SOURCE_ID id=$($duplicate.Name) count=$($duplicate.Count)")
    }
    foreach ($invalid in $sourceIds | Where-Object {
        $_ -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$'
    }) {
        $errors.Add("INVALID_SOURCE_ID id=$invalid")
    }
}

$sourceIdSet = @{}
foreach ($sourceId in $sourceIds) {
    $sourceIdSet[$sourceId] = $true
}
foreach ($reference in $explicitSourceRefs) {
    if (-not $sourceIdSet.ContainsKey([string]$reference.Id)) {
        $errors.Add("UNKNOWN_EXPLICIT_SOURCE_ID id=$($reference.Id) file=$($reference.File) line=$($reference.Line)")
    }
}

$manifestPath = Join-Path $root 'routing-manifest.yaml'
$manifest = $null
$manifestRouteCount = 0
$manifestStageCount = 0
$permanentBytes = 0
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    $errors.Add('MISSING routing-manifest.yaml')
} else {
    try {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        $errors.Add("INVALID_ROUTING_MANIFEST $($_.Exception.Message)")
    }
}

if ($null -ne $manifest) {
    if ([string]::IsNullOrWhiteSpace([string]$manifest.schema_version)) {
        $errors.Add('MANIFEST_SCHEMA_VERSION missing')
    }
    if ([string]$manifest.path_resolution -ne 'manifest_directory') {
        $errors.Add("MANIFEST_PATH_RESOLUTION expected=manifest_directory actual=$($manifest.path_resolution)")
    }

    $stages = @(Get-PropertyArray -Object $manifest -Name 'stages')
    $routes = @(Get-PropertyArray -Object $manifest -Name 'routes')
    $manifestRouteCount = $routes.Count
    $manifestStageCount = $stages.Count

    foreach ($duplicate in @($stages | ForEach-Object { [string]$_.id } |
        Group-Object | Where-Object { $_.Count -gt 1 })) {
        $errors.Add("DUPLICATE_STAGE_ID id=$($duplicate.Name)")
    }
    foreach ($duplicate in @($routes | ForEach-Object { [string]$_.id } |
        Group-Object | Where-Object { $_.Count -gt 1 })) {
        $errors.Add("DUPLICATE_ROUTE_ID id=$($duplicate.Name)")
    }

    $stageIdSet = @{}
    foreach ($stage in $stages) {
        $stageId = [string]$stage.id
        if ([string]::IsNullOrWhiteSpace($stageId)) {
            $errors.Add('EMPTY_STAGE_ID')
            continue
        }
        $stageIdSet[$stageId] = $true
        $seenStagePaths = @{}
        foreach ($category in @('required', 'optional')) {
            foreach ($resource in @(Get-PropertyArray -Object $stage -Name $category)) {
                $resourcePath = Resolve-ManifestResource -Resource $resource -Context "stage:${stageId}:$category"
                if ($null -ne $resourcePath) {
                    if ($seenStagePaths.ContainsKey($resourcePath)) {
                        $errors.Add("MANIFEST_STAGE_CATEGORY_OVERLAP stage=$stageId path=$resourcePath")
                    }
                    $seenStagePaths[$resourcePath] = $category
                }
            }
        }
    }

    $permanentProperty = $manifest.PSObject.Properties['permanent']
    if ($null -eq $permanentProperty) {
        $errors.Add('MANIFEST_PERMANENT missing')
    } else {
        foreach ($resource in @(Get-PropertyArray -Object $permanentProperty.Value -Name 'required')) {
            $resourcePath = Resolve-ManifestResource -Resource $resource -Context 'permanent:required'
            if ($null -ne $resourcePath) {
                $fullPath = Join-Path $root ($resourcePath -replace '/', [IO.Path]::DirectorySeparatorChar)
                if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
                    $permanentBytes += (Get-Item -LiteralPath $fullPath).Length
                }
            }
        }
    }

    $defaultForbiddenPaths = @()
    foreach ($resource in @(Get-PropertyArray -Object $manifest -Name 'default_forbidden')) {
        $resourcePath = Resolve-ManifestResource -Resource $resource -Context 'default_forbidden'
        if ($null -ne $resourcePath) {
            $defaultForbiddenPaths += $resourcePath
        }
    }

    $dimensionNames = @('intent', 'data_structure', 'response_support', 'task_goal', 'risk')
    $vocabularyProperty = $manifest.PSObject.Properties['controlled_vocabulary']
    $allowedDimensionValues = @{}
    if ($null -eq $vocabularyProperty) {
        $errors.Add('MANIFEST_CONTROLLED_VOCABULARY missing')
    } else {
        foreach ($dimensionName in $dimensionNames) {
            $values = @(Get-PropertyArray -Object $vocabularyProperty.Value -Name $dimensionName |
                ForEach-Object { [string]$_ })
            if ($values.Count -eq 0) {
                $errors.Add("MANIFEST_VOCABULARY_EMPTY dimension=$dimensionName")
            }
            $allowedDimensionValues[$dimensionName] = $values
        }
    }

    foreach ($route in $routes) {
        $routeId = [string]$route.id
        if ([string]::IsNullOrWhiteSpace($routeId)) {
            $errors.Add('EMPTY_ROUTE_ID')
            continue
        }
        if ([string]::IsNullOrWhiteSpace([string]$route.label) -or
            [string]::IsNullOrWhiteSpace([string]$route.description)) {
            $errors.Add("ROUTE_DESCRIPTION_MISSING route=$routeId")
        }

        foreach ($stageName in @(
            @(Get-PropertyArray -Object $route -Name 'default_stages') +
            @(Get-PropertyArray -Object $route -Name 'deferred_stages')
        )) {
            if (-not $stageIdSet.ContainsKey([string]$stageName)) {
                $errors.Add("UNKNOWN_ROUTE_STAGE route=$routeId stage=$stageName")
            }
        }
        $stageOverlap = @(
            @(Get-PropertyArray -Object $route -Name 'default_stages') |
            Where-Object { $_ -in @(Get-PropertyArray -Object $route -Name 'deferred_stages') }
        )
        foreach ($stageName in $stageOverlap) {
            $errors.Add("ROUTE_STAGE_OVERLAP route=$routeId stage=$stageName")
        }

        $resourceStages = @(Get-PropertyArray -Object $route -Name 'resource_stages' |
            ForEach-Object { [string]$_ })
        if ($resourceStages.Count -eq 0) {
            $errors.Add("ROUTE_RESOURCE_STAGES_EMPTY route=$routeId")
        }
        foreach ($duplicate in @($resourceStages | Group-Object | Where-Object { $_.Count -gt 1 })) {
            $errors.Add("ROUTE_RESOURCE_STAGE_DUPLICATE route=$routeId stage=$($duplicate.Name)")
        }
        if ('any' -in $resourceStages -and $resourceStages.Count -ne 1) {
            $errors.Add("ROUTE_RESOURCE_STAGE_ANY_MIXED route=$routeId")
        }
        foreach ($resourceStage in $resourceStages) {
            if ($resourceStage -ne 'any' -and -not $stageIdSet.ContainsKey($resourceStage)) {
                $errors.Add("ROUTE_RESOURCE_STAGE_UNKNOWN route=$routeId stage=$resourceStage")
            }
        }

        $dimensionProperty = $route.PSObject.Properties['dimensions']
        if ($null -eq $dimensionProperty) {
            $errors.Add("ROUTE_DIMENSIONS_MISSING route=$routeId")
        } else {
            foreach ($dimensionName in $dimensionNames) {
                $values = @(Get-PropertyArray -Object $dimensionProperty.Value -Name $dimensionName |
                    ForEach-Object { [string]$_ })
                if ($values.Count -eq 0) {
                    $errors.Add("ROUTE_DIMENSION_EMPTY route=$routeId dimension=$dimensionName")
                }
                if ($allowedDimensionValues.ContainsKey($dimensionName)) {
                    foreach ($value in $values) {
                        if ($value -notin $allowedDimensionValues[$dimensionName]) {
                            $errors.Add("ROUTE_DIMENSION_UNKNOWN route=$routeId dimension=$dimensionName value=$value")
                        }
                    }
                }
            }
        }

        $seenRoutePaths = @{}
        foreach ($category in @('required', 'optional', 'deferred', 'forbidden')) {
            foreach ($resource in @(Get-PropertyArray -Object $route -Name $category)) {
                $resourcePath = Resolve-ManifestResource -Resource $resource -Context "route:${routeId}:$category"
                if ($null -ne $resourcePath) {
                    if ($seenRoutePaths.ContainsKey($resourcePath)) {
                        $errors.Add("MANIFEST_ROUTE_CATEGORY_OVERLAP route=$routeId path=$resourcePath first=$($seenRoutePaths[$resourcePath]) second=$category")
                    }
                    $seenRoutePaths[$resourcePath] = $category
                    if (-not [bool]$route.conditional -and
                        $category -in @('required', 'optional') -and
                        $resourcePath -in $defaultForbiddenPaths) {
                        $errors.Add("DEFAULT_FORBIDDEN_ACTIVE route=$routeId path=$resourcePath")
                    }
                }
            }
        }
    }

    $budgetProperty = $manifest.PSObject.Properties['budgets']
    if ($null -eq $budgetProperty) {
        $errors.Add('MANIFEST_BUDGETS missing')
    } else {
        $permanentMax = [int64]$budgetProperty.Value.permanent_max_bytes
        $lightweightMax = [int64]$budgetProperty.Value.lightweight_entry_max_bytes
        if ($permanentMax -le 0 -or $lightweightMax -le 0) {
            $errors.Add('MANIFEST_BUDGET_LIMIT invalid')
        } else {
            if ($permanentBytes -gt $permanentMax) {
                $errors.Add("PERMANENT_BUDGET actual=$permanentBytes max=$permanentMax")
            }
            foreach ($entry in @(Get-PropertyArray -Object $budgetProperty.Value -Name 'lightweight_entries')) {
                $entryPath = [string]$entry
                $fullEntryPath = Join-Path $root ($entryPath -replace '/', [IO.Path]::DirectorySeparatorChar)
                if (-not (Test-Path -LiteralPath $fullEntryPath -PathType Leaf)) {
                    $errors.Add("LIGHTWEIGHT_ENTRY_MISSING path=$entryPath")
                } else {
                    $entryBytes = (Get-Item -LiteralPath $fullEntryPath).Length
                    if ($entryBytes -gt $lightweightMax) {
                        $errors.Add("LIGHTWEIGHT_ENTRY_BUDGET path=$entryPath actual=$entryBytes max=$lightweightMax")
                    }
                }
            }
        }
    }

    $generatedRoutingPath = Join-Path $root '00B_任务路由与最小读取集.md'
    if (-not (Test-Path -LiteralPath $generatedRoutingPath -PathType Leaf)) {
        $errors.Add('GENERATED_ROUTING_DOC missing=00B_任务路由与最小读取集.md')
    } else {
        $generatedText = Get-Content -LiteralPath $generatedRoutingPath -Raw -Encoding UTF8
        $manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
        if ($generatedText -notmatch 'SOURCE=routing-manifest\.yaml;\s*SHA256=([A-Fa-f0-9]{64});') {
            $errors.Add('GENERATED_ROUTING_DOC missing_manifest_hash')
        } elseif ($Matches[1].ToUpperInvariant() -ne $manifestHash) {
            $errors.Add("GENERATED_ROUTING_DOC stale expected=$manifestHash actual=$($Matches[1].ToUpperInvariant())")
        }
    }
}

$routeTestOutput = @()
$routeTestStatus = 'SKIPPED'
if (-not $SkipRoutingTests) {
    $routeTestPath = Join-Path $root 'tools\test_routing.ps1'
    if (-not (Test-Path -LiteralPath $routeTestPath -PathType Leaf)) {
        $errors.Add('MISSING tools/test_routing.ps1')
        $routeTestStatus = 'MISSING'
    } else {
        $pwshPath = Join-Path $PSHOME 'pwsh.exe'
        $routeTestOutput = @(& $pwshPath -NoProfile -File $routeTestPath -LibraryRoot $root 2>&1)
        $routeExitCode = $LASTEXITCODE
        if ($routeExitCode -ne 0) {
            $errors.Add("ROUTING_TEST_FAILED exit=$routeExitCode")
            $routeTestStatus = 'FAIL'
        } else {
            $routeTestStatus = 'PASS'
        }
    }
}

$sourceRegistryPath = Join-Path $root 'evidence\source_registry.json'
$claimsRegistryPath = Join-Path $root 'evidence\claims_registry.json'
$evidenceRegistryStatus = 'NOT_CONFIGURED'
if ((Test-Path -LiteralPath $sourceRegistryPath) -or (Test-Path -LiteralPath $claimsRegistryPath)) {
    $evidenceRegistryStatus = 'PARTIAL'
    if (-not (Test-Path -LiteralPath $sourceRegistryPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $claimsRegistryPath -PathType Leaf)) {
        $errors.Add('EVIDENCE_REGISTRY requires both source_registry.json and claims_registry.json')
    } else {
        try {
            $sourceRegistry = Get-Content -LiteralPath $sourceRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $claimsRegistry = Get-Content -LiteralPath $claimsRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ([string]::IsNullOrWhiteSpace([string]$sourceRegistry.schema_version) -or
                [string]::IsNullOrWhiteSpace([string]$claimsRegistry.schema_version)) {
                $errors.Add('EVIDENCE_REGISTRY_SCHEMA_VERSION missing')
            }
            $sourceEntries = @($sourceRegistry.entries)
            $claimEntries = @($claimsRegistry.entries)
            if ($sourceEntries.Count -eq 0 -or $claimEntries.Count -eq 0) {
                $errors.Add('EVIDENCE_REGISTRY_ENTRIES must_be_nonempty')
            }
            $registrySourceIds = @($sourceEntries | ForEach-Object { [string]$_.source_id })
            foreach ($duplicate in @($registrySourceIds | Group-Object | Where-Object { $_.Count -gt 1 })) {
                $errors.Add("DUPLICATE_REGISTRY_SOURCE_ID id=$($duplicate.Name)")
            }
            $allowedStatuses = @('已核验', '条件通过', '案例线索', '待核验', '已隔离')
            $allowedGrades = @('A', 'A/B', 'B', 'C', 'D')
            foreach ($sourceEntry in $sourceEntries) {
                $registryId = [string]$sourceEntry.source_id
                if ([string]::IsNullOrWhiteSpace($registryId)) {
                    $errors.Add('EMPTY_REGISTRY_SOURCE_ID')
                    continue
                }
                if (-not $sourceIdSet.ContainsKey($registryId)) {
                    $errors.Add("REGISTRY_SOURCE_NOT_IN_LEDGER id=$registryId")
                }
                foreach ($field in @('title', 'url', 'accessed_at')) {
                    $property = $sourceEntry.PSObject.Properties[$field]
                    if ($null -eq $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) {
                        $errors.Add("REGISTRY_SOURCE_FIELD_MISSING id=$registryId field=$field")
                    }
                }
                if ([string]$sourceEntry.evidence_grade -notin $allowedGrades) {
                    $errors.Add("INVALID_REGISTRY_SOURCE_GRADE id=$registryId grade=$($sourceEntry.evidence_grade)")
                }
                if ([string]$sourceEntry.status -notin $allowedStatuses) {
                    $errors.Add("INVALID_REGISTRY_SOURCE_STATUS id=$registryId status=$($sourceEntry.status)")
                }
            }
            $claimIds = @($claimEntries | ForEach-Object { [string]$_.claim_id })
            foreach ($duplicate in @($claimIds | Group-Object | Where-Object { $_.Count -gt 1 })) {
                $errors.Add("DUPLICATE_CLAIM_ID id=$($duplicate.Name)")
            }
            foreach ($claim in $claimEntries) {
                $claimId = [string]$claim.claim_id
                if ([string]::IsNullOrWhiteSpace($claimId) -or
                    [string]::IsNullOrWhiteSpace([string]$claim.statement)) {
                    $errors.Add("CLAIM_REQUIRED_FIELD_MISSING id=$claimId")
                }
                if ([string]$claim.status -notin $allowedStatuses) {
                    $errors.Add("INVALID_CLAIM_STATUS id=$claimId status=$($claim.status)")
                }
                $claimEvidence = @($claim.evidence)
                $claimLocations = @($claim.locations | ForEach-Object { [string]$_ })
                if ($claimEvidence.Count -eq 0 -or $claimLocations.Count -eq 0) {
                    $errors.Add("CLAIM_BINDING_MISSING id=$claimId")
                }
                foreach ($evidence in $claimEvidence) {
                    if ([string]$evidence.source_id -notin $registrySourceIds) {
                        $errors.Add("UNKNOWN_CLAIM_SOURCE claim=$claimId source=$($evidence.source_id)")
                    }
                    if ([string]::IsNullOrWhiteSpace([string]$evidence.locator) -or
                        [string]::IsNullOrWhiteSpace([string]$evidence.support)) {
                        $errors.Add("CLAIM_EVIDENCE_FIELD_MISSING claim=$claimId source=$($evidence.source_id)")
                    }
                }
                $claimSourceIds = @($claimEvidence | ForEach-Object { [string]$_.source_id })
                foreach ($location in $claimLocations) {
                    $locationPath = $location.Split('#')[0]
                    if ([IO.Path]::IsPathRooted($locationPath)) {
                        $errors.Add("CLAIM_LOCATION_ABSOLUTE claim=$claimId location=$location")
                        continue
                    }
                    $localLocation = Join-Path $root ($locationPath -replace '/', [IO.Path]::DirectorySeparatorChar)
                    if (-not (Test-Path -LiteralPath $localLocation -PathType Leaf)) {
                        $errors.Add("CLAIM_LOCATION_MISSING claim=$claimId location=$location")
                        continue
                    }
                    $matchingRefs = @($explicitSourceRefs | Where-Object {
                        [string]$_.File -eq $locationPath -and [string]$_.Id -in $claimSourceIds
                    })
                    if ($matchingRefs.Count -eq 0) {
                        $errors.Add("CLAIM_LOCATION_UNBOUND claim=$claimId location=$location")
                    }
                }
                if ($null -ne $claim.PSObject.Properties['review_due'] -and
                    -not [string]::IsNullOrWhiteSpace([string]$claim.review_due)) {
                    $reviewDue = [datetime]::MinValue
                    if (-not [datetime]::TryParse([string]$claim.review_due, [ref]$reviewDue)) {
                        $errors.Add("INVALID_REVIEW_DUE claim=$claimId value=$($claim.review_due)")
                    } elseif ($reviewDue.Date -lt (Get-Date).Date) {
                        $warnings.Add("CLAIM_REVIEW_DUE claim=$claimId due=$($reviewDue.ToString('yyyy-MM-dd'))")
                    }
                }
            }
            $evidenceRegistryStatus = 'VALIDATED'
        } catch {
            $errors.Add("INVALID_EVIDENCE_REGISTRY $($_.Exception.Message)")
        }
    }
}

$hashGroups = @($markdownFiles | Get-FileHash -Algorithm SHA256 | Group-Object Hash |
    Where-Object { $_.Count -gt 1 })
foreach ($group in $hashGroups) {
    $paths = ($group.Group.Path | ForEach-Object { Get-RelativeLibraryPath -FullName $_ }) -join ', '
    $warnings.Add("DUPLICATE_MARKDOWN $paths")
}

$urlCount = 0
$filesWithExternalUrls = 0
foreach ($file in $markdownFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $fileUrlCount = ([regex]::Matches($text, 'https?://')).Count
    $urlCount += $fileUrlCount
    if ($fileUrlCount -gt 0) {
        $filesWithExternalUrls++
    }
}

$nonMarkdown = @($allFiles | Where-Object { $_.Extension -ne '.md' })
$zeroByteFiles = @($allFiles | Where-Object { $_.Length -eq 0 })
foreach ($file in $zeroByteFiles) {
    $errors.Add("ZERO_BYTE_FILE $(Get-RelativeLibraryPath -FullName $file.FullName)")
}

foreach ($file in $nonMarkdown) {
    $relative = Get-RelativeLibraryPath -FullName $file.FullName
    if ($file.Extension -eq '.json') {
        try {
            $null = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {
            $errors.Add("INVALID_JSON $relative")
        }
    }

    if ($file.Extension -in @('.pdf', '.jpg')) {
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        if ($file.Extension -eq '.pdf') {
            $validSignature = $bytes.Length -ge 4 -and $bytes[0] -eq 0x25 -and
                $bytes[1] -eq 0x50 -and $bytes[2] -eq 0x44 -and $bytes[3] -eq 0x46
        } else {
            $validSignature = $bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8
        }
        if (-not $validSignature) {
            $errors.Add("FILE_SIGNATURE $relative")
        }
    }
}

$nonMarkdownHashGroups = @($nonMarkdown | Get-FileHash -Algorithm SHA256 | Group-Object Hash |
    Where-Object { $_.Count -gt 1 })
foreach ($group in $nonMarkdownHashGroups) {
    $paths = ($group.Group.Path | ForEach-Object { Get-RelativeLibraryPath -FullName $_ }) -join ', '
    $warnings.Add("DUPLICATE_NON_MARKDOWN $paths")
}

$nonMarkdownSummary = ($nonMarkdown | Group-Object Extension | Sort-Object Name |
    ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ','

$infos.Add("SOURCE_IDS=$($sourceIds.Count)")
$infos.Add("EXPLICIT_SOURCE_REFS=$($explicitSourceRefs.Count)")
$infos.Add("BACKTICK_FILE_REFS=$backtickFileRefs")
$infos.Add("EXTERNAL_FILE_REFS=$externalFileRefs")
$infos.Add("EXTERNAL_REPO_REFS=$externalRepoRefs")
$infos.Add("TOMBSTONE_REFS=$tombstoneRefs")
$infos.Add("MANIFEST_ROUTES=$manifestRouteCount")
$infos.Add("MANIFEST_STAGES=$manifestStageCount")
$infos.Add("PERMANENT_BYTES=$permanentBytes")
$infos.Add("EVIDENCE_REGISTRY=$evidenceRegistryStatus")
$infos.Add("ROUTING_TEST_STATUS=$routeTestStatus")

"LIBRARY_ROOT=$root"
"TOTAL_FILES=$($allFiles.Count)"
"MARKDOWN_FILES=$($markdownFiles.Count)"
"MARKDOWN_BYTES=$(($markdownFiles | Measure-Object Length -Sum).Sum)"
"NON_MARKDOWN_FILES=$($nonMarkdown.Count)"
"NON_MARKDOWN_BY_EXTENSION=$nonMarkdownSummary"
"EXTERNAL_URL_OCCURRENCES=$urlCount"
"FILES_WITH_EXTERNAL_URLS=$filesWithExternalUrls"
"INFOS=$($infos.Count)"
foreach ($infoItem in $infos) { "INFO $infoItem" }
if ($routeTestOutput.Count -gt 0) {
    "ROUTING_TEST_OUTPUT_BEGIN"
    foreach ($routeLine in $routeTestOutput) { "ROUTING_TEST $routeLine" }
    "ROUTING_TEST_OUTPUT_END"
}
"WARNINGS=$($warnings.Count)"
foreach ($warning in $warnings) { "WARNING $warning" }
"ERRORS=$($errors.Count)"
foreach ($errorItem in $errors) { "ERROR $errorItem" }

if ($errors.Count -gt 0) {
    'AUDIT_STATUS=FAIL'
    exit 1
}

'AUDIT_STATUS=PASS'
exit 0
