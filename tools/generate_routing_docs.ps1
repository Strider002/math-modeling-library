[CmdletBinding()]
param(
    [string]$ManifestPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'routing-manifest.yaml'),
    [string]$OutputPath = (Join-Path (Split-Path -Parent $PSScriptRoot) '00B_任务路由与最小读取集.md'),
    [switch]$Check
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

function Escape-MarkdownCell {
    param([AllowEmptyString()][string]$Text)
    if ($null -eq $Text) {
        return ''
    }
    return (($Text -replace '\|', '\|') -replace '\r?\n', ' ').Trim()
}

$tick = [char]96

function Format-Code {
    param([AllowEmptyString()][string]$Text)
    return [string]$tick + $Text + [string]$tick
}

function Format-ResourcePaths {
    param([object[]]$Resources)
    $paths = @($Resources | ForEach-Object { [string]$_.path } | Sort-Object -Unique)
    if ($paths.Count -eq 0) {
        return '—'
    }
    return (($paths | ForEach-Object { Format-Code $_ }) -join '<br>')
}

function Format-StringList {
    param([object[]]$Items)
    $values = @($Items | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($values.Count -eq 0) {
        return '—'
    }
    return ($values -join '、')
}

function Format-RouteDimensions {
    param($Route)
    $parts = @()
    foreach ($name in @('intent', 'data_structure', 'response_support', 'task_goal', 'risk')) {
        $values = Format-StringList @(Get-PropertyArray -Object $Route.dimensions -Name $name)
        $parts += ($name + '=' + $values)
    }
    return ($parts -join '；')
}

if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "Routing manifest not found: $ManifestPath"
}

$resolvedManifest = (Resolve-Path -LiteralPath $ManifestPath).Path
try {
    $manifest = Get-Content -LiteralPath $resolvedManifest -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    throw "routing-manifest.yaml must be JSON-compatible YAML 1.2 (valid JSON): $($_.Exception.Message)"
}

$manifestHash = (Get-FileHash -LiteralPath $resolvedManifest -Algorithm SHA256).Hash
$lines = [System.Collections.Generic.List[string]]::new()

$lines.Add("<!-- GENERATED FILE; SOURCE=routing-manifest.yaml; SHA256=$manifestHash; DO NOT EDIT -->")
$lines.Add('# 数学建模任务路由与最小读取集')
$lines.Add('')
$lines.Add('> 本文件由 ' + (Format-Code 'routing-manifest.yaml') + ' 机械生成，只供人类查阅。')
$lines.Add('> 路由事实只在 manifest 中手工维护；不要直接修改本文件。')
$lines.Add('')
$lines.Add('## 1. 使用原则')
$lines.Add('')
$lines.Add('1. 只有任务确实涉及数学建模、数据分析/挖掘、预测、优化、评价、回归、机器学习、机理仿真、建模论文或知识库维护时才触发本路由。')
$lines.Add('2. 已触发的任务始终读取永久质量核心；再按当前任务类型和工作阶段读取最小集合。')
$lines.Add('3. 未显式传入阶段时，路由器使用各任务的默认起始阶段；显式传入阶段会覆盖默认阶段。')
$lines.Add('4. ' + (Format-Code 'required') + ' 必须立即读取；' + (Format-Code 'optional') + ' 仅在所述条件成立时读取；' + (Format-Code 'deferred') + ' 到对应阶段再读取；' + (Format-Code 'forbidden') + ' 未满足专用条件时不得加载。')
$lines.Add('5. 路由只决定读取范围，不替代方法卡中的公式、假设、验证和证据核验。')
$lines.Add('')
$lines.Add('## 2. 永久质量核心')
$lines.Add('')
foreach ($resource in @(Get-PropertyArray -Object $manifest.permanent -Name 'required')) {
    $lines.Add('- ' + (Format-Code ([string]$resource.path)) + '：' + [string]$resource.reason)
}
$lines.Add('')
$lines.Add('## 3. 受控维度与字节预算')
$lines.Add('')
$lines.Add('| 维度 | 允许值 |')
$lines.Add('|---|---|')
foreach ($dimensionName in @('intent', 'data_structure', 'response_support', 'task_goal', 'risk')) {
    $values = Format-StringList @(Get-PropertyArray -Object $manifest.controlled_vocabulary -Name $dimensionName)
    $lines.Add('| ' + (Format-Code $dimensionName) + ' | ' + (Escape-MarkdownCell $values) + ' |')
}
$lines.Add('')
$lightweightEntries = @(
    Get-PropertyArray -Object $manifest.budgets -Name 'lightweight_entries' |
        ForEach-Object { Format-Code ([string]$_) }
) -join '、'
$lines.Add('- 预算度量：字节（' + (Format-Code ([string]$manifest.budgets.metric)) + '），不使用行数作为上下文预算。')
$lines.Add('- 永久核心上限：' + [string]$manifest.budgets.permanent_max_bytes + ' bytes。')
$lines.Add('- 轻量入口上限：' + [string]$manifest.budgets.lightweight_entry_max_bytes +
    ' bytes；受检入口：' + $lightweightEntries + '。')
