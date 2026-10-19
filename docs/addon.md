# Addon

WoW Lua has no `require`. `src/tooltip_plus.toc` loads files in order, and every file shares one table via `local addonName, ns = ...`.

- `core/`: constants, profiles, classification, anchoring, content, fade
- `types/`: one detector per hover surface (action bars, world objects / NPCs, unit frames)
- `config/`: options menu, edit mode, minimap button, slash commands
- `main.lua`: hook + `ADDON_LOADED` only
- `assets/`: minimap icon

Global settings are the template known types inherit. Pick a type from the Tooltips dropdown to override position, content, or fade for that hover surface. Unmatched tips keep the default UI and are not editable. Fade defaults to one second.

Re-anchor uses `hooksecurefunc` on `GameTooltip_SetDefaultAnchor` and `GameTooltip.SetOwner`. Those globals stay in place. Guard unit names, health, and tooltip line text with `issecretvalue` before comparing or concatenating them.

## Slash commands

Always `/tt+` or `/tooltipplus`.

- `/tt+`: open the options menu (Settings: on/off and minimap icon; Tooltip: per-profile placement)
- `/tt+ edit`: enter position edit mode
- `/tt+ profile`, `/tt+ profile list`, `/tt+ profile use <name>`, `/tt+ profile save`, `/tt+ profile save <name>`
- `/tt+ help`
- `/tt+ status`
- `/tt+ on`
- `/tt+ off`
