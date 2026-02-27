local consts = require("scripts.consts")

local GuiParts = {}

--- @param player LuaPlayer
--- @param name string
--- @return LuaGuiElement
function GuiParts.window(player, name)
  local window = player.gui.screen.add({
    type = "frame",
    name = name,
    style = consts.name("window"),
    direction = "vertical",
  })
  window.style.maximal_height = math.floor(player.display_resolution.height * 0.8)
  window.auto_center = true
  return window
end

--- @param window LuaGuiElement
--- @param title LocalisedString
--- @param options { name: string? }?
--- @return LuaGuiElement
function GuiParts.titlebar(window, title, options)
  local titlebar = window.add({
    type = "flow",
    name = options and options.name,
    style = consts.name("titlebar"),
    direction = "horizontal",
  })
  titlebar.drag_target = window
  titlebar.add({
    type = "label",
    style = consts.name("titlebar-title"),
    caption = title,
    ignored_by_interaction = true,
  })
  titlebar.add({
    type = "empty-widget",
    style = consts.name("titlebar-drag-handle"),
    ignored_by_interaction = true,
  })
  return titlebar
end

--- @param titlebar LuaGuiElement
--- @param options { name: string? }?
--- @return LuaGuiElement
function GuiParts.close_button(titlebar, options)
  return titlebar.add({
    type = "sprite-button",
    name = options and options.name,
    style = "frame_action_button",
    sprite = "utility/close",
    hovered_sprite = "utility/close_black",
    clicked_sprite = "utility/close_black",
    tooltip = { "gui.close-instruction" },
    mouse_button_filter = { "left" },
  })
end

--- @param window LuaGuiElement
--- @param options { name: string? }?
--- @return LuaGuiElement
function GuiParts.footer(window, options)
  local footer = window.add({
    type = "flow",
    name = options and options.name,
    style = consts.name("footer"),
    direction = "horizontal",
  })
  footer.drag_target = window
  return footer
end

--- @param footer LuaGuiElement
--- @param options { name: string? }?
--- @return LuaGuiElement
function GuiParts.footer_drag_handle(footer, options)
  return footer.add({
    type = "empty-widget",
    name = options and options.name,
    style = consts.name("footer-drag-handle"),
    ignored_by_interaction = true,
  })
end

--- @param parent LuaGuiElement
--- @return LuaGuiElement
function GuiParts.horizontal_pusher(parent)
  return parent.add({
    type = "empty-widget",
    style = consts.name("horizontal-pusher"),
  })
end

--- @param parent LuaGuiElement
--- @return LuaGuiElement
function GuiParts.vertical_pusher(parent)
  return parent.add({
    type = "empty-widget",
    style = consts.name("vertical-pusher"),
  })
end

--- @param parent LuaGuiElement
--- @param captions LocalisedString[]
--- @param options { name: string? }?
--- @return LuaGuiElement
function GuiParts.paragraphs(parent, captions, options)
  local paragraphs = parent.add({
    type = "flow",
    name = options and options.name,
    direction = "vertical",
    style = consts.name("paragraphs"),
  })

  for i, caption in ipairs(captions) do
    paragraphs.add({
      type = "label",
      caption = caption,
    })
  end

  return paragraphs
end

--- @param parent LuaGuiElement
--- @param icon SpritePath
--- @param caption LocalisedString
--- @param options { name: string?, style: string? }?
--- @return LuaGuiElement
function GuiParts.icon_label(parent, icon, caption, options)
  local icon_label = parent.add({
    type = "flow",
    name = options and options.name,
    style = consts.name("icon-label"),
    direction = "horizontal",
  })
  icon_label.add({
    type = "sprite",
    sprite = icon,
    style = consts.name("icon-label-icon"),
  })
  icon_label.add({
    type = "label",
    caption = caption,
    style = options and options.style,
  })
  return icon_label
end

return GuiParts
