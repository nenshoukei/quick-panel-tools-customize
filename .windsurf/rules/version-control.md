---
trigger: always_on
---

# Version Control and Migrations

## Version Management

- Update `info.json` version number following semantic versioning.
- Document breaking changes in changelog.
- Use migration files for data structure changes.

## Migrations

- Create migration scripts in `migrations/` directory.
- Name migration files with version numbers: `migration-1.0.0.lua`.
- Test migrations on save files from previous versions.
- Use `script.on_configuration_changed()` for non-destructive updates.
