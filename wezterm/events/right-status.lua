local wezterm = require("wezterm")
local M = {}

M.separator_char = " ~ "

M.colors = {
  date_fg = "#3E7FB5",
  date_bg = "#181825",
  separator_fg = "#786D22",
  separator_bg = "#181825",
}

M.cells = {} -- wezterm FormatItems (ref: https://wezfurlong.org/wezterm/config/lua/wezterm/format.html)

---@param text string
---@param icon string
---@param fg string
---@param bg string
---@param separate boolean
M.push = function(text, icon, fg, bg, separate)
  table.insert(M.cells, { Foreground = { Color = fg } })
  table.insert(M.cells, { Background = { Color = bg } })
  table.insert(M.cells, { Attribute = { Intensity = "Bold" } })
  table.insert(M.cells, { Text = icon .. " " .. text .. " " })

  if separate then
    table.insert(M.cells, { Foreground = { Color = M.colors.separator_fg } })
    table.insert(M.cells, { Background = { Color = M.colors.separator_bg } })
    table.insert(M.cells, { Text = M.separator_char })
  end

  table.insert(M.cells, "ResetAttributes")
end

M.set_date = function()
  local date = wezterm.strftime(" %a %H:%M")
  -- 本机适配：原仓库此处 separate = true（为后面的电量格留分隔符），
  -- 本机去掉电量显示后不再需要分隔符，改为 false。
  M.push(date, "", M.colors.date_fg, M.colors.date_bg, false)
end

-- 本机适配：原仓库还有一个 M.set_battery()（Nerd Font 电量图标 + 百分比），按需求已移除。
-- 需要恢复时，可把下面注释里的函数加回，并在 M.setup 中调用：
--
-- M.set_battery = function()
--   local discharging_icons = { "", "", "", "", "", "", "", "", "", "" }
--   local charging_icons    = { "", "", "", "", "", "", "", "", "", "" }
--   local math = require("utils.math")
--   local charge, icon = "", ""
--   for _, b in ipairs(wezterm.battery_info()) do
--     local idx = math.clamp(math.round(b.state_of_charge * 10), 1, 10)
--     charge = string.format("%.0f%%", b.state_of_charge * 100)
--     icon = (b.state == "Charging") and charging_icons[idx] or discharging_icons[idx]
--   end
--   -- 颜色见 M.colors.battery_fg / battery_bg（#B52F90 / #181825）
--   M.push(charge, icon, "#B52F90", "#181825", false)
-- end

M.setup = function()
  wezterm.on("update-right-status", function(window, _pane)
    M.cells = {}
    M.set_date()
    -- M.set_battery()   -- 本机已去掉电量

    window:set_right_status(wezterm.format(M.cells))
  end)
end

return M
