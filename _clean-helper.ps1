﻿﻿﻿﻿﻿﻿﻿﻿$skillRoot = Split-Path -Parent $PSCommandPath
if (-not (Test-Path (Join-Path $skillRoot "_common.ps1"))) {
    $skillRoot = "C:\.trae\skills\c-drive-cleaner"
}
. (Join-Path $skillRoot "_common.ps1")

Write-Host "===== 清理缓存 =====" -ForegroundColor Cyan
Write-Host "文件将永久删除，不经过回收站" -ForegroundColor Red
Write-Host ""

$items = @(
    @{Path="$env:APPDATA\LarkShell"; Name="飞书缓存"}
    @{Path="$env:LOCALAPPDATA\JetBrains"; Name="JetBrains Local"}
    @{Path="$env:LOCALAPPDATA\Doubao\User Data\Default\Code Cache"; Name="豆包 Code缓存(170MB+)"}
    @{Path="$env:LOCALAPPDATA\Doubao\User Data\Default\Cache"; Name="豆包网页缓存"}
    @{Path="$env:LOCALAPPDATA\Doubao\User Data\Default\Service Worker"; Name="豆包 Service Worker"}
    @{Path="$env:LOCALAPPDATA\Doubao\User Data\Default\DawnWebGPUCache"; Name="豆包 GPU WebCache"}
    @{Path="$env:LOCALAPPDATA\Doubao\User Data\Default\GPUCache"; Name="豆包 GPUCache"}
    @{Path="$env:LOCALAPPDATA\Doubao\User Data\Default\DawnGraphiteCache"; Name="豆包 GraphiteCache"}
    @{Path="$env:LOCALAPPDATA\Doubao\User Data\Default\blob_storage"; Name="豆包 Blob存储"}
    @{Path="$env:LOCALAPPDATA\Doubao\debug.log"; Name="豆包调试日志"}
    @{Path="$env:LOCALAPPDATA\DingTalk_133"; Name="钉钉缓存"}
    @{Path="$env:USERPROFILE\.cache"; Name="用户缓存"}
    @{Path="$env:LOCALAPPDATA\ms-playwright"; Name="Playwright"}
    @{Path="$env:LOCALAPPDATA\Yarn\Cache"; Name="Yarn旧缓存"}
)

$ok = 0
for ($i = 0; $i -lt $items.Length; $i++) {
    $p = $items[$i].Path
    $n = $items[$i].Name
    $idx = $i + 1
    $total = $items.Length
    if (Test-Path $p -ErrorAction SilentlyContinue) {
        $r = Get-FolderSizeFast $p
        $sizeStr = ""
        if ($r.Found -and $r.Size -gt 0) {
            $sizeMB = [math]::Round($r.Size / 1MB, 2)
            $sizeStr = if ($sizeMB -ge 1024) { "$([math]::Round($sizeMB/1024,2)) GB" } else { "$sizeMB MB" }
        } else { $sizeStr = "?" }
        Write-Host "[$idx/$total] $n — $sizeStr" -ForegroundColor Yellow
        try {
            Remove-Directory -Path $p -ShowProgress
            $ok++
        } catch {
            Write-Host "  [失败] $($_.Exception.Message)" -ForegroundColor Red
        }
        Write-Host ""
    } else {
        Write-Host "[$idx/$total] $n — 不存在, 跳过" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Cleaned: $ok of $total" -ForegroundColor Green
$d = Get-PSDrive C
$used = [math]::Round($d.Used/1GB, 2)
$free = [math]::Round($d.Free/1GB, 2)
$pct = [math]::Round($d.Used/($d.Used+$d.Free)*100, 1)
Write-Host "C: Used=$used GB / Free=$free GB / $pct%" -ForegroundColor Cyan
