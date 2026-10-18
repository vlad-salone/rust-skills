---
name: rust-router
description: "Entry point for any Rust question. Use first for compile errors (E0xxx, borrow checker, lifetimes, Send/Sync), design questions, crate choice, performance, unsafe/FFI, CLI tools, and game development (Bevy, ECS, wgpu). Picks the right m01-m15, domain-*, coding-guidelines or unsafe-checker skill and traces the problem through domain, design and mechanics before answering."
globs: ["**/Cargo.toml", "**/*.rs"]
---

# Rust Question Router

## Core Principle

**Don't answer directly. Place the question on a layer first, then trace.**

```
Layer 3: Domain Constraints (WHY)
├── What the product must do: frame budgets, exit codes, determinism, UX
├── domain-cli, domain-gamedev
└── "Why is it designed this way?"

Layer 2: Design Choices (WHAT)
├── Architecture, data modelling, error strategy, lifecycle, performance
├── m09–m15
└── "What pattern should I use?"

Layer 1: Language Mechanics (HOW)
├── Ownership, borrowing, mutability, traits, errors, concurrency
├── m01–m07, unsafe-checker
└── "How do I express this in Rust?"
```

A compile error is a Layer 1 symptom. The fix that lasts usually lives one layer up.

## Routing by Entry Point

| User Signal | Entry Layer | Direction | First Skill |
|-------------|-------------|-----------|-------------|
| E0xxx error, borrow checker message | Layer 1 | Trace UP ↑ | Error table below |
| "How should I design / structure..." | Layer 2 | Check L3, then DOWN ↓ | m09-domain |
| "Building a game / CLI..." | Layer 3 | Trace DOWN ↓ | domain-* |
| "Best practice / idiomatic way..." | Layer 2 | Both directions | m15-anti-pattern |
| Performance complaint | Layer 1 → 2 | UP then DOWN | m10-performance |
| Style, naming, clippy | — | Direct | coding-guidelines |
| unsafe, FFI, raw pointers | Layer 1 | Direct, then UP | unsafe-checker |

### Dual loading when a domain is present

If the question mentions a domain, load **both** the mechanics skill and the domain skill. The domain skill supplies the constraint that decides between otherwise equal fixes.

| Domain Keywords | L1 Skill (typical) | L3 Skill |
|-----------------|--------------------|----------|
| game, Bevy, ECS, system, component, frame, tick, shader, wgpu, physics, audio thread | m01 / m03 / m07 | **domain-gamedev** |
| CLI, terminal, clap, subcommand, stdout, exit code, TUI, ratatui | m06 / m05 | **domain-cli** |

---

## Layer 1 Skills (Language Mechanics)

| Pattern | Route To |
|---------|----------|
| move, borrow, lifetime, E0382, E0597, E0106 | m01-ownership |
| Box, Rc, Arc, Weak, RefCell, Cell, smart pointer | m02-resource |
| mut, interior mutability, E0499, E0502, E0596 | m03-mutability |
| generic, trait, dyn, impl Trait, E0277, E0308, E0599 | m04-zero-cost |
| newtype, typestate, PhantomData, builder, sealed | m05-type-driven |
| Result, Option, ?, panic, anyhow, thiserror | m06-error-handling |
| Send, Sync, thread, async, channel, Mutex, deadlock | m07-concurrency |
| unsafe, FFI, extern, raw pointer, transmute, repr(C) | **unsafe-checker** |

## Layer 2 Skills (Design Choices)

| Pattern | Route To |
|---------|----------|
| domain model, entity, value object, invariant | m09-domain |
| performance, optimization, benchmark, allocation, cache | m10-performance |
| which crate, dependency, feature flag, workspace, bindings | m11-ecosystem |
| RAII, Drop, lazy init, pool, guard, cleanup | m12-lifecycle |
| error categories, retry, fallback, user-facing vs internal | m13-domain-error |
| mental model, "why does Rust", coming from another language | m14-mental-model |
| anti-pattern, code smell, idiomatic, code review | m15-anti-pattern |

## Layer 3 Skills (Domain Constraints)

