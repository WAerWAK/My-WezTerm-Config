# My WezTerm Config

> 一套自用的 Windows 终端配置：**WezTerm + PowerShell 7 + Oh My Posh**，
> 换电脑时一条命令还原，主题随时可切。

[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-0078D4)](#)
[![Shell](https://img.shields.io/badge/shell-PowerShell%207-5391FE)](#)
[![Terminal](https://img.shields.io/badge/terminal-WezTerm%20nightly-4E49EE)](#)
[![Prompt](https://img.shields.io/badge/prompt-Oh%20My%20Posh-3B82F6)](#)
[![License](https://img.shields.io/badge/license-MIT-green)](wezterm/LICENSE)

---

## 目录

- [这是什么](#这是什么)
- [界面预览](#界面预览)
- [组成与依赖](#组成与依赖)
- [快速开始](#快速开始)
  - [1. 安装依赖](#1-安装依赖)
  - [2. 获取配置](#2-获取配置)
  - [3. 一键部署](#3-一键部署)
  - [4. 验证](#4-验证)
- [仓库结构](#仓库结构)
- [配置详解](#配置详解)
  - [WezTerm](#wezterm)
  - [Oh My Posh 主题](#oh-my-posh-主题)
  - [PowerShell profile](#powershell-profile)
- [日常使用](#日常使用)
- [自定义指南](#自定义指南)
- [与上游同步](#与上游同步)
- [踩坑记录](#踩坑记录)
- [换机迁移清单](#换机迁移清单)
- [更新日志](#更新日志)
- [致谢与许可](#致谢与许可)

---

## 这是什么

一台 Windows 开发机上长期演进出来的终端环境，包含三部分：

| 层 | 组件 | 负责什么 |
|---|---|---|
| 终端模拟器 | **WezTerm**（nightly） | 窗口 / 标签 / 窗格 / 键位 / 字体渲染 / GPU 加速 |
| Shell | **PowerShell 7** | 命令解释、模块、启动逻辑（profile） |
| 提示符 | **Oh My Posh** | 渲染提示符：路径、Git 状态、语言版本、内存、时间 |

配置本身的价值点：

- **模块化 Lua 配置**：WezTerm 侧拆成 `config/`（声明式设置）+ `events/`（自绘标签栏、状态栏），长期可维护。
- **两套可秒切的 Oh My Posh 配色**：`深海蓝`（蓝色渐变）与 `石墨`（低饱和灰蓝），链式 powerline 布局。
- **响应式提示符**：窗口变窄时次要信息自动让位，避免第一行挤爆换行。
- **一键部署脚本**：`install.ps1` 自动备份 + 部署，新机器上五分钟内可用。

---

## 界面预览

提示符分两行，第一行是状态信息，第二行是输入行：

![效果预览](D:\Projects\WezTermConfig\docs\效果预览.png)

> `▶` 表示各级颜色的过渡三角。没有内容的段（比如当前目录不是 Node 项目时的 `node` 段）
> 只会留下一个颜色过渡，不会断开整条颜色链。

两套配色的色卡与对比度如下：

![配色对比图](D:\Projects\WezTermConfig\docs\配色对比图.png)

| 主题 | 色系 | 左链末端 | 最低对比度 |
|---|---|---|---|
| `myconfig_深海蓝` | 蓝，全程白字 | `#2172A1` | 5.27:1 |
| `myconfig_石墨` | 低饱和灰蓝，全程白字 | `#42667B` | 6.14:1 |

---

## 组成与依赖

参考环境（原作者的机器，其它版本一般也能用）：

| 组件 | 版本 | 安装方式 | 备注 |
|---|---|---|---|
| WezTerm | `20260929-043349-cab25161`（nightly） | `scoop install wezterm-nightly` | 稳定版长期停留在 `20240203`，配置用到了 nightly 字段 |
| Oh My Posh | `31.4.1` | `scoop install oh-my-posh` | |
| PowerShell | `7.6.6` | 官方安装包 / winget | **必须是 7.x**，5.1 不读本仓库的 profile |
| Maple Mono NF CN | `7.9` | `scoop install Maple-Mono-NF-CN` | 提供等宽 + Nerd Font 图标 + 中文 + 连字 |
| Git | 任意 | `scoop install git` | Git 段与版本管理需要 |
| Scoop | `v0.6.0` | 官方脚本 | 仅为示例，可换成 winget / choco |

字体是**硬性依赖**：主题里大量使用 Nerd Font 图标（`\ue0b0`、`\ue738` 等），
字体不对会显示成方框 `□`。

---

## 快速开始

### 1. 安装依赖

```powershell
# Scoop
scoop bucket add versions
scoop bucket add nerd-fonts
scoop install wezterm-nightly oh-my-posh Maple-Mono-NF-CN git

# 或者用 winget
winget install wez.wezterm JanDeDobbeleer.OhMyPosh Microsoft.PowerShell
# 字体仍建议用 scoop 装，或从 https://www.nerdfonts.com/ 手动下载安装
```

### 2. 获取配置

```powershell
git clone https://github.com/WAerWAK/My-WezTerm-Config.git D:\Projects\WezTermConfig
cd D:\Projects\WezTermConfig
```

### 3. 一键部署

```powershell
# 交互式，每一步都会问你
.\install.ps1

# 或者直接部署全部，不问
.\install.ps1 -Force

# 只想更新主题，不动 WezTerm 配置和 profile
.\install.ps1 -Force -SkipWezTerm -SkipProfile
```

脚本做的事：

1. 检查 `wezterm` / `oh-my-posh` / `pwsh` 是否就绪；
2. 把已存在的目标配置**改名**为 `<原名>.bak-<时间戳>`（只改名，不删除）；
3. 从仓库复制配置到位；
4. 打印还需要手动完成的步骤。

| 配置 | 部署到 |
|---|---|
| WezTerm | `~/.config/wezterm`（Windows 为 `%USERPROFILE%\.config\wezterm`） |
| Oh My Posh 主题 | `~/.config/omp` |
| PS7 profile | `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`（macOS/Linux 为 `~/.config/powershell/`） |

**回滚**：把 `<目标>.bak-<时间戳>` 改回原名字即可。

### 4. 验证

重新打开 WezTerm（或新开一个标签页），然后在 PowerShell 里：

```powershell
Get-OmpThemePath      # 应指向 ~/.config/omp/<主题名>.omp.json
Get-OmpTheme          # 当前主题名，例如 myconfig_深海蓝
wezterm show-keys     # 能看到配置里的键位，说明 WezTerm 配置已加载
```

---

## 仓库结构

```
My-WezTerm-Config/
├── README.md                        本文件
├── install.ps1                      一键部署脚本（备份 + 复制 + 提示）
├── .gitignore
├── docs/
│   └── theme-palettes.png           两套配色的色值与对比度对照图
│
├── wezterm/                         → 部署到 ~/.config/wezterm
│   ├── wezterm.lua                  入口：装配各模块 + 注册事件钩子
│   ├── config/
│   │   ├── init.lua                 Config 构造器（提供 :append 合并）
│   │   ├── appearance.lua           外观：GPU 前端 / 帧率 / 渐变背景 / 标签栏 / 光标 / 窗口按钮
│   │   ├── bindings.lua             键位表 + key tables + 鼠标绑定
│   │   ├── domains.lua              SSH / WSL / Unix 域
│   │   ├── fonts.lua                字体与字号
│   │   ├── general.lua              行为项 + hyperlink_rules
│   │   └── launch.lua               默认 shell 与启动菜单
│   ├── events/
│   │   ├── right-status.lua         右侧状态栏（日期；电量函数保留但已注释）
│   │   ├── tab-title.lua            标签标题（自绘胶囊样式）
│   │   └── new-tab-button.lua       标签栏「+」按钮（左键新建 / 右键菜单）
│   ├── colors/custom.lua            备用配色（微调版 Catppuccin Mocha，默认未启用）
│   ├── utils/
│   │   ├── math.lua                 clamp / round
│   │   └── platform.lua             is_win / is_mac / is_linux 判定
│   ├── backdrops/space.jpg          背景图素材（默认未启用）
│   ├── .editorconfig / .stylua.toml / selene.toml / .luarc.json   代码风格与 lint
│   └── LICENSE                      上游 MIT 许可证（本仓库派生自它，必须保留）
│
├── omp/                             → 部署到 ~/.config/omp
│   ├── myconfig_深海蓝.omp.json      主题：蓝色渐变
│   ├── myconfig_石墨.omp.json        主题：低饱和灰蓝渐变
│   └── current-theme.txt            当前启用哪套（一行纯文本，内容就是主题名）
│
└── powershell/                      → 部署到 PS7 的 profile 位置
    └── Microsoft.PowerShell_profile.ps1
```

---

## 配置详解

### WezTerm

#### 加载顺序

WezTerm 按下面的顺序找配置，**先命中者生效**：

| 优先级 | 位置 | 说明 |
|---|---|---|
| 1 | 命令行 `--config-file <路径>` | 临时测试用 |
| 2 | 环境变量 `WEZTERM_CONFIG_FILE` | 一般不用 |
| 3 | `~/.config/wezterm/wezterm.lua` | ✅ **本配置走这里** |
| 4 | `~/.wezterm.lua` | ⚠️ **只要这个文件存在，第 3 项就永远不会被加载** |

> 这是最容易踩的坑：从旧配置迁移过来时，一定要把 `~/.wezterm.lua` 改名或删掉。

#### 模块职责

`wezterm.lua` 只做三件事：注册三个事件钩子、把 `config/` 下的模块 `:append` 进来。

| 模块 | 关键内容 |
|---|---|
| `appearance.lua` | `front_end = "WebGpu"`、`animation_fps = 60`、窗口背景渐变、`use_fancy_tab_bar = true`、`window_decorations = "INTEGRATED_BUTTONS\|RESIZE"`、`initial_cols = 120` / `initial_rows = 24`、`window_close_confirmation = "AlwaysPrompt"` |
| `bindings.lua` | 全量键位（已关掉默认键位），含 `CTRL+SHIFT+Space` leader 键表 |
| `fonts.lua` | `Maple Mono NF CN`，字号 11（macOS 12） |
| `launch.lua` | 默认 shell `pwsh`，F3 启动菜单（PowerShell 5.1 / 7 / Cmd / GitBash / WSL / 管理员 WezTerm） |
| `domains.lua` | SSH / WSL / Unix 域定义 |
| `general.lua` | 行为开关 + `hyperlink_rules` |

#### 常用快捷键

Windows 上 `SUPER` 就是 `Win` 键。完整列表见 `config/bindings.lua`，或运行 `wezterm show-keys`。

| 按键 | 作用 |
|---|---|
| `F1` | 进入复制模式（vi 风格选择） |
| `F2` | 命令面板 |
| `F3` | 启动菜单（选 shell / 域） |
| `F4` | 标签导航器 |
| `F11` / `F12` | 全屏 / 调试浮层 |
| `Ctrl+C` / `Ctrl+V` | 复制 / 粘贴 |
| `Super+F` | 搜索 |
| `Super+T` / `Super+Shift+W` | 新建标签 / 关闭标签 |
| `Super+[` / `Super+]` | 切换标签 |
| `Super+Shift+[` / `Super+Shift+]` | 移动标签 |
| `Super+N` | 新窗口 |
| `Super+W` | 关闭当前窗格 |
| `Super+Shift+H/J/K/L` | 按方向切换窗格 |
| `Super+Shift+方向键` | 调整窗格大小 |
| `Super+方向键` / `Super+R` | 放大 / 缩小 / 重置字号 |
| `Super+Shift+Z` | 窗格最大化切换 |
| `Ctrl+Shift+Space` | leader 键（进入自定义键表） |

#### 相对上游的适配点

本仓库的 `wezterm/` 派生自 [QianSong1/wezterm-config](https://github.com/QianSong1/wezterm-config)，
针对 Windows 开发机做了这些修改（源码里都有 `本机适配` 注释）：

| 文件 | 改动 |
|---|---|
| `fonts.lua` | 字体由 `JetBrainsMono NF` 改为 `Maple Mono NF CN`（前者未安装会回退默认字体导致图标缺失），字号 9 → 11 |
| `launch.lua` | 默认 shell 由 `powershell`（5.1）改为 `pwsh`（7）——否则 Oh My Posh 提示符不加载；GitBash 路径改成本机 scoop 路径；用 WSL 域替换了原作者的 SSH 主机；新增「管理员 WezTerm」入口 |
| `bindings.lua` / `domains.lua` / `events/*` | 键位、域、标签栏与状态栏的细节调整 |

> ⚠️ **换机器必改**：`config/launch.lua` 里 GitBash 的绝对路径
> （`D:\Apps\Scoop\apps\git\current\bin\bash.exe`）是按原机器写的。

### Oh My Posh 主题

#### 主题是怎么被选中的

配置文件全部放在 `~/.config/omp`（**不是** scoop 内置主题目录，避免 `scoop update` 覆盖）。
选哪套由 profile 里的逻辑按优先级决定：

| 优先级 | 来源 | 作用范围 | 怎么改 |
|---|---|---|---|
| 1 | 环境变量 `$env:OMP_THEME` | 仅当前会话 | `Set-OmpTheme 石墨 -SessionOnly` |
| 2 | `~/.config/omp/current-theme.txt` | 持久 | `Set-OmpTheme 石墨` |
| 3 | 主题目录里排序最靠前的一套 | 兜底 | 无需干预 |

解析出的路径是 `~/.config/omp/<主题名>.omp.json`，找不到才去 `$env:POSH_THEMES_PATH` 找同名文件。

#### 主题结构

两套主题**共用同一骨架，只有 12 个 `background` 值不同**。

| 块 | 对齐 | 内容 |
|---|---|---|
| 1 | left | `root` → `path` → `java` → `node` → `python` → `rust` → `kotlin` → `sysinfo`，颜色由深到浅 |
| 2 | right | `executiontime` → `git` → `session` → `os` |
| 3 | left（换行） | `status`：`❯`，上条命令失败时变红 |

| 段 | 样式 | 说明 |
|---|---|---|
| `root` | `diamond` + `leading_diamond` `\ue0be` | 提权会话显示 ⚡，普通会话输出占位符 U+2800，只保留一个颜色过渡 |
| `path` | `powerline` | `options.style = full` 始终显示完整路径；`mapped_locations_enabled: false` 让家目录也展开成完整路径 |
| `java` `node` `python` `rust` `kotlin` | **`accordion`** | 有对应项目文件时显示「图标 + 版本」；没有时**只画颜色过渡、完全不查询版本**（零开销） |
| `sysinfo` | `powerline` | 物理内存占用百分比 |
| `executiontime` | `diamond` | 首尾三角，`always_enabled: true` |
| `git` | `accordion` | 非 Git 仓库时只留过渡色 |
| `session` / `os` | `powerline` | 用户名、系统图标 |

#### 响应式：窄窗口自动让位

Oh My Posh 的 `min_width` 表示「终端宽度小于该值就隐藏这个段」。本配置用它给第一行减负：

| 段 | `min_width` | 含义 |
|---|---|---|
| `executiontime` | 100 | 窗口窄于 100 列时隐藏 |
| `session` | 140 | 窗口窄于 140 列时隐藏 |
| `os` | 130 | 窗口窄于 130 列时隐藏 |

> 注意：`accordion` 样式的段**不吃 `min_width`**（它的定义就是"禁用时仍画色块"），
> 所以语言段和 `git` 段没有门槛，详见[踩坑记录](#踩坑记录)。

### PowerShell profile

`Microsoft.PowerShell_profile.ps1` 按顺序做四件事：

| 顺序 | 内容 | 说明 |
|---|---|---|
| 1 | PowerToys CommandNotFound | 输入未安装命令时提示用 winget 安装 |
| 2 | GitHub PAT 注入 | 从 `~/.dsh/secrets/github_token.dpapi`（DPAPI 加密）解密写入 `$env:GITHUB_TOKEN`；文件不存在时静默跳过 |
| 3 | Oh My Posh 初始化 | 定义 `Get-OmpTheme` / `Get-OmpThemePath` / `Set-OmpTheme`，再按优先级解析主题并加载；找不到任何主题时退回内置默认 |
| 4 | PSReadLine 增强 | 历史 + 插件预测、ListView 视图、Windows 编辑模式、Tab 菜单补全、上下键历史搜索 |

---

## 日常使用

```powershell
# 主题
Get-OmpTheme                        # 当前主题名
Get-OmpThemePath                    # 当前实际加载的主题文件全路径
Set-OmpTheme 石墨                    # 切换并记忆（下次开终端仍生效）
Set-OmpTheme 深海蓝 -SessionOnly     # 只影响当前会话

# 新增一套自己的主题
Copy-Item ~\.config\omp\myconfig_深海蓝.omp.json ~\.config\omp\myconfig_我的.omp.json
Set-OmpTheme 我的                    # 名字可只写一部分

# 排查
oh-my-posh debug                    # 看各段渲染耗时
wezterm show-keys                   # 看生效中的键位
wezterm ls-fonts --list-system      # 看系统里有哪些字体
```

---

## 自定义指南

| 想改什么 | 改哪个文件 | 生效方式 |
|---|---|---|
| 终端外观（透明、渐变、光标、按钮） | `wezterm/config/appearance.lua` | 保存即热重载 |
| 键位 | `wezterm/config/bindings.lua` | 保存即热重载 |
| 字体 / 字号 | `wezterm/config/fonts.lua` | 保存即热重载 |
| 默认 shell、启动菜单 | `wezterm/config/launch.lua` | 保存即热重载 |
| 标签栏、状态栏 | `wezterm/events/*.lua` | 保存即热重载 |
| 提示符颜色 | `omp/myconfig_*.omp.json` 里各段的 `background` | 存盘后新开标签页；当前窗口用 `Set-OmpTheme <名字>` 立即生效 |
| 提示符段（增删改） | 同上，`blocks[].segments[]` | 同上 |
| 主题选择 / 别名 / 环境变量 | `powershell/Microsoft.PowerShell_profile.ps1` | `. $PROFILE` 或新开标签页 |

改完记得提交：

```powershell
cd D:\Projects\WezTermConfig
git add -A
git commit -m "调整 xxx"
git push
```

---

## 与上游同步

`wezterm/` 派生自 [QianSong1/wezterm-config](https://github.com/QianSong1/wezterm-config)，
想拉上游更新时可以：

```powershell
cd D:\Projects\WezTermConfig
git remote add upstream https://github.com/QianSong1/wezterm-config.git
git fetch upstream
git diff upstream/main -- wezterm/      # 先看差异，再决定要不要合并
git merge upstream/main                 # 注意会与本仓库的「本机适配」产生冲突
```

冲突几乎总是出在那几个 `本机适配` 注释过的地方（字体、默认 shell、GitBash 路径）。

---

## 踩坑记录

这些都是实际踩过的坑，换机器或改配置时可能会再遇到。

### 1. 提示符第一行太长 → 输入时光标往下跳一行

**现象**：提示符两行（信息行 + `❯` 行），光标停在 `❯` 右边正常，但一敲键盘光标就掉到第三行。

**原因**：Oh My Posh 为了让右侧块靠右，会把第一行**填充到恰好等于窗口宽度**，
第一行永远顶在折行边界上。此时只要有一个字符的「宽度认知」两边不一致，就会出事：

| 字符 | PSReadLine 算 | 终端渲染 |
|---|---|---|
| `\ue0be` `\ue0b0` `\uf0e7` 等 Nerd Font 图标 | 1 | 1 |
| `❯` | 1 | 1 |
| **零宽空格 U+200B** | **1** | **0** |

用 U+200B 当占位符时，PSReadLine 认为提示符比实际宽 1 格 → 判定第一行折成了两行 →
于是它按「3 行」重绘，光标就落到第三行。**注意 `ExtraPromptLineCount` 显示的是正确值 `1`，
所以从这个数字上看不出问题。**

**修复**：占位符改用 **U+2800（盲文空白）**——宽度 1 格，三方算法一致，视觉上同样是空白。

**排查手法**：

```powershell
# 直接问 PSReadLine 某个字符占几格
Import-Module PSReadLine
$t = [Microsoft.PowerShell.PSConsoleReadLine]
$m = $t.GetMethod('LengthInBufferCells', [Reflection.BindingFlags]'NonPublic,Static,Public', $null, @([string]), $null)
$m.Invoke($null, @("a$([char]0x200B)b"))   # 返回 3 说明它把零宽空格算成 1 格
```

### 2. `accordion` 样式的段无法用 `min_width` 隐藏

`accordion` 的设计目标是「段被禁用时仍然渲染背景色块，只是没有文字」，
而 `min_width` 走的正是"禁用"这条路径 —— 结果就是门槛设了也没用，色块照旧。
`git` 段同理。

试过「宽窗口用 accordion / 窄窗口用 powerline」的双段配对方案，**会导致两个段同时显示**
（accordion 版没被门槛拦住，窄版又满足条件显示了），所以最终放弃。

结论：能靠 `min_width` 瘦身的只有 `powerline` / `diamond` 样式的段。

### 3. 提示符卡顿

`oh-my-posh debug` 看各段耗时。本项目可能的两处开销：

- **语言段**：`accordion` 在非项目目录不会查询版本，但在**对应项目目录里仍会查** ——
  Python 若走 pyenv 的 `python.bat` shim，单段可达 600 ms；
- **`git` 段**：仓库越大越慢。

整条提示符的参考值：普通目录约 65 ms，Gradle 项目根目录约 200 ms。

### 4. Windows Terminal 里换行/着色异常

如果同一套主题在 Windows Terminal 里表现不同，可以关闭
**设置 → 配置文件 → 外观 → Adjust indistinguishable colors**，
它会「自作主张」调整对比度不足的前景/背景色，把 powerline 分隔符和相邻色块调得不一致。

### 5. 图片类图标变成方框

字体没装或名字写错。`wezterm ls-fonts --list-system | Select-String "Maple"` 确认字体已安装，
再核对 `config/fonts.lua` 里的字体名。

---

## 换机迁移清单

- [ ] 安装 Scoop，`scoop bucket add versions` / `nerd-fonts`
- [ ] `scoop install wezterm-nightly oh-my-posh Maple-Mono-NF-CN git`
- [ ] 安装 PowerShell 7（`winget install Microsoft.PowerShell`）
- [ ] `git clone https://github.com/WAerWAK/My-WezTerm-Config.git`
- [ ] `.\install.ps1`（老机器上已有配置会被自动备份）
- [ ] 改 `wezterm/config/launch.lua` 里的 GitBash 路径
- [ ] 关掉所有旧终端，重开 WezTerm，确认标签栏 / 状态栏 / 提示符都正常
- [ ] 需要 GitHub API 的话，重新生成 DPAPI 令牌文件（**换机器无法解密旧文件**）

---

## 更新日志

| 日期 | 内容 |
|---|---|
| 2026-10-04 | 仓库建立：整理 WezTerm 配置、两套 Oh My Posh 主题、profile，加入 `install.ps1` 与本文档 |
| 2026-10-04 | 修复提示符占位符：零宽空格 U+200B → 盲文空白 U+2800（解决输入时光标跳行） |
| 2026-10-04 | 右链加入 `min_width` 响应式门槛（executiontime 100 / session 140 / os 130） |

---

## 致谢与许可

- WezTerm 配置派生自 [QianSong1/wezterm-config](https://github.com/QianSong1/wezterm-config)
  （基于 KevinSilvester/wezterm-config 改造），沿用其 **MIT** 许可证，见 [`wezterm/LICENSE`](wezterm/LICENSE)。
- 提示符由 [Oh My Posh](https://ohmyposh.dev/) 渲染，主题为自建。
- 字体 [Maple Mono NF CN](https://github.com/subframe7536/maple-font)。
- 本仓库其余部分（Oh My Posh 主题、profile、`install.ps1`、文档）同样以 MIT 许可发布。
