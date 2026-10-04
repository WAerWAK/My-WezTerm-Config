local platform = require("utils.platform")()

local options = {
  default_prog = {},
  launch_menu = {},
}

if platform.is_win then
  -- 本机适配：原仓库为 "powershell"（5.1）。本机的 Oh My Posh 提示符配置在 PowerShell 7 的 profile 里，
  -- 用 5.1 启动不会加载提示符，故改为 pwsh。
  options.default_prog = { "pwsh" }
  options.launch_menu = {
    { label = " PowerShell v1", args = { "powershell" } },
    { label = " PowerShell v7", args = { "pwsh" } },
    { label = " Cmd", args = { "cmd" } },
    -- 本机适配：原为 C:\soft\Git\bin\bash.exe
    { label = " GitBash", args = { "D:\\Apps\\Scoop\\apps\\git\\current\\bin\\bash.exe" } },
    -- 本机适配：原为 { label = "AlmaLinux", args = { "ssh", "kali@192.168.44.147", "-p", "22" } }（本机无此主机）
    { label = " Ubuntu-22.04 (WSL)", domain = { DomainName = "WSL:Ubuntu-22.04" } },
    -- 本机新增：以管理员身份启动 WezTerm（会弹 UAC）
    { label = " WezTerm (Admin)", args = { "powershell.exe", "-NoProfile", "-Command", "Start-Process wezterm-gui -Verb RunAs" } },
  }
elseif platform.is_mac then
  options.default_prog = { "/opt/homebrew/bin/fish", "--login" }
  options.launch_menu = {
    { label = " Bash", args = { "bash", "--login" } },
    { label = " Fish", args = { "/opt/homebrew/bin/fish", "--login" } },
    { label = " Nushell", args = { "/opt/homebrew/bin/nu", "--login" } },
    { label = " Zsh", args = { "zsh", "--login" } },
  }
elseif platform.is_linux then
  options.default_prog = { "bash", "--login" }
  options.launch_menu = {
    { label = " Bash", args = { "bash", "--login" } },
    { label = " Fish", args = { "/opt/homebrew/bin/fish", "--login" } },
    { label = " Nushell", args = { "/opt/homebrew/bin/nu", "--login" } },
    { label = " Zsh", args = { "zsh", "--login" } },
  }
end

return options
