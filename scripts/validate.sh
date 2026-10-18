#!/usr/bin/env bash
# Validate the skill pack: frontmatter, cross-references, manifest, no CJK text.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 -I - "$ROOT" <<'PY'
import json, pathlib, re, sys

root = pathlib.Path(sys.argv[1])
skills_dir = root / "skills"
errors, warnings = [], []

cjk = re.compile(r"[　-〿぀-ヿ一-鿿＀-￯]")
skill_ref = re.compile(r"\b(m\d{2}-[a-z-]+|domain-[a-z-]+|rust-router|coding-guidelines|unsafe-checker)\b")

dirs = sorted(p for p in skills_dir.iterdir() if p.is_dir())
names = {p.name for p in dirs}

# 1. frontmatter
for d in dirs:
    f = d / "SKILL.md"
    if not f.exists():
        errors.append(f"{d.name}: missing SKILL.md"); continue
    text = f.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        errors.append(f"{d.name}: no frontmatter"); continue
    fm = m.group(1)
    nm = re.search(r"^name:\s*(\S+)", fm, re.M)
    if not nm or nm.group(1) != d.name:
        errors.append(f"{d.name}: frontmatter name {nm.group(1) if nm else None!r} != directory")
    if not re.search(r"^description:\s*\S", fm, re.M):
        errors.append(f"{d.name}: missing description")

# 2. cross-references and CJK, across every markdown file in skills/ and templates/
for f in sorted(list(skills_dir.rglob("*.md")) + list((root / "templates").rglob("*"))):
    if not f.is_file(): continue
    text = f.read_text(encoding="utf-8", errors="replace")
    rel = f.relative_to(root)
    for i, line in enumerate(text.splitlines(), 1):
        if cjk.search(line):
            errors.append(f"{rel}:{i}: CJK text")
    for ref in set(skill_ref.findall(text)):
        if ref.endswith("-*") or ref in names: continue
        # allow generic placeholders like m0x / domain-xxx
        if re.fullmatch(r"domain-(xxx|name|driven|specific)|m0x-xxx", ref): continue
        errors.append(f"{rel}: references unknown skill '{ref}'")

# 3. manifest agrees with skills/
manifest = json.loads((root / ".claude-plugin" / "plugin.json").read_text())
listed = {pathlib.Path(s).name for s in manifest.get("skills", [])}
for missing in sorted(names - listed):
    errors.append(f"plugin.json: skill directory '{missing}' not listed")
for extra in sorted(listed - names):
    errors.append(f"plugin.json: lists '{extra}' which has no directory")

# 4. placeholders left behind
for f in [root / "LICENSE", root / ".claude-plugin" / "plugin.json", root / ".claude-plugin" / "marketplace.json"]:
    if "CHANGE_ME" in f.read_text():
        warnings.append(f"{f.relative_to(root)}: still contains CHANGE_ME")

for w in warnings: print(f"warn  {w}")
for e in errors:   print(f"error {e}")
print(f"{len(dirs)} skills checked, {len(errors)} errors, {len(warnings)} warnings")
sys.exit(1 if errors else 0)
PY
