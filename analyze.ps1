# analyze.ps1 - C盘深度分析一键入口
# 用法: .\analyze.ps1 [-Categories "A,B,C"] [-OutputFormat console|markdown|json]
# 示例: .\analyze.ps1                        # 全部扫描，控制台输出
#        .\analyze.ps1 -OutputFormat markdown  # 全部扫描，生成Markdown报告
#        .\analyze.ps1 -Categories "C,D"       # 只扫描开发缓存+浏览器

param(
    [string]$Categories = "all",
    [string]$OutputFormat = "console"
)

$SkillRoot = Split-Path -Parent $PSCommandPath
if (-not $SkillRoot) { $SkillRoot = "C:\.trae\skills\c-drive-cleaner" }
. (Join-Path $SkillRoot "_common.ps1")

$Global:CDriveScanResults = [System.Collections.ArrayList]::new()

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  C盘深度清理器 v5.0 — 一键分析" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$space = Get-DriveSpace
if ($space) {
    $barLen = 30
    $usedBlocks = [math]::Round($space.UsedPercent / 100 * $barLen)
    $freeBlocks = $barLen - $usedBlocks
    $bar = "█" * $usedBlocks + "░" * $freeBlocks
    Write-Host "  C盘空间 [$bar] $($space.UsedPercent)%" -ForegroundColor $(if ($space.UsedPercent -gt 90) { "Red" } elseif ($space.UsedPercent -gt 80) { "Yellow" } else { "Green" })
    Write-Host "  已用: $($space.UsedGB) GB / 总计: $($space.TotalGB) GB / 剩余: $($space.FreeGB) GB" -ForegroundColor White
    Write-Host ""
}

$allCats = @(
    @{ Code = "A"; Script = "scan-system-hidden.ps1"; Label = "系统隐藏大文件" }
    @{ Code = "B"; Script = "scan-temp-files.ps1"; Label = "临时文件与缓存" }
    @{ Code = "C"; Script = "scan-dev-caches.ps1"; Label = "开发工具缓存" }
    @{ Code = "D"; Script = "scan-browsers.ps1"; Label = "浏览器缓存" }
    @{ Code = "E"; Script = "scan-app-data.ps1"; Label = "应用数据与日志" }
    @{ Code = "F"; Script = "scan-large-files.ps1"; Label = "大文件TOP N" }
    @{ Code = "G"; Script = "scan-special-sources.ps1"; Label = "特殊占用源" }
    @{ Code = "H"; Script = "scan-security-software.ps1"; Label = "安全软件数据" }
    @{ Code = "I"; Script = "scan-multi-version.ps1"; Label = "多版本软件" }
    @{ Code = "J"; Script = "scan-duplicate-runtimes.ps1"; Label = "重复运行时" }
    @{ Code = "K"; Script = "scan-ime-data.ps1"; Label = "输入法数据" }
    @{ Code = "L"; Script = "scan-im-apps.ps1"; Label = "即时通讯数据" }
)

$selectedCats = if ($Categories -eq "all") {
    $allCats
} else {
    $codes = $Categories -split "," | ForEach-Object { $_.Trim().ToUpper() }
    $allCats | Where-Object { $_.Code -in $codes }
}

