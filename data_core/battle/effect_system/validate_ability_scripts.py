#!/usr/bin/env python3
"""Comprueba que cada AbilityId oficial tiene scripts/abilities/<id>.txt."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
ABILITY_GD = ROOT / "data_core/ability/ability.gd"
SCRIPTS = Path(__file__).resolve().parent / "scripts/abilities"
EXCLUDE = {"NONE", "COUNT", "CUSTOM_314", "CUSTOM_317"}


def parse_ids(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    start = text.find("enum Id {")
    idx = start + len("enum Id {")
    depth = 1
    end = idx
    while end < len(text) and depth:
        if text[end] == "{":
            depth += 1
        elif text[end] == "}":
            depth -= 1
        end += 1
    names: list[str] = []
    for line in text[idx : end - 1].splitlines():
        raw = line.split("#")[0].strip().rstrip(",")
        if not raw:
            continue
        name = raw.split("=")[0].strip()
        if name and name[0].isalpha():
            names.append(name)
    return names


def main() -> int:
    ids = [n for n in parse_ids(ABILITY_GD) if n not in EXCLUDE]
    missing = [n for n in ids if not (SCRIPTS / f"{n.lower()}.txt").exists()]
    empty = []
    for n in ids:
        p = SCRIPTS / f"{n.lower()}.txt"
        if not p.exists():
            continue
        lines = [
            ln
            for ln in p.read_text(encoding="utf-8").splitlines()
            if ln.strip() and not ln.strip().startswith("#")
        ]
        if not lines:
            empty.append(n)
    print(f"oficiales: {len(ids)}")
    print(f"faltan archivos: {len(missing)}")
    for m in missing:
        print(f"  MISSING {m}")
    print(f"vacíos: {len(empty)}")
    for e in empty:
        print(f"  EMPTY {e}")
    return 1 if missing or empty else 0


if __name__ == "__main__":
    raise SystemExit(main())
