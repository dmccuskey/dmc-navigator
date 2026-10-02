# Changelog

## 0.4.0 (2026-10-01)

### Fixed

- A push or pop while a slide runs no longer corrupts the navigator. The first slide's `enterFrame` listener was never removed: it pushed its view onto the stack again every frame, and the wrong view ended up on top. Now the running slide finishes at once, then the new one starts.
- A view can be removed in the `REMOVED_VIEW` handler: the navigator no longer touches it after the event (it crashed with `attempt to index field 'view'` on the next line).
- `popViewAnimated()` with the first view on top does nothing and returns `false`. Popping the first view used to empty the stack but keep it as the root, so the next push slid in over nothing; popping an empty navigator crashed.
- After `cleanUp()`, the next push is a new first view, shown at once.
- The nav bar works with the current DMC-Corona-UI's NavBar (`pushNavItemGetTransition()`, `popNavItemGetTransition()`), as well as the 2015 one (the same names with a leading underscore).
- The module no longer sets the global `_extend`: it uses lua_utils' `extend()` instead of its own copy.
- The example runs again: rewritten without widgets (plain buttons and a title bar), and rebuilt.

### Added

- `popToRoot( params )`.
- `navigator.top_view` and `navigator.views` (a copy of the stack).
- `popViewAnimated()` returns whether it popped.
- `Navigator.VERSION`.
- Unit tests (stand-in display, `Runtime` and clock), and `tests/run_unit.sh` to run them with plain Lua 5.1.

### Removed

- `viewIsVisible()` and `viewInMotion()`, which did nothing.
- The dmc-utils requirement (unused).

### Changed

- Rebuilt against the current dmc-corona-boot, DMC-Lua-Library and dmc-objects.

## 0.3.1 (2026-09-28)

### Fixed

- `popViewAnimated()` crashed (`attempt to index field '_nav_bar'`) when no nav bar was set.
