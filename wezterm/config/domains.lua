return {
  -- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
  -- 本机适配：原仓库在这里定义了两台示例主机（Kali-linux / 192.168.44.147、Alma-linux / host.myalmalinux.com），
  -- 本机没有这些主机，保留会让启动菜单出现连不上的项，故清空。需要时按下面留档的格式添加：
  --
  -- ssh_domains = {
  --   {
  --     multiplexing = "None",                  -- 不用多路复用
  --     name = "Kali-linux",                    -- 域名称（唯一）
  --     remote_address = "192.168.44.147:22",   -- host:port
  --     username = "kali",
  --     ssh_option = { identityfile = "C:\\Users\\<你的用户名>\\.ssh\\id_rsa" },
  --   },
  -- }
  ssh_domains = {},

  -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
  unix_domains = {},

  -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
  -- 本机适配：原为 name="WSL:Ubuntu"、distribution="Ubuntu"、username="kevin"、default_cwd="/home/kevin"、default_prog={"fish"}。
  -- 本机发行版是 Ubuntu-22.04，且 WSL 内未装 fish，故去掉 username 与 default_prog，使用发行版默认 shell。
  wsl_domains = {
    {
      name = "WSL:Ubuntu-22.04",
      distribution = "Ubuntu-22.04",
      default_cwd = "/home",
    },
  },
}
