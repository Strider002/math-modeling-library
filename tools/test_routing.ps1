[CmdletBinding()]
param(
    [string]$LibraryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$CasesPath,
    [switch]$SkipGeneratedDocCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $LibraryRoot).Path
$routerPath = Join-Path $root 'tools\route_knowledge.ps1'
$generatorPath = Join-Path $root 'tools\generate_routing_docs.ps1'
$manifestPath = Join-Path $root 'routing-manifest.yaml'
if ([string]::IsNullOrWhiteSpace($CasesPath)) {
    $CasesPath = Join-Path $root 'tests\routing_cases.json'
}

foreach ($requiredFile in @($routerPath, $generatorPath, $manifestPath, $CasesPath)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required routing test input not found: $requiredFile"
    }
}

try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    throw "Manifest is not valid JSON-compatible YAML 1.2: $($_.Exception.Message)"
}

try {
    $suite = Get-Content -LiteralPath $CasesPath -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    throw "Routing case file is not valid JSON: $($_.Exception.Message)"
}

$cases = @($suite.cases)
if ($cases.Count -lt 12 -or $cases.Count -gt 30) {
    throw "Routing case count must be between 12 and 30; actual=$($cases.Count)."
}
foreach ($duplicate in @($cases.id | Group-Object | Where-Object { $_.Count -gt 1 })) {
    throw "Duplicate routing case id '$($duplicate.Name)'."
}

$manifestRouteIds = @($manifest.routes | ForEach-Object { [string]$_.id })
$manifestConditionalRouteIds = @(
    $manifest.routes |
        Where-Object { [bool]$_.conditional } |
        ForEach-Object { [string]$_.id }
)
$defaultForbiddenPaths = @($manifest.default_forbidden | ForEach-Object { [string]$_.path })
$dimensionNames = @('intent', 'data_structure', 'response_support', 'task_goal', 'risk')
foreach ($dimensionName in $dimensionNames) {
    $allowedProperty = $manifest.controlled_vocabulary.PSObject.Properties[$dimensionName]
    if ($null -eq $allowedProperty -or @($allowedProperty.Value).Count -eq 0) {
        throw "controlled_vocabulary.$dimensionName must be non-empty."
    }
    $allowed = @($allowedProperty.Value | ForEach-Object { [string]$_ })
    foreach ($route in $manifest.routes) {
        $dimensionProperty = $route.dimensions.PSObject.Properties[$dimensionName]
        if ($null -eq $dimensionProperty -or @($dimensionProperty.Value).Count -eq 0) {
            throw "Route '$($route.id)' dimensions.$dimensionName must be non-empty."
        }
        foreach ($value in @($dimensionProperty.Value | ForEach-Object { [string]$_ })) {
            if ($value -notin $allowed) {
                throw "Route '$($route.id)' dimensions.$dimensionName has unknown value '$value'."
            }
        }
    }
}
$stageIds = @($manifest.stages | ForEach-Object { [string]$_.id })
foreach ($route in $manifest.routes) {
    $resourceStages = @($route.resource_stages | ForEach-Object { [string]$_ })
    if ($resourceStages.Count -eq 0) {
        throw "Route '$($route.id)' resource_stages must be non-empty."
    }
    if ('any' -in $resourceStages -and $resourceStages.Count -ne 1) {
        throw "Route '$($route.id)' resource_stages cannot combine any with stage ids."
    }
    foreach ($resourceStage in $resourceStages) {
        if ($resourceStage -ne 'any' -and $resourceStage -notin $stageIds) {
            throw "Route '$($route.id)' resource_stages has unknown stage '$resourceStage'."
        }
    }
}
if ([string]$manifest.budgets.metric -ne 'bytes') {
    throw 'Manifest budget metric must be bytes.'
}
if ([int64]$manifest.budgets.permanent_max_bytes -le 0 -or
    [int64]$manifest.budgets.lightweight_entry_max_bytes -le 0 -or
    @($manifest.budgets.lightweight_entries).Count -eq 0) {
    throw 'Manifest byte budgets must be positive and declare at least one lightweight entry.'
}

$listJson = & $routerPath -ManifestPath $manifestPath -ListRoutes -AsJson
if ($LASTEXITCODE -ne 0) {
    throw "route_knowledge.ps1 -ListRoutes failed with exit code $LASTEXITCODE."
}
$listedRoutes = @($listJson | ConvertFrom-Json)
$listedRouteIds = @($listedRoutes | ForEach-Object { [string]$_.id })
if (@(Compare-Object ($manifestRouteIds | Sort-Object) ($listedRouteIds | Sort-Object)).Count -ne 0) {
    throw 'Route list output differs from manifest route ids.'
}
foreach ($listedRoute in $listedRoutes) {
    if (@($listedRoute.resource_stages).Count -eq 0) {
        throw "ListRoutes omitted resource_stages for '$($listedRoute.id)'."
    }
    foreach ($dimensionName in $dimensionNames) {
        $dimensionProperty = $listedRoute.dimensions.PSObject.Properties[$dimensionName]
        if ($null -eq $dimensionProperty -or @($dimensionProperty.Value).Count -eq 0) {
            throw "ListRoutes omitted dimensions.$dimensionName for '$($listedRoute.id)'."
        }
    }
}

$failures = [System.Collections.Generic.List[string]]::new()
$passed = 0

if (-not $SkipGeneratedDocCheck) {
    $docCheckOutput = & $generatorPath -ManifestPath $manifestPath -OutputPath (Join-Path $root '00B_任务路由与最小读取集.md') -Check
    if ($LASTEXITCODE -ne 0) {
        $failures.Add('generated_doc: 00B is stale or missing. ' + ($docCheckOutput -join ' '))
    }
}

