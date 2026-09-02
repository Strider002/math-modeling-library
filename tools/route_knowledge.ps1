[CmdletBinding(DefaultParameterSetName = 'Resolve')]
param(
    [Parameter(ParameterSetName = 'List', Mandatory = $true)]
    [switch]$ListRoutes,

    [Parameter(ParameterSetName = 'Resolve')]
    [string[]]$RouteId,

    [Parameter(ParameterSetName = 'Resolve')]
    [string[]]$Stage,

    [Parameter(ParameterSetName = 'List')]
    [Parameter(ParameterSetName = 'Resolve')]
    [switch]$AsJson,

    [Parameter(ParameterSetName = 'List')]
    [Parameter(ParameterSetName = 'Resolve')]
    [string]$ManifestPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'routing-manifest.yaml')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Assert-UniqueIds {
    param(
        [Parameter(Mandatory = $true)][object[]]$Items,
        [Parameter(Mandatory = $true)][string]$Kind
    )

    $ids = @($Items | ForEach-Object { [string]$_.id })
    foreach ($empty in @($ids | Where-Object { [string]::IsNullOrWhiteSpace($_) })) {
        throw "$Kind contains an empty id."
    }
    foreach ($duplicate in @($ids | Group-Object | Where-Object { $_.Count -gt 1 })) {
        throw "$Kind id '$($duplicate.Name)' is duplicated."
    }
}

function Assert-Resource {
    param(
        [Parameter(Mandatory = $true)]$Resource,
        [Parameter(Mandatory = $true)][string]$Context
    )

    if ($null -eq $Resource.PSObject.Properties['path'] -or
        [string]::IsNullOrWhiteSpace([string]$Resource.path)) {
        throw "$Context contains a resource without path."
    }
    if ($null -eq $Resource.PSObject.Properties['reason'] -or
        [string]::IsNullOrWhiteSpace([string]$Resource.reason)) {
        throw "$Context resource '$($Resource.path)' has no reason."
    }
}

