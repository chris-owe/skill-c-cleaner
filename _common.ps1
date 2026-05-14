# _common.ps1 - c-drive-cleaner shared functions
# Dot-source: . (Join-Path (Split-Path -Parent $PSCommandPath) "_common.ps1")
# Or from scanners: . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSCommandPath)) "_common.ps1")

if (-not $Global:CDriveScanResults) {
    $Global:CDriveScanResults = [System.Collections.ArrayList]::new()
}

function Get-SkillRoot {
    if ($PSCommandPath) {
        $dir = Split-Path -Parent $PSCommandPath
        if (Test-Path (Join-Path $dir "_common.ps1")) { return $dir }
        $parent = Split-Path -Parent $dir
        if (Test-Path (Join-Path $parent "_common.ps1")) { return $parent }
    }
    return "C:\.trae\skills\c-drive-cleaner"
}

function Get-FolderSizeFast {
    param([string]$Path)
    if (-not (Test-Path $Path -ErrorAction SilentlyContinue)) { return @{ Size = 0; Count = 0; Found = $false } }
    try {
        $dummy = "C:\__ROBOSIZE_$(Get-Random)__"
        $output = & robocopy $Path $dummy /L /S /NFL /NDL /NJH /BYTES 2>&1
        $bytesLine = $output | Where-Object { $_ -match '^\s*Bytes' } | Select-Object -Last 1
        if ($bytesLine) {
            $nums = [regex]::Matches($bytesLine, '\d+') | ForEach-Object { $_.Value }
            if ($nums.Count -ge 1) {
                return @{ Size = [long]$nums[0]; Count = 0; Found = $true }
            }
        }
    } catch {}
    $files = Get-ChildItem $Path -Recurse -Force -File -ErrorAction SilentlyContinue
    $size = ($files | Measure-Object Length -Sum).Sum
    return @{ Size = if ($size) { [long]$size } else { 0 }; Count = @($files).Count; Found = $true }
}

function Expand-EnvPath {
    param([string]$Path)
    return $Path -replace '%USERPROFILE%', $env:USERPROFILE `
        -replace '%LOCALAPPDATA%', $env:LOCALAPPDATA `
        -replace '%APPDATA%', $env:APPDATA `
        -replace '%PROGRAMFILES\(X86\)%', ${env:ProgramFiles(x86)} `
        -replace '%PROGRAMFILES%', $env:ProgramFiles `
        -replace '%PROGRAMDATA%', $env:ProgramData `
        -replace '%DOCUMENTS%', ([Environment]::GetFolderPath("MyDocuments"))
}

function Load-SignatureDb {
    param([string]$Category)
    $sigFile = Join-Path (Get-SkillRoot) "extensions\app-signatures.json"
    if (-not (Test-Path $sigFile)) { return @() }
    try {
        $sigs = Get-Content $sigFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $catApps = $sigs.categories.$Category.apps
        if ($catApps) { return @($catApps) } else { return @() }
    } catch { return @() }
}

function Load-CustomSigs {
    $customFile = Join-Path (Get-SkillRoot) "extensions\user-custom.json"
    if (-not (Test-Path $customFile)) { return @() }
    try {
        $cust = Get-Content $customFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cust.apps -and @($cust.apps).Count -gt 0) { return @($cust.apps) } else { return @() }
    } catch { return @() }
}

function Test-AppSignature {
    param([PSObject]$App)
    $found = $false
    $totalSize = 0L
    $foundPath = ""
    foreach ($dp in $App.detect_paths) {
        $expanded = Expand-EnvPath $dp
        if (-not (Test-Path $expanded -ErrorAction SilentlyContinue)) { continue }
        $found = $true
        $foundPath = $expanded
        if ($App.sub_paths) {
            $subSize = 0L
            foreach ($sub in $App.sub_paths) {
                $subFull = Join-Path $expanded $sub
                $r = Get-FolderSizeFast $subFull
                if ($r.Found) { $subSize += $r.Size }
            }
            $totalSize += $subSize
        } else {
            $r = Get-FolderSizeFast $expanded
            $totalSize += $r.Size
        }
    }
    return @{ Found = $found; Size = $totalSize; Path = $foundPath }
}

