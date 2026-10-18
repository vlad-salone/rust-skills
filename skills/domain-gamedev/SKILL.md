---
name: domain-gamedev
description: "Use when building games or real-time interactive software in Rust. Keywords: game, gamedev, game engine, Bevy, ECS, entity component system, Component, Resource, System, Query, Commands, B0001, B0002, macroquad, ggez, Fyrox, wgpu, winit, shader, sprite, frame, tick, game loop, fixed timestep, delta time, physics, rapier, avian, input handling, hot reload, asset loading, save game, replay, determinism, netcode, audio thread, kira, rodio, cpal, slotmap, hecs"
globs: ["**/Cargo.toml"]
---

# Game Development Domain

> **Layer 3: Domain Constraints**

## Domain Constraints → Design Implications

| Domain Rule | Design Constraint | Rust Implication |
|-------------|-------------------|------------------|
| Frame budget (16.6 ms at 60 fps, 8.3 ms at 120) | No blocking I/O or unbounded work on the frame path | Pre-allocate, pool, offload loads to tasks (m10, m12) |
| Entities are born and die every frame | Never hold `&T` / `Rc<T>` to an entity across frames | Generational ids (`Entity`, slotmap keys), resolved each frame (m01, m02) |
| Systems run in parallel | Every system declares disjoint data access | Components and Resources are `Send + Sync`; conflicts are design errors (m03, m07) |
| Data-oriented layout | Hot loops iterate contiguous arrays | ECS archetypes / SoA over `Vec<Box<dyn GameObject>>` (m10) |
| Determinism (replays, lockstep, tests) | Same inputs → same world | Fixed timestep, seeded RNG, no `HashMap` iteration order, careful `f32` (m05) |
| Real-time audio thread | No locks, allocations or panics on the audio callback | Lock-free ring buffers, atomics, preallocated voices (m07, m10) |
| Content changes constantly | Assets load async and hot-reload | `Handle<T>` strong/weak, asset server owns the data (m12) |
| Ship on many targets | wasm32 has no threads by default, consoles restrict allocation | `cfg` gates, avoid `std::thread` in core loop, feature flags (m11) |

---

## Critical Constraints

### Access Must Be Disjoint

```
RULE: Two systems (or two queries in one system) may not both reach the
      same component mutably, or one mutably and one immutably.
WHY:  The scheduler runs systems in parallel; overlapping access is a data
      race. Bevy enforces it at system construction (B0001, B0002), the
      borrow checker enforces it inside a system (E0499, E0502).
RUST: Narrow queries with With<> / Without<>, use ParamSet, or split systems.
```

### Nothing Blocks the Frame

```
RULE: The update/render loop never waits on disk, network, a mutex held by
      another long task, or a large allocation.
WHY:  A single 50 ms stall is a visible hitch.
RUST: Spawn loads on an async task pool, poll a channel each frame, keep
      buffers alive between frames (Vec::clear, not Vec::new).
```

### References Don't Survive a Frame

```
RULE: Game objects refer to each other by id, not by reference or Rc.
WHY:  Despawns happen mid-frame; a reference would be dangling, an Rc would
      keep the corpse alive. Both hide lifecycle bugs.
RUST: Store Entity / SlotMap keys; look them up each frame; handle "gone".
```

### Audio Callback Is Hard Real-Time

```
RULE: The audio thread's callback must finish in its buffer period, every time.
WHY:  A missed deadline is an audible click.
RUST: Communicate via lock-free ring buffers (rtrb, ringbuf) and atomics;
      no Mutex, no Vec::push, no format!, no logging inside the callback.
```

---

## Trace Down ↓

From constraints to design (Layer 2) and mechanics (Layer 1):

```
"Entities need to reference each other"
    ↓ m09-domain: entity = identity, component = value
    ↓ m01-ownership: store ids, not references; owner is the World

"A system needs two overlapping queries"
    ↓ m03-mutability: express disjointness in the type (Without<>) or sequence it (ParamSet)
    ↓ If neither works → the data model is wrong: split the component

"Shared config / lookup table used by many systems"
    ↓ m02-resource: a Resource (single owner, World) accessed via Res<T>
    ↓ Not Rc, not a global static; Arc only when it crosses into non-ECS threads

"Game state is a mess of booleans"
    ↓ m05-type-driven: States enum + run conditions; typestate for menus/loading
    ↓ m15-anti-pattern: boolean-flag soup is the classic smell here

"Frame time spikes"
    ↓ m10-performance: profile (tracy, puffin, flamegraph) before changing anything
    ↓ m12-lifecycle: pools and handles own long-lived buffers

"Missing asset / corrupt save at runtime"
    ↓ m13-domain-error: dev build panics loudly; release degrades (placeholder asset, fresh save)
    ↓ m06-error-handling: Result at the loading boundary, never unwrap in systems
```

---

## Key Crates

| Purpose | Crates |
|---------|--------|
| Full engine (ECS, render, audio, UI) | bevy |
| Lightweight 2D | macroquad, ggez, comfy |
| Scene-graph engine with editor | fyrox |
| Standalone ECS | hecs, legion, shipyard (bevy_ecs also works alone) |
| Windowing / input | winit, gilrs (gamepads) |
| GPU | wgpu, glow |
| Physics | avian (ECS-native), rapier |
| Audio | kira, rodio, cpal (raw device access) |
| Lock-free queues | rtrb, ringbuf, crossbeam |
| Stable ids | slotmap, thunderdome |
| Math | glam (used by bevy, macroquad) |
| Serialization (saves, configs) | serde, ron, bincode / postcard |
| Deterministic RNG | rand with StdRng::seed_from_u64, fastrand |
| Profiling | tracy-client, puffin, bevy's own trace features |

