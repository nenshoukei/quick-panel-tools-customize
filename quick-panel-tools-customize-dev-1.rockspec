package = "quick-panel-tools-customize"
version = "dev-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   detailed = "A Factorio mod that allows you to customize the tools tab of the Quick Panel, which is primarily used when playing on a Steam Deck or with a controller.",
   homepage = "*** please enter a project homepage ***",
   license = "The MIT License"
}
dependencies = {
   queries = {}
}
build_dependencies = {
   queries = {}
}
build = {
   type = "builtin",
   modules = {
      control = "control.lua",
      data = "data.lua",
      ["data-final-fixes"] = "data-final-fixes.lua",
      ["scripts.consts"] = "scripts/consts.lua",
      ["scripts.control.customize-gui-control"] = "scripts/control/customize-gui-control.lua",
      ["scripts.gui.customize-gui"] = "scripts/gui/customize-gui.lua",
      ["scripts.gui.gui-parts"] = "scripts/gui/gui-parts.lua",
      ["scripts.gui.shortcut-editor"] = "scripts/gui/shortcut-editor.lua",
      ["scripts.lib.customization"] = "scripts/lib/customization.lua",
      ["scripts.lib.event"] = "scripts/lib/event.lua",
      ["scripts.lib.gui-component"] = "scripts/lib/gui-component.lua",
      ["scripts.lib.metatable"] = "scripts/lib/metatable.lua",
      ["scripts.lib.shortcut-dict"] = "scripts/lib/shortcut-dict.lua",
      ["scripts.lib.shortcut-slots"] = "scripts/lib/shortcut-slots.lua",
      ["scripts.prototypes.custom-input"] = "scripts/prototypes/custom-input.lua",
      ["scripts.prototypes.item-group"] = "scripts/prototypes/item-group.lua",
      ["scripts.prototypes.shortcut"] = "scripts/prototypes/shortcut.lua",
      ["scripts.prototypes.style"] = "scripts/prototypes/style.lua",
      ["scripts.types.d"] = "scripts/types.d.lua",
      ["scripts.utils"] = "scripts/utils.lua",
      settings = "settings.lua"
   }
}
test_dependencies = {
   queries = {}
}
