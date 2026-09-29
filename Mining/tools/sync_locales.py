#!/usr/bin/env python3
"""Deduplicate locale blocks and fill missing keys from en via translation."""
from __future__ import annotations

import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

try:
    from deep_translator import GoogleTranslator
except ImportError:
    print("pip install deep-translator", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[1] / "src/shared/loc/strings"
TARGETS = ["es", "pt", "de", "fr", "id", "tr"]
LANG_MAP = {t: t for t in TARGETS}
ORDER = ["ru", "en", *TARGETS]
CHUNK = 5
SKIP = {"init.lua"}

ENTRY_RE = re.compile(r'^\t\t\["([^"]+)"\]\s*=\s*"(.*)",\s*$')
LOCALE_START = re.compile(r'^\t([a-z][a-z\-]*)\s*=\s*\{\s*$')
PLACEHOLDER_RE = re.compile(r"\{[^{}]+\}")


def protect(text: str) -> tuple[str, list[str]]:
    tokens: list[str] = []

    def repl(m: re.Match[str]) -> str:
        tokens.append(m.group(0))
        return f"PH{len(tokens) - 1}TOKEN"

    return PLACEHOLDER_RE.sub(repl, text), tokens


def restore(text: str, tokens: list[str]) -> str:
    for i, tok in enumerate(tokens):
        text = text.replace(f"PH{i}TOKEN", tok)
    return text


def lua_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def parse_locales(text: str) -> dict[str, dict[str, str]]:
    locales: dict[str, dict[str, str]] = {}
    locale: str | None = None
    skip_locale: str | None = None
    for line in text.splitlines():
        sm = LOCALE_START.match(line)
        if sm:
            locale = sm.group(1)
            if locale in locales and len(locales[locale]) > 0:
                skip_locale = locale
            else:
                skip_locale = None
                locales.setdefault(locale, {})
            continue
        if locale and line.strip() == "},":
            locale = None
            skip_locale = None
            continue
        if locale and skip_locale != locale:
            em = ENTRY_RE.match(line)
            if em:
                locales[locale][em.group(1)] = em.group(2)
    return locales


def translate_values(values: list[str], target: str) -> list[str]:
    protected: list[str] = []
    token_lists: list[list[str]] = []
    for t in values:
        p, tok = protect(t)
        protected.append(p)
        token_lists.append(tok)

    def try_batch(translator, batch: list[str]) -> list[str] | None:
        for attempt in range(3):
            try:
                return translator.translate_batch(batch)
            except Exception:
                time.sleep(0.4 * (attempt + 1))
        return None

    translators = [GoogleTranslator(source="en", target=LANG_MAP[target])]
    out: list[str] = []
    for i in range(0, len(protected), CHUNK):
        batch = protected[i : i + CHUNK]
        toks = token_lists[i : i + CHUNK]
        translated: list[str] | None = None
        for tr in translators:
            translated = try_batch(tr, batch)
            if translated is not None:
                break
        if translated is None:
            translated = []
            for item in batch:
                time.sleep(0.25)
                done = False
                for tr in translators:
                    try:
                        translated.append(tr.translate(item))
                        done = True
                        break
                    except Exception:
                        continue
                if not done:
                    translated.append(item)
        for raw, tok in zip(translated, toks):
            out.append(restore(raw or "", tok))
        time.sleep(0.2)
    return out


def translate_locale(keys: list[str], values: list[str], loc: str) -> tuple[str, dict[str, str]]:
    print(f"    translate {loc} ({len(keys)} keys)", flush=True)
    return loc, dict(zip(keys, translate_values(values, loc)))


def format_file(header_lines: list[str], locales: dict[str, dict[str, str]], key_order: list[str]) -> str:
    lines = list(header_lines)
    if not lines or lines[-1].strip() != "return {":
        if lines and lines[-1].strip() == "return {":
            pass
        else:
            lines.append("return {")
    else:
        lines = lines[:-1]
        lines.append("return {")
    for loc in ORDER:
        if loc not in locales:
            continue
        entries = locales[loc]
        lines.append(f"\t{loc} = {{")
        for key in key_order:
            if key in entries:
                lines.append(f'\t\t["{key}"] = "{lua_escape(entries[key])}",')
        lines.append("\t},")
    lines.append("}")
    return "\n".join(lines) + "\n"


def process_standard(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    header: list[str] = []
    for line in text.splitlines():
        if line.strip().startswith("return {"):
            header.append(line)
            break
        header.append(line)

    locales = parse_locales(text)
    if "en" not in locales:
        print(f"skip {path.name}: no en", flush=True)
        return
    en = locales["en"]
    key_order = list(en.keys())
    missing_any = False
    for loc in TARGETS:
        bucket = locales.setdefault(loc, {})
        missing = [k for k in key_order if k not in bucket]
        if missing:
            missing_any = True
            print(f"  {path.name}: fill {loc} missing {len(missing)}", flush=True)
            values = [en[k] for k in missing]
            translated = translate_values(values, loc)
            for k, v in zip(missing, translated):
                bucket[k] = v
    if not missing_any and len([l for l in ORDER if l in locales]) >= len(ORDER):
        # still rewrite to dedupe structure
        pass
    path.write_text(format_file(header, locales, key_order), encoding="utf-8")
    print(f"  wrote {path.name}", flush=True)


def process_names(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    m = re.search(
        r"(--.*\n)*local NAMES: \{ \[string\]: string \} = \{(.*?)\n\}\n\nreturn \{",
        text,
        re.S,
    )
    if not m:
        print(f"skip names {path.name}", flush=True)
        return
    header = text[: m.start()] + "local NAMES: { [string]: string } = {" + m.group(2) + "\n}\n\n"
    locales = parse_locales(text)
    en = locales.get("en") or {}
    if not en:
        for line in m.group(2).splitlines():
            em = re.match(r'\t\["([^"]+)"\]\s*=\s*"(.*)",\s*$', line)
            if em:
                en[em.group(1)] = em.group(2)
    key_order = list(en.keys())
    for loc in ["ru", "en", *TARGETS]:
        locales.setdefault(loc, dict(en))
    for loc in TARGETS:
        bucket = locales[loc]
        missing = [k for k in key_order if k not in bucket]
        if missing:
            print(f"  {path.name}: fill {loc} missing {len(missing)}", flush=True)
            translated = translate_values([en[k] for k in missing], loc)
            for k, v in zip(missing, translated):
                bucket[k] = v
    lines = ["return {", "\tru = NAMES,", "\ten = NAMES,"]
    for loc in TARGETS:
        lines.append(f"\t{loc} = {{")
        for k in key_order:
            lines.append(f'\t\t["{k}"] = "{lua_escape(locales[loc][k])}",')
        lines.append("\t},")
    lines.append("}")
    path.write_text(header + "\n".join(lines) + "\n", encoding="utf-8")
    print(f"  wrote {path.name}", flush=True)


def main() -> None:
    files = [f for f in sorted(ROOT.glob("*.lua")) if f.name not in SKIP]
    # First pass: dedupe-only files that are complete
    for f in files:
        locales = parse_locales(f.read_text(encoding="utf-8"))
        if "en" not in locales:
            continue
        key_order = list(locales["en"].keys())
        complete = all(
            all(k in locales.get(loc, {}) for k in key_order) for loc in TARGETS
        )
        if complete:
            header: list[str] = []
            for line in f.read_text(encoding="utf-8").splitlines():
                header.append(line)
                if line.strip() == "return {":
                    break
            f.write_text(format_file(header, locales, key_order), encoding="utf-8")
            print(f"deduped {f.name}", flush=True)

    for f in files:
        if f.name in ("ores.lua", "layers.lua"):
            process_names(f)
        else:
            locales = parse_locales(f.read_text(encoding="utf-8"))
            if "en" not in locales:
                continue
            key_order = list(locales["en"].keys())
            if not all(all(k in locales.get(loc, {}) for k in key_order) for loc in TARGETS):
                process_standard(f)

    print("sync done", flush=True)


if __name__ == "__main__":
    main()
