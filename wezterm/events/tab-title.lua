local wezterm = require("wezterm")

-- Inspired by https://github.com/wez/wezterm/discussions/628#discussioncomment-1874614
-- 本机适配：字形统一改用 utf8.char 生成，避免源码里出现不可见字符。

local GLYPH_SEMI_CIRCLE_LEFT = utf8.char(0xe0b6)
local GLYPH_SEMI_CIRCLE_RIGHT = utf8.char(0xe0b4)
local GLYPH_CIRCLE = utf8.char(0xf111) .. " "
local GLYPH_ADMIN = utf8.char(0xfc7e) .. " "

local M = {}

M.cells = {}

M.colors = {
  default = {
    bg = "#8C246F",
    fg = "#181825",
  },
  is_active = {
    bg = "#6F8C36",
    fg = "#181825",
  },

  hover = {
    bg = "#8C246F",
    fg = "#181825",
  },
}

M.set_process_name = function(s)
  local a = string.gsub(s, "(.*[/\\])(.*)", "%2")
  return a:gsub("%.exe$", "")
end

-- 本机适配：标题优先级改为「自定义标签名 > 当前文件夹名 > 前台进程名」。
-- 文件夹名由 Oh My Posh 的 console_title_template（📁{{.Folder}}）写入 pane 标题，
-- 因此这里优先使用 active_title；前台进程名仅作兜底。
M.set_title = function(process_name, static_title, active_title, max_width, inset)
  local title
  inset = inset or 6

  if static_title:len() > 0 then
    title = " " .. static_title .. " "
  elseif active_title:len() > 0 then
    title = " " .. active_title .. " "
  elseif process_name:len() > 0 then
    title = " " .. process_name .. " "
  else
    title = " ? "
  end

  if title:len() > max_width - inset then
    local diff = title:len() - max_width + inset
    title = wezterm.truncate_right(title, title:len() - diff)
  end

  return title
end

M.check_if_admin = function(p)
  -- 本机适配：原判据只认 Windows 原生的 "Administrator: " 标题前缀；
  -- 本机 PowerShell profile 还会给提权窗口标题加 "[ADMIN] " 前缀，两种都识别。
  if p:match("^Administrator: ") or p:find("%[ADMIN%]") then
    return true
  end
  return false
end

---@param fg string
---@param bg string
---@param attribute table
---@param text string
M.push = function(bg, fg, attribute, text)
  table.insert(M.cells, { Background = { Color = bg } })
  table.insert(M.cells, { Foreground = { Color = fg } })
  table.insert(M.cells, { Attribute = attribute })
  table.insert(M.cells, { Text = text })
end

M.setup = function()
  wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    M.cells = {}

    local bg
    local fg
    local process_name = M.set_process_name(tab.active_pane.foreground_process_name)
    local is_admin = M.check_if_admin(tab.active_pane.title)
    -- 本机适配：去掉 pane 标题里的 [ADMIN] 前缀（管理员身份另有图标标记，避免重复显示）
    local pane_title = (tab.active_pane.title or ""):gsub("%[ADMIN%]%s*", "")
    local title = M.set_title(process_name, tab.tab_title, pane_title, max_width, (is_admin and 8))

    if tab.is_active then
      bg = M.colors.is_active.bg
      fg = M.colors.is_active.fg
    elseif hover then
      bg = M.colors.hover.bg
      fg = M.colors.hover.fg
    else
      bg = M.colors.default.bg
      fg = M.colors.default.fg
    end

    local has_unseen_output = false
    for _, pane in ipairs(tab.panes) do
      if pane.has_unseen_output then
        has_unseen_output = true
        break
      end
    end

    -- Left semi-circle
    M.push(fg, bg, { Intensity = "Bold" }, GLYPH_SEMI_CIRCLE_LEFT)

    -- Admin Icon
    if is_admin then
      M.push(bg, fg, { Intensity = "Bold" }, " " .. GLYPH_ADMIN)
    end

    -- Title
    M.push(bg, fg, { Intensity = "Bold" }, " " .. title)

    -- Unseen output alert
    if has_unseen_output then
      M.push(bg, "#FF3B8B", { Intensity = "Bold" }, " " .. GLYPH_CIRCLE)
    end

    -- Right padding
    M.push(bg, fg, { Intensity = "Bold" }, " ")

    -- Right semi-circle
    M.push(fg, bg, { Intensity = "Bold" }, GLYPH_SEMI_CIRCLE_RIGHT)

    return M.cells
  end)
end

return M
