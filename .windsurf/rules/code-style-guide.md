---
trigger: always_on
---

# Code Style Guide

This project is to create a mod for Factorio, a game of factories. Written in Lua.

Based on Lua 5.2.1

## General

- Follow `.editorconfig` for code formatting.
- Naming convertions:
  - constants should be `UPPER_CASE`.
  - local variables should be `lower_case`.
  - class names, module names and type names should be `UpperCamelCase`, except for `consts` and `utils`.
  - file names should be `lower-case.lua`.
- Global variables must NOT be defined.
- Write annotation comments for Lua Language Server.
  - Factorio data types are included by the editor extension.
- Variables without type inference should be explicitly typed with annotations. (@type, @class, ...)
- Functions should be explicitly type with annotations. (@param, @return, @vararg, ...)
- Prefer `arr[#arr + 1] = value` to append an element to an array than `table.insert()`.
- Prefer `for i = 1, #arr` to iterate an array than `for i, v in ipairs(arr)`.
- Do NOT use `#arr` on sparse tables.
- Define a local variable to access table fields to improve performance.
- Prefer `local function name()` to define a local function than `local name = function()`.
- Prefer `function table.name()` to define a method than `table.name = function()`.

### Error Handling

- Always validate required parameters at the beginning of functions.
- Use `assert()` for development-time checks.
- Use `if condition then return end` for early returns.

## Factorio specific

- `pairs()` / `next()`: Iteration order is guaranteed to be insertion order. Keys inserted first are iterated first.
- `require()`: File path is based on the root of the project. `..` is not allowed.
- Global variables like `data`, `script`, `game`, `prototypes`, `helpers`, `storage` are defined by Factorio.
- Top level lua files are loaded and run by Factorio for each stage:
  - Settings stage: `settings.lua` or `settings-*.lua`, to define the mod's settings by `data:extend()`.
  - Prototype stage: `data.lua` or `data-*.lua` to define the mod's prototypes by `data:extend()`.
  - Runtime stage: `control.lua` or `control-*.lua` to control the mod's behavior on the game runtime.
- Definitions of settings and prototypes cannot be changed on Runtime stage.
- Factorio supports multi-players, so all state in the game must be deterministic. Otherwise desync of state among players will happen.
- `storage` is a table which is automatically persisted by Factorio on save/load the game.
  - It is per-mod. So keys are not conflicted with other mods.
  - It can only store:
    - basic data: `nil`, strings, numbers, booleans
    - references to objects returned by the game function.
    - tables of above types.
  - To persist a table with a metatable, that metatable should be registered by `script.register_metatable()` to restore on unserialization.
  - Functions are not allowed in `storage`.
- To print debug logs, use `log()` that prints logs to log files and debug console.

## Project specific

- Use `scripts/consts.lua` to define constants.
  - Use `consts.name(id)` to get a unique name for the id. It is prefixed with the mod name.
  - Use `consts.str(key, ...)` to get a localized string under `[mks-qptc]` section in `locale/[lang]/strings.cfg`.
  - Use `consts.resource(file_name)` to get a resource file path under `resources/` directory.
- Use `scripts/utils.lua` to define pure lua utility functions that are used across the mod.
- Use `scripts/types.d.lua` to define types. This file should only contain type definitions and should not contain any executable code.
- Use `scripts/lib/gui-component.lua` to define GUI component classes.

### Directory Structure

- `locale/` - Localization files.
- `resources/` - Resource files such as images, sounds, etc.
- `scripts/` - Lua scripts.
  - `control/` - Runtime control scripts used by `control.lua`.
  - `gui/` - GUI components and helpers.
  - `lib/` - Shared libraries and utilities.
  - `prototypes/` - Prototype definitions for Prototype stage. One type, one file.
- `tests/` - Unit tests.

### Testing

- Use `tests/` directory for unit test files.
- Test files should follow the naming convention: `test-*.lua`.
- Use `script.on_event(defines.events.on_tick)` for test execution in development.
- Write unit tests for utility functions in `scripts/utils.lua`.
- No integration tests are needed.