| Domain Keywords | Route To |
|-----------------|----------|
| game, gamedev, Bevy, ECS, macroquad, wgpu, winit, rapier, avian, kira, frame, tick | domain-gamedev |
| CLI, command line, clap, terminal, TUI, ratatui, shell completion, exit code | domain-cli |

---

## Error Code Routing

| Error Code | Route To | Common Cause |
|------------|----------|--------------|
| E0382 | m01-ownership | Use of moved value |
| E0597 | m01-ownership | Reference outlives owner |
| E0506 | m01-ownership | Assign to borrowed value |
| E0507 | m01-ownership | Move out of borrowed content |
| E0515 | m01-ownership | Return reference to local |
| E0716 | m01-ownership | Temporary dropped while borrowed |
| E0106 | m01-ownership | Missing lifetime specifier |
| E0596 | m03-mutability | Borrow immutable as mutable |
| E0499 | m03-mutability | Two mutable borrows |
| E0502 | m03-mutability | Mutable and immutable borrow overlap |
| E0277 | m04-zero-cost, or m07 if Send/Sync | Trait bound not satisfied |
| E0308 | m04-zero-cost | Mismatched types |
| E0599 | m04-zero-cost | No method found (trait not in scope?) |
| E0038 | m04-zero-cost | Trait not dyn-compatible |
| E0433 / E0425 | m11-ecosystem | Unresolved path, missing dependency or `use` |
| E0509 | m12-lifecycle | Move out of a type that implements Drop |
| B0001 / B0002 (Bevy) | domain-gamedev + m03-mutability | Conflicting system parameters |

---

## Functional Routing

| Request | Action |
|---------|--------|
| Code style, naming, clippy lint meaning | Read **coding-guidelines** |
| Unsafe review, SAFETY comments, FFI wrapper | Read **unsafe-checker**, then the matching `rules/*.md` |
| Latest crate version, API details, MSRV | Fetch https://docs.rs/<crate> or https://crates.io/crates/<crate> with WebFetch. Never guess a version number. |
| Current Rust release or edition features | Fetch https://releases.rs or https://doc.rust-lang.org/edition-guide/ |
| Starter code for errors, workers, FFI wrappers | Copy from `templates/` at the plugin root |

---

## Keyword Conflict Resolution

| Keyword | Resolution |
|---------|------------|
| `unsafe` | unsafe-checker (more specific than m11) |
| `error` | m06 for mechanics, m13 for categorisation and recovery strategy |
| `RAII` / `Drop` | m12 for design, m02 for the smart-pointer mechanics |
| `crate` | m11 for selection and integration; WebFetch for versions |
| `performance` in a game | m10 **and** domain-gamedev (frame budget is the constraint) |
| `Mutex` / `Arc` in Bevy | domain-gamedev first: ECS usually removes the need |

**Priority:**

```
1. Error codes (E0xxx, B000x)        → direct lookup, highest priority
2. Domain keyword + error            → load BOTH domain and mechanics skill
3. Design question                   → Layer 2 skill, check Layer 3 for constraints
4. General concept                   → single mechanics skill
```

---

## How to Answer

1. **Name the entry layer and the skills loaded** in one or two lines.
2. **Trace**: state the domain constraint (if any) and the design decision it implies.
3. **Then the fix**, as code, following `coding-guidelines`.
4. If the user has tried the same fix three times, stop patching the symptom and move up a layer.

Keep the trace short. A compact form:

```
Layer 1: E0502 — mutable and immutable borrow of `world` overlap
   ↑ Layer 3 (domain-gamedev): systems must declare disjoint access
   ↓ Layer 2: split into two systems, or use ParamSet / Without<> filter
Fix: ...
```

Skip the trace entirely for trivial questions (syntax, a single method name).

---

## Default Project Settings

When creating new Rust projects or `Cargo.toml` files:

```toml
[package]
edition = "2024"          # latest stable edition

[lints.rust]
unsafe_code = "warn"

[lints.clippy]
all = "warn"
pedantic = "warn"
```

Do not pin `rust-version` unless the user asks for an MSRV; if they do, check `rustc --version` and the dependencies' MSRVs rather than guessing.

---

## Sub-Files

| File | Content |
|------|---------|
| `examples/workflow.md` | Worked routing examples for CLI and game-dev questions |
