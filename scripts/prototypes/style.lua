local consts = require("scripts.consts")

local styles = data.raw["gui-style"].default
local slot_size = styles.slot.size

-- GuiParts

styles[consts.name("window")] = {
  type = "frame_style",
}

styles[consts.name("titlebar")] = {
  type = "horizontal_flow_style",
  horizontal_spacing = 8,
}
styles[consts.name("titlebar-title")] = {
  type = "label_style",
  parent = "frame_title",
  bottom_padding = 3,
  top_margin = -3,
}
styles[consts.name("titlebar-drag-handle")] = {
  type = "empty_widget_style",
  parent = "draggable_space",
  left_margin = 4,
  right_margin = 4,
  height = 24,
  horizontally_stretchable = "on",
}

styles[consts.name("footer")] = {
  type = "horizontal_flow_style",
  parent = "dialog_buttons_horizontal_flow",
}
styles[consts.name("footer-drag-handle")] = {
  type = "empty_widget_style",
  parent = "draggable_space",
  height = 32,
  horizontally_stretchable = "on",
}

styles[consts.name("horizontal-pusher")] = {
  type = "empty_widget_style",
  horizontally_stretchable = "on",
}
styles[consts.name("vertical-pusher")] = {
  type = "empty_widget_style",
  vertically_stretchable = "on",
}

styles[consts.name("paragraphs")] = {
  type = "vertical_flow_style",
  vertical_spacing = 4,
  bottom_margin = 8,
}

styles[consts.name("icon-label")] = {
  type = "horizontal_flow_style",
  horizontal_spacing = 4,
  vertical_align = "center",
}
styles[consts.name("icon-label-icon")] = {
  type = "image_style",
  size = 24,
  stretch_image_to_widget_size = true,
}

-- CustomizeGui

styles[consts.name("tab-content")] = {
  type = "vertical_flow_style",
  left_padding = 12,
  right_padding = 12,
  bottom_padding = 12,
}

styles[consts.name("json-content-flow")] = {
  type = "vertical_flow_style",
  top_padding = 8,
  bottom_padding = 8,
  left_padding = 8,
  right_padding = 8,
}
styles[consts.name("json-text-box")] = {
  type = "textbox_style",
  width = 400,
  minimal_height = 38,
}

-- ShortcutEditor

styles[consts.name("shortcut-pages")] = {
  type = "table_style",
  vertical_spacing = 12,
  horizontal_spacing = 12,
}
styles[consts.name("shortcut-page")] = {
  type = "frame_style",
  parent = "slot_button_deep_frame",
}
styles[consts.name("shortcut-page-center")] = {
  type = "empty_widget_style",
  size = slot_size,
}