function Read-RoutingManifest {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Routing manifest not found: $Path"
    }

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    try {
        $manifest = Get-Content -LiteralPath $resolved -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        throw "routing-manifest.yaml must be JSON-compatible YAML 1.2 (valid JSON): $($_.Exception.Message)"
    }

    if ([string]::IsNullOrWhiteSpace([string]$manifest.schema_version)) {
        throw 'Manifest schema_version is required.'
    }

    $stages = @(Get-PropertyArray -Object $manifest -Name 'stages')
    $routes = @(Get-PropertyArray -Object $manifest -Name 'routes')
    if ($stages.Count -eq 0) {
        throw 'Manifest must define at least one stage.'
    }
    if ($routes.Count -eq 0) {
        throw 'Manifest must define at least one route.'
    }

    Assert-UniqueIds -Items $stages -Kind 'Stage'
    Assert-UniqueIds -Items $routes -Kind 'Route'

    $dimensionNames = @('intent', 'data_structure', 'response_support', 'task_goal', 'risk')
    $controlledVocabularyProperty = $manifest.PSObject.Properties['controlled_vocabulary']
    if ($null -eq $controlledVocabularyProperty -or $null -eq $controlledVocabularyProperty.Value) {
        throw 'Manifest controlled_vocabulary is required.'
    }
    $controlledVocabulary = $controlledVocabularyProperty.Value
    $allowedValues = @{}
    foreach ($dimensionName in $dimensionNames) {
        $values = @(
            Get-PropertyArray -Object $controlledVocabulary -Name $dimensionName |
                ForEach-Object { [string]$_ }
        )
        if ($values.Count -eq 0) {
            throw "controlled_vocabulary.$dimensionName must be a non-empty array."
        }
        foreach ($duplicate in @($values | Group-Object | Where-Object { $_.Count -gt 1 })) {
            throw "controlled_vocabulary.$dimensionName duplicates '$($duplicate.Name)'."
        }
        $allowedValues[$dimensionName] = $values
    }

    $stageIds = @{}
    foreach ($stageItem in $stages) {
        $stageIds[[string]$stageItem.id] = $true
        foreach ($category in @('required', 'optional')) {
            foreach ($resource in @(Get-PropertyArray -Object $stageItem -Name $category)) {
                Assert-Resource -Resource $resource -Context "Stage '$($stageItem.id)' $category"
            }
        }
    }

    foreach ($resource in @(Get-PropertyArray -Object $manifest.permanent -Name 'required')) {
        Assert-Resource -Resource $resource -Context 'Permanent required'
    }
    foreach ($resource in @(Get-PropertyArray -Object $manifest -Name 'default_forbidden')) {
        Assert-Resource -Resource $resource -Context 'Default forbidden'
    }

    foreach ($route in $routes) {
        $dimensionsProperty = $route.PSObject.Properties['dimensions']
        if ($null -eq $dimensionsProperty -or $null -eq $dimensionsProperty.Value) {
            throw "Route '$($route.id)' must define dimensions."
        }
        foreach ($dimensionName in $dimensionNames) {
            $values = @(
                Get-PropertyArray -Object $route.dimensions -Name $dimensionName |
                    ForEach-Object { [string]$_ }
            )
            if ($values.Count -eq 0) {
                throw "Route '$($route.id)' dimensions.$dimensionName must be non-empty."
            }
            foreach ($duplicate in @($values | Group-Object | Where-Object { $_.Count -gt 1 })) {
                throw "Route '$($route.id)' dimensions.$dimensionName duplicates '$($duplicate.Name)'."
            }
            foreach ($value in $values) {
                if ($value -notin $allowedValues[$dimensionName]) {
                    throw "Route '$($route.id)' dimensions.$dimensionName has unknown value '$value'."
                }
            }
        }
        $resourceStages = @(
            Get-PropertyArray -Object $route -Name 'resource_stages' |
                ForEach-Object { [string]$_ }
        )
        if ($resourceStages.Count -eq 0) {
            throw "Route '$($route.id)' resource_stages must be non-empty."
        }
        foreach ($duplicate in @($resourceStages | Group-Object | Where-Object { $_.Count -gt 1 })) {
            throw "Route '$($route.id)' resource_stages duplicates '$($duplicate.Name)'."
        }
        if ('any' -in $resourceStages -and $resourceStages.Count -ne 1) {
            throw "Route '$($route.id)' resource_stages cannot combine 'any' with stage ids."
        }
        foreach ($resourceStage in $resourceStages) {
            if ($resourceStage -ne 'any' -and -not $stageIds.ContainsKey($resourceStage)) {
                throw "Route '$($route.id)' resource_stages has unknown stage '$resourceStage'."
            }
        }
        foreach ($stageName in @(
            @(Get-PropertyArray -Object $route -Name 'default_stages') +
            @(Get-PropertyArray -Object $route -Name 'deferred_stages')
        )) {
            if (-not $stageIds.ContainsKey([string]$stageName)) {
                throw "Route '$($route.id)' references unknown stage '$stageName'."
            }
        }
        foreach ($category in @('required', 'optional', 'deferred', 'forbidden')) {
            foreach ($resource in @(Get-PropertyArray -Object $route -Name $category)) {
                Assert-Resource -Resource $resource -Context "Route '$($route.id)' $category"
            }
        }
    }

    return [pscustomobject]@{
        Path = $resolved
        Root = Split-Path -Parent $resolved
        Data = $manifest
        Stages = $stages
        Routes = $routes
    }
}

$loaded = Read-RoutingManifest -Path $ManifestPath
$manifest = $loaded.Data
$manifestRoot = $loaded.Root
$stageItems = $loaded.Stages
$routeItems = $loaded.Routes

$stageIndex = @{}
foreach ($stageItem in $stageItems) {
    $stageIndex[[string]$stageItem.id] = $stageItem
}

$routeIndex = @{}
foreach ($routeItem in $routeItems) {
    $routeIndex[[string]$routeItem.id] = $routeItem
}

if ($ListRoutes) {
    $listed = @(
        $routeItems |
            Sort-Object { [string]$_.id } |
            ForEach-Object {
                [pscustomobject]@{
                    id = [string]$_.id
                    label = [string]$_.label
                    conditional = [bool]$_.conditional
                    description = [string]$_.description
                    signals = @((Get-PropertyArray -Object $_ -Name 'signals') | ForEach-Object { [string]$_ })
                    resource_stages = @((Get-PropertyArray -Object $_ -Name 'resource_stages') | ForEach-Object { [string]$_ })
                    default_stages = @((Get-PropertyArray -Object $_ -Name 'default_stages') | ForEach-Object { [string]$_ })
                    dimensions = [pscustomobject]@{
                        intent = @((Get-PropertyArray -Object $_.dimensions -Name 'intent') | ForEach-Object { [string]$_ })
                        data_structure = @((Get-PropertyArray -Object $_.dimensions -Name 'data_structure') | ForEach-Object { [string]$_ })
                        response_support = @((Get-PropertyArray -Object $_.dimensions -Name 'response_support') | ForEach-Object { [string]$_ })
                        task_goal = @((Get-PropertyArray -Object $_.dimensions -Name 'task_goal') | ForEach-Object { [string]$_ })
                        risk = @((Get-PropertyArray -Object $_.dimensions -Name 'risk') | ForEach-Object { [string]$_ })
                    }
                }
            }
    )

    if ($AsJson) {
        $listed | ConvertTo-Json -Depth 8
    } else {
        foreach ($route in $listed) {
            Write-Output ("$($route.id) | $($route.label) | conditional=$($route.conditional)")
            Write-Output ('  resource_stages: ' + ($route.resource_stages -join ', '))
            Write-Output ('  default_stages: ' + ($route.default_stages -join ', '))
            Write-Output ('  intent: ' + ($route.dimensions.intent -join ', '))
            Write-Output ('  data_structure: ' + ($route.dimensions.data_structure -join ', '))
            Write-Output ('  response_support: ' + ($route.dimensions.response_support -join ', '))
            Write-Output ('  task_goal: ' + ($route.dimensions.task_goal -join ', '))
            Write-Output ('  risk: ' + ($route.dimensions.risk -join ', '))
            Write-Output ('  signals: ' + ($route.signals -join '；'))
        }
    }
    exit 0
}

