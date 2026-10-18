---
name: m07-concurrency
description: "Use for concurrency/async. Triggers: E0277 Send Sync, cannot be sent between threads, thread, spawn, channel, mpsc, Mutex, RwLock, Atomic, async, await, Future, tokio, deadlock, race condition"
---

# Concurrency

> **Layer 1: Language Mechanics**

## Core Question

**Is this CPU-bound or I/O-bound, and what's the sharing model?**

Before choosing concurrency primitives:
- What's the workload type?
- What data needs to be shared?
- What's the thread safety requirement?

---

## Error → Design Question

| Error | Don't Just Say | Ask Instead |
|-------|----------------|-------------|
| E0277 Send | "Add Send bound" | Should this type cross threads? |
| E0277 Sync | "Wrap in Mutex" | Is shared access really needed? |
| Future not Send | "Use spawn_local" | Is async the right choice? |
| Deadlock | "Reorder locks" | Is the locking design correct? |

---

## Thinking Prompt

Before adding concurrency:

1. **What's the workload?**
   - CPU-bound → threads (std::thread, rayon)
   - I/O-bound → async (tokio, async-std)
   - Mixed → hybrid approach

2. **What's the sharing model?**
   - No sharing → message passing (channels)
   - Immutable sharing → Arc<T>
   - Mutable sharing → Arc<Mutex<T>> or Arc<RwLock<T>>

3. **What are the Send/Sync requirements?**
   - Cross-thread ownership → Send
   - Cross-thread references → Sync
   - Single-thread async → spawn_local

---

## Trace Up ↑

Don't just fix the error. Trace up to find the domain constraint that explains it.

### Domain Detection Table

| Context Keywords | Load Domain Skill | Key Constraint |
|-----------------|-------------------|----------------|
| game, Bevy, ECS, system, frame, tick, audio thread | **domain-gamedev** | Systems run in parallel; components must be Send + Sync; real-time budgets |
| CLI, terminal, clap, subcommand | **domain-cli** | Usually single-threaded; async only for network or many files |

### Example: Bevy + Rc Error

```
"Rc<T> cannot be shared between threads" in a Bevy component
    ↑ DETECT: "component" / "Bevy" → Load domain-gamedev
    ↑ FIND: domain-gamedev says "Components and Resources must be Send + Sync"
    ↑ FIND: domain-gamedev says "shared data belongs in a Resource or Asset, not in Rc"
    ↓ DESIGN: Move the shared data into a Resource (or Handle<T> to an Asset)
    ↓ IMPL: Res<MyConfig> in the system signature, or Arc<T> if it truly must be shared by value
```

### Generic Trace

```
"Send not satisfied for my type"
    ↑ Ask: What domain is this? Load domain-* skill
    ↑ Ask: Does this type need to cross thread boundaries?
    ↑ Check: m09-domain (is the data model correct?)
```

| Situation | Trace To | Question |
|-----------|----------|----------|
| Send/Sync in an ECS | **domain-gamedev** | Should this be a Resource, Asset, or per-entity Component? |
| Send/Sync in CLI | **domain-cli** | Is multi-thread really needed? |
| Mutex vs channels | m09-domain | Shared state or message passing? |
| Async vs threads | m10-performance | What's the workload profile? |

---

## Trace Down ↓

From design to implementation:

```
"Need parallelism for CPU work"
    ↓ Use: std::thread or rayon

"Need concurrency for I/O"
    ↓ Use: async/await with tokio

"Need to share immutable data across threads"
    ↓ Use: Arc<T>

"Need to share mutable data across threads"
    ↓ Use: Arc<Mutex<T>> or Arc<RwLock<T>>
    ↓ Or: channels for message passing

"Need simple atomic operations"
    ↓ Use: AtomicBool, AtomicUsize, etc.
```

---

## Send/Sync Markers

| Marker | Meaning | Example |
|--------|---------|---------|
| `Send` | Can transfer ownership between threads | Most types |
| `Sync` | Can share references between threads | `Arc<T>` |
| `!Send` | Must stay on one thread | `Rc<T>` |
| `!Sync` | No shared refs across threads | `RefCell<T>` |

## Quick Reference

| Pattern | Thread-Safe | Blocking | Use When |
|---------|-------------|----------|----------|
| `std::thread` | Yes | Yes | CPU-bound parallelism |
| `async/await` | Yes | No | I/O-bound concurrency |
| `Mutex<T>` | Yes | Yes | Shared mutable state |
| `RwLock<T>` | Yes | Yes | Read-heavy shared state |
| `mpsc::channel` | Yes | Optional | Message passing |
| `Arc<Mutex<T>>` | Yes | Yes | Shared mutable across threads |

## Decision Flowchart

```
What type of work?
├─ CPU-bound → std::thread or rayon
├─ I/O-bound → async/await
└─ Mixed → hybrid (spawn_blocking)

Need to share data?
├─ No → message passing (channels)
├─ Immutable → Arc<T>
└─ Mutable →
   ├─ Read-heavy → Arc<RwLock<T>>
   └─ Write-heavy → Arc<Mutex<T>>
   └─ Simple counter → AtomicUsize

Async context?
├─ Type is Send → tokio::spawn
├─ Type is !Send → spawn_local
└─ Blocking code → spawn_blocking
```

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| E0277 `Send` not satisfied | Non-Send in async | Use Arc or spawn_local |
| E0277 `Sync` not satisfied | Non-Sync shared | Wrap with Mutex |
| Deadlock | Lock ordering | Consistent lock order |
| `future is not Send` | Non-Send across await | Drop before await |
| `MutexGuard` across await | Guard held during suspend | Scope guard properly |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| Arc<Mutex<T>> everywhere | Contention, complexity | Message passing |
| thread::sleep in async | Blocks executor | tokio::time::sleep |
| Holding locks across await | Blocks other tasks | Scope locks tightly |
| Ignoring deadlock risk | Hard to debug | Lock ordering, try_lock |

---

## Async-Specific Patterns

### Avoid MutexGuard Across Await

```rust
// Bad: guard held across await
let guard = mutex.lock().await;
do_async().await;  // guard still held!

// Good: scope the lock
{
    let guard = mutex.lock().await;
    // use guard
}  // guard dropped
do_async().await;
```

### Non-Send Types in Async

```rust
// Rc is !Send, can't cross await in spawned task
// Option 1: use Arc instead
// Option 2: use spawn_local (single-thread runtime)
// Option 3: ensure Rc is dropped before .await
```

---

## Related Skills

| When | See |
|------|-----|
| Smart pointer choice | m02-resource |
| Interior mutability | m03-mutability |
| Performance tuning | m10-performance |
| Domain concurrency needs | domain-* |