foreach ($case in $cases) {
    $caseId = [string]$case.id
    $caseFailures = [System.Collections.Generic.List[string]]::new()
    $routeIds = @($case.route_ids | ForEach-Object { [string]$_ })
    $stages = @($case.stages | ForEach-Object { [string]$_ })
    $must = @($case.must | ForEach-Object { [string]$_ })
    $mustNot = @($case.must_not | ForEach-Object { [string]$_ })
    $requiredGates = @($case.required_gates | ForEach-Object { [string]$_ })

    if (-not [bool]$case.trigger) {
        if ($routeIds.Count -ne 0) {
            $caseFailures.Add('non-trigger case must not declare route_ids')
        }
        if ($stages.Count -ne 0) {
            $caseFailures.Add('non-trigger case must not declare stages')
        }
        if ($must.Count -ne 0 -or $requiredGates.Count -ne 0) {
            $caseFailures.Add('non-trigger case must not load files or gates')
        }
    } else {
        if ($routeIds.Count -eq 0) {
            $caseFailures.Add('triggered case must declare at least one route_id')
        }
        foreach ($routeId in $routeIds) {
            if ($routeId -notin $manifestRouteIds) {
                $caseFailures.Add("unknown route_id '$routeId'")
            }
        }

        if ($caseFailures.Count -eq 0) {
            try {
                $invoke = @{
                    ManifestPath = $manifestPath
                    RouteId = [string[]]$routeIds
                    AsJson = $true
                }
                if ($stages.Count -gt 0) {
                    $invoke.Stage = [string[]]$stages
                }
                $resolvedJson = & $routerPath @invoke
                if ($LASTEXITCODE -ne 0) {
                    throw "router exited with code $LASTEXITCODE"
                }
                $resolved = $resolvedJson | ConvertFrom-Json
            } catch {
                $caseFailures.Add('router failure: ' + $_.Exception.Message)
                $resolved = $null
            }

            if ($null -ne $resolved) {
                $requiredPaths = @($resolved.required | ForEach-Object { [string]$_.path })
                $optionalPaths = @($resolved.optional | ForEach-Object { [string]$_.path })
                $deferredPaths = @($resolved.deferred | ForEach-Object { [string]$_.path })
                $forbiddenPaths = @($resolved.forbidden | ForEach-Object { [string]$_.path })
                $activeLoadPaths = @($requiredPaths + $optionalPaths | Sort-Object -Unique)

                foreach ($path in $must) {
                    if ($path -notin $requiredPaths) {
                        $caseFailures.Add("must path is not required: $path")
                    }
                }
                foreach ($path in $requiredGates) {
                    if ($path -notin $requiredPaths) {
                        $caseFailures.Add("required gate is not required: $path")
                    }
                }
                foreach ($path in $mustNot) {
                    if ($path -in $activeLoadPaths) {
                        $caseFailures.Add("must_not path is active: $path")
                    }
                }

                $selectedConditional = @($routeIds | Where-Object { $_ -in $manifestConditionalRouteIds })
                if ($selectedConditional.Count -eq 0) {
                    foreach ($path in $defaultForbiddenPaths) {
                        if ($path -notin $forbiddenPaths) {
                            $caseFailures.Add("default forbidden path is not forbidden: $path")
                        }
                        if ($path -in $activeLoadPaths) {
                            $caseFailures.Add("default forbidden path became active: $path")
                        }
                    }
                }

                $categories = @{
                    required = $requiredPaths
                    optional = $optionalPaths
                    deferred = $deferredPaths
                    forbidden = $forbiddenPaths
                }
                $categoryNames = @('required', 'optional', 'deferred', 'forbidden')
                for ($i = 0; $i -lt $categoryNames.Count; $i++) {
                    for ($j = $i + 1; $j -lt $categoryNames.Count; $j++) {
                        $leftName = $categoryNames[$i]
                        $rightName = $categoryNames[$j]
                        $overlap = @($categories[$leftName] | Where-Object { $_ -in $categories[$rightName] })
                        foreach ($path in $overlap) {
                            $caseFailures.Add(('path appears in both {0} and {1}: {2}' -f $leftName, $rightName, $path))
                        }
                    }
                }

                foreach ($category in $categoryNames) {
                    foreach ($entry in @($resolved.$category)) {
                        if (-not [bool]$entry.exists) {
                            $caseFailures.Add("router did not confirm path existence: $($entry.path)")
                        }
                        if (@($entry.reasons).Count -eq 0) {
                            $caseFailures.Add("router returned path without reason: $($entry.path)")
                        }
                    }
                }
            }
        }
    }

    if ($caseFailures.Count -eq 0) {
        $passed++
        Write-Output "PASS $caseId"
    } else {
        foreach ($failure in $caseFailures) {
            $failures.Add(('{0}: {1}' -f $caseId, $failure))
        }
        Write-Output "FAIL $caseId"
    }
}

Write-Output "ROUTING_CASES=$($cases.Count)"
Write-Output "PASSED=$passed"
Write-Output "FAILED=$($failures.Count)"
foreach ($failure in $failures) {
    Write-Output "ERROR $failure"
}

if ($failures.Count -gt 0) {
    Write-Output 'ROUTING_TEST_STATUS=FAIL'
    exit 1
}

Write-Output 'ROUTING_TEST_STATUS=PASS'
exit 0