$totalCats = @($selectedCats).Count
$catIdx = 0
foreach ($cat in $selectedCats) {
    $catIdx++
    $scriptPath = Join-Path $SkillRoot "scanners\$($cat.Script)"
    if (Test-Path $scriptPath) {
        Write-Host "[$catIdx/$totalCats] " -NoNewline -ForegroundColor DarkGray
        . $scriptPath
    } else {
        Write-Host "  ⚠️ 找不到扫描脚本: $($cat.Script)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  扫描完成 — 汇总" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$results = $Global:CDriveScanResults
$totalCleanable = 0
$totalCautious = 0
$totalForbidden = 0
$totalAll = 0
if ($results.Count -gt 0) {
    $totalCleanable = [math]::Round(($results | Where-Object { $_.Risk -eq "safe" } | Measure-Object SizeMB -Sum).Sum, 2)
    $totalCautious = [math]::Round(($results | Where-Object { $_.Risk -eq "cautious" } | Measure-Object SizeMB -Sum).Sum, 2)
    $totalForbidden = [math]::Round(($results | Where-Object { $_.Risk -eq "forbidden" } | Measure-Object SizeMB -Sum).Sum, 2)
    $totalAll = [math]::Round(($results | Measure-Object SizeMB -Sum).Sum, 2)
}

if ($results.Count -eq 0) {
    Write-Host "  未发现可清理项目" -ForegroundColor Green
} else {
    Write-Host "  ✅ 可安全清理:   $totalCleanable MB ($([math]::Round($totalCleanable/1024,2)) GB)" -ForegroundColor Green
    Write-Host "  ⚠️ 需确认后操作: $totalCautious MB ($([math]::Round($totalCautious/1024,2)) GB)" -ForegroundColor Yellow
    Write-Host "  🔴 不可删除:     $totalForbidden MB ($([math]::Round($totalForbidden/1024,2)) GB)" -ForegroundColor Red
    Write-Host "  📊 总扫描占用:   $totalAll MB ($([math]::Round($totalAll/1024,2)) GB)" -ForegroundColor White
    Write-Host ""

    $byCategory = $results | Group-Object Category | Sort-Object { ($_.Group | Measure-Object SizeMB -Sum).Sum } -Descending
    Write-Host "  按类别统计:" -ForegroundColor White
    foreach ($grp in $byCategory) {
        $catSize = [math]::Round(($grp.Group | Measure-Object SizeMB -Sum).Sum, 2)
        $catLabel = switch ($grp.Name) {
            "A" { "系统隐藏" } "B" { "临时文件" } "C" { "开发缓存" } "D" { "浏览器" }
            "E" { "应用数据" } "F" { "大文件" } "G" { "特殊源" } "H" { "安全软件" }
            "I" { "多版本" } "J" { "重复运行时" } "K" { "输入法" } "L" { "即时通讯" }
            default { $grp.Name }
        }
        Write-Host "    $($grp.Name)类($catLabel): $catSize MB" -ForegroundColor DarkGray
    }
}

if ($OutputFormat -eq "markdown") {
    $mdPath = Join-Path $SkillRoot "report_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# C盘深度清理报告")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("**生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    if ($space) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("## C盘空间概览")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("| 项目 | 大小 |")
        [void]$sb.AppendLine("|------|------|")
        [void]$sb.AppendLine("| 总计 | $($space.TotalGB) GB |")
        [void]$sb.AppendLine("| 已用 | $($space.UsedGB) GB ($($space.UsedPercent)%) |")
        [void]$sb.AppendLine("| 剩余 | $($space.FreeGB) GB |")
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## 扫描结果")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| 类别 | 名称 | 大小 | 风险 | 建议 | 来源 |")
    [void]$sb.AppendLine("|------|------|------|------|------|------|")
    foreach ($r in $results) {
        $riskIcon = switch ($r.Risk) { "safe" { "✅" } "cautious" { "⚠️" } "dangerous" { "❌" } "forbidden" { "🔴" } default { "⚠️" } }
        $sizeStr = if ($r.SizeMB -ge 1024) { "$([math]::Round($r.SizeMB/1024,2)) GB" } else { "$($r.SizeMB) MB" }
        [void]$sb.AppendLine("| $($r.Category) | $($r.Name) | $sizeStr | $riskIcon | $($r.Advice) | $($r.Source) |")
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## 汇总")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("- ✅ 可安全清理: $([math]::Round($totalCleanable,2)) MB")
    [void]$sb.AppendLine("- ⚠️ 需确认后操作: $([math]::Round($totalCautious,2)) MB")
    [void]$sb.AppendLine("- 🔴 不可删除: $([math]::Round($totalForbidden,2)) MB")
    $sb.ToString() | Out-File $mdPath -Encoding UTF8
    Write-Host ""
    Write-Host "  📝 Markdown报告已生成: $mdPath" -ForegroundColor Green
}

if ($OutputFormat -eq "json") {
    $jsonPath = Join-Path $SkillRoot "report_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $results | ConvertTo-Json -Depth 5 | Out-File $jsonPath -Encoding UTF8
    Write-Host ""
    Write-Host "  📝 JSON报告已生成: $jsonPath" -ForegroundColor Green
}

Write-Host ""
