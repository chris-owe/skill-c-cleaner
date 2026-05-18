# clean-dev-caches.ps1 - 开发缓存清理（逐一确认模式）
# 覆盖 npm, pip, cargo, gradle, yarn, pnpm, node-gyp, maven, conda, go
# 每项列出大小后需用户显式确认

$UserProfile = $env:USERPROFILE
$LocalAppData = $env:LOCALAPPDATA

Write-Host "===== 开发工具缓存清理 — 逐项确认模式 =====" -ForegroundColor Cyan
Write-Host "每项会列出路径和大小，需显式确认 Y/N" -ForegroundColor Yellow
Write-Host ""

$totalFreed = 0

function Clean-Cache {
    param([string]$Path, [string]$Name, [string]$CmdHint)
    if (-not (Test-Path $Path)) {
        Write-Host "[$Name] 未使用 — 跳过" -ForegroundColor DarkGray
        return
    }
    $items = Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue
    $size = ($items | Where-Object { -not $_.PSIsContainer } | Measure-Object Length -Sum).Sum
    $sizeMB = [math]::Round($size / 1MB, 2)
    if ($sizeMB -lt 1) {
        Write-Host "[$Name] ${sizeMB} MB — 太小，跳过" -ForegroundColor DarkGray
        return
    }
    Write-Host "[$Name] $Path" -ForegroundColor Green
    Write-Host "  大小: ${sizeMB} MB" -ForegroundColor DarkGray
    if ($CmdHint) {
        Write-Host "  命令行清理: $CmdHint" -ForegroundColor DarkGray
    }
    $confirm = Read-Host "  是否清理? (Y/N)"
    if ($confirm -eq 'Y') {
        try {
            Remove-Item "$Path\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  ✅ 已清理 ${sizeMB} MB" -ForegroundColor Green
            $script:totalFreed += [long]$size
        } catch {
            Write-Host "  ❌ 无法删除文件(可能正在使用): 尝试用命令行 $CmdHint" -ForegroundColor Red
        }
    } else { Write-Host "  跳过" -ForegroundColor DarkGray }
}

# 按风险从低到高排列
Clean-Cache "$LocalAppData\npm-cache" "npm缓存" "npm cache clean --force"
Clean-Cache "$LocalAppData\node-gyp\Cache" "node-gyp缓存" "手动删除后使用符号链接"
Clean-Cache "$LocalAppData\pip\cache" "pip缓存" "pip cache purge"
Clean-Cache "$LocalAppData\Yarn\Cache" "Yarn缓存" "yarn cache clean"
Clean-Cache "$LocalAppData\pnpm\store" "pnpm store" "pnpm store prune"
Clean-Cache "$UserProfile\.gradle\caches" "Gradle缓存" "gradle cleanBuildCache"
Clean-Cache "$UserProfile\.cargo\registry" "Cargo registry" "cargo cache --autoclean"
Clean-Cache "$LocalAppData\conda\pkgs" "conda pkgs" "conda clean --all"
Clean-Cache "$UserProfile\go\pkg\mod" "Go模块缓存" "go clean -modcache"

# Maven和NuGet单独处理（高风险，需要确认用途）
Write-Host "──────────────────────────" -ForegroundColor Cyan
Write-Host "[⚠️ 高风险缓存 — 请确认后操作]" -ForegroundColor Yellow

$nugetPath = "$UserProfile\.nuget\packages"
if (Test-Path $nugetPath) {
    $nsizeMB = [math]::Round((Get-ChildItem $nugetPath -Recurse -Force -EA SilentlyContinue | Where-Object {-not $_.PSIsContainer} | Measure-Object Length -Sum).Sum / 1MB, 2)
    Write-Host "[NuGet缓存] ${nsizeMB} MB — 删除后VS打开方案重新下载" -ForegroundColor Yellow
    if ((Read-Host "  确认删除? 输入 YES 才执行") -eq 'YES') {
        Remove-Item "$nugetPath\*" -Recurse -Force -EA SilentlyContinue
        Write-Host "  ✅ 已清理" -ForegroundColor Green
    }
}

$mavenPath = "$UserProfile\.m2\repository"
if (Test-Path $mavenPath) {
    $msizeMB = [math]::Round((Get-ChildItem $mavenPath -Recurse -Force -EA SilentlyContinue | Where-Object {-not $_.PSIsContainer} | Measure-Object Length -Sum).Sum / 1MB, 2)
    Write-Host "[Maven仓库] ${msizeMB} MB — 删除后构建重新下载" -ForegroundColor Yellow
    if ((Read-Host "  确认删除? 输入 YES 才执行") -eq 'YES') {
        Remove-Item "$mavenPath\*" -Recurse -Force -EA SilentlyContinue
        Write-Host "  ✅ 已清理" -ForegroundColor Green
    }
}

Write-Host ""
$totalMB = [math]::Round($totalFreed / 1MB, 2)
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "本次清理完成，释放: ${totalMB} MB" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