function Convert-RiskLevel {
    param($Cleanable)
    if ($Cleanable -eq $true) { return "safe" }
    if ($Cleanable -eq "cautious") { return "cautious" }
    if ($Cleanable -eq $false) { return "forbidden" }
    return "cautious"
}

function Write-ScanResult {
    param(
        [string]$Category,
        [string]$Name,
        [long]$Size,
        [string]$Risk,
        [string]$Path,
        [string]$Advice,
        [string]$Migration,
        [string]$Note,
        [string]$Source = ""
    )
    $sizeMB = [math]::Round($Size / 1MB, 2)
    $sizeGB = [math]::Round($Size / 1GB, 2)
    $sizeStr = if ($sizeGB -ge 1) { "$sizeGB GB" } else { "$sizeMB MB" }
    $riskIcon = switch ($Risk) {
        "safe"      { "✅" }
        "cautious"  { "⚠️" }
        "dangerous" { "❌" }
        "forbidden" { "🔴" }
        default     { "⚠️" }
    }
    $color = switch ($Risk) {
        "safe"      { "Green" }
        "cautious"  { "Yellow" }
        "dangerous" { "Red" }
        "forbidden" { "Red" }
        default     { "Yellow" }
    }
    if ($sizeMB -gt 0) {
        $srcTag = if ($Source) { " [$Source]" } else { "" }
        Write-Host "  $riskIcon ${Name}${srcTag}: $sizeStr" -ForegroundColor $color
        if ($Path) { Write-Host "     路径: $Path" -ForegroundColor DarkGray }
        if ($Advice) { Write-Host "     建议: $Advice" -ForegroundColor DarkGray }
        if ($Migration) { Write-Host "     迁移: $Migration" -ForegroundColor DarkGray }
        if ($Note) { Write-Host "     备注: $Note" -ForegroundColor DarkGray }
    }
    [void]$Global:CDriveScanResults.Add(@{
        Category = $Category
        Name     = $Name
        SizeMB   = $sizeMB
        Risk     = $Risk
        Path     = $Path
        Advice   = $Advice
        Migration = $Migration
        Note     = $Note
        Source   = $Source
    })
}

function Get-DriveSpace {
    $drive = Get-PSDrive C -ErrorAction SilentlyContinue
    if (-not $drive) { return $null }
    $totalGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
    $usedGB = [math]::Round($drive.Used / 1GB, 2)
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    $usedPercent = [math]::Round($drive.Used / ($drive.Used + $drive.Free) * 100, 1)
    return @{
        TotalGB     = $totalGB
        UsedGB      = $usedGB
        FreeGB      = $freeGB
        UsedPercent = $usedPercent
    }
}

function Invoke-SignatureScan {
    param(
        [string]$Category,
        [string]$CategoryLabel,
        [string[]]$AlreadyScanned = @()
    )
    $apps = Load-SignatureDb -Category $Category
    foreach ($app in $apps) {
        if ($app.name -in $AlreadyScanned) { continue }
        $result = Test-AppSignature $app
        if ($result.Found -and $result.Size -gt 1MB) {
            $risk = Convert-RiskLevel $app.cleanable
            $advice = ""
            if ($app.cleanable -eq $true) { $advice = "可安全清理" }
            elseif ($app.cleanable -eq "cautious") { $advice = "确认后可操作" }
            elseif ($app.cleanable -eq $false) { $advice = "不可删除" }
            if ($app.sub_cleanable) { $advice += " (可清理: $($app.sub_cleanable))" }
            $migration = ""
            if ($app.migratable -eq $true) { $migration = "可迁移" }
            if ($app.migration_method) { $migration += " ($($app.migration_method))" }
            Write-ScanResult -Category $CategoryLabel -Name $app.name `
                -Size $result.Size -Risk $risk -Path $result.Path `
                -Advice $advice -Migration $migration -Note $app.note -Source "DB"
        }
    }
    $customApps = Load-CustomSigs
    foreach ($app in $customApps) {
        if ($app.name -in $AlreadyScanned) { continue }
        $result = Test-AppSignature $app
        if ($result.Found -and $result.Size -gt 1MB) {
            $risk = Convert-RiskLevel $app.cleanable
            Write-ScanResult -Category $CategoryLabel -Name $app.name `
                -Size $result.Size -Risk $risk -Path $result.Path `
                -Note $app.note -Source "自定义"
        }
    }
}
