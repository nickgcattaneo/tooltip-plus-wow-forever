# Production build

Write a release copy of the addon without installing it or touching a folder already in AddOns:

```bat
py scripts/install_dev.py --production
```

That creates `.release/TooltipPlus`. The folder name and `TooltipPlus.toc` match, SavedVariables stay `TooltipPlusDB`, and the version is the `## Version` line from `src/tooltip_plus.toc` (for example `1.0.0`). The dev stamp (`-dev.<git>` and `Local dev build`) is left off.

`.release/` is gitignored. Copy `.release/TooltipPlus` into `Interface\AddOns`, or zip that folder for upload. WoW loads it as **Tooltip+**.

`--production` does not watch, and it does not park or replace an AddOns install. Use [local development](development.md) for that loop.