$requestedRouteIds = @($RouteId | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
$stageWasExplicit = $PSBoundParameters.ContainsKey('Stage')
$requestedStages = @($Stage | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })

if ($requestedRouteIds.Count -eq 0 -and $requestedStages.Count -eq 0) {
    throw 'Specify at least one -RouteId or -Stage, or use -ListRoutes.'
}

$selectedRoutes = @()
foreach ($id in $requestedRouteIds) {
    if (-not $routeIndex.ContainsKey([string]$id)) {
        $available = (@($routeIndex.Keys) | Sort-Object) -join ', '
        throw "Unknown route id '$id'. Available: $available"
    }
    $selectedRoutes += $routeIndex[[string]$id]
}

if ($stageWasExplicit) {
    $activeStageIds = @($requestedStages | Sort-Object -Unique)
} else {
    $activeStageIds = @(
        $selectedRoutes |
            ForEach-Object { Get-PropertyArray -Object $_ -Name 'default_stages' } |
            ForEach-Object { [string]$_ } |
            Sort-Object -Unique
    )
}

foreach ($stageId in $activeStageIds) {
    if (-not $stageIndex.ContainsKey([string]$stageId)) {
        $available = (@($stageIndex.Keys) | Sort-Object) -join ', '
        throw "Unknown stage '$stageId'. Available: $available"
    }
}

$buckets = @{
    required = @{}
    optional = @{}
    deferred = @{}
    forbidden = @{}
}

function Add-ResolvedResource {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('required', 'optional', 'deferred', 'forbidden')]
        [string]$Category,
        [Parameter(Mandatory = $true)]$Resource,
        [Parameter(Mandatory = $true)][string]$Source
    )

    $path = ([string]$Resource.path).Trim()
    $reason = ([string]$Resource.reason).Trim()
    if (-not $buckets[$Category].ContainsKey($path)) {
        $buckets[$Category][$path] = [System.Collections.Generic.List[string]]::new()
    }
    $message = if ([string]::IsNullOrWhiteSpace($Source)) { $reason } else { "$Source：$reason" }
    if (-not $buckets[$Category][$path].Contains($message)) {
        $buckets[$Category][$path].Add($message)
    }
}

foreach ($resource in @(Get-PropertyArray -Object $manifest -Name 'default_forbidden')) {
    Add-ResolvedResource -Category forbidden -Resource $resource -Source '默认边界'
}

foreach ($resource in @(Get-PropertyArray -Object $manifest.permanent -Name 'required')) {
    Add-ResolvedResource -Category required -Resource $resource -Source '永久门禁'
}

$routeScopes = @()
foreach ($route in $selectedRoutes) {
    $resourceStages = @(
        Get-PropertyArray -Object $route -Name 'resource_stages' |
            ForEach-Object { [string]$_ }
    )
    $resourceActive = ('any' -in $resourceStages) -or
        (@($activeStageIds | Where-Object { $_ -in $resourceStages }).Count -gt 0)
    $routeScopes += [pscustomobject]@{
        id = [string]$route.id
        resource_stages = $resourceStages
        resource_active = $resourceActive
    }

    foreach ($category in @('required', 'optional')) {
        $targetCategory = if ($resourceActive) { $category } else { 'deferred' }
        $source = if ($resourceActive) {
            "路由 $($route.id)"
        } else {
            "路由 $($route.id)（当前阶段不在资源作用域）"
        }
        foreach ($resource in @(Get-PropertyArray -Object $route -Name $category)) {
            Add-ResolvedResource -Category $targetCategory -Resource $resource -Source $source
        }
    }
    foreach ($resource in @(Get-PropertyArray -Object $route -Name 'deferred')) {
        Add-ResolvedResource -Category deferred -Resource $resource -Source "路由 $($route.id)"
    }
    foreach ($resource in @(Get-PropertyArray -Object $route -Name 'forbidden')) {
        Add-ResolvedResource -Category forbidden -Resource $resource -Source "路由 $($route.id)"
    }
}

