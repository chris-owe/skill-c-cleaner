﻿﻿﻿$skillRoot = Split-Path -Parent $PSCommandPath
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
    @{Path="$env:LOCALAPPDATA\Doubao"; Name="豆包缓存"}
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
        Write-Host "[$idx/$total] $n ..." -NoNewline
        try {
            Remove-Directory -Path $p -ShowTimer
            Write-Host " Done" -ForegroundColor Green
            $ok++
        } catch {
            Write-Host " Failed" -ForegroundColor Red
        }
    } else {
        Write-Host "[$idx/$total] $n - skip" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Cleaned: $ok of $total" -ForegroundColor Green
$d = Get-PSDrive C
$used = [math]::Round($d.Used/1GB, 2)
$free = [math]::Round($d.Free/1GB, 2)
$pct = [math]::Round($d.Used/($d.Used+$d.Free)*100, 1)
Write-Host "C: Used=$used GB / Free=$free GB / $pct%" -ForegroundColor Cyan
