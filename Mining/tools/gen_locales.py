#!/usr/bin/env python3
"""Fill es/pt/de/fr/id/tr locale keys from en via DeepSeek API."""
from __future__ import annotations

import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "src/shared/loc/strings"
TARGETS = ["es", "pt", "de", "fr", "id", "tr"]
SKIP = {"init.lua", "components.lua", "dailyRewards.lua"}
BATCH_SIZE = 32
API_URL = "https://api.deepseek.com/chat/completions"
MODEL = "deepseek-chat"

LANG_LABELS = {
    "es": "Spanish",
    "pt": "Brazilian Portuguese",
    "de": "German",
    "fr": "French",
    "id": "Indonesian",
    "tr": "Turkish",
}

ENTRY_RE = re.compile(r'^\t\t\["([^"]+)"\]\s*=\s*"(.*)",\s*$')
LOCALE_START = re.compile(r"^\t([a-z][a-z\-]*)\s*=\s*\{\s*$")
PLACEHOLDER_RE = re.compile(r"\{[^{}]+\}")

FALLBACK_EN: list[str] = []


def api_key() -> str:
    for name in ("DEEPSEEK_API_KEY", "DEEPSEEK_KEY"):
        val = os.environ.get(name, "").strip()
        if val:
            return val
    print("Missing DEEPSEEK_API_KEY in environment", file=sys.stderr)
    sys.exit(1)


def lua_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def placeholders(text: str) -> set[str]:
    return set(PLACEHOLDER_RE.findall(text))


def validate_translation(src: str, dst: str) -> str:
    if not dst or not dst.strip():
        return src
    if placeholders(src) != placeholders(dst):
        return src
    return dst


def parse_standard(path: Path) -> dict[str, dict[str, str]]:
    locales: dict[str, dict[str, str]] = {}
    locale: str | None = None
    for line in path.read_text(encoding="utf-8").splitlines():
        sm = LOCALE_START.match(line)
        if sm:
            locale = sm.group(1)
            locales[locale] = {}
            continue
        if locale and line.strip() == "},":
            locale = None
            continue
        if locale:
            em = ENTRY_RE.match(line)
            if em:
                locales[locale][em.group(1)] = em.group(2)
    return locales


def parse_names(path: Path) -> tuple[dict[str, str], dict[str, dict[str, str]]]:
    text = path.read_text(encoding="utf-8")
    m = re.search(
        r"local NAMES: \{ \[string\]: string \} = \{(.*?)\n\}\n\nreturn \{(.*?)\}\s*$",
        text,
        re.S,
    )
    if not m:
        return {}, {}
    names: dict[str, str] = {}
    for line in m.group(1).splitlines():
        em = re.match(r'\t\["([^"]+)"\]\s*=\s*"(.*)",\s*$', line)
        if em:
            names[em.group(1)] = em.group(2)
    locales: dict[str, dict[str, str]] = {}
    locale: str | None = None
    for line in m.group(2).splitlines():
        sm = LOCALE_START.match(line)
        if sm:
            loc = sm.group(1)
            if loc in ("ru", "en"):
                locale = None
                continue
            locale = loc
            locales[locale] = {}
            continue
        if locale and line.strip() == "},":
            locale = None
            continue
        if locale:
            em = ENTRY_RE.match(line)
            if em:
                locales[locale][em.group(1)] = em.group(2)
    return names, locales


def deepseek_translate(items: list[tuple[str, str]], target: str) -> dict[str, str]:
    if not items:
        return {}
    lang = LANG_LABELS[target]
    payload = {
        "model": MODEL,
        "temperature": 0.2,
        "response_format": {"type": "json_object"},
        "messages": [
            {
                "role": "system",
                "content": (
                    f"You translate Roblox mining-game UI strings from English to {lang}. "
                    "Return ONLY valid JSON: an object whose keys are the input keys and values are translations. "
                    "CRITICAL: copy every placeholder like {{amount}}, {{coins}}, {{name}}, {{days}} exactly — "
                    "same braces, same names, same order when multiple appear. "
                    "Keep strings concise. Do not add quotes around values beyond JSON encoding."
                ),
            },
            {
                "role": "user",
                "content": json.dumps({k: v for k, v in items}, ensure_ascii=False),
            },
        ],
    }
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        API_URL,
        data=body,
        headers={
            "Authorization": f"Bearer {api_key()}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            content = data["choices"][0]["message"]["content"]
            parsed = json.loads(content)
            if not isinstance(parsed, dict):
                raise ValueError("response is not a JSON object")
            out: dict[str, str] = {}
            for key, src in items:
                raw = parsed.get(key, src)
                if isinstance(raw, str):
                    out[key] = validate_translation(src, raw)
                else:
                    out[key] = src
                    FALLBACK_EN.append(f"{target}:{key}")
            return out
        except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError, json.JSONDecodeError, KeyError, ValueError) as e:
            wait = 1.5 * (attempt + 1)
            print(f"    API retry {attempt + 1} ({target}): {e}", flush=True)
            time.sleep(wait)
    # hard fallback
    fb = {k: v for k, v in items}
    for k, _ in items:
        FALLBACK_EN.append(f"{target}:{k}:api_fail")
    return fb