foreach ($stageId in $activeStageIds) {
    $stageItem = $stageIndex[[string]$stageId]
    foreach ($category in @('required', 'optional')) {
        foreach ($resource in @(Get-PropertyArray -Object $stageItem -Name $category)) {
            Add-ResolvedResource -Category $category -Resource $resource -Source "阶段 $stageId"
        }
    }
}

$deferredStageIds = @(
    $selectedRoutes |
        ForEach-Object { Get-PropertyArray -Object $_ -Name 'deferred_stages' } |
        ForEach-Object { [string]$_ } |
        Where-Object { $_ -notin $activeStageIds } |
        Sort-Object -Unique
)
foreach ($stageId in $deferredStageIds) {
    $stageItem = $stageIndex[[string]$stageId]
    foreach ($category in @('required', 'optional')) {
        foreach ($resource in @(Get-PropertyArray -Object $stageItem -Name $category)) {
            Add-ResolvedResource -Category deferred -Resource $resource -Source "后续阶段 $stageId"
        }
    }
}

foreach ($path in @($buckets.required.Keys)) {
    $null = $buckets.optional.Remove($path)
    $null = $buckets.deferred.Remove($path)
    $null = $buckets.forbidden.Remove($path)
}
foreach ($path in @($buckets.optional.Keys)) {
    $null = $buckets.deferred.Remove($path)
    $null = $buckets.forbidden.Remove($path)
}
foreach ($path in @($buckets.deferred.Keys)) {
    $null = $buckets.forbidden.Remove($path)
}

function Convert-Bucket {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('required', 'optional', 'deferred', 'forbidden')]
        [string]$Category
    )

    $items = @()
    foreach ($path in @($buckets[$Category].Keys | Sort-Object)) {
        $localPath = Join-Path $manifestRoot ($path -replace '/', [IO.Path]::DirectorySeparatorChar)
        $exists = Test-Path -LiteralPath $localPath
        if (-not $exists) {
            throw "Manifest resource does not exist: category=$Category path=$path resolved=$localPath"
        }
        $items += [pscustomobject]@{
            path = $path
            reasons = @($buckets[$Category][$path] | Sort-Object -Unique)
            exists = $true
        }
    }
    return $items
}

$resolvedDimensions = [ordered]@{}
foreach ($dimensionName in @('intent', 'data_structure', 'response_support', 'task_goal', 'risk')) {
    $resolvedDimensions[$dimensionName] = @(
        $selectedRoutes |
            ForEach-Object { Get-PropertyArray -Object $_.dimensions -Name $dimensionName } |
            ForEach-Object { [string]$_ } |
            Sort-Object -Unique
    )
}

$result = [pscustomobject]@{
    manifest = [pscustomobject]@{
        path = $loaded.Path
        schema_version = [string]$manifest.schema_version
        sha256 = (Get-FileHash -LiteralPath $loaded.Path -Algorithm SHA256).Hash
    }
    selected_routes = @($selectedRoutes | ForEach-Object { [string]$_.id } | Sort-Object -Unique)
    active_stages = @($activeStageIds)
    route_scopes = @($routeScopes | Sort-Object id)
    dimensions = [pscustomobject]$resolvedDimensions
    required = @(Convert-Bucket -Category required)
    optional = @(Convert-Bucket -Category optional)
    deferred = @(Convert-Bucket -Category deferred)
    forbidden = @(Convert-Bucket -Category forbidden)
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 12
    exit 0
}

Write-Output ('ROUTES=' + ($result.selected_routes -join ', '))
Write-Output ('STAGES=' + ($result.active_stages -join ', '))
Write-Output ('DIMENSIONS=intent=[' + ($result.dimensions.intent -join ', ') +
    ']; data_structure=[' + ($result.dimensions.data_structure -join ', ') +
    ']; response_support=[' + ($result.dimensions.response_support -join ', ') +
    ']; task_goal=[' + ($result.dimensions.task_goal -join ', ') +
    ']; risk=[' + ($result.dimensions.risk -join ', ') + ']')
foreach ($category in @('required', 'optional', 'deferred', 'forbidden')) {
    Write-Output ''
    Write-Output ('[' + $category.ToUpperInvariant() + ']')
    foreach ($item in @($result.$category)) {
        Write-Output ('- ' + $item.path)
        foreach ($reason in @($item.reasons)) {
            Write-Output ('  reason: ' + $reason)
        }
    }
}
