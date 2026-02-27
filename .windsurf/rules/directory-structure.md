---
trigger: always_on
---

# Directory Structure

- `locale/` - Localization files.
- `resources/` - Resource files such as images, sounds, etc.
- `scripts/` - Lua scripts.
  - `control/` - Runtime control scripts used by `control.lua`.
  - `gui/` - GUI components and helpers.
  - `lib/` - Shared libraries and utilities.
  - `prototypes/` - Prototype definitions for Prototype stage. One type, one file.
- `tests/` - Unit tests.

## Testing

- Use `tests/` directory for unit test files.
- Test files should follow the naming convention: `test-*.lua`.
- Use `script.on_event(defines.events.on_tick)` for test execution in development.
- Write unit tests for utility functions in `scripts/utils.lua`.
- No integration tests are needed.
