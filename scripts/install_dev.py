"""Build a stamped Tooltip+ dev addon and optionally install it into AddOns."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

SOURCE_ADDON_NAME = "TooltipPlus"
TITLE = "Tooltip+"
PARKED_ADDON_NAME = "TooltipPlus.prod-disabled"
LEGACY_SOURCE_ADDON_NAME = "ToolTipPlus"
OLD_DEV_ADDON_NAMES = ("TooltipPlusDev", "ToolTipPlusDev")
LEGACY_PARKED_ADDON_NAME = "ToolTipPlus.prod-disabled"
REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = REPO_ROOT / "src"
SOURCE_TOC_NAME = "tooltip_plus.toc"
STAGE_DIR = REPO_ROOT / ".release" / "dev" / SOURCE_ADDON_NAME
RELEASE_DIR = REPO_ROOT / ".release" / SOURCE_ADDON_NAME
CONFIG_PATH = REPO_ROOT / "config.local.json"
ENV_ADDONS_DIR = "TOOLTIPPLUS_ADDONS_DIR"
WATCH_SUFFIXES = {".lua", ".toc", ".xml", ".tga", ".blp", ".png", ".ogg", ".mp3", ".ttf"}
WATCH_INTERVAL = 0.25
WATCH_QUIET = 1.0


def git_short_hash() -> str | None:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=REPO_ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    sha = result.stdout.strip()
    return sha or None


def load_addons_dir(cli_value: str | None) -> Path:
    if cli_value:
        return Path(cli_value).expanduser()

    env_value = os.environ.get(ENV_ADDONS_DIR)
    if env_value:
        return Path(env_value).expanduser()

    if not CONFIG_PATH.is_file():
        example = REPO_ROOT / "config.local.example.json"
        raise SystemExit(
            f"Missing {CONFIG_PATH.name}. Copy {example.name} to "
            f"{CONFIG_PATH.name} and set addons_dir."
        )

    data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    addons_dir = data.get("addons_dir")
    if not addons_dir:
        raise SystemExit(f"{CONFIG_PATH.name} must set addons_dir.")
    return Path(str(addons_dir)).expanduser()


def toc_version(source_toc: Path) -> str:
    for line in source_toc.read_text(encoding="utf-8").splitlines():
        if line.lower().startswith("## version:"):
            return line.split(":", 1)[1].strip()
    return "0.0.0"


def stamp_toc(text: str, version: str, *, dev: bool) -> str:
    out = []
    for line in text.splitlines():
        key = line.split(":", 1)[0].strip().lower()
        if key == "## version":
            out.append(f"## Version: {version}")
        elif dev and key == "## notes":
            notes = line.split(":", 1)[1].strip()
            if "dev build" not in notes.lower():
                notes = f"{notes} Local dev build."
            out.append(f"## Notes: {notes}")
        else:
            out.append(line)
    return "\n".join(out) + "\n"


def is_link(path: Path) -> bool:
    if path.is_symlink():
        return True
    is_junction = getattr(path, "is_junction", None)
    if callable(is_junction) and is_junction():
        return True
    if os.name == "nt" and path.exists():
        import ctypes

        attrs = ctypes.windll.kernel32.GetFileAttributesW(str(path))
        return attrs != -1 and bool(attrs & 0x400)
    return False


def remove_install_dir(dest: Path, source: Path) -> None:
    # A leftover junction into the repo resolves to source. Unlink it; do not
    # rmtree, or the source addon would be deleted.
    if is_link(dest):
        dest.unlink()
        return

    if not dest.exists():
        return

    if dest.resolve() == source.resolve():
        raise SystemExit(
            f"Refusing to replace {dest}: it is the source addon folder."
        )

    shutil.rmtree(dest)


def copy_addon_files(source: Path, dest: Path, *, skip_toc: bool = False) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    skip = {".ds_store", "thumbs.db"}
    for item in source.iterdir():
        if item.name.startswith(".") or item.name.lower() in skip:
            continue
        if skip_toc and item.suffix.lower() == ".toc":
            continue
        target = dest / item.name
        if item.is_dir():
            shutil.copytree(item, target, dirs_exist_ok=True)
        else:
            shutil.copy2(item, target)


def stage_addon(stage_dir: Path, *, dev: bool) -> tuple[Path, str]:
    if not SOURCE_DIR.is_dir():
        raise SystemExit(f"Missing addon source: {SOURCE_DIR}")

    source_toc = SOURCE_DIR / SOURCE_TOC_NAME
    if not source_toc.is_file():
        raise SystemExit(f"Missing {source_toc.name}")

    version = toc_version(source_toc)
    if dev:
        sha = git_short_hash()
        version = f"{version}-dev.{sha}" if sha else f"{version}-dev"

    if stage_dir.exists():
        shutil.rmtree(stage_dir)
    copy_addon_files(SOURCE_DIR, stage_dir, skip_toc=True)

    staged_toc = stage_dir / f"{SOURCE_ADDON_NAME}.toc"
    staged_toc.write_text(
        stamp_toc(source_toc.read_text(encoding="utf-8"), version, dev=dev),
        encoding="utf-8",
        newline="\n",
    )
    return stage_dir, version


def build_dev() -> tuple[Path, str]:
    return stage_addon(STAGE_DIR, dev=True)


def build_release() -> tuple[Path, str]:
    return stage_addon(RELEASE_DIR, dev=False)


def install_dev(addons_dir: Path, staged: Path, *, replace: bool = True) -> Path:
    if not addons_dir.is_dir():
        raise SystemExit(f"AddOns directory does not exist: {addons_dir}")

    dest = addons_dir / SOURCE_ADDON_NAME
    if is_production_install(dest):
        raise SystemExit(
            f"{dest} is a production {TITLE} install. "
            "Rerun without --keep-prod so it can be parked first."
        )
    if replace or is_link(dest):
        remove_install_dir(dest, SOURCE_DIR)
    dest.mkdir(parents=True, exist_ok=True)
    copy_addon_files(staged, dest)
    if replace:
        remove_old_dev_installs(addons_dir)
    return dest


def toc_header(addon_dir: Path, field: str) -> str | None:
    names = [f"{SOURCE_ADDON_NAME}.toc", f"{LEGACY_SOURCE_ADDON_NAME}.toc"]
    names.extend(f"{name}.toc" for name in OLD_DEV_ADDON_NAMES)
    tocs = [addon_dir / name for name in names]
    if addon_dir.is_dir():
        tocs.extend(sorted(addon_dir.glob("*.toc")))
    needle = f"## {field.lower()}:"
    seen = set()
    for toc in tocs:
        key = str(toc).lower()
        if key in seen or not toc.is_file():
            continue
        seen.add(key)
        for line in toc.read_text(encoding="utf-8").splitlines():
            if line.lower().startswith(needle):
                return line.split(":", 1)[1].strip()
    return None


def toc_title(addon_dir: Path) -> str | None:
    return toc_header(addon_dir, "title")


def is_dev_title(title: str | None) -> bool:
    return title in {f"{TITLE} (dev)", "ToolTip+ (dev)"}


def is_stamped_dev_install(addon_dir: Path) -> bool:
    if is_dev_title(toc_title(addon_dir)):
        return True
    version = toc_header(addon_dir, "version")
    return version is not None and "-dev" in version.lower()


def is_production_install(addon_dir: Path) -> bool:
    if not addon_dir.exists() and not is_link(addon_dir):
        return False
    title = toc_title(addon_dir)
    return title is not None and not is_dev_title(title)


def remove_old_dev_installs(addons_dir: Path) -> None:
    """Drop a leftover TooltipPlusDev folder from the previous install layout."""
    for name in OLD_DEV_ADDON_NAMES:
        legacy = addons_dir / name
        if not (legacy.exists() or is_link(legacy)):
            continue
        if not is_stamped_dev_install(legacy):
            continue
        remove_install_dir(legacy, SOURCE_DIR)
        log(f"Removed leftover dev install {legacy}")


def park_production(addons_dir: Path) -> Path | None:
    """Rename a production TooltipPlus folder so the client cannot load it."""
    prod = addons_dir / SOURCE_ADDON_NAME
    parked = addons_dir / PARKED_ADDON_NAME

    if parked.exists() or is_link(parked):
        if is_production_install(prod):
            raise SystemExit(
                f"Both {prod.name} and {parked.name} exist. "
                f"Move or delete one, or run with --keep-prod."
            )
        log(f"Production already parked at {parked}")
        return parked

    if not is_production_install(prod):
        return None

    try:
        prod.rename(parked)
    except OSError as exc:
        raise SystemExit(
            f"Could not park {prod}. Close the game and retry, or use --keep-prod. ({exc})"
        ) from exc
    log(f"Parked production {SOURCE_ADDON_NAME} -> {parked.name}")
    return parked


def restore_production(addons_dir: Path) -> bool:
    """Put a parked production TooltipPlus folder back."""
    prod = addons_dir / SOURCE_ADDON_NAME
    parked = addons_dir / PARKED_ADDON_NAME

    if not parked.exists() and not is_link(parked):
        log(f"No parked production folder at {parked}")
        return False

    if prod.exists() or is_link(prod):
        if is_stamped_dev_install(prod):
            remove_install_dir(prod, SOURCE_DIR)
            log(f"Removed leftover dev install {prod}")
        else:
            raise SystemExit(
                f"Cannot restore {parked.name}: {prod} already exists."
            )

    try:
        parked.rename(prod)
    except OSError as exc:
        raise SystemExit(
            f"Could not restore {parked}. Close the game and retry. ({exc})"
        ) from exc
    log(f"Restored production {SOURCE_ADDON_NAME}")
    return True


def source_snapshot() -> dict[str, tuple[int, int]]:
    snapshot = {}
    if not SOURCE_DIR.is_dir():
        return snapshot
    for path in SOURCE_DIR.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix.lower() not in WATCH_SUFFIXES:
            continue
        stat = path.stat()
        snapshot[str(path.relative_to(SOURCE_DIR))] = (stat.st_mtime_ns, stat.st_size)
    return snapshot


def log(message: str) -> None:
    print(message, flush=True)


def run_once(build_only: bool, addons_dir: Path | None, *, replace: bool) -> Path | None:
    staged, version = build_dev()
    log(f"Built {SOURCE_ADDON_NAME} {version} -> {staged}")
    if build_only:
        return None
    assert addons_dir is not None
    dest = install_dev(addons_dir, staged, replace=replace)
    log(f"Installed {TITLE} -> {dest}")
    return dest


def watch(
    build_only: bool,
    addons_dir: Path | None,
    *,
    park_prod: bool,
) -> int:
    parked = False
    if park_prod and addons_dir is not None:
        parked = park_production(addons_dir) is not None or (
            addons_dir / PARKED_ADDON_NAME
        ).exists()
    try:
        run_once(build_only, addons_dir, replace=True)
        log(
            f"Watching {SOURCE_DIR} (Ctrl+C to stop). "
            f"Rebuilds after {WATCH_QUIET:.0f}s quiet. /reload in game to pick up changes."
        )
        last = source_snapshot()
        pending_since: float | None = None
        pending_snapshot: dict[str, tuple[int, int]] | None = None

        while True:
            time.sleep(WATCH_INTERVAL)
            current = source_snapshot()
            if current != last:
                if pending_snapshot != current:
                    pending_snapshot = current
                    pending_since = time.monotonic()
                    log(f"Change detected; waiting {WATCH_QUIET:.0f}s for more writes.")
                if pending_since is None or time.monotonic() - pending_since < WATCH_QUIET:
                    continue
                last = current
                pending_since = None
                pending_snapshot = None
                try:
                    run_once(build_only, addons_dir, replace=False)
                except OSError as exc:
                    print(f"Watch rebuild failed: {exc}", file=sys.stderr, flush=True)
            else:
                pending_since = None
                pending_snapshot = None
    except KeyboardInterrupt:
        log("Stopped watching.")
    finally:
        if parked and addons_dir is not None:
            restore_production(addons_dir)
            log("Reload the UI to load production Tooltip+ again.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build a Tooltip+ (dev) addon and install it into AddOns."
    )
    parser.add_argument(
        "--build",
        action="store_true",
        help="Stage .release/dev/TooltipPlus only; do not copy into AddOns.",
    )
    parser.add_argument(
        "--production",
        action="store_true",
        help="Stage .release/TooltipPlus with the TOC version. Does not install or watch.",
    )
    parser.add_argument(
        "--watch",
        action="store_true",
        help="Rebuild when files under src/ change.",
    )
    parser.add_argument(
        "--keep-prod",
        action="store_true",
        help="Do not park a production TooltipPlus folder. Install stops if it is still there.",
    )
    parser.add_argument(
        "--restore-prod",
        action="store_true",
        help="Rename TooltipPlus.prod-disabled back to TooltipPlus and exit.",
    )
    parser.add_argument(
        "--addons-dir",
        help=f"Override AddOns path (else {ENV_ADDONS_DIR} or config.local.json).",
    )
    args = parser.parse_args()

    if args.restore_prod:
        restore_production(load_addons_dir(args.addons_dir))
        return 0

    if args.production:
        if args.watch:
            raise SystemExit("--production stages a release folder and does not watch.")
        staged, version = build_release()
        log(f"Built {SOURCE_ADDON_NAME} {version} -> {staged}")
        return 0

    addons_dir = None if args.build else load_addons_dir(args.addons_dir)
    park_prod = not args.keep_prod and not args.build

    if args.watch:
        return watch(
            args.build,
            addons_dir,
            park_prod=park_prod,
        )

    if park_prod and addons_dir is not None:
        park_production(addons_dir)
    dest = run_once(args.build, addons_dir, replace=True)
    if dest is not None:
        log("Reload the UI (/reload) or restart the client if the folder is new.")
        if park_prod:
            log(f"Production stays parked until: py scripts/install_dev.py --restore-prod")
    return 0


if __name__ == "__main__":
    sys.exit(main())
