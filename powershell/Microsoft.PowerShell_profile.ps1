
#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58

# GitHub PAT 解密（供 scoop / gh-api.ps1 使用）：读取 DPAPI 加密文件，注入真 token
$__ghp = "$env:USERPROFILE\.dsh\secrets\github_token.dpapi"
if (Test-Path $__ghp) {
    try {
        $__ghs = Get-Content $__ghp | ConvertTo-SecureString
        $env:GITHUB_TOKEN = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($__ghs))
    } catch {}
}
Remove-Variable __ghp, __ghs -ErrorAction SilentlyContinue

# === 管理员身份标记（必须在 Oh My Posh 初始化之前设置）===
# 主题的 console_title_template 用的是模板变量 {{ .Root }}；这个环境变量留给
# 需要在 shell 侧判断提权的场景（自定义脚本、状态栏模块等）使用。
$__isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($__isAdmin) { $env:OMP_ADMIN = '1' } else { Remove-Item Env:\OMP_ADMIN -ErrorAction SilentlyContinue }

# === 终端美化：Oh My Posh ===
# 自定义主题统一放在 ~\.config\omp（scoop 升级 oh-my-posh 不会覆盖）。
# 选哪套主题由「主题名」决定，优先级：
#   $env:OMP_THEME（仅当前会话） > current-theme.txt（持久记录） > 主题目录里排序最靠前的一套
# 会话内切换：Set-OmpTheme 深海蓝        （写入 current-theme.txt，下次开终端仍生效）
#             Set-OmpTheme 石墨 -SessionOnly   （只影响当前会话）
# 查看当前：Get-OmpTheme / Get-OmpThemePath
$global:OmpThemeDir = if ($env:OMP_THEME_DIR) { $env:OMP_THEME_DIR } else { "$env:USERPROFILE\.config\omp" }
$global:OmpThemePointer = Join-Path $global:OmpThemeDir 'current-theme.txt'

function Get-OmpTheme {
    if ($env:OMP_THEME) { return $env:OMP_THEME }
    if (Test-Path $global:OmpThemePointer) {
        $name = (Get-Content $global:OmpThemePointer -Raw -Encoding utf8 -ErrorAction SilentlyContinue)
        if ($name) { $name = $name.Trim() }
        if ($name) { return $name }
    }
    # 没有指针文件时：用主题目录里排序最靠前的一套（避免回退到 scoop 内置目录里的旧副本）
    $first = Get-ChildItem -LiteralPath $global:OmpThemeDir -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like '*.omp.json' } | Sort-Object Name | Select-Object -First 1
    if ($first) { return ($first.BaseName -replace '\.omp$', '') }
    return 'myconfig2'
}

function Get-OmpThemePath {
    $name = Get-OmpTheme
    # current-theme.txt 里也可以直接写完整路径
    if ([System.IO.Path]::IsPathRooted($name) -and (Test-Path -LiteralPath $name -PathType Leaf)) {
        return (Resolve-Path -LiteralPath $name).Path
    }
    $candidates = @()
    if ($global:OmpThemeDir) { $candidates += (Join-Path $global:OmpThemeDir "${name}.omp.json") }
    if ($env:POSH_THEMES_PATH) { $candidates += (Join-Path $env:POSH_THEMES_PATH "${name}.omp.json") }
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c -PathType Leaf) { return (Resolve-Path -LiteralPath $c).Path }
    }
    return $null
}

function Set-OmpTheme {
    <#
    .SYNOPSIS  切换 Oh My Posh 主题并立即生效
    .EXAMPLE   Set-OmpTheme 石墨
    .EXAMPLE   Set-OmpTheme 深海蓝 -SessionOnly
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Name,
        [switch]$SessionOnly
    )
    $file = Join-Path $global:OmpThemeDir "${Name}.omp.json"
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        $hit = Get-ChildItem -LiteralPath $global:OmpThemeDir -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like '*.omp.json' -and $_.BaseName.Contains($Name) } |
            Select-Object -First 1
        if ($hit) { $file = $hit.FullName; $Name = $hit.BaseName -replace '\.omp$', '' }
    }
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        $all = (Get-ChildItem -LiteralPath $global:OmpThemeDir -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like '*.omp.json' } |
                ForEach-Object { $_.BaseName -replace '\.omp$', '' }) -join '、'
        Write-Warning "找不到主题 '$Name'。可用主题：$all"
        return
    }
    if ($SessionOnly) {
        $env:OMP_THEME = $Name
    } else {
        Set-Content -LiteralPath $global:OmpThemePointer -Value $Name -Encoding utf8
        Remove-Item Env:\OMP_THEME -ErrorAction SilentlyContinue
    }
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        oh-my-posh init pwsh --config $file | Invoke-Expression
        Write-Host "Oh My Posh 主题已切换：$Name" -ForegroundColor Green
    }
}

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $__ompTheme = Get-OmpThemePath
    if ($__ompTheme) {
        oh-my-posh init pwsh --config $__ompTheme | Invoke-Expression
    } else {
        # 一个自定义主题都找不到时，退回 Oh My Posh 内置默认主题
        oh-my-posh init pwsh | Invoke-Expression
    }
    Remove-Variable __ompTheme -ErrorAction SilentlyContinue
}
Remove-Variable __isAdmin -ErrorAction SilentlyContinue

# === PSReadLine 增强（PS7 自带；非交互/重定向控制台会自动跳过）===
if (Get-Module -ListAvailable PSReadLine) {
    try {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
        Set-PSReadLineOption -EditMode Windows
        Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
        Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    } catch {
        # 控制台不支持虚拟终端（脚本/管道场景）时忽略
    }
}

# === 说明 ===
# 窗口标题由主题的 console_title_template 渲染（管理员会话带 ⚡ 前缀），
# 不需要在 profile 里再包装 prompt 函数。
# 主题文件：~\.config\omp\<主题名>.omp.json（当前用哪套见 current-theme.txt）

