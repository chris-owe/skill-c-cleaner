# clean-safe.ps1 - Layer 3 安全自动清理
# 仅清理"明确可安全删除"的类别：临时文件、缓存、缩略图
# 不涉及系统级操作，不会造成任何副作用
# 默认 WhatIf 模式，用户去掉 -WhatIf 才真正执行

param([switch]$ReallyDelete)

$LocalAppData = $env:LOCALAPPDATA
$LogFile = "C:\cleanup_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

if (-not $ReallyDelete) {
    Write-Host "===== 安全清理 — WhatIf 预览模式 =====" -ForegroundColor Cyan
    Write-Host "下面显示的都会在真正执行时被清理。添加 -ReallyDelete 参数才真正删除。" -ForegroundColor Yellow
    Write-Host ""
    $WhatIf = $true
} else {
    Write-Host "===== 安全清理 — 执行中 =====" -ForegroundColor Cyan
    Write-Host "正在运行...所有操作记录将保存到 $LogFile" -ForegroundColor Yellow
    $WhatIf = $false
    Start-Transcript -Path $LogFile -Append
}

function Safe-Clean {
    param([string]$Path, [string]$Description)
    if (-not (Test-Path $Path)) {
        Write-Host "$Description — 路径不存在，跳过" -ForegroundColor DarkGray
        return 0
    }
    $items = Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue
    $size = ($items | Where-Object { -not $_.PSIsContainer } | Measure-Object Length -Sum).Sum
    $count = @($items).Count
    $sizeMB = [math]::Round($size / 1MB, 2)
    Write-Host "$Description" -ForegroundColor Green
    Write-Host "  路径: $Path" -ForegroundColor DarkGray
    Write-Host "  大小: ${sizeMB} MB ($count 项)" -ForegroundColor DarkGray
    if (-not $WhatIf) {
        try {
            Remove-Item "$Path\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  ✅ 已清理" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ 清理失败: $_" -ForegroundColor Red
        }
    }
    return $size
}

$totalFreed = 0

# 1. Windows 临时文件
$totalFreed += Safe-Clean "C:\Windows\Temp" "[1/7] Windows 临时文件夹"

# 2. 用户临时文件
$totalFreed += Safe-Clean "$LocalAppData\Temp" "[2/7] 用户临时文件夹"

# 3. 缩略图缓存
$thumbPath = "$LocalAppData\Microsoft\Windows\Explorer"
if (Test-Path $thumbPath) {
    $thumbFiles = Get-ChildItem $thumbPath -Filter "*.db" -ErrorAction SilentlyContinue
    $thumbSize = ($thumbFiles | Measure-Object Length -Sum).Sum
    $thumbMB = [math]::Round($thumbSize / 1MB, 2)
    Write-Host "[3/7] 缩略图缓存" -ForegroundColor Green
    Write-Host "  大小: ${thumbMB} MB" -ForegroundColor DarkGray
    if (-not $WhatIf -and $thumbFiles) {
        $thumbFiles | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ 已清理"
    }
    $totalFreed += [long]$thumbSize
}

# 4. 回收站
try {
    $rb = Get-ChildItem "C:\`$Recycle.Bin" -Recurse -Force -ErrorAction SilentlyContinue
    $rbSize = ($rb | Where-Object { -not $_.PSIsContainer } | Measure-Object Length -Sum).Sum
    $rbMB = [math]::Round($rbSize / 1MB, 2)
    Write-Host "[4/7] 回收站: ${rbMB} MB" -ForegroundColor Green
    if (-not $WhatIf) {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Host "  ✅ 已清空"
    }
    $totalFreed += [long]$rbSize
} catch { Write-Host "[4/7] 回收站: 无法访问" -ForegroundColor DarkGray }

# 5. Delivery Optimization
$totalFreed += Safe-Clean "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization" "[5/7] 传递优化文件"

# 6. Windows 错误报告
$totalFreed += Safe-Clean "C:\ProgramData\Microsoft\Windows\WER" "[6/7] Windows 错误报告"

# 7. Windows更新缓存
Write-Host "[7/7] Windows更新缓存 (跳过 — 需要停止wuauserv服务，请用clean-deep.ps1)" -ForegroundColor Yellow

$totalMB = [math]::Round($totalFreed / 1MB, 2)
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "可释放空间: ${totalMB} MB (预览模式)" -ForegroundColor Yellow
    Write-Host "请确认无误后，加 -ReallyDelete 参数再次运行" -ForegroundColor Yellow
} else {
    Write-Host "已释放空间: ${totalMB} MB" -ForegroundColor Green
    Stop-Transcript
    Write-Host "日志已保存: $LogFile"
}
Write-Host "============================================" -ForegroundColor Cyan
