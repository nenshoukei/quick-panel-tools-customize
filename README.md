# Quick Panel Tool Customize

A Factorio mod that allows you to customize the tools tab of the Quick Panel, which is primarily used when playing on a Steam Deck or with a controller.

## Features

- **Rearrange Tools**: Change the order of tools in the Quick Panel to match your preference.
- **Hide Tools**: Hide specific tools that you don't frequently use, keeping your Quick Panel clean and efficient.

## Description

Ever feel "I want to install a new mod, but it adds a new tool... It pushes every tool buttons! I can't use my favorite tools as same position!" -- I felt it too.

**Quick Panel Tool Customize** gives you the freedom to organize your tools tab exactly how you want it, making your gameplay on Steam Deck or with a controller smoother and more enjoyable.

## How to use

TL;DR: Open Customize GUI on tools, customize, copy JSON, and paste it to mod Startup settings.

Because tools tab cannot be modified in-game, you need to change Mod Startup settings on Factorio title screen.

1. Install this mod.
2. Load a game, or start a new game.
3. Open Customize GUI on Tools tab in Quick Panel.
4. Customize tools as you wish.
5. Click `JSON` button to see Customize JSON.
6. Copy the Customize JSON.
7. Close the Customize GUI.
8. Save the game, and exit to the Factorio title screen.
9. Open `Settings` → `Mod settings`.
10. On Startup tab, find `Quick Panel Tools Customize`.
11. Paste the Customize JSON into `Customize JSON` textbox.
12. `Confirm` to proceed. Factorio will restart.
13. Load the game. Factorio shows Confirmation, click `Load` to proceed.
14. and enjoy!

## Compatibility

This mod uses a bit _hacky_ way to customize the tools tab since Factorio does not provide ways to hide tools.

If you hide a tool, this mod will remove it from the game on startup. (Don't worry, it's restored if you unhide it)

So any other mod trying to modify that hidden tool during the game will throw an error.

Normally, a mod only modifies a tool to toggle it, or enable/disable it. Therefore, toggle tools cannot be hidden on Customize GUI for safety, but it is still possible to throw an error if a mod to enable/disable hidden tools. So, it is not recommended to hide modded tools.

If error occurs, you have to reset your Customize JSON on Startup settings. Sorry for inconvenience.

### Technical Details

- On startup:
  - This mod overrides `ShortcutPrototype.order` to sort shortcuts (tools) by order.
  - This mod inserts a dummy shortcut as a placeholder to maintain the order of shortcuts.
  - To hide a shortcut, this mod removes its `ShortcutPrototype` by setting `data.raw["shortcut"][name] = nil`.
  - This mod sets a metatable to `data.raw["shortcut"]` to return a virtual `ShortcutPrototype` for removed keys.
  - Also, the metatable is used to detect a new shortcut added by other mods later.

## License

[The MIT License](LICENSE.md)