## Design Patterns

| Pattern | Purpose | Implementation |
|---------|---------|----------------|
| Fixed timestep | Deterministic simulation | Accumulate dt, step physics at fixed rate, render with interpolation |
| ECS | Data-oriented, parallel-friendly | Components as plain structs, logic in systems |
| State machine | Menus, loading, pause | `States` enum + run conditions / typestate |
| Event queue | Decouple producers from consumers | `EventWriter` / `EventReader`, or a `Vec<Event>` drained each frame |
| Command buffer | Mutate the world safely during iteration | `Commands` applied at sync points |
| Object pool | Avoid allocation churn | Pre-spawned bullets/particles, `Vec` with `clear()` |
| Handle-based assets | Hot reload, sharing | `Handle<T>` resolved through the asset store each frame |

## Code Pattern: Fixed Timestep Loop

```rust
use std::time::{Duration, Instant};

const TICK: Duration = Duration::from_micros(16_667); // 60 Hz simulation
const MAX_FRAME: Duration = Duration::from_millis(250); // clamp after a hitch

fn run(mut world: World) {
    let mut last = Instant::now();
    let mut acc = Duration::ZERO;

    loop {
        let now = Instant::now();
        acc += (now - last).min(MAX_FRAME); // don't spiral after a stall
        last = now;

        world.handle_input();

        while acc >= TICK {
            world.fixed_update(TICK); // physics, gameplay: deterministic
            acc -= TICK;
        }

        let alpha = acc.as_secs_f32() / TICK.as_secs_f32();
        world.render(alpha); // interpolate between the last two fixed states
    }
}
```

## Code Pattern: Disjoint Queries in Bevy

```rust
// Conflict: both queries can match the same entity's Transform (B0001).
fn follow_player_bad(
    player: Query<&Transform, With<Player>>,
    mut followers: Query<&mut Transform, With<Follower>>,
) { /* ... */ }

// Fix 1: make the sets provably disjoint in the type.
fn follow_player(
    player: Query<&Transform, (With<Player>, Without<Follower>)>,
    mut followers: Query<&mut Transform, (With<Follower>, Without<Player>)>,
) {
    let Ok(target) = player.single() else { return };
    for mut t in &mut followers {
        t.translation = t.translation.lerp(target.translation, 0.1);
    }
}

// Fix 2: the sets genuinely overlap → ParamSet, one at a time.
fn follow_player_overlapping(
    mut set: ParamSet<(
        Query<&Transform, With<Player>>,
        Query<&mut Transform, With<Follower>>,
    )>,
) {
    let target = set.p0().single().map(|t| t.translation);
    if let Ok(target) = target {
        for mut t in set.p1().iter_mut() {
            t.translation = t.translation.lerp(target, 0.1);
        }
    }
}
```

---

## Common Mistakes

| Mistake | Domain Violation | Fix |
|---------|-----------------|-----|
| `Rc<T>` / `RefCell<T>` in a component | Components must be Send + Sync | Resource, Asset handle, or plain data |
| Storing `&Entity` data or `Rc<Enemy>` in another struct | References across frames | Store `Entity` id; look up; handle `Err` on despawn |
| `Vec<Box<dyn GameObject>>` with virtual `update()` | Cache-hostile, hard to parallelize | ECS, or SoA structs per kind |
| `std::fs::read` in a system | Blocks the frame | Async asset loading, poll per frame |
| `thread::sleep` to cap frame rate | Jitter, wastes a core | Fixed timestep + vsync / present mode |
| Physics stepped with variable `dt` | Non-deterministic, tunnelling | Fixed timestep with accumulator |
| `HashMap` iteration driving gameplay | Order differs between runs | `Vec`, `BTreeMap`, or a fixed hasher seed |
| `Mutex` inside the audio callback | Priority inversion, clicks | Lock-free ring buffer + atomics |
| `unwrap()` on asset lookups in systems | Crash on one missing file | Placeholder asset + logged warning in release |
| Global `static mut GAME_STATE` | UB and untestable | A Resource owned by the World (m12, unsafe-checker) |
| `f64` everywhere "for precision" | GPU and most crates want `f32`; mixing costs conversions | `f32` with origin rebasing for large worlds |

---

## Trace to Layer 1

| Constraint | Layer 2 Pattern | Layer 1 Implementation |
|------------|-----------------|------------------------|
| Disjoint access | Narrow queries, split systems | `With<>` / `Without<>` filters, `ParamSet` |
| Id-based references | Entity relationships as components | `Entity`, `slotmap::Key`, `Option<Entity>` |
| No frame blocking | Async loading, pools | `AsyncComputeTaskPool`, channels, `Vec::clear` |
| Determinism | Fixed timestep, seeded RNG | `Duration` accumulator, `StdRng::seed_from_u64` |
| Real-time audio | Producer/consumer split | `rtrb`, `AtomicU32` parameters, preallocated buffers |
| Graceful asset failure | Typed load errors | `thiserror` at the loader, `Result` to the caller |

---

## Related Skills

| When | See |
|------|-----|
| Borrow conflicts inside systems | m03-mutability |
| Who owns entity data | m01-ownership, m02-resource |
| Send/Sync on components, task pools | m07-concurrency |
| Frame time and allocation | m10-performance |
| Asset and pool lifetimes | m12-lifecycle |
| Game state as types | m05-type-driven |
| Unsafe in GPU / FFI (SDL, platform SDKs) | unsafe-checker |
| Which engine or crate | m11-ecosystem |
