#Requires -Version 7.0
<#
.SYNOPSIS
    把本仓库的 WezTerm / Oh My Posh / PowerShell profile 配置部署到当前用户。

.DESCRIPTION
    部署策略以「不丢东西」为前提：
      1. 检查依赖是否就绪（wezterm / oh-my-posh / pwsh）
      2. 已存在的目标目录或文件改名为 <原名>.bak-<时间戳>（只改名，不删除）
      3. 从仓库复制配置到目标位置
      4. 打印还需要手动完成的步骤

    目标位置：
      WezTerm 配置   ->  ~/.config/wezterm
      Oh My Posh 主题 ->  ~/.config/omp
      PS7 profile    ->  ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1  (Windows)
                          ~/.config/powershell/Microsoft.PowerShell_profile.ps1   (macOS/Linux)

.PARAMETER Force
    跳过所有确认提示。

.PARAMETER SkipWezTerm
    不部署 WezTerm 配置。

.PARAMETER SkipOmp
    不部署 Oh My Posh 主题。

.PARAMETER SkipProfile
    不部署 PowerShell profile。

.EXAMPLE
    .\install.ps1
    交互式部署全部配置。

.EXAMPLE
    .\install.ps1 -Force -SkipProfile
    直接部署 WezTerm 与 Oh My Posh 配置，不碰 profile。
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$SkipWezTerm,
    [switch]$SkipOmp,
    [switch]$SkipProfile
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot
$Stamp    = Get-Date -Format 'yyyyMMdd-HHmmss'
$IsWin    = $IsWindows -or ($PSVersionTable.PSEdition -eq 'Desktop')

function Say      ($m) { Write-Host $m }
function Step     ($m) { Write-Host "`n== $m" -ForegroundColor Cyan }
function Ok       ($m) { Write-Host "   [OK]   $m" -ForegroundColor Green }
function Warn     ($m) { Write-Host "   [WARN] $m" -ForegroundColor Yellow }
function Skip     ($m) { Write-Host "   [SKIP] $m" -ForegroundColor DarkGray }

function Confirm-Yes($question) {
    if ($Force) { return $true }
    $a = Read-Host "   $question [Y/n]"
    return ($a -eq '' -or $a -match '^[Yy]')
}

# 只改名、不删除：把已有配置挪到带时间戳的备份名
function Move-Aside($path) {
    if (Test-Path -LiteralPath $path) {
        $bak = "$path.bak-$Stamp"
        Move-Item -LiteralPath $path -Destination $bak -Force
        Warn "已备份原配置 -> $bak"
    }
}

$Home_ = $env:USERPROFILE
if (-not $IsWin) { $Home_ = $HOME }

$targets = @{
    WezTerm = Join-Path $Home_ '.config/wezterm'
    Omp     = Join-Path $Home_ '.config/omp'
    Profile = if ($IsWin) {
        Join-Path $Home_ 'Documents/PowerShell/Microsoft.PowerShell_profile.ps1'
    } else {
        Join-Path $Home_ '.config/powershell/Microsoft.PowerShell_profile.ps1'
    }
}

Say "仓库位置 : $RepoRoot"
Say "备份后缀 : .bak-$Stamp"

# ---------------------------------------------------------------- 1. 依赖检查
Step '1/4 检查依赖'
$missing = @()
foreach ($cmd in 'wezterm', 'oh-my-posh', 'pwsh') {
    $found = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($found) { Ok "$cmd  ->  $($found.Source)" } else { Warn "$cmd 未安装"; $missing += $cmd }
}
if ($missing.Count -gt 0) {
    Warn "缺少：$($missing -join ', ')"
    Warn "参考 README 的「依赖安装」一节；可以先继续部署文件，装好依赖后再重开终端。"
    if (-not (Confirm-Yes '仍然继续部署？')) { Say '已取消。'; return }
}

