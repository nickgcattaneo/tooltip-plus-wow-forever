# tooltip-plus-wow-forever

Source for **ToolTip+**, a World of Warcraft: Forever addon that positions (and later customizes) the default game tooltip.

The GitHub repo and project config use `tooltip-plus-wow-forever`. The client loads the addon as `ToolTipPlus`, titled **ToolTip+** in the AddOns list.

## Requirements

- WoW Forever beta (`## Interface: 16001`)
- Addon folder: `World of Warcraft\_classic_beta_\Interface\AddOns\ToolTipPlus`

## Local setup

Keep this git repo outside `AddOns`, then junction the addon folder in:

```bat
mklink /J "C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\ToolTipPlus" "C:\Users\nickg\Desktop\dev\tooltip-plus-wow-forever\ToolTipPlus"
```

Start the client (or `/reload` if the folder already existed). Enable **ToolTip+** on the character screen.

If **Forever Mouse Tooltip** is also enabled, both addons hook the same default-anchor helper and will fight over position. Disable that one while testing ToolTip+.

Editor: install the recommended Cursor extensions (Lua Language Server and Ketho's WoW API).

## Slash commands

- `/tt+` or `/tooltipplus`: status and help
- `/tt+ on` / `/tt+ off`
- `/tt+ mode cursor | corner | default`
- `/tt+ corner BOTTOMRIGHT | BOTTOMLEFT | TOPRIGHT | TOPLEFT`
- `/tt+ offset <x> <y>`

## Notes

- Re-anchor uses `hooksecurefunc("GameTooltip_SetDefaultAnchor", ...)`. Do not replace that global; Forever taint plus secret values will error.
- Tooltip *content* edits come later. Guard any unit name, health, or `C_TooltipInfo` text with `issecretvalue` before comparing or concatenating.
