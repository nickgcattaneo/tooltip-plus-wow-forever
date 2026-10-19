# Local development

## Copy `src` into AddOns

This skips the install script. In `Interface\AddOns`, create a folder named `TooltipPlus`. Copy the files inside `src/` into that folder (`main.lua`, `tooltip_plus.toc`, and the `core`, `config`, `types`, and `assets` folders). Do not copy the `src` folder itself.

WoW only loads a TOC whose name matches the folder, so rename `tooltip_plus.toc` to `TooltipPlus.toc`.

From the repo root, on a default Forever beta install:

```bat
xcopy /E /I /Y src\* "C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\TooltipPlus\"
ren "C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\TooltipPlus\tooltip_plus.toc" TooltipPlus.toc
```

Change the AddOns path if your client lives somewhere else. Start the client and enable **Tooltip+**. If the game is already open, `/reload`.

A later `py scripts/install_dev.py` treats this folder as a production install and parks it as `TooltipPlus.prod-disabled` before writing the script's copy.

## Install with the script

Keep this git repo outside `AddOns`. Copy the example config and set your client path:

```bat
copy config.local.example.json config.local.json
```

`config.local.json` is gitignored. Then build a dev copy and install it:

```bat
py scripts/install_dev.py
```

That writes `.release/dev/TooltipPlus` (version like `0.2.0-dev.ac3b4eb`, SavedVariables `TooltipPlusDB`) and copies it to `addons_dir\TooltipPlus`. The TOC notes line is marked `Local dev build`. If a production `TooltipPlus` folder is already present, it is renamed to `TooltipPlus.prod-disabled` first. `--watch` restores that folder when you stop the watcher. After a one-shot install, restore with:

```bat
py scripts/install_dev.py --restore-prod
```

`--keep-prod` skips parking. The install then stops if a production `TooltipPlus` is still in AddOns. Close the game if a rename fails because files are locked.

```bat
py scripts/install_dev.py --build
```

stages `.release/dev/TooltipPlus` and does not copy it. Watch source files and rebuild on change:

```bat
py scripts/install_dev.py --watch
```

Saves under `src/` start a 1s quiet timer. When writes stop, the script rebuilds. `/reload` in game to pick up the new files.

`--watch --build` updates `.release/dev/TooltipPlus` only. `TOOLTIPPLUS_ADDONS_DIR` or `--addons-dir` override the config file.

Start the client and enable **Tooltip+**.

If **Forever Mouse Tooltip** is also enabled, both addons hook the same default-anchor helper and will fight over position. Disable that one while testing Tooltip+.

## Editor

Install the Lua Language Server (`sumneko.lua`) from Cursor's extension list. `.vscode/extensions.json` recommends it.

WoW API (`ketho.wow-api`, display name **WoW API**) is on the [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=ketho.wow-api) and is not in the store Cursor searches. A VSIX is the extension's install file. The Marketplace page no longer has a download button. If VS Code is installed, open **WoW API** there, click the gear, and choose **Download VSIX**.

In Cursor, press `Ctrl+Shift+P` and run **Extensions: Install from VSIX...**, then pick that file. The Extensions view menu does not list this command.

After it is installed, the command **Activate WoW API extension** turns it on. It also turns itself on when the workspace contains a `.toc` file. This repo has `src/tooltip_plus.toc`.
