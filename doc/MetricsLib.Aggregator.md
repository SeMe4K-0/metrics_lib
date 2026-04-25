# `MetricsLib.Aggregator`

Periodically reads raw samples from `MetricsLib.Storage`, computes
aggregates (avg, p95, p99, rate/s), broadcasts results via PubSub, and
keeps the last 60 snapshots in state for the dashboard history.

# `child_spec`

Returns a specification to start this module under a supervisor.

See `Supervisor`.

# `history`

```elixir
@spec history() :: [map()]
```

Return up to the last 60 snapshots (newest first).

# `latest`

```elixir
@spec latest() :: map() | nil
```

Return the most recent snapshot, or nil if none computed yet.

# `start_link`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
