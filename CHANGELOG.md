# Changelog

## 0.1.0

Forked from [actionbook/rust-skills](https://github.com/actionbook/rust-skills) v2.0.9 and reduced to a skills-only pack.

### Kept
- `rust-router` (rewritten: no negotiation protocol, no mandatory output template, routes only to skills that exist here)
- Layer 1: `m01-ownership` … `m07-concurrency`
- Layer 2: `m09-domain` … `m15-anti-pattern`
- `domain-cli`
- `coding-guidelines`
- `unsafe-checker` with all 47 rules, checklists and examples
- Code templates for error handling, concurrency and FFI wrappers

### Added
- `domain-gamedev`: frame budget, ECS disjoint access, id-based references, determinism, audio-thread and asset-lifecycle constraints; Bevy B0001/B0002 routing
- `scripts/validate.sh`: frontmatter, cross-reference and plugin-manifest checks

### Removed
- The `UserPromptSubmit` hook and its broad keyword regex
- All background agents, slash commands, the actionbook MCP server and agent-browser dependency
- Daily-report, achievement, cache and dynamic-skill-generation features
- Domains: web, fintech, ML, cloud-native, IoT, embedded
- LSP-based skills (call graph, symbol analyzer, trait explorer, deps visualizer, refactor helper)
- Chinese trigger words and docs; the ASCII-art banners
