# Rust Code Templates

Starter code that follows the `coding-guidelines` and `unsafe-checker` skills. Copy a file into your crate and adapt it.

```
templates/
├── error-handling/
│   ├── thiserror.rs    # Library error enum with thiserror
│   └── anyhow.rs       # Application errors with anyhow + Context
├── concurrency/
│   ├── worker-pool.rs  # Thread pool for CPU-bound work (crossbeam)
│   └── async-task.rs   # tokio tasks, JoinSet, oneshot/mpsc patterns
└── ffi/
    └── safe-wrapper.rs # Safe Rust abstraction over an unsafe C API
```

| Template | Use when | Related skill |
|----------|----------|---------------|
| `thiserror.rs` | A library whose callers must match on error kinds | m06-error-handling |
| `anyhow.rs` | A binary or CLI that reports errors with context | m06-error-handling, domain-cli |
| `worker-pool.rs` | CPU-bound parallel processing | m07-concurrency |
| `async-task.rs` | I/O-bound concurrency, background loads | m07-concurrency, domain-gamedev |
| `safe-wrapper.rs` | Wrapping a C library (SDL, platform SDKs, codecs) | unsafe-checker |

```bash
cp templates/error-handling/thiserror.rs src/error.rs
```
