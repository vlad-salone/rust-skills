# Workflow Examples

Worked examples of how rust-router places a question and traces it.

## Example 1: Error Code with Domain Context

```
User: "E0502 in my Bevy system: I iterate `Query<&Transform>` and also
       mutate `Query<&mut Transform, With<Player>>`."

1. Entry: Layer 1 (E0502 = overlapping borrows)        → m03-mutability
2. Context: "Bevy system", "Query"                      → domain-gamedev
3. Trace UP ↑
   domain-gamedev: every system must declare disjoint access so the
   scheduler can run systems in parallel. Two queries that can match the
   same entity's Transform conflict (Bevy reports this as B0001 at runtime
   even when the Rust borrow checker is satisfied).
4. Trace DOWN ↓ (Layer 2 design choice)
   - Make the queries provably disjoint: add `Without<Player>` to the
     read-only query, or
   - Use `ParamSet<(Query<..>, Query<..>)>` and access them one at a time, or
   - Split into two systems and order them.
5. Answer: show the `Without<Player>` version first (zero runtime cost,
   expresses the intent), mention ParamSet for the case where the sets
   genuinely overlap.
```

## Example 2: Design Question

```
User: "How should my CLI handle a config file, env vars and flags that
       all set the same option?"

1. Entry: Layer 2 (design question)                     → m09-domain
2. Trace UP ↑ to Layer 3:                               → domain-cli
   domain-cli constraint: precedence is flags > env > file > defaults,
   because users expect a flag to win and scripts rely on env.
3. Trace DOWN ↓ to Layer 1:
   - m05-type-driven: one `Config` struct, built by a layered builder
   - m06-error-handling: a bad file is a user-facing error on stderr,
     exit non-zero
4. Answer: clap `#[derive(Parser)]` with `env = "..."` attributes for the
   env layer, `figment` or `config` for the file layer, merge in that order.
```

## Example 3: Performance Complaint in a Game

```
User: "My frame time spikes every few seconds."

1. Entry: Layer 1 → 2 (perf)                            → m10-performance
2. Domain: game                                          → domain-gamedev
3. Trace UP ↑: frame budget is 16.6 ms at 60 fps; periodic spikes point
   to allocation bursts, asset loads on the main thread, or a growing Vec
   reallocating.
4. Trace DOWN ↓:
   - m10: profile first (tracy / puffin / `cargo flamegraph`), then
     pre-allocate, pool, or move work to an async task
   - m12-lifecycle: asset handles and pools own the long-lived buffers
5. Answer: measurement steps first, then the two or three likely fixes.
```

## Example 4: Send Error in an ECS

```
User: "`Rc<Texture>` in my component: Rc<..> cannot be sent between threads"

1. Entry: Layer 1 (E0277 Send)                          → m07-concurrency
2. Domain: component                                     → domain-gamedev
3. Trace UP ↑: components are stored in the World and systems run on any
   thread, so components must be Send + Sync. Shared, read-mostly data
   belongs in a Resource or an Asset referenced by Handle<T>.
4. Answer: replace `Rc<Texture>` with `Handle<Image>` (or a Resource);
   Arc<T> only if the data truly must live inside the component.
```

## Example 5: Pure Mechanics Question

```
User: "What's the difference between `impl Trait` in argument position
       and a generic parameter?"

1. Entry: Layer 1                                        → m04-zero-cost
2. No domain keywords, no design question → no trace needed
3. Answer directly from m04: both are static dispatch; the generic form
   lets callers use turbofish and name the type.
```
