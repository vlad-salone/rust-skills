# Rust Skills (lean)

A skills-only Rust assistant pack for Claude Code. It makes Claude place a Rust question on a layer, trace it to the constraint that actually decides the answer, and then fix the code.

Forked from [actionbook/rust-skills](https://github.com/actionbook/rust-skills) and cut down to the reasoning skills, two domains (CLI tools and game development), the coding guidelines and the unsafe/FFI rule set. No hooks, no background agents, no external MCP servers.

## How it works

```
Layer 3: Domain Constraints (WHY)     domain-cli, domain-gamedev
Layer 2: Design Choices    (WHAT)     m09 … m15
Layer 1: Language Mechanics (HOW)     m01 … m07, unsafe-checker
```

A borrow-checker error is a Layer 1 symptom. `rust-router` sends Claude to the mechanics skill for the error *and* to the domain skill when the question mentions a game, an ECS, a CLI, and so on. The domain skill supplies the rule that chooses between otherwise equal fixes, for example "components must be `Send + Sync`" or "errors go to stderr, data to stdout".

Example trace Claude produces before the fix:

```
Layer 1: E0502 — mutable and immutable borrow of `world` overlap
   ↑ Layer 3 (domain-gamedev): systems must declare disjoint access
   ↓ Layer 2: split into two systems, or use ParamSet / Without<> filter
Fix: ...
```

## Install

### As a Claude Code plugin (recommended)

From a local clone:

```bash
git clone <this repo> rust-skills
claude --plugin-dir /path/to/rust-skills
```

Or add it as a marketplace and install once (edit `.claude-plugin/marketplace.json` owner first):

```
/plugin marketplace add <github-user>/rust-skills
/plugin install rust-skills@rust-skills
```

### As plain skills

Works with any agent that reads `SKILL.md` directories.

```bash
# user-wide
cp -r skills/* ~/.claude/skills/

# or one project
cp -r skills/* my-project/.claude/skills/
```

### Make the router fire first

There is no hook in this pack. Skills are picked by their descriptions, which is enough for most Rust questions. If you want the router consulted every time, add this to the project's `CLAUDE.md`:

```markdown
For any Rust question (compile error, design, crate choice, performance,
unsafe) invoke the `rust-router` skill first and follow its routing.
```

## Skills

| Skill | Core question |
|-------|---------------|
| `rust-router` | Which layer does this question live on, and which skills apply? |
| `m01-ownership` | Who should own this data, and for how long? |
| `m02-resource` | Which ownership pattern does this resource need? |
| `m03-mutability` | Why does this data need to change, and who may change it? |
| `m04-zero-cost` | Compile-time or runtime polymorphism? |
| `m05-type-driven` | How can the type system prevent invalid states? |
| `m06-error-handling` | Is this failure expected or a bug? |
| `m07-concurrency` | CPU-bound or I/O-bound, and what is the sharing model? |
| `m09-domain` | What role does this concept play in the domain? |
| `m10-performance` | Where is the bottleneck, and is optimising worth it? |
| `m11-ecosystem` | Which crate fits, and how should it integrate? |
| `m12-lifecycle` | When is this resource created, used and cleaned up? |
| `m13-domain-error` | Who handles this error, and how do they recover? |
| `m14-mental-model` | What is the right way to think about this concept? |
| `m15-anti-pattern` | Is this pattern hiding a design problem? |
| `domain-cli` | Exit codes, stdout vs stderr, config precedence, clap, TUI |
| `domain-gamedev` | Frame budget, ECS disjoint access, id-based references, determinism, audio thread, assets |
| `coding-guidelines` | Rust-specific naming, style and deprecated-API rules |
| `unsafe-checker` | 47 rules for unsafe code and FFI, with checklists and a clippy mapping |

`templates/` holds starter code for `thiserror`/`anyhow` error types, a worker pool, async tasks and a safe FFI wrapper.

## Adding a domain

Copy `skills/domain-cli` to `skills/domain-<name>`, keep the section layout (constraints table, critical constraints, trace down, key crates, common mistakes, trace to Layer 1), then:

1. add the directory to `.claude-plugin/plugin.json`,
2. add a row to the Layer 3 tables in `skills/rust-router/SKILL.md`,
3. run `scripts/validate.sh`.

## Validation

```bash
scripts/validate.sh
```

Checks every `SKILL.md` has frontmatter whose `name` matches its directory, that every skill referenced in prose exists, that the plugin manifest and the `skills/` directory agree, and that no Chinese text slipped back in.

## What was removed from upstream

The prompt-submit hook and its very broad trigger regex, the background agents and slash commands, the `actionbook` MCP server and `agent-browser` dependency, the daily-report and achievement features, the web/fintech/ML/cloud-native/IoT/embedded domains, the LSP-based code-navigation skills, and the bilingual trigger words. See `CHANGELOG.md`.

## License

MIT. The original work is © ZhangHanDong and contributors; see `LICENSE`.