$lines.Add('')
$lines.Add('## 4. 阶段门禁')
$lines.Add('')
$lines.Add('| 阶段 ID | 阶段 | 必读 | 条件追加 |')
$lines.Add('|---|---|---|---|')
foreach ($stage in @(Get-PropertyArray -Object $manifest -Name 'stages')) {
    $required = Format-ResourcePaths @(Get-PropertyArray -Object $stage -Name 'required')
    $optional = Format-ResourcePaths @(Get-PropertyArray -Object $stage -Name 'optional')
    $lines.Add('| ' + (Format-Code ([string]$stage.id)) + ' | ' +
        (Escape-MarkdownCell ([string]$stage.label)) + ' | ' + $required + ' | ' + $optional + ' |')
}
$lines.Add('')
$lines.Add('说明：普通 ' + (Format-Code 'delivery') + ' 必读 ' +
    (Format-Code '知识库/基础方法/12_论文写作与可视化.md') + ' 与 ' +
    (Format-Code '知识库/基础方法/13_竞赛工作流与检查清单.md') +
    '；含代码或支撑材料时改用 ' + (Format-Code 'code_delivery') +
    '，同时强制读取 ' + (Format-Code '知识库/基础方法/15_代码与实验规范.md') + '。')
$lines.Add('')
$lines.Add('## 5. 默认任务路由')
$lines.Add('')
$lines.Add('| 路由 ID | 用途 | 受控维度 | 资源生效阶段 | 触发信号 | 默认阶段 | 必读专题 | 条件追加 | 后续阶段 |')
$lines.Add('|---|---|---|---|---|---|---|---|---|')
$normalRoutes = @(
    (Get-PropertyArray -Object $manifest -Name 'routes') |
        Where-Object { -not [bool]$_.conditional } |
        Sort-Object { [string]$_.id }
)
foreach ($route in $normalRoutes) {
    $signals = Format-StringList @(Get-PropertyArray -Object $route -Name 'signals')
    $dimensions = Format-RouteDimensions $route
    $resourceStages = Format-StringList @(Get-PropertyArray -Object $route -Name 'resource_stages')
    $defaultStages = Format-StringList @(Get-PropertyArray -Object $route -Name 'default_stages')
    $deferredStages = Format-StringList @(Get-PropertyArray -Object $route -Name 'deferred_stages')
    $required = Format-ResourcePaths @(Get-PropertyArray -Object $route -Name 'required')
    $optional = Format-ResourcePaths @(Get-PropertyArray -Object $route -Name 'optional')
    $lines.Add('| ' + (Format-Code ([string]$route.id)) + ' | ' +
        (Escape-MarkdownCell ([string]$route.label)) + '：' +
        (Escape-MarkdownCell ([string]$route.description)) + ' | ' +
        (Escape-MarkdownCell $dimensions) + ' | ' +
        (Escape-MarkdownCell $resourceStages) + ' | ' +
        (Escape-MarkdownCell $signals) + ' | ' +
        (Escape-MarkdownCell $defaultStages) + ' | ' +
        $required + ' | ' + $optional + ' | ' +
        (Escape-MarkdownCell $deferredStages) + ' |')
}
$lines.Add('')
$lines.Add('## 6. 条件路由与默认禁载资源')
$lines.Add('')
$lines.Add('下列内容不是普通建模任务的默认上下文。只有任务明确满足相应条件时，才选择专用条件路由。')
$lines.Add('')
$lines.Add('| 条件路由 ID | 明确条件 | 受控维度 | 资源生效阶段 | 允许读取 |')
$lines.Add('|---|---|---|---|---|')
$conditionalRoutes = @(
    (Get-PropertyArray -Object $manifest -Name 'routes') |
        Where-Object { [bool]$_.conditional } |
        Sort-Object { [string]$_.id }
)
foreach ($route in $conditionalRoutes) {
    $allowed = @(
        @(Get-PropertyArray -Object $route -Name 'required') +
        @(Get-PropertyArray -Object $route -Name 'optional')
    )
    $lines.Add('| ' + (Format-Code ([string]$route.id)) + ' | ' +
        (Escape-MarkdownCell ([string]$route.description)) + ' | ' +
        (Escape-MarkdownCell (Format-RouteDimensions $route)) + ' | ' +
        (Escape-MarkdownCell (Format-StringList @(Get-PropertyArray -Object $route -Name 'resource_stages'))) + ' | ' +
        (Format-ResourcePaths $allowed) + ' |')
}
$lines.Add('')
$lines.Add('| 默认禁载资源 | 原因 |')
$lines.Add('|---|---|')
foreach ($resource in @(Get-PropertyArray -Object $manifest -Name 'default_forbidden')) {
    $lines.Add('| ' + (Format-Code ([string]$resource.path)) + ' | ' +
        (Escape-MarkdownCell ([string]$resource.reason)) + ' |')
}
$lines.Add('')
$lines.Add('## 7. 路由器用法')
$lines.Add('')
$fence = ([string]$tick) * 3
$lines.Add($fence + 'powershell')
$lines.Add('#查看全部路由')
$lines.Add('.\tools\route_knowledge.ps1 -ListRoutes')
$lines.Add('')
$lines.Add('#普通回归：未给阶段时使用该路由的默认起始阶段')
$lines.Add('.\tools\route_knowledge.ps1 -RouteId regression_general')
$lines.Add('')
$lines.Add('#组合路由与显式阶段；JSON 适合后续自动处理')
$lines.Add('.\tools\route_knowledge.ps1 -RouteId regression_general,network_spatial -Stage data,model_selection,validation_design -AsJson')
$lines.Add('')
$lines.Add('#输出前切换到验证审计和含代码交付门禁')
$lines.Add('.\tools\route_knowledge.ps1 -RouteId cumcm_c_pipeline -Stage validation_audit,code_delivery')
$lines.Add($fence)
$lines.Add('')
$lines.Add('## 8. 生成与一致性')
$lines.Add('')
$lines.Add('- 生成：' + (Format-Code '.\tools\generate_routing_docs.ps1'))
$lines.Add('- 只检查是否与 manifest 一致：' + (Format-Code '.\tools\generate_routing_docs.ps1 -Check'))
$lines.Add('- 黄金路由测试：' + (Format-Code '.\tools\test_routing.ps1'))
$lines.Add('')
$lines.Add('任何路由变化只修改 ' + (Format-Code 'routing-manifest.yaml') +
    '，随后重新生成本文件并运行黄金测试。')
