---
trigger: always_on
---

# Factorio Mod Guide

This guide provides an overview of Factorio mod development.

## Prototypes

- Prototypes are used as templates for the items, entities, recipes, etc. in the game engine.
- Prototype definitions are typed as `data.XxxPrototype` and prototypes on runtime are typed as `LuaXxxPrototype`, where `Xxx` is type of prototype.
- On Prototype stage, all prototype definitions can be accessed through `data.raw` like `data.raw["item"]["xxx"]`.
    - Prototype definitions can be modified or removed by other mods, so check theire existence first to access them.
    - To define a new prototype based on existing prototype, make a deep-copy by `table.deepcopy()` provided by Factorio.

## Data Lifecycle

Factorio has three stages at game startup and during runtime.

On each stage, top-level lua files for that stage (`[stage].lua`, `[stage]-updates.lua`, `[stage]-final-fixes.lua`) are loaded and run by Factorio.

- Settings stage: `settings.lua` or `settings-*.lua` to define the mod's settings by `data:extend()`.
- Prototype stage: `data.lua` or `data-*.lua` to define the mod's prototypes by `data:extend()`.
- Runtime stage: `control.lua` or `control-*.lua` to control the mod's behavior on the game runtime.

Each file on every mod runs in order of dependency or mod name sort. So, other mod's data at the same stage can be modified by using `[stage]-updates.lua` or `[stage]-final-fixes.lua`.

## Game Startup

At game startup, including loading a game, Factorio runs following steps:

1. Run `control.lua`, `control-updates.lua`, `control-final-fixes.lua` for every mods.
2. Is the mod new to the save?
    - Yes:
        - `on_init` event fires.
        - Migrations
    - No:
        - Migrations
        - `on_load` event fires.
3. Has the mod configuration changed?
    - Yes:
        - `on_configuration_changed` event fires.
4. Startup done.

## Runtime events

On runtime, there are several events can be hooked:

- `script.on_init()` handlers are called on starting a new game. Not at save/load the game.
    - `storage` should be initialized in this event handler. Never be on top-scope.
    - It has full access to `game` and `storage`.
- `script.on_load()` handlers are called on loading the game. Not at starting a new game.
    - Game state like `storage` must not be changed on this event. Otherwise desyncs happen.
    - Access to `game` is not available. Reading `storage` is allowed, but not writing.
    - Event handlers should be registered again by `script.on_event()`. (Not serialized)
    - The only legitimate uses of this event are these:
        - Re-setup metatables not registered with `script.register_metatable()`, as they are not persisted through the save/load cycle.
        - Re-setup event handlers.
        - Create local references to data stored in `storage`.
- `script.on_configuration_changed()` handlers are called when the mod configuration changed, including mod version changes.
    - It is also called after `on_load` when Mod startup settings changed in Factorio title screen.
    - It has full access to `game` and `storage`.

## GUI

- All GUI elements are represented as `LuaGuiElement` object in Factorio.
- `element.tags` table can be used to store custom data for the element.
    - Only basic data types (`string`, `boolean`, `number` and `table` of basic data types) are allowed.
    - Numeric keys on sparse table are converted to strings. (`[1]` becomes `["1"]`).
- Setting a string to `element.style` sets the style from `gui-style` prototype by the string key.
    - There is only one `gui-style` prototype in the game. Predefined by Factorio.
    - Accessing to `element.style` returns the style object `LuaStyle`.
- Events on GUI elements can be subscribed by `script.on_event()` with event type like `defines.events.on_gui_click`.
    - Event handler receives `event` object with `element` property that points to the GUI element.

## Localization

- All strings displayed on Factorio must be localized. Otherwise, `missing key: ...` is displayed instead.
- Localization files are stored in `locale/[lang]/[filename].cfg`.
- Localization files are INI-format files, where `[section]` is the namespace and `key=value` is the localization entry.
- A localized string is represented as `{ "namespace.key" }` in Lua code.
- Parameters can be used in localization strings as `__1__`, `__2__`, ... syntax, and `{ "namespace.key", parameter1, parameter2 }` in Lua code.
- Plural format can be used like `format-days=__1__ __plural_for_parameter_1__{1=day|rest=days}`, which results in `1 day` and `2 days`.
    - Plural format can contain other keys like `__plural_for_parameter__1__{1=__1__ player is|rest=__1__ players are}__ connecting`, which results in `1 player is connecting` and `2 players are connecting`.
- Concatenating localised strings can be done by a special array with empty string at first like `{ "", { "namespace.key1" }, { "namespace.key2" } }`.
- Some built-in placeholders are provided by Factorio:
    - `__1__`, `__2__`, ... for parameters
    - `__CONTROL_LEFT_CLICK__` for left mouse button, or B button on controller.
    - `__CONTROL_RIGHT_CLICK__` for right mouse button, or X button on controller.
    - `__CONTROL__[name]__` for custom input bindings for name, where name is `CustomInputPrototype.name`.

## Performance Considerations

- Cache frequently accessed table fields in local variables.
- Avoid expensive operations in `on_tick` event handlers.
- Use `remote.call()` for inter-mod communication instead of global variables.
- Batch operations when possible to reduce event frequency.
- Consider using `script.on_nth_tick()` for periodic tasks instead of every tick.
