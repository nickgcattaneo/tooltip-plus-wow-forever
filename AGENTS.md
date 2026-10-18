# Agents

This repo is **tooltip-plus-wow-forever**, the source for the WoW Forever addon branded **ToolTip+** in game.

## Layout

- Project / GitHub name: `tooltip-plus-wow-forever`
- Loadable addon: `ToolTipPlus/` (folder name must match `ToolTipPlus.toc`)
- In-game title: `ToolTip+`
- Slash: `/tt+` and `/tooltipplus`

Do not rename the addon folder to match the repo. Junction `ToolTipPlus/` into `_classic_beta_\Interface\AddOns\`.

## Forever rules

- TOC `## Interface: 16001`. Lua 5.1 only. No `goto`, `//`, bitwise operators, `require`, or `io`/`os`.
- Mainline-family APIs (`C_Spell`, `C_Item`, `C_AddOns`). Do not write Classic globals like `GetSpellInfo`.
- Midnight secret values are active. Guard names, health, and tooltip line text with `issecretvalue` before any compare, concat, or string op.
- Reposition tooltips with `hooksecurefunc("GameTooltip_SetDefaultAnchor", ...)`. Never replace that global.
- Nick is the author. No people-management claims in docs if this ever appears on a resume.

## Build

There is no packager yet. Edit `ToolTipPlus/`, `/reload` in the Forever client.