# ---------------------------------------------------------------- 2. WezTerm
Step '2/4 部署 WezTerm 配置'
if ($SkipWezTerm) {
    Skip '按参数要求跳过'
} else {
    $src = Join-Path $RepoRoot 'wezterm'
    $dst = $targets.WezTerm
    if (-not (Test-Path -LiteralPath $src)) {
        Warn "仓库里找不到 wezterm 目录：$src"
    } elseif (Confirm-Yes "把 $src 部署到 $dst ？") {
        Move-Aside $dst
        New-Item -ItemType Directory -Path (Split-Path $dst) -Force | Out-Null
        Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
        Ok "已部署 $((Get-ChildItem $dst -Recurse -File -Force | Measure-Object).Count) 个文件 -> $dst"
        Warn "注意：config/launch.lua 里的 GitBash 路径是按原作者机器写死的，换机器后需要改。"
    } else { Skip '用户取消' }
}

# ---------------------------------------------------------------- 3. Oh My Posh
Step '3/4 部署 Oh My Posh 主题'
if ($SkipOmp) {
    Skip '按参数要求跳过'
} else {
    $src = Join-Path $RepoRoot 'omp'
    $dst = $targets.Omp
    if (-not (Test-Path -LiteralPath $src)) {
        Warn "仓库里找不到 omp 目录：$src"
    } elseif (Confirm-Yes "把 $src 部署到 $dst ？（含 current-theme.txt 当前主题指针）") {
        Move-Aside $dst
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $src '*') -Destination $dst -Force
        Ok "已部署主题：$((Get-ChildItem $dst -File | ForEach-Object { $_.BaseName }) -join ', ')"
    } else { Skip '用户取消' }
}

# ---------------------------------------------------------------- 4. profile
Step '4/4 部署 PowerShell 7 profile'
if ($SkipProfile) {
    Skip '按参数要求跳过'
} else {
    $src = Join-Path $RepoRoot 'powershell/Microsoft.PowerShell_profile.ps1'
    $dst = $targets.Profile
    if (-not (Test-Path -LiteralPath $src)) {
        Warn "仓库里找不到 profile：$src"
    } elseif (Confirm-Yes "把 profile 部署到 $dst ？") {
        New-Item -ItemType Directory -Path (Split-Path $dst) -Force | Out-Null
        Move-Aside $dst
        Copy-Item -LiteralPath $src -Destination $dst -Force
        Ok "已部署 profile -> $dst"
        Warn "profile 里的 GitHub PAT 段依赖 ~/.dsh/secrets/github_token.dpapi，新机器上不存在会自动跳过。"
    } else { Skip '用户取消' }
}

# ---------------------------------------------------------------- 后续步骤
Say ''
Say '================ 还需要手动完成的步骤 ================' -ForegroundColor Magenta
Say ''
Say '  1) 安装依赖（Windows / scoop 为例）'
Say '       scoop bucket add versions'
Say '       scoop bucket add nerd-fonts'
Say '       scoop install wezterm-nightly oh-my-posh Maple-Mono-NF-CN'
Say ''
Say '  2) 确认默认 shell 是 PowerShell 7（pwsh），不是 Windows PowerShell 5.1'
Say '       5.1 不会读取本仓库部署的 profile。'
Say ''
Say '  3) 关闭所有旧终端窗口，重新打开 WezTerm'
Say ''
Say '  4) 环境差异需要手动调整的地方：'
Say '       - wezterm/config/launch.lua   启动菜单里的 GitBash 绝对路径'
Say '       - wezterm/config/fonts.lua    字体名（换字体时）'
Say ''
Say '  5) 验证'
Say '       Get-OmpThemePath       # 应指向 ~/.config/omp/<主题名>.omp.json'
Say '       Get-OmpTheme           # 当前主题名'
Say '       Set-OmpTheme 石墨       # 换另一套配色'
Say ''
Say '如需回滚：把 <目标>.bak-<时间戳> 改回原名字即可。' -ForegroundColor DarkGray
Say ''