def translate_missing(keys: list[str], en: dict[str, str], target: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for i in range(0, len(keys), BATCH_SIZE):
        chunk = keys[i : i + BATCH_SIZE]
        batch = [(k, en[k]) for k in chunk]
        print(f"    {target} batch {i // BATCH_SIZE + 1}/{(len(keys) + BATCH_SIZE - 1) // BATCH_SIZE} ({len(chunk)} keys)", flush=True)
        result.update(deepseek_translate(batch, target))
        time.sleep(0.3)
    return result


def merge_standard(path: Path, locale: str, entries: dict[str, str], key_order: list[str] | None = None) -> None:
    if not entries:
        return
    lines = path.read_text(encoding="utf-8").splitlines()
    in_loc = False
    close_idx: int | None = None
    for i, line in enumerate(lines):
        sm = LOCALE_START.match(line)
        if sm and sm.group(1) == locale:
            in_loc = True
            continue
        if in_loc and line.strip() == "},":
            close_idx = i
            break
    new_lines = [f'\t\t["{k}"] = "{lua_escape(entries[k])}",' for k in (key_order or sorted(entries.keys())) if k in entries]
    if close_idx is not None:
        lines[close_idx:close_idx] = new_lines
    else:
        block = [f"\t{locale} = {{", *new_lines, "\t},"]
        if lines and lines[-1].strip() == "}":
            lines = lines[:-1] + block + ["}"]
        else:
            lines.extend(block)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def process_standard(path: Path) -> None:
    locales = parse_standard(path)
    en = locales.get("en")
    if not en:
        print(f"skip {path.name}: no en", flush=True)
        return
    key_order = list(en.keys())
    any_work = False
    for target in TARGETS:
        existing = locales.get(target, {})
        missing = [k for k in key_order if k not in existing]
        if not missing:
            continue
        any_work = True
        print(f"{path.name} -> {target}: {len(missing)} missing", flush=True)
        translated = translate_missing(missing, en, target)
        merge_standard(path, target, translated, missing)
        locales = parse_standard(path)
    if any_work:
        print(f"  updated {path.name}", flush=True)


def process_names(path: Path) -> None:
    names, locales = parse_names(path)
    if not names:
        print(f"skip {path.name}: no NAMES", flush=True)
        return
    keys = list(names.keys())
    any_work = False
    for target in TARGETS:
        existing = locales.get(target, {})
        missing = [k for k in keys if k not in existing]
        if not missing:
            continue
        any_work = True
        print(f"{path.name} -> {target}: {len(missing)} missing", flush=True)
        translated = translate_missing(missing, names, target)
        merge_standard(path, target, translated, missing)
    if any_work:
        print(f"  updated {path.name}", flush=True)


def main() -> None:
    print(f"Using env var: DEEPSEEK_API_KEY, model: {MODEL}", flush=True)
    for f in sorted(ROOT.glob("*.lua")):
        if f.name in SKIP:
            continue
        if f.name in ("ores.lua", "layers.lua"):
            process_names(f)
        else:
            process_standard(f)
    print("done", flush=True)
    if FALLBACK_EN:
        print(f"fallbacks_to_en: {len(FALLBACK_EN)}", flush=True)
        for item in FALLBACK_EN[:30]:
            print(f"  {item}", flush=True)
        if len(FALLBACK_EN) > 30:
            print(f"  ... +{len(FALLBACK_EN) - 30} more", flush=True)


if __name__ == "__main__":
    main()
