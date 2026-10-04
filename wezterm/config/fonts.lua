local wezterm = require("wezterm")
local platform = require("utils.platform")

-- 本机适配：原仓库用 "JetBrainsMono NF"（本机未安装，会回退到默认字体并导致图标缺失）
local font = "Maple Mono NF CN"
-- 本机适配：原值为 mac 12 / 其他 9；Maple Mono NF CN 在 9pt 下过小，取 11
local font_size = platform().is_mac and 12 or 11

return {
  font = wezterm.font(font),
  font_size = font_size,

  --ref: https://wezfurlong.org/wezterm/config/lua/config/freetype_pcf_long_family_names.html#why-doesnt-wezterm-use-the-distro-freetype-or-match-its-configuration
  freetype_load_target = "Normal", ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
  freetype_render_target = "Normal", ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
}