$lines.Add('')

# Keep generated output byte-stable across Windows and CI checkouts.
# .gitattributes requires LF for Markdown, so do not use the host newline.
$newLine = "`n"
$content = ($lines -join $newLine)
if (-not $content.EndsWith($newLine)) {
    $content += $newLine
}

$current = if (Test-Path -LiteralPath $OutputPath -PathType Leaf) {
    Get-Content -LiteralPath $OutputPath -Raw -Encoding UTF8
} else {
    $null
}

if ($Check) {
    if ($current -ceq $content) {
        Write-Output "ROUTING_DOC_STATUS=UP_TO_DATE"
        Write-Output "MANIFEST_SHA256=$manifestHash"
        exit 0
    }
    Write-Output "ROUTING_DOC_STATUS=STALE"
    Write-Output "MANIFEST_SHA256=$manifestHash"
    exit 1
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $outputDirectory
}

$temporaryPath = $OutputPath + '.tmp.' + $PID
try {
    [IO.File]::WriteAllText($temporaryPath, $content, [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporaryPath -Destination $OutputPath -Force
} finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }
}

Write-Output "ROUTING_DOC_STATUS=GENERATED"
Write-Output "OUTPUT=$OutputPath"
Write-Output "MANIFEST_SHA256=$manifestHash"
