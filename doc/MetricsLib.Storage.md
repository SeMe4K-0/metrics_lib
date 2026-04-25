# `MetricsLib.Storage`

ETS-backed storage for raw metric samples.

Two tables are used internally:

- `:metrics_kv`      — `:set`, holds counters (atomically incremented) and gauge values.
- `:metrics_samples` — `:bag`, holds timing samples (many rows per key).

Both tables are `:public` so any process writes directly without going
through a GenServer bottleneck. `read_concurrency: true` optimises reads.

# `all_kv`

```elixir
@spec all_kv() :: list()
```

Return all counter and gauge rows.

# `all_samples`

```elixir
@spec all_samples() :: list()
```

Return all timing sample rows.

# `child_spec`

Returns a specification to start this module under a supervisor.

See `Supervisor`.

# `clear`

```elixir
@spec clear() :: :ok
```

Delete all rows from both tables.

# `gauge`

```elixir
@spec gauge(String.t(), number(), map()) :: :ok
```

Insert (overwrite) a gauge value.

# `increment`

```elixir
@spec increment(String.t(), number(), map()) :: :ok
```

Atomically increment a counter.

# `start_link`

# `timing`

```elixir
@spec timing(String.t(), number(), map()) :: :ok
```

Append a timing sample.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
