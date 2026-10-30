---
name: m10-performance
description: "Use for runtime or build performance in Rust, including symptom reports that never say 'performance'. Triggers: performance, optimization pass, benchmark, profiling, flamegraph, criterion, slow, make it faster, speed up, fps drop, frame or tick time, simulation speed, scaling to many entities, allocation, cache, SIMD, compile times, slow builds, iteration speed, hot reload"
---

# Performance Optimization

> **Layer 2: Design Choices**

## Core Question

**What's the bottleneck, and is optimization worth it?**

Before optimizing:
- Have you measured? (Don't guess)
- What's the acceptable performance?
- Will optimization add complexity?

---

## Performance Decision → Implementation

| Goal | Design Choice | Implementation |
|------|---------------|----------------|
| Reduce allocations | Pre-allocate, reuse | `with_capacity`, object pools |
| Improve cache | Contiguous data | `Vec`, `SmallVec` |
| Parallelize | Data parallelism | `rayon`, threads |
| Avoid copies | Zero-copy | References, `Cow<T>` |
| Reduce indirection | Inline data | `smallvec`, arrays |

---

## Thinking Prompt

Before optimizing:

1. **Have you measured?**
   - Profile first → cargo flamegraph, samply, tracy (see tool table for your OS)
   - Benchmark → criterion, cargo bench
   - Identify actual hotspots

2. **What's the priority?**
   - Algorithm (10x-1000x improvement)
   - Data structure (2x-10x)
   - Allocation (2x-5x)
   - Cache (1.5x-3x)

3. **What's the trade-off?**
   - Complexity vs speed
   - Memory vs CPU
   - Latency vs throughput

---

## Trace Up ↑

To domain constraints (Layer 3):

```
"How fast does this need to be?"
    ↑ Ask: What's the performance SLA?
    ↑ Check: domain-* (latency requirements)
    ↑ Check: Business requirements (acceptable response time)
```

| Question | Trace To | Ask |
|----------|----------|-----|
| Latency requirements | domain-* | What's acceptable response time? |
| Throughput needs | domain-* | How many requests per second? |
| Memory constraints | domain-* | What's the memory budget? |
| Frame or tick budget (games, simulations) | domain-gamedev | What's the budget per tick at the target speed and entity count? |

---

## Trace Down ↓

To implementation (Layer 1):

```
"Need to reduce allocations"
    ↓ m01-ownership: Use references, avoid clone
    ↓ m02-resource: Pre-allocate with_capacity

"Need to parallelize"
    ↓ m07-concurrency: Choose rayon or threads
    ↓ m07-concurrency: Consider async for I/O-bound

"Need cache efficiency"
    ↓ Data layout: Prefer Vec over HashMap when possible
    ↓ Access patterns: Sequential over random access
```

---

## Quick Reference

| Tool | Purpose | Platforms |
|------|---------|-----------|
| `cargo bench` + `criterion` or `divan` | Statistical micro-benchmarks | all |
| `cargo flamegraph` | Sampling CPU profile → SVG | Linux (perf), macOS (dtrace), Windows (built-in blondie backend, run as admin) |
| `tracy` (`tracy-client`) / `puffin` | Frame-aware instrumented profiling, live GUI | all; the default for games |
| `samply` | Sampling profiler with Firefox Profiler UI | Linux, macOS, Windows |
| Superluminal, Windows Performance Analyzer | Deep sampling + thread timelines | Windows |
| `dhat-rs` | Heap allocation profiling from inside the program | all |
| `heaptrack`, `valgrind --tool=cachegrind` | Allocation tracking, cache simulation | Linux only |
| `cargo miri` | Undefined-behaviour detection (not a profiler) | all |

## Optimization Priority

```
1. Algorithm choice     (10x - 1000x)
2. Data structure       (2x - 10x)
3. Allocation reduction (2x - 5x)
4. Cache optimization   (1.5x - 3x)
5. SIMD/Parallelism     (2x - 8x)
```

## Common Techniques

| Technique | When | How |
|-----------|------|-----|
| Pre-allocation | Known size | `Vec::with_capacity(n)` |
| Avoid cloning | Hot paths | Use references or `Cow<T>` |
| Batch operations | Many small ops | Collect then process |
| SmallVec | Usually small | `smallvec::SmallVec<[T; N]>` |
| Inline buffers | Fixed-size data | Arrays over Vec |

---

## Build and Iteration Time

Measure first: `cargo build --timings` writes an HTML report of per-crate compile time. Slow incremental rebuilds usually come from one large crate or from linking.

| Lever | How | Trade-off |
|-------|-----|-----------|
| Optimize dependencies only | `[profile.dev.package."*"] opt-level = 3` | Fast runtime in dev; your own crates still rebuild quickly |
| Faster linker | `rust-lld` (default on x86_64 Linux since Rust 1.90), `mold` on Linux, `linker = "rust-lld.exe"` for Windows MSVC in `.cargo/config.toml` | Linking often dominates incremental rebuilds |
| Split the workspace | Move stable code into its own crates | Only changed crates recompile |
| Less monomorphization | `dyn Trait` at cold boundaries (m04-zero-cost) | A little runtime for compile time |
| Cranelift backend | Nightly `-Zcodegen-backend=cranelift` for dev builds | Faster debug codegen, slower output |
| Shared cache | `sccache` | Helps clean builds and CI, not incremental |
| Hot reload | `bevy/dynamic_linking`, `subsecond` hot-patching | Fast-moving APIs: check current docs with WebFetch before recommending |

---

## Common Mistakes

| Mistake | Why Wrong | Better |
|---------|-----------|--------|
| Optimize without profiling | Wrong target | Profile first |
| Benchmark in debug mode | Meaningless | Always `--release` |
| Profile at small scale | Scaling problems hide | Profile at the target entity count and speed |
| Use LinkedList | Cache unfriendly | `Vec` or `VecDeque` |
| Hidden `.clone()` | Unnecessary allocs | Use references |
| Premature optimization | Wasted effort | Make it work first |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| Clone to avoid lifetimes | Performance cost | Proper ownership |
| Box everything | Indirection cost | Stack when possible |
| HashMap for small sets | Overhead | Vec with linear search |
| String concat in loop | O(n^2) | `String::with_capacity` or `format!` |

---

## Related Skills

| When | See |
|------|-----|
| Reducing clones | m01-ownership |
| Concurrency options | m07-concurrency |
| Smart pointer choice | m02-resource |
| Domain requirements | domain-* |
| Frame or tick budget | domain-gamedev |
| Compile time from generics | m04-zero-cost |
