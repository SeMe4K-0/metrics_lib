# `MetricsLib`

Lightweight metrics collection for Elixir applications.

## Quick start

    # In mix.exs
    {:metrics_lib, "~> 0.1"}

    # In your Application.start/2
    MetricsLib.Telemetry.attach_defaults()

## Manual instrumentation

    MetricsLib.increment("user.registered")
    MetricsLib.gauge("queue.depth", length(queue))
    MetricsLib.timing("payment.latency", elapsed_ms)

## Dashboard

Mount `MetricsLib.Dashboard.Live` in your Phoenix router:

    live "/metrics", MetricsLib.Dashboard.Live

The dashboard auto-updates every 5 seconds via Phoenix PubSub.

# `gauge`

```elixir
@spec gauge(String.t(), number(), map()) :: :ok
```

Set a gauge to an absolute value.

Gauges represent a current state (queue depth, active connections, etc.).
Only the last written value per key is kept.

## Examples

    MetricsLib.gauge("vm.memory_mb", :erlang.memory(:total) / 1_048_576)
    MetricsLib.gauge("queue.depth", 42, %{queue: "email"})

# `increment`

```elixir
@spec increment(String.t(), number(), map()) :: :ok
```

Increment a counter by `value` (default 1).

Counters accumulate within each aggregation window and are reset after
each snapshot is broadcast.

## Examples

    MetricsLib.increment("http.requests")
    MetricsLib.increment("http.requests", 1, %{method: "GET", status: 200})

# `measure`

```elixir
@spec measure(String.t(), map(), (-&gt; any())) :: any()
```

Measure the execution time of `fun` and record it as a timing.

Returns the function's return value.

## Example

    result = MetricsLib.measure("render.template", fn -> render_page() end)

# `timing`

```elixir
@spec timing(String.t(), number(), map()) :: :ok
```

Record a timing sample in milliseconds.

All samples within a window are aggregated into avg/p50/p95/p99/max.

## Examples

    start = System.monotonic_time(:millisecond)
    do_work()
    MetricsLib.timing("job.duration", System.monotonic_time(:millisecond) - start)

    # With tags
    MetricsLib.timing("db.query", 12.5, %{table: "users", op: "select"})

---

*Consult [api-reference.md](api-reference.md) for complete listing*
